"""Six user tasks from docs/sprint4/usability-plan.md; no mocked browser or API.

API calls create fictional preconditions and independently verify persistence.
All actions being assessed (login, selection, counting, filtering) use the UI.
"""
import pytest
from selenium.webdriver.common.by import By

from pages import Clicker


@pytest.mark.parametrize('role', ['entry', 'exit', 'manager'])
def test_t1_sign_in_to_assigned_screen(driver, role):
    page = Clicker(driver)
    page.login(role)
    headings = [e.text for e in driver.find_elements(By.TAG_NAME, 'h1') if e.is_displayed()]
    assert headings == [{'entry': 'Entryway attendant', 'exit': 'Exit attendant', 'manager': 'Manager attendance'}[role]]


def test_t2_record_one_entry_and_check_it_persists(driver, api):
    case = api.scenario('Entry')
    page = Clicker(driver)
    page.login('entry')
    assert not page.button('+ Record one entry').is_enabled()
    page.select('entry-event', case['event_option'])
    assert not page.button('+ Record one entry').is_enabled()
    assert page.station_options('entry') == [case['stations']['Entry Gate']['name']]
    page.select('entry-station', case['stations']['Entry Gate']['name'])
    page.wait_inside(2)
    page.count('entry')
    page.wait_inside(3)
    assert '3 in venue / 5 capacity' in driver.find_element(By.TAG_NAME, 'body').text
    assert int(api.event(case)['totalEntries']) == 3
    assert int(api.venue(case)['currentCount']) == 3
    driver.refresh()
    page.choose('entry', case)
    page.wait_inside(3)
    assert case['stations']['Entry Gate']['name'] in page.visible(By.CSS_SELECTOR, '.ant-table-tbody').text


def test_t3_record_one_exit_and_stop_at_zero(driver, api):
    case = api.scenario('Exit', inside=1)
    page = Clicker(driver)
    page.login('exit')
    assert not page.button('- Record one exit').is_enabled()
    page.select('exit-event', case['event_option'])
    assert page.station_options('exit') == [case['stations']['Exit Gate']['name']]
    page.select('exit-station', case['stations']['Exit Gate']['name'])
    page.wait_inside(1)
    page.count('exit')
    page.wait_inside(0)
    page.text('This event is empty. An exit cannot reduce attendance below zero.')
    assert not page.button('- Record one exit').is_enabled()
    assert int(api.event(case)['totalExits']) == 1
    assert int(api.venue(case)['currentCount']) == 0
    driver.refresh()
    page.choose('exit', case)
    page.wait_inside(0)
    assert not page.button('- Record one exit').is_enabled()


def test_t4_fill_last_space_and_block_further_entry(driver, api):
    case = api.scenario('Capacity', inside=4, capacity=5)
    page = Clicker(driver)
    page.login('entry')
    page.choose('entry', case)
    page.text('1 spaces remaining at the venue')
    page.count('entry')
    page.wait_inside(5)
    page.text('Venue is at capacity. Wait for an exit before recording another entry.')
    assert not page.button('+ Record one entry').is_enabled()
    assert int(api.event(case)['totalEntries']) == 5
    page.button('Refresh attendance').click()
    page.wait_inside(5)
    assert not page.button('+ Record one entry').is_enabled()


def test_t5_filter_manager_attendance_and_recover_from_no_results(driver, api):
    case = api.scenario('Manager')
    page = Clicker(driver)
    page.login('manager')
    page.select('attendance-venue', case['venue']['name'])
    page.select('attendance-status', 'Active')
    page.search(case['event']['name'])
    page.wait.until(lambda d: len(page.manager_rows()) == 1)
    cells = page.manager_rows()[0].find_elements(By.TAG_NAME, 'td')
    assert case['event']['name'] in cells[0].text
    assert [x.text for x in cells[2:]] == ['active', '2', '0', '2', '5']
    assert page.summary('TOTAL ENTRIES') == 2
    assert page.summary('TOTAL EXITS') == 0
    assert page.summary('CURRENTLY INSIDE') == 2
    page.search('no-event-with-this-name')
    page.text('No events match these filters.')
    assert page.summary('CURRENTLY INSIDE') == 0
    page.search(case['event']['name'])
    page.wait.until(lambda d: len(page.manager_rows()) == 1)


def test_t6_review_closed_event_history_without_changing_counts(driver, api):
    page = Clicker(driver)
    before = api.request('attendanceEvents:list', filter={'name': 'Harbor Workshop'})[0]
    page.login('manager')
    page.select('attendance-venue', 'Harbor Center')
    page.select('attendance-status', 'Closed')
    page.search('Harbor Workshop')
    page.wait.until(lambda d: len(page.manager_rows()) == 1)
    cells = page.manager_rows()[0].find_elements(By.TAG_NAME, 'td')
    assert [x.text for x in cells[2:]] == ['closed', '420', '420', '0', '500']
    assert page.summary('TOTAL ENTRIES') == 420
    assert page.summary('TOTAL EXITS') == 420
    assert page.summary('CURRENTLY INSIDE') == 0
    assert not driver.find_elements(By.XPATH, '//button[contains(.,"Record one")]')
    page.button('Refresh attendance').click()
    after = api.request('attendanceEvents:list', filter={'id': before['id']})[0]
    for field in ('totalEntries', 'totalExits', 'currentInside'):
        assert after[field] == before[field]
