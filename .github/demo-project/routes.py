"""URL route definitions and handler functions."""

from datetime import datetime


def health_check():
    """Return server health status."""
    return {
        "status": "ok",
        "uptime": "3d 14h 22m",
        "version": "1.2.0",
    }


def get_users():
    """Return list of active users."""
    return {
        "users": [
            {"id": 1, "name": "alice", "role": "admin"},
            {"id": 2, "name": "bob", "role": "engineer"},
            {"id": 3, "name": "carol", "role": "engineer"},
        ],
        "total": 3,
        "generated_at": datetime(2026, 5, 21, 12, 0, 0).isoformat(),
    }


ROUTES = {
    "/health": health_check,
    "/users": get_users,
}
