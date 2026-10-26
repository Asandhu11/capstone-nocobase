import requests

from config import BASE_URL, HEALTHCHECK_PATH, HOME_PATH, REQUEST_TIMEOUT


def get_url(path=""):
    return f"{BASE_URL.rstrip('/')}" + (path if path.startswith("/") else f"/{path}")


def app_healthcheck():
    response = requests.get(
        get_url(HEALTHCHECK_PATH),
        timeout=REQUEST_TIMEOUT,
        allow_redirects=True,
    )
    return response


def app_homepage():
    response = requests.get(
        get_url(HOME_PATH),
        timeout=REQUEST_TIMEOUT,
        allow_redirects=True,
    )
    return response


def app_is_running():
    try:
        response = app_healthcheck()
        return response.status_code == 200
    except requests.RequestException:
        return False
