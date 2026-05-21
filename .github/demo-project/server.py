"""Lightweight HTTP server with routing and middleware."""

import json
import logging
import os
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

from middleware import apply_cors, log_request
from routes import ROUTES

logger = logging.getLogger(__name__)


def dispatch(path):
    """Route request to the matching handler."""
    logger.info(log_request(path))
    handler = ROUTES.get(path)
    if handler:
        data = handler()
        return 200, json.dumps(data)
    return 404, json.dumps({"error": "not found"})


def respond(status, body):
    """Format an HTTP response with CORS headers."""
    headers = apply_cors({})
    headers["Content-Type"] = "application/json"
    logger.info("%d (%d bytes)", status, len(body))
    return {"status": status, "headers": headers, "body": body}


class DemoHandler(BaseHTTPRequestHandler):
    """Tiny request handler for the README GIF."""

    def do_GET(self):
        status, body = dispatch(self.path)
        response = respond(status, body)
        self.send_response(response["status"])
        for name, value in response["headers"].items():
            self.send_header(name, value)
        self.end_headers()
        self.wfile.write(response["body"].encode("utf-8"))

    def log_message(self, *_args):
        return


def main():
    """Start the server."""
    port = int(os.environ.get("CHOPSTICKS_DEMO_PORT", "8080"))
    print(f"[{datetime.now():%H:%M:%S}] server running on :{port}")
    print(f"routes: {', '.join(ROUTES.keys())}")
    HTTPServer(("127.0.0.1", port), DemoHandler).serve_forever()


if __name__ == "__main__":
    main()
