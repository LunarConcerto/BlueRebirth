using System.Net;
using System.Text;
using System.Text.Json;
using BlueOath.Server.Hosting;
using BlueOath.Server.Infrastructure;
using BlueOath.Server.Protocols;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Listeners;

/// <summary>
/// GM WebUI 监听器：在独立端口上提供内嵌的 HTML 管理界面（日志流 + 命令输入框）。
/// 使用 <see cref="HttpListener"/> 实现，无需额外依赖。
/// </summary>
internal sealed class GmWebListener : BackgroundService
{
    private readonly ServerOptions _options;
    private readonly ServerEndpoints _endpoints;
    private readonly GmCommandHandler _gmHandler;
    private readonly LogBroadcastProvider _logBroadcast;
    private readonly ILogger<GmWebListener> _logger;
    private HttpListener? _listener;

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public GmWebListener(
        ServerOptions options,
        ServerEndpoints endpoints,
        GmCommandHandler gmHandler,
        LogBroadcastProvider logBroadcast,
        ILogger<GmWebListener> logger)
    {
        _options = options;
        _endpoints = endpoints;
        _gmHandler = gmHandler;
        _logBroadcast = logBroadcast;
        _logger = logger;
    }

    public override Task StartAsync(CancellationToken cancellationToken)
    {
        if (_options.GmPort is not { } port)
            return Task.CompletedTask;

        try
        {
            _listener = new HttpListener();
            _listener.Prefixes.Add($"http://localhost:{port}/");
            _listener.Start();
            _endpoints.GmPort = port;
            _logger.LogInformation("GM WebUI listening on http://localhost:{Port}", port);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "GM WebUI failed to start on port {Port} (HttpListener may need URL reservation)", port);
        }
        return base.StartAsync(cancellationToken);
    }

    public override Task StopAsync(CancellationToken cancellationToken)
    {
        try { _listener?.Stop(); } catch { }
        try { _listener?.Close(); } catch { }
        return base.StopAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var listener = _listener;
        if (listener is null)
            return;

while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    var ctx = await listener.GetContextAsync().WaitAsync(stoppingToken);
                    _ = HandleRequestAsync(ctx, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (ObjectDisposedException)
                {
                    break;
                }
                catch (HttpListenerException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "GM WebUI request error");
                }
            }
    }

    private async Task HandleRequestAsync(HttpListenerContext ctx, CancellationToken ct)
    {
        try
        {
            var path = ctx.Request.Url?.AbsolutePath ?? "/";
            if (path == "/" || path == "/index.html")
                await ServeHtmlAsync(ctx);
            else if (path == "/log")
                await ServeLogStreamAsync(ctx, ct);
            else if (path == "/gm" && ctx.Request.HttpMethod == "POST")
                await ServeGmCommandAsync(ctx, ct);
            else
            {
                ctx.Response.StatusCode = 404;
                ctx.Response.Close();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "GM WebUI handler error");
            try { ctx.Response.Abort(); } catch { }
        }
    }

    private static async Task ServeHtmlAsync(HttpListenerContext ctx)
    {
        ctx.Response.ContentType = "text/html; charset=utf-8";
        ctx.Response.Headers.Add("Cache-Control", "no-cache");
        var html = Encoding.UTF8.GetBytes(HtmlTemplate);
        ctx.Response.ContentLength64 = html.Length;
        await ctx.Response.OutputStream.WriteAsync(html);
        ctx.Response.Close();
    }

    private async Task ServeLogStreamAsync(HttpListenerContext ctx, CancellationToken ct)
    {
        ctx.Response.ContentType = "text/event-stream";
        ctx.Response.Headers.Add("Cache-Control", "no-cache");
        ctx.Response.Headers.Add("Connection", "keep-alive");

        using var writer = new StreamWriter(ctx.Response.OutputStream, Encoding.UTF8) { AutoFlush = true };

        // 先发送缓冲的历史日志
        foreach (var entry in _logBroadcast.GetBuffer())
            await WriteSseAsync(writer, entry);

        // 订阅实时日志
        var tcs = new TaskCompletionSource();
        var subscription = _logBroadcast.Subscribe(entry =>
        {
            _ = WriteSseAsync(writer, entry);
        });

        using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(ct);
        linkedCts.Token.Register(() => tcs.TrySetResult());
        try
        {
            await tcs.Task;
        }
        catch { }
        finally
        {
            subscription.Dispose();
            try { ctx.Response.Close(); } catch { }
        }
    }

    private async Task ServeGmCommandAsync(HttpListenerContext ctx, CancellationToken ct)
    {
        using var reader = new StreamReader(ctx.Request.InputStream, ctx.Request.ContentEncoding);
        var command = await reader.ReadToEndAsync();
        var result = await _gmHandler.ExecuteAsync(command.Trim(), ct);

        ctx.Response.ContentType = "text/plain; charset=utf-8";
        var bytes = Encoding.UTF8.GetBytes(result);
        ctx.Response.ContentLength64 = bytes.Length;
        await ctx.Response.OutputStream.WriteAsync(bytes);
        ctx.Response.Close();
    }

    private static async Task WriteSseAsync(StreamWriter writer, LogEntry entry)
    {
        try
        {
            var json = JsonSerializer.Serialize(entry, JsonOptions);
            await writer.WriteLineAsync($"data: {json}\n");
        }
        catch { /* 客户端断开 */ }
    }

    private const string HtmlTemplate = @"<!DOCTYPE html>
<html lang=""zh"">
<head>
<meta charset=""utf-8"">
<meta name=""viewport"" content=""width=device-width, initial-scale=1"">
<title>BlueOath GM Console</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Consolas,monospace;background:#0d1117;color:#c9d1d9;height:100vh;display:flex;flex-direction:column}
#log{flex:1;overflow-y:auto;padding:8px;font-size:13px;line-height:1.45}
#log .line{padding:1px 4px;border-bottom:1px solid #161b22}
#log .line.information{color:#8b949e}
#log .line.warning{color:#d2991d}
#log .line.error{color:#f85149}
#log .line.critical{color:#f85149;font-weight:bold}
#log .line.debug{color:#484f58}
#toolbar{display:flex;align-items:center;padding:6px;background:#161b22;border-top:1px solid #30363d}
#cmd{flex:1;padding:8px 12px;background:#0d1117;color:#c9d1d9;border:1px solid #30363d;font-family:Consolas,monospace;font-size:14px;outline:none;border-radius:4px}
#cmd:focus{border-color:#58a6ff}
#send{padding:8px 16px;margin-left:6px;background:#238636;color:#fff;border:none;cursor:pointer;font-family:Consolas,monospace;font-size:14px;border-radius:4px}
#send:hover{background:#2ea043}
#status{padding:0 8px;font-size:12px;color:#58a6ff;white-space:nowrap}
</style>
</head>
<body>
<div id=""log""></div>
<div id=""toolbar"">
  <span id=""status"">●</span>
  <input id=""cmd"" placeholder=""GM command (e.g. add_currency local-player gold 1000)"" autofocus>
  <button id=""send"" onclick=""sendCmd()"">Send</button>
</div>
<script>
const log=document.getElementById('log');
const cmd=document.getElementById('cmd');
const status=document.getElementById('status');
const evt=new EventSource('/log');
evt.onopen=function(){status.textContent='●';status.style.color='#58a6ff'};
evt.onerror=function(){status.textContent='○';status.style.color='#f85149'};
evt.onmessage=function(e){
  var d=JSON.parse(e.data);
  var div=document.createElement('div');
  div.className='line '+d.level;
  div.textContent=d.ts+' '+d.msg;
  log.appendChild(div);
  if(log.children.length>800)log.removeChild(log.firstChild);
  log.scrollTop=log.scrollHeight;
};
async function sendCmd(){
  var t=cmd.value.trim();
  if(!t)return;
  cmd.value='';
  cmd.disabled=true;
  try{
    var r=await fetch('/gm',{method:'POST',body:t});
    var txt=await r.text();
    if(txt)appendLine('information',txt);
  }catch(e){appendLine('error','[GM] '+e)}
  finally{cmd.disabled=false;cmd.focus()}
}
function appendLine(level,msg){
  var div=document.createElement('div');
  div.className='line '+level;
  div.textContent=msg;
  log.appendChild(div);
  log.scrollTop=log.scrollHeight;
}
cmd.addEventListener('keydown',function(e){if(e.key==='Enter')sendCmd()});
</script>
</body>
</html>";
}