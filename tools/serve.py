#!/usr/bin/env python3
"""Serve the f5Rocket browser prototype with Python's standard library."""

from __future__ import annotations

import argparse
import functools
import mimetypes
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


class F5RocketRequestHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".css": "text/css; charset=utf-8",
        ".html": "text/html; charset=utf-8",
        ".js": "text/javascript; charset=utf-8",
        ".json": "application/json; charset=utf-8",
        ".png": "image/png",
        ".svg": "image/svg+xml",
    }

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Serve the f5Rocket local prototype.")
    parser.add_argument("--host", default="127.0.0.1", help="Bind host (default: 127.0.0.1)")
    parser.add_argument("--port", default=8080, type=int, help="Bind port (default: 8080)")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    mimetypes.add_type("image/svg+xml", ".svg")
    mimetypes.add_type("text/javascript", ".js")
    handler = functools.partial(F5RocketRequestHandler, directory=str(PROJECT_ROOT))
    server = ThreadingHTTPServer((args.host, args.port), handler)
    display_host = "localhost" if args.host in {"127.0.0.1", "0.0.0.0"} else args.host
    print(f"f5Rocket preview: http://{display_host}:{args.port}", flush=True)
    print(f"Serving: {PROJECT_ROOT}", flush=True)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping f5Rocket preview.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
