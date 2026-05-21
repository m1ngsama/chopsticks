"""Small helpers for the README demo server."""


def apply_cors(headers):
    """Return response headers with permissive demo CORS."""
    next_headers = dict(headers)
    next_headers["Access-Control-Allow-Origin"] = "*"
    next_headers["Access-Control-Allow-Headers"] = "Content-Type"
    return next_headers


def log_request(path):
    """Format a deterministic request log line."""
    return f"GET {path}"
