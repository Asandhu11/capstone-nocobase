import json
import os
import re
from pathlib import Path

import pytest
from selenium import webdriver

from fixtures import FixtureAPI


@pytest.fixture(scope='session')
def api():
    return FixtureAPI()


@pytest.fixture
def driver():
    options = webdriver.ChromeOptions()
    options.add_argument('--headless=new')
    options.add_argument('--window-size=1440,1000')
    browser = webdriver.Remote(
        command_executor=os.environ.get('SELENIUM_REMOTE_URL', 'http://localhost:4444'),
        options=options,
    )
    browser.set_page_load_timeout(90)
    directory = Path(os.environ.get('E2E_ARTIFACTS', '../../test-results'))
    directory.mkdir(parents=True, exist_ok=True)
    (directory / 'environment.json').write_text(json.dumps({
        key: browser.capabilities.get(key)
        for key in ('browserName', 'browserVersion', 'platformName')
    }, indent=2))
    yield browser
    browser.quit()


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    report = outcome.get_result()
    browser = item.funcargs.get('driver')
    if report.failed and browser:
        directory = Path(os.environ.get('E2E_ARTIFACTS', '../../test-results'))
        directory.mkdir(parents=True, exist_ok=True)
        name = re.sub(r'[^a-zA-Z0-9_-]', '_', item.nodeid) + '-' + report.when
        try:
            browser.save_screenshot(str(directory / (name + '.png')))
            (directory / (name + '.html')).write_text(browser.page_source)
            (directory / (name + '.json')).write_text(json.dumps({
                'test': item.nodeid, 'url': browser.current_url,
                'error': str(report.longrepr),
            }, indent=2))
        except Exception as error:
            # Artifact collection must not mask the original test failure.
            print('Could not collect browser evidence:', error)
