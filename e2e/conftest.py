import time
import urllib.error
import urllib.request

import pytest

import helpers


@pytest.fixture(scope="session", autouse=True)
def website_is_up():
    """Give the site a short grace period, then fail with a clear message."""
    deadline = time.time() + 120
    last = None
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(helpers.BASE_URL + "/", timeout=5) as response:
                if response.status == 200:
                    return
        except (urllib.error.URLError, OSError) as error:
            last = error
        time.sleep(2)
    pytest.exit(f"The Clicker website did not answer at {helpers.BASE_URL}: {last}", returncode=2)


@pytest.fixture(autouse=True)
def remember_test_name(request):
    helpers.CURRENT_TEST["name"] = request.node.name
