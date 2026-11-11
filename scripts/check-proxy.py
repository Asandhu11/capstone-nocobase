#!/usr/bin/env python3
"""Validate that the Sprint 5 NGINX proxy is reachable and forwarding to NocoBase."""
import argparse
import os
import sys
import time
from urllib import error, request


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate NGINX proxy availability")
    default_base = os.getenv("PROXY_URL") or f"http://localhost:{os.getenv('PROXY_PORT', '13005')}"
    parser.add_argument("--base-url", default=default_base, help="Proxy base URL (default from PROXY_URL or PROXY_PORT)")
    parser.add_argument("--timeout", type=float, default=5.0, help="HTTP timeout in seconds")
    parser.add_argument("--retries", type=int, default=5, help="Number of attempts before failing")
    parser.add_argument("--interval", type=float, default=2.0, help="Seconds between retries")
    return parser.parse_args()


def fetch_status(url: str, timeout: float) -> tuple[int, str]:
    req = request.Request(url, headers={"User-Agent": "sprint5-proxy-check/1.0"})
    with request.urlopen(req, timeout=timeout) as resp:
        snippet = resp.read(220).decode("utf-8", errors="replace").replace("\n", " ")
        return resp.getcode(), snippet


def main() -> int:
    args = parse_args()
    base_url = args.base_url.rstrip("/")
    health_url = f"{base_url}/api/pm:listEnabled"

    print(f"Checking proxy health endpoint: {health_url}")

    last_error = ""
    for attempt in range(1, args.retries + 1):
        try:
            status, snippet = fetch_status(health_url, args.timeout)
            if status == 200:
                print(f"OK: proxy is up (status 200) on attempt {attempt}.")
                print(f"Response sample: {snippet}")
                return 0

            last_error = f"unexpected status {status}; response sample: {snippet}"
        except error.HTTPError as exc:
            last_error = f"HTTPError {exc.code}: {exc.reason}"
        except error.URLError as exc:
            last_error = f"URLError: {exc.reason}"
        except TimeoutError:
            last_error = "TimeoutError"
        except Exception as exc:  # pragma: no cover
            last_error = f"{type(exc).__name__}: {exc}"

        print(f"Attempt {attempt}/{args.retries} failed: {last_error}")
        if attempt < args.retries:
            time.sleep(args.interval)

    print("FAIL: proxy validation failed.")
    print(f"Last error: {last_error}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
