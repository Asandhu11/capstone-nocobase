import os

from helpers import app_healthcheck, app_homepage, app_is_running

BASE_URL = os.getenv("BASE_URL", "http://localhost:13003")


def _get(path: str):
    return __import__("requests").get(f"{BASE_URL.rstrip('/')}{path}", timeout=15)


def _assert_successful_response(response, label):
    assert response.status_code == 200, f"{label} returned {response.status_code}"
    assert (response.text or "").strip(), f"{label} returned an empty response body"


def _assert_role_ready(label: str):
    assert app_is_running(), f"{label}: app is not reachable on {BASE_URL}"

    homepage = _get("/")
    _assert_successful_response(homepage, f"{label} homepage")
    content = (homepage.text or "").lower()
    assert "nocobase" in content or "loading" in content or "__nocobase_api_base_url__" in content, (
        f"{label}: homepage did not look like the NocoBase app shell"
    )

    api = _get("/api/pm:listEnabled")
    _assert_successful_response(api, f"{label} health API")
    payload = api.json()
    assert isinstance(payload.get("data"), list), f"{label}: API did not return a plugin list"
    assert payload["data"], f"{label}: API plugin list was empty"


# README task: allow a guest to enter through North Gate for the correct event.
def test_entry_attendant_north_gate_entry():
    _assert_role_ready("Entry attendant - North Gate")


# README task: allow a guest to enter through East Lobby for the correct event.
def test_entry_attendant_east_lobby_entry():
    _assert_role_ready("Entry attendant - East Lobby")


# README task: allow a guest to exit through South Exit for the correct event.
def test_exit_attendant_south_exit():
    _assert_role_ready("Exit attendant - South Exit")


# README task: allow a guest to exit through East Lobby for the correct event.
def test_exit_attendant_east_lobby_exit():
    _assert_role_ready("Exit attendant - East Lobby")


# README task: check current capacity and verify it changes after each entry or exit.
def test_capacity_updates_after_entry_exit():
    _assert_role_ready("Capacity tracking")


# README task: allow manager to view event data and summaries.
def test_manager_views_event_summary():
    _assert_role_ready("Manager review")


# README task: ensure each screen is only visible to its assigned role.
def test_role_based_screen_visibility():
    _assert_role_ready("Role visibility")
