using System.Text.Json;
using BlueOath.Server.Hosting;

namespace BlueOath.Server.Protocols;

/// <summary>引导 HTTP 响应：状态码、原因短语、Content-Type 与响应体。</summary>
internal sealed record BootstrapHttpResponse(
    int StatusCode, string ReasonPhrase, string ContentType, string Body);

/// <summary>
/// 应答真实客户端在登录过程中发出的 SDK 引导 HTTP 请求（公网 IP 探测、热更版本检查、
/// 服务器列表、登录角色等）。所有响应体都经过逆向确认，字段类型（字符串/数字）需与客户端
/// 解析方式精确匹配。
/// </summary>
internal sealed class BootstrapHttpResponder(ServerEndpoints endpoints, AnnouncementConfig announcementConfig,
    ServerOptions options)
{
    private readonly ServerEndpoints _endpoints = endpoints;
    private readonly string _profileIdJson = JsonSerializer.Serialize(options.ProfileId);

    public BootstrapHttpResponse BuildResponse(string requestLine, string? host = null)
    {
        // 公网 IP 探测：返回一个假 IP，让 SDK 认为网络可用。
        if (host is not null && (host.Contains("ifconfig.io", StringComparison.OrdinalIgnoreCase) ||
            host.Contains("ipify.org", StringComparison.OrdinalIgnoreCase) ||
            host.Contains("ipinfo.io", StringComparison.OrdinalIgnoreCase) ||
            host.Contains("3322.net", StringComparison.OrdinalIgnoreCase)))
            return new(200, "OK", "text/plain; charset=utf-8", "203.0.113.1");

        if (requestLine.Contains("/phone/switch/getstate", StringComparison.OrdinalIgnoreCase))
            // switch（事件 27）在其 JSON 解析失败时会派发 errornu:"-1"。线上样本（catalog id=27）
            // 显示 errornu 是字符串，而 DNS_sw.state 被 asInt() 成数字。据此对齐：errornu 用字符串
            // "0"，state 用数字 1。
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"DNS_sw\":{\"state\":1}}");

        if (requestLine.Contains("/sdk/gettime", StringComparison.OrdinalIgnoreCase))
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"time\":" + DateTimeOffset.UtcNow.ToUnixTimeSeconds() + "}");

        if (requestLine.Contains("/phone/applereview", StringComparison.OrdinalIgnoreCase))
            // 线上响应（catalog.json id=19）用字符串 "0" 作为 errornu、数字作为 applereview。
            // applereview=1 会让 BabelTimeSDKManager.AppleReview == IS_REVIEW，从而把
            // HotPatchFacade 路由到 OnlyInitHotPatchManager（仅本地 assetmap 初始化、不请求
            // getversion），并使 Lua 的 LoginLogic:CheckUpdate 完全跳过更新检查 -> 直达登录。
            // 这样就能彻底绕开 getversion 热更下载，实现离线游玩。
            return new(200, "OK", "application/json; charset=utf-8", "{\"errornu\":\"0\",\"applereview\":1}");

        if (requestLine.Contains("/phone/getversion/", StringComparison.OrdinalIgnoreCase))
            // "script" 分支会反序列化成 SDK.ScriptInfo（而非 PackageUpdateInfo）：
            //   errornu、script=VersionInfo[]、static_url、spare_static_url。
            // VersionInfo：pl/os/groupbase/gn/path/src_version/tar_version/updateType/file/
            //   total_size/sizes/forceExit/forceUpdate。OnCallBack 用 tar_version 作为服务器版本；
            //   == 本地 assetmap 版本 "1.4.0" => NO_NEED_DOWNLOAD => FinishCheck。
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"script\":[{\"pl\":\"google_windows\",\"os\":\"android\"," +
                "\"groupbase\":\"\",\"gn\":\"jpshipgirl\",\"path\":\"\"," +
                "\"src_version\":\"1.4.0\",\"tar_version\":\"1.4.0\",\"updateType\":\"0\"," +
                "\"file\":\"\",\"total_size\":0,\"sizes\":[],\"forceExit\":0,\"forceUpdate\":0}]," +
                "\"static_url\":\"\",\"spare_static_url\":\"\"}");

        if (requestLine.Contains("/phone/getPlData/getPlData", StringComparison.OrdinalIgnoreCase))
        {
            var noticeBoardJson = "null";
            if (announcementConfig.NoticeBoard is { } nb)
            {
                noticeBoardJson = JsonSerializer.Serialize(nb);
            }
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":0,\"errordesc\":\"\",\"networkCheck\":\"1\"," +
                "\"uuid\":\"00000000-0000-4000-8000-000000000001\",\"pid\":" + _profileIdJson + "," +
                "\"serverId\":\"jp\",\"pl\":\"google_windows\",\"os\":\"android\",\"gn\":\"jpshipgirl\"," +
                "\"sensorInfo\":\"\",\"localInfo\":\"\",\"timeZoneId\":\"\"," +
                "\"screenWidth\":\"1920\",\"screenHeight\":\"1080\",\"dangerWidth\":\"0\",\"strDeviceInfo\":\"\"," +
                "\"noticeBoard\":" + noticeBoardJson + "}");
        }

        if (requestLine.Contains("/login?", StringComparison.OrdinalIgnoreCase))
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":0,\"errordesc\":\"\",\"Pid\":" + _profileIdJson + ",\"UID\":" + _profileIdJson + "," +
                "\"uid\":" + _profileIdJson + ",\"uuid\":\"00000000-0000-4000-8000-000000000001\"," +
                "\"token\":\"local-token\",\"openid\":" + _profileIdJson + ",\"ServerID\":\"jp\"," +
                "\"serverid\":\"jp\",\"newuser\":\"0\",\"qid\":\"1\",\"id\":\"1\"}");

        if (requestLine.Contains("/gethash", StringComparison.OrdinalIgnoreCase))
        {
            var gamePort = _endpoints.ResolvedGameLoginPort;
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"pid\":" + _profileIdJson + ",\"serverID\":\"game1\"," +
                "\"feignRoleId\":\"1\",\"qid\":\"1\",\"uuid\":\"00000000-0000-4000-8000-000000000001\"," +
                "\"offset\":\"0\",\"host\":\"127.0.0.1\",\"port\":" + gamePort + "}");
        }

        if (requestLine.Contains("/phone/serverlist/", StringComparison.OrdinalIgnoreCase))
        {
            var gamePort = _endpoints.ResolvedGameLoginPort;
            // SDK（new_sdk.dll 的 getServerList）不解析响应体，只把原始 JSON 存起来，
            // 由 Lua 侧（platformmanager.getServiceListAndAllServiceNotic）读取
            // result.root.notice + result.root.item[]。Lua 会把 result.errornu 与字符串 "0"
            // 比较，所以这里的 errornu 必须是带引号的 "0"（不同于 SDK 自己的 getPlData，
            // 后者是 asInt() 成数字）。
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"root\":{\"notice\":{\"open\":0,\"desc\":\"\"},\"item\":[" +
                "{\"name\":\"BlueoathRebirth\",\"serverIndex\":1,\"new\":0,\"groupid\":\"1\",\"openDateTime\":\"20171109140000\"," +
                "\"status\":1,\"hot\":0,\"host\":\"127.0.0.1\",\"port\":" + gamePort + ",\"recommend_weight\":1}" +
                "]}}");
        }

        if (requestLine.Contains("/phone/loginrole/", StringComparison.OrdinalIgnoreCase))
        {
            var gamePort = _endpoints.ResolvedGameLoginPort;
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"root\":{\"role\":[" +
                "{\"name\":\"BlueoathRebirth\",\"serverIndex\":1,\"groupid\":\"1\",\"serverId\":\"1\"," +
                "\"host\":\"127.0.0.1\",\"port\":" + gamePort + ",\"status\":1,\"openDateTime\":\"20171109140000\"}" +
                "]}}");
        }

        if (requestLine.Contains("/phone/platform/getPlatformUserInfo", StringComparison.OrdinalIgnoreCase))
            // 实名/快速登录检查（事件 1002）。LoginPage._CheckRealName 把 isFastUser == 1 或
            // idcardStatus == 1 视为「无需实名门槛」，继续走 OnSDKEnterGame ->
            // LoginLogic.CheckUpdate -> getHash -> KCP 登录。
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"data\":{" +
                "\"isFastUser\":1,\"idcardStatus\":1,\"isAdult\":1,\"OnNoRealnameLogin\":0}}");

        if (requestLine.Contains("/phone/platform/getGameMaintainNotice", StringComparison.OrdinalIgnoreCase))
        {
            var dataJson = JsonSerializer.Serialize(announcementConfig.MaintainNotices);
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"data\":" + dataJson + "}");
        }

        if (requestLine.Contains("/phone/innerbrowse", StringComparison.OrdinalIgnoreCase))
        {
            var noticearJson = JsonSerializer.Serialize(announcementConfig.InnerBrowse);
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"noticear\":" + noticearJson + "}");
        }

        if (requestLine.Contains("/phone/getuserextra/", StringComparison.OrdinalIgnoreCase))
            // 用户附加功能状态（事件 1008，LoginOk 之后）。PlatformManager.CheckUserExtraFunctionState
            // 读取 result.data.userInfo.readQuestion、result.data.payBack.returnGold/returnMonthCard
            // 和 result.data.oldUser.returnUserReceiveGift。
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"data\":{\"userInfo\":{\"readQuestion\":0}," +
                "\"payBack\":{\"returnGold\":0,\"returnMonthCard\":0}," +
                "\"oldUser\":{\"returnUserReceiveGift\":0}}}");

        if (requestLine.Contains("/c.gif", StringComparison.OrdinalIgnoreCase))
            return new(200, "OK", "text/plain; charset=utf-8", "ok");

        // CDN 主机（static1/static3.zuiyouxi.com）在 SDK 初始化（事件 31）期间提供下载测速，
        // 之后也提供热更版本清单。凡是我们尚未明确理解的路径也统一回 200，让测速成功，
        // 上面的请求行 + 主机信息会被记入日志供进一步分析。
        if (host is not null && IsCdnHost(host))
            return new(200, "OK", "text/plain; charset=utf-8", "ok");

        return new(501, "Not Implemented", "text/plain; charset=utf-8", "");
    }

    private static bool IsCdnHost(string host) =>
        host.StartsWith("static", StringComparison.OrdinalIgnoreCase) &&
        host.EndsWith(".zuiyouxi.com", StringComparison.OrdinalIgnoreCase);
}
