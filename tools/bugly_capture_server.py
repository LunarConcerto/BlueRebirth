import http.server
import os
import sys
import time

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9887
OUT = sys.argv[2] if len(sys.argv) > 2 else r"E:\逆向工程\苍蓝誓约项目\runtime\debug\bugly_capture"
os.makedirs(OUT, exist_ok=True)
counter = [0]


class Handler(http.server.BaseHTTPRequestHandler):
    def _handle(self):
        counter[0] += 1
        n = counter[0]
        try:
            length = int(self.headers.get("Content-Length", 0) or 0)
        except ValueError:
            length = 0
        body = self.rfile.read(length) if length else b""
        ts = time.strftime("%Y%m%d_%H%M%S")
        base = os.path.join(OUT, "%s_%03d" % (ts, n))
        with open(base + ".meta", "wb") as f:
            f.write((self.command + " " + self.path + " HTTP/%s\n" % self.request_version).encode("utf-8", "replace"))
            f.write(str(self.headers).encode("utf-8", "replace"))
        with open(base + ".body", "wb") as f:
            f.write(body)
        preview = body[:200]
        try:
            txt = preview.decode("utf-8", "replace")
        except Exception:
            txt = repr(preview)
        print("[%s] #%d %s %s len=%d\n  headers=%s\n  body-preview=%s" % (
            ts, n, self.command, self.path, len(body), str(self.headers).replace("\r\n", " | "), txt))
        sys.stdout.flush()
        self.send_response(200)
        self.send_header("Content-Length", "0")
        self.end_headers()

    do_GET = _handle
    do_POST = _handle
    do_PUT = _handle

    def log_message(self, *args):
        pass


print("bugly capture server on 127.0.0.1:%d -> %s" % (PORT, OUT))
http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
