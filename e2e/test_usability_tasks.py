"""End-to-end tests for the six usability-test tasks in docs/usability-test-plan.md.

Each test follows one task from the plan, step by step, through a real browser:
no direct database or API shortcuts. Task 1 adds one person and Task 2 removes one,
and Task 3 adds and removes one person again, so the head-counts end where they began.
"""
import pytest
from selenium.webdriver.common.by import By

import helpers
from helpers import (card, choose, inside_now, manager_rows, option_texts, quote, record_button,
                     record_one, recent_rows, signed_in, visible, wait, wait_for_manager_table)

HARBOR_EVENT = "Harbor Community Night"
ENTRY_STATION = "North Gate"
EXIT_STATION = "South Exit"


def test_task1_entry_attendant_records_one_person_entering():
    """Task 1: As the entryway attendant, let one person in through the North Gate."""
    with signed_in("entry") as driver:
        # Nothing can be counted until an event and a station are chosen.
        assert not record_button(driver, "entry").is_enabled()
        assert inside_now_text(driver) == "--"

        choose(driver, "entry-event", HARBOR_EVENT)
        # Only stations that make sense for entering this venue are offered.
        stations = option_texts(driver, "entry-station")
        assert stations == [ENTRY_STATION], stations

        before, after = record_one(driver, "entry", HARBOR_EVENT, ENTRY_STATION)
        assert after == before + 1

        # The page confirms it and lists the new record at the top.
        newest = recent_rows(driver)[0]
        assert HARBOR_EVENT in newest and ENTRY_STATION in newest and "1 entry" in newest


def test_task2_exit_attendant_records_one_person_leaving():
    """Task 2: As the exit attendant, let one person out through the South Exit."""
    with signed_in("exit") as driver:
        assert not record_button(driver, "exit").is_enabled()

        choose(driver, "exit-event", HARBOR_EVENT)
        stations = option_texts(driver, "exit-station")
        assert stations == [EXIT_STATION], stations

        before, after = record_one(driver, "exit", HARBOR_EVENT, EXIT_STATION)
        assert after == before - 1

        newest = recent_rows(driver)[0]
        assert HARBOR_EVENT in newest and EXIT_STATION in newest and "1 exit" in newest


def test_task3_manager_checks_current_attendance_and_sees_new_activity():
    """Task 3: As the manager, read how many people are inside, then check that a
    new entry and exit recorded by the attendants show up after a refresh."""
    with signed_in("manager") as driver:
        wait_for_manager_table(driver)
        rows = manager_rows(driver)
        names = {r["name"] for r in rows}
        assert {HARBOR_EVENT, "Eastside Open Gym", "Harbor Workshop"} <= names

        entries, exits, inside = card(driver, "TOTAL ENTRIES"), card(driver, "TOTAL EXITS"), card(driver, "CURRENTLY INSIDE")
        # The summary cards must agree with each other and with the table below them.
        assert inside == entries - exits
        assert inside == sum(r["inside"] for r in rows)
        workshop = next(r for r in rows if r["name"] == "Harbor Workshop")
        assert workshop["status"].lower() == "closed" and workshop["inside"] == 0

    with signed_in("entry") as driver:
        record_one(driver, "entry", HARBOR_EVENT, ENTRY_STATION)

    with signed_in("manager") as driver:
        wait_for_manager_table(driver)
        assert card(driver, "TOTAL ENTRIES") == entries + 1
        assert card(driver, "CURRENTLY INSIDE") == inside + 1

    with signed_in("exit") as driver:
        record_one(driver, "exit", HARBOR_EVENT, EXIT_STATION)

    with signed_in("manager") as driver:
        wait_for_manager_table(driver)
        assert card(driver, "TOTAL EXITS") == exits + 1
        assert card(driver, "CURRENTLY INSIDE") == inside


def test_task4_manager_narrows_the_list_to_find_one_event():
    """Task 4: As the manager, find a single event using the filters and search box."""
    with signed_in("manager") as driver:
        wait_for_manager_table(driver)
        assert len(manager_rows(driver)) >= 3

        choose(driver, "attendance-venue", "Harbor Center")
        wait(driver).until(lambda d: {r["venue"] for r in manager_rows(d)} == {"Harbor Center"})
        assert {r["name"] for r in manager_rows(driver)} == {HARBOR_EVENT, "Harbor Workshop"}

        driver.find_element(By.ID, "attendance-search").send_keys("Workshop")
        wait(driver).until(lambda d: [r["name"] for r in manager_rows(d)] == ["Harbor Workshop"])

        # Combining it with a status that no longer matches gives a clear empty message.
        choose(driver, "attendance-status", "Active")
        visible(driver, "//*[contains(normalize-space(.), 'No events match these filters.')]")
        assert manager_rows(driver) == []


def test_task5_attendant_recovers_from_a_wrong_password():
    """Task 5: An attendant mistypes the password, notices the error, and signs in again."""
    driver = helpers.make_driver()
    try:
        helpers.open_sign_in(driver)
        helpers.submit_credentials(driver, helpers.ACCOUNTS["entry"], "not-the-password")
        # An error is shown and the person is still on the sign-in page.
        helpers.wait_for_sign_in_error(driver)
        assert not helpers.present_now(driver, "//h1[normalize-space()='Entryway attendant']")

        # The person types the right password. If the first click does not take (the page
        # is still settling after the error), they simply click Sign in again, up to 3 tries.
        helpers.sign_in_again(driver, "entry")
    except Exception:
        helpers.save_artifacts(driver, "sign-in")
        raise
    finally:
        driver.quit()


@pytest.mark.parametrize("role, forbidden", [
    ("entry", ["Manager attendance", "Exit attendant", "Record one exit"]),
    ("exit", ["Manager attendance", "Entryway attendant", "Record one entry"]),
])
def test_task6_attendants_only_see_their_own_screen(role, forbidden):
    """Task 6 (part 1): An attendant cannot reach the other roles' screens or buttons."""
    with signed_in(role) as driver:
        page_text = driver.find_element(By.TAG_NAME, "body").text
        for text in forbidden:
            if text == helpers.HEADINGS[role]:
                continue
            assert text not in page_text, f"{role} account can see '{text}'"


def test_task6_manager_screen_is_read_only():
    """Task 6 (part 2): The manager can look but not change anything."""
    with signed_in("manager") as driver:
        wait_for_manager_table(driver)
        page_text = driver.find_element(By.TAG_NAME, "body").text
        for text in ("Record one entry", "Record one exit", "Entryway attendant", "Exit attendant"):
            assert text not in page_text, f"manager account can see '{text}'"
        buttons = [b.text.strip() for b in driver.find_elements(By.TAG_NAME, "button") if b.is_displayed()]
        for word in ("Edit", "Delete", "Add new", "Submit", "Record"):
            assert not any(word.lower() in label.lower() for label in buttons), buttons


def inside_now_text(driver):
    return driver.find_element(
        By.XPATH, "//div[normalize-space()='PEOPLE INSIDE THIS EVENT']/following-sibling::div[1]").text
