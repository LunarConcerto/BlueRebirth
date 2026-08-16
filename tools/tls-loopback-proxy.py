import argparse
import asyncio
import json
import ssl
import sys


async def pipe(reader: asyncio.StreamReader, writer: asyncio.StreamWriter, label: str) -> int:
    total = 0
    try:
        while data := await reader.read(65536):
            total += len(data)
            writer.write(data)
            await writer.drain()
    except (ConnectionError, asyncio.CancelledError) as error:
        print(json.dumps({"event": "pipe-error", "label": label, "error": str(error)}), file=sys.stderr, flush=True)
    finally:
        writer.close()
    return total


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=0)
    parser.add_argument("--backend-port", type=int, required=True)
    parser.add_argument("--cert", required=True)
    parser.add_argument("--key", required=True)
    args = parser.parse_args()

    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.maximum_version = ssl.TLSVersion.TLSv1_2
    context.load_cert_chain(args.cert, args.key)
    sni_by_ssl_object: dict[int, str | None] = {}

    def on_server_name(ssl_object: ssl.SSLObject, server_name: str | None, _: ssl.SSLContext) -> None:
        sni_by_ssl_object[id(ssl_object)] = server_name
        print(json.dumps({"event": "client-hello", "sni": server_name}), file=sys.stderr, flush=True)

    context.set_servername_callback(on_server_name)

    async def handle(client_reader: asyncio.StreamReader, client_writer: asyncio.StreamWriter) -> None:
        ssl_object = client_writer.get_extra_info("ssl_object")
        sni = sni_by_ssl_object.pop(id(ssl_object), None) if ssl_object else None
        peer = client_writer.get_extra_info("peername")
        print(json.dumps({"event": "tls-ready", "sni": sni, "peer": str(peer)}), file=sys.stderr, flush=True)
        try:
            backend_reader, backend_writer = await asyncio.open_connection(
                "127.0.0.1", args.backend_port
            )
            upstream, downstream = await asyncio.gather(
                pipe(client_reader, backend_writer, "client-to-backend"),
                pipe(backend_reader, client_writer, "backend-to-client"),
            )
            print(json.dumps({"event": "closed", "sni": sni, "upstream": upstream, "downstream": downstream}), file=sys.stderr, flush=True)
        except (ConnectionError, asyncio.CancelledError) as error:
            print(json.dumps({"event": "connection-error", "sni": sni, "error": str(error)}), file=sys.stderr, flush=True)
            client_writer.close()

    def handshake_error(loop: asyncio.AbstractEventLoop, context_info: dict) -> None:
        print(json.dumps({"event": "asyncio-error", "message": context_info.get("message"), "error": str(context_info.get("exception", ""))}), file=sys.stderr, flush=True)

    asyncio.get_running_loop().set_exception_handler(handshake_error)

    server = await asyncio.start_server(
        handle, "127.0.0.1", args.port, ssl=context
    )
    port = server.sockets[0].getsockname()[1]
    print(json.dumps({"ready": True, "port": port, "backendPort": args.backend_port}), flush=True)
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
