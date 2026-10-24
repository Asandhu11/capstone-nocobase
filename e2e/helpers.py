"""Small helpers that drive the Clicker website the way a person would.

Everything here talks to the real web page through a browser. All page-specific
locators are kept in this one file so a change to the website only needs a change here.
"""
import os
import re
import time
from contextlib import contextmanager

from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

BASE_URL = os.environ.get("BASE_URL", "http://app").rstrip("/")
SELENIUM_URL = os.environ.get("SELENIUM_URL", "http://selenium:4444/wd/hub")
ARTIFACT_DIR = os.environ.get("ARTIFACT_DIR", "/artifacts")
TIMEOUT = int(os.environ.get("E2E_TIMEOUT", "40"))
PASSWORD = "admin123"
ACCOUNTS = {
    "entry": "entry@clicker.test",
    "exit": "exit@clicker.test",
    "manager": "manager@clicker.test",
}
HEADINGS = {"entry": "Entryway attendant", "exit": "Exit attendant", "manager": "Manager attendance"}

# Set by conftest.py so failure screenshots are named after the running test.
CURRENT_TEST = {"name": "test"}


def quote(text):
    """Quote a string for use inside an XPath expression."""
    return "'" + text + "'" if "'" not in text else '"' + text + '"'


def make_driver():
    """Open a browser. In Docker this is the Selenium container; a local Chrome is
    only used when SELENIUM_URL is set to 'local' (handy while developing tests)."""
    options = webdriver.ChromeOptions()
    options.add_argument("--window-size=1440,1000")
    options.add_argument("--lang=en-US")
    if SELENIUM_URL == "local":
        from selenium.webdriver.chrome.service import Service
        options.binary_location = os.environ["CHROME_BIN"]
        for flag in ("--headless=new", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"):
            options.add_argument(flag)
        driver = webdriver.Chrome(service=Service(os.environ["CHROMEDRIVER"]), options=options)
    else:
        driver = webdriver.Remote(command_executor=SELENIUM_URL, options=options)
    driver.implicitly_wait(0)  # explicit waits only, so failures are easy to read
    return driver


def wait(driver, seconds=None):
    return WebDriverWait(driver, seconds or TIMEOUT, poll_frequency=0.25)


def visible(driver, xpath):
    return wait(driver).until(EC.visibility_of_element_located((By.XPATH, xpath)))


def present_now(driver, xpath):
    """Elements matching xpath right now (no waiting)."""
    return [e for e in driver.find_elements(By.XPATH, xpath) if e.is_displayed()]


def save_artifacts(driver, label):
    """Keep a screenshot and the page text when something goes wrong."""
    try:
        os.makedirs(ARTIFACT_DIR, exist_ok=True)
        stem = re.sub(r"[^A-Za-z0-9_.-]+", "_", f"{CURRENT_TEST['name']}-{label}")
        driver.save_screenshot(os.path.join(ARTIFACT_DIR, stem + ".png"))
        with open(os.path.join(ARTIFACT_DIR, stem + ".txt"), "w", encoding="utf-8") as f:
            f.write(driver.current_url + "\n\n" + driver.find_element(By.TAG_NAME, "body").text)
    except Exception:  # never hide the real failure behind a screenshot problem
        pass


# ------------------------------------------------------------------ sign in
PASSWORD_INPUT = "//input[@type='password']"
ACCOUNT_INPUT = "//input[@type='password']/preceding::input[not(@type='password') and not(@type='hidden')][1]"
SIGN_IN_BUTTON = "//button[@type='submit' or contains(normalize-space(.), 'Sign in')]"
LOGIN_ERROR = "//*[contains(@class,'ant-message-error') or contains(@class,'ant-alert-error') or contains(@class,'notice-error')]"
ERROR_WORDS = ("incorrect", "invalid", "wrong", "not exist", "failed")


def open_sign_in(driver):
    driver.get(BASE_URL + "/")
    visible(driver, PASSWORD_INPUT)


def retype(element, text):
    """Replace whatever is in a text box. (Selenium's clear() does not always update
    React/Ant Design inputs, so select-all and delete like a person would.)"""
    element.click()
    element.send_keys(Keys.CONTROL, "a")
    element.send_keys(Keys.BACKSPACE)
    element.send_keys(text)


def submit_credentials(driver, email, password):
    retype(visible(driver, ACCOUNT_INPUT), email)
    retype(driver.find_element(By.XPATH, PASSWORD_INPUT), password)
    driver.find_element(By.XPATH, SIGN_IN_BUTTON).click()


def sign_in(driver, role):
    open_sign_in(driver)
    submit_credentials(driver, ACCOUNTS[role], PASSWORD)
    visible(driver, f"//h1[normalize-space()={quote(HEADINGS[role])}]")


def wait_for_sign_in_error(driver):
    """A real error message appears (not just any icon) and the Sign in button is free again."""
    def error_shown(d):
        text = d.find_element(By.TAG_NAME, "body").text.lower()
        return present_now(d, LOGIN_ERROR) or any(word in text for word in ERROR_WORDS)
    wait(driver).until(error_shown)
    wait(driver).until(lambda d: not d.find_elements(
        By.XPATH, "//button[contains(@class,'ant-btn-loading')]"))
    assert driver.find_elements(By.XPATH, PASSWORD_INPUT), "left the sign-in page after a wrong password"


def sign_in_again(driver, role, attempts=3):
    """Retype the credentials and press Sign in, retrying like a person would if the page
    has not moved on after a few seconds."""
    time.sleep(1)  # let the error message and form finish settling
    for attempt in range(attempts):
        submit_credentials(driver, ACCOUNTS[role], PASSWORD)
        try:
            WebDriverWait(driver, 8, poll_frequency=0.25).until(EC.visibility_of_element_located(
                (By.XPATH, f"//h1[normalize-space()={quote(HEADINGS[role])}]")))
            return attempt + 1
        except TimeoutException:
            continue
    raise AssertionError(f"could not sign in as {role} after {attempts} tries")


@contextmanager
def signed_in(role):
    """A fresh browser, signed in as the given role. Always closed afterwards."""
    driver = make_driver()
    try:
        sign_in(driver, role)
        yield driver
    except Exception:
        save_artifacts(driver, role)
        raise
    finally:
        driver.quit()


# --------------------------------------------------------------- select boxes
def select_box_locator(select_id):
    return (By.XPATH,
            f"//*[@id={quote(select_id)}]/ancestor::div[contains(concat(' ', normalize-space(@class), ' '), ' ant-select ')][1]")


def select_box(driver, select_id):
    return driver.find_element(*select_box_locator(select_id))


OPEN_OPTIONS = ("//div[contains(@class,'ant-select-dropdown') and not(contains(@class,'ant-select-dropdown-hidden'))]"
                "//div[contains(concat(' ', normalize-space(@class), ' '), ' ant-select-item-option ')]")


def open_select(driver, select_id):
    # The id sits on antd's (often invisible) inner input, so wait for it to exist and
    # click the visible select box around it, the way a person would.
    wait(driver).until(EC.presence_of_element_located((By.XPATH, f"//*[@id={quote(select_id)}]")))
    wait(driver).until(EC.element_to_be_clickable(select_box_locator(select_id)))
    select_box(driver, select_id).click()
    wait(driver).until(lambda d: present_now(d, OPEN_OPTIONS))


def option_texts(driver, select_id):
    """The choices a person would see if they opened this drop-down."""
    open_select(driver, select_id)
    seen = {"last": None}

    def settled(d):
        texts = [e.text.strip() for e in present_now(d, OPEN_OPTIONS)]
        if texts and all(texts) and texts == seen["last"]:
            return texts
        seen["last"] = texts
        time.sleep(0.4)  # list still loading or animating; look again
        return False

    texts = wait(driver).until(settled)
    driver.find_element(By.TAG_NAME, "body").click()  # close it again
    return texts


def choose(driver, select_id, label):
    open_select(driver, select_id)
    option = wait(driver).until(EC.element_to_be_clickable(
        (By.XPATH, OPEN_OPTIONS + f"[contains(normalize-space(.), {quote(label)})]")))
    option.click()


# --------------------------------------------------------------- attendant screens
def number(text):
    """'1,101' -> 1101. Returns -1 while the page still shows a placeholder such as '--'."""
    digits = re.sub(r"\D", "", text)
    return int(digits) if digits else -1


def inside_now(driver):
    text = driver.find_element(
        By.XPATH, "//div[normalize-space()='PEOPLE INSIDE THIS EVENT']/following-sibling::div[1]").text
    return number(text)


def record_button(driver, direction):
    word = "entry" if direction == "entry" else "exit"
    return visible(driver, f"//button[contains(normalize-space(.), 'Record one {word}')]")


def recent_rows(driver):
    return [r.text for r in driver.find_elements(
        By.XPATH, "//h2[starts-with(normalize-space(),'Recent')]/following::tbody[1]/tr[contains(@class,'ant-table-row')]")]


def record_one(driver, direction, event, station):
    """Pick an event and station, press the big button once, and return the new head-count."""
    choose(driver, f"{direction}-event", event)
    wait(driver).until(lambda d: inside_now(d) >= 0)
    choose(driver, f"{direction}-station", station)
    before = inside_now(driver)
    wait(driver).until(lambda d: record_button(d, direction).is_enabled())
    record_button(driver, direction).click()
    expected = before + 1 if direction == "entry" else before - 1
    word = "entry" if direction == "entry" else "exit"
    visible(driver, f"//div[contains(@class,'ant-alert-success')][contains(., 'One {word} saved')]")
    wait(driver).until(lambda d: inside_now(d) == expected)
    return before, expected


# --------------------------------------------------------------- manager screen
def card(driver, title):
    return number(driver.find_element(
        By.XPATH, f"//div[normalize-space()={quote(title)}]/following-sibling::div[1]").text)


MANAGER_ROWS = "//tbody/tr[contains(@class,'ant-table-row')]"


def manager_rows(driver):
    """Each event row as a dict of what a manager can read on screen."""
    rows = []
    for tr in driver.find_elements(By.XPATH, MANAGER_ROWS):
        cells = [c.text.strip() for c in tr.find_elements(By.TAG_NAME, "td")]
        rows.append({
            "name": cells[0].split("\n")[0], "venue": cells[0].split("\n")[-1], "status": cells[2],
            "entries": number(cells[3]), "exits": number(cells[4]), "inside": number(cells[5]),
            "capacity": number(cells[6]),
        })
    return rows


def wait_for_manager_table(driver):
    visible(driver, MANAGER_ROWS)
    wait(driver).until(lambda d: len(manager_rows(d)) >= 1)
