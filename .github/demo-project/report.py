"""Small runnable report for the README demo."""

import json

from routes import get_users, health_check


def build_summary():
    """Collect a deterministic status payload."""
    users = get_users()
    return {
        "service": "demo-api",
        "status": health_check()["status"],
        "active_users": users["total"],
        "roles": sorted({user["role"] for user in users["users"]}),
    }


if __name__ == "__main__":
    print(json.dumps(build_summary(), indent=2))
