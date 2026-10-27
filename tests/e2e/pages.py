"""Small page helper using visible controls, explicit waits and normal clicks."""
import os

from selenium.common.exceptions import StaleElementReferenceException
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.actions.wheel_input import ScrollOrigin
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


class Clicker:
    def __init__(self, driver):
        self.driver = driver
        self.wait = WebDriverWait(driver, 45, ignored_exceptions=(StaleElementReferenceException,))
        self.base = os.environ.get('CLICKER_TEST_URL', 'http://localhost:13004').rstrip('/')

    def visible(self, by, value):
        return self.wait.until(EC.visibility_of_element_located((by, value)))

    def text(self, value):
        return self.visible(By.XPATH, '//*[normalize-space(.)=' + repr(value) + ']')

    def button(self, label):
        return self.visible(By.XPATH, '//button[normalize-space(.)=' + repr(label) + ']')

    def login(self, role):
        self.driver.get(self.base + '/signin')
        username = self.visible(By.CSS_SELECTOR, 'input:not([type="password"]):not([type="hidden"])')
        username.send_keys(role + '@clicker.test')
        self.visible(By.CSS_SELECTOR, 'input[type="password"]').send_keys('admin123')
        self.button('Sign in').click()
        title = {'entry': 'Entryway attendant', 'exit': 'Exit attendant', 'manager': 'Manager attendance'}[role]
        self.visible(By.XPATH, '//h1[normalize-space(.)=' + repr(title) + ']')
        self.wait.until(lambda d: 'refreshes every 5 seconds' in d.find_element(By.TAG_NAME, 'body').text)

    def select(self, id_, label):
        control = self.wait.until(EC.presence_of_element_located((By.ID, id_)))
        # Ant Design's non-searchable selects have an opacity:0 input.
        # Click their visible selector, as a participant would.
        control.find_element(By.XPATH, 'ancestor::div[contains(@class,"ant-select-selector")][1]').click()
        if id_ in ('entry-event', 'exit-event'):
            control.send_keys(label)
        # Options are portalled and virtualized. Scroll with ordinary wheel
        # actions when the desired option is outside the currently rendered list.
        def find_option(driver):
            for dropdown in driver.find_elements(By.CSS_SELECTOR, '.ant-select-dropdown:not(.ant-select-dropdown-hidden)'):
                if not dropdown.is_displayed():
                    continue
                for option in dropdown.find_elements(By.CSS_SELECTOR, '.ant-select-item-option-content'):
                    if option.is_displayed() and option.text == label:
                        return option
                holders = dropdown.find_elements(By.CSS_SELECTOR, '.rc-virtual-list-holder')
                if holders:
                    ActionChains(driver).scroll_from_origin(ScrollOrigin.from_element(holders[0]), 0, 160).perform()
            return False
        option = self.wait.until(find_option)
        option.click()
        self.wait.until(lambda d: not any(e.is_displayed() for e in d.find_elements(
            By.CSS_SELECTOR, '.ant-select-dropdown:not(.ant-select-dropdown-hidden)')))

    def station_options(self, role):
        control = self.wait.until(EC.presence_of_element_located((By.ID, role + '-station')))
        control.find_element(By.XPATH, 'ancestor::div[contains(@class,"ant-select-selector")][1]').click()
        self.visible(By.CSS_SELECTOR, '.ant-select-dropdown:not(.ant-select-dropdown-hidden)')
        options = [e.text for e in self.driver.find_elements(
            By.CSS_SELECTOR, '.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option-content') if e.is_displayed()]
        ActionChains(self.driver).send_keys(Keys.ESCAPE).perform()
        return options

    def choose(self, role, scenario):
        self.select(role + '-event', scenario['event_option'])
        key = 'Entry Gate' if role == 'entry' else 'Exit Gate'
        self.select(role + '-station', scenario['stations'][key]['name'])

    def count(self, role):
        label = '+ Record one entry' if role == 'entry' else '- Record one exit'
        button = self.button(label)
        self.wait.until(lambda d: button.is_enabled())
        button.click()
        self.visible(By.XPATH, '//*[contains(@class,"ant-alert-message") and starts-with(normalize-space(.),"One ' + role + ' saved")]')

    def inside(self):
        return int(self.visible(By.XPATH,
            '//div[normalize-space(.)="PEOPLE INSIDE THIS EVENT"]/following-sibling::div[1]').text.replace(',', ''))

    def wait_inside(self, expected):
        self.wait.until(lambda d: self.inside() == expected)

    def search(self, value):
        field = self.visible(By.ID, 'attendance-search')
        field.send_keys(Keys.CONTROL, 'a')
        field.send_keys(value)

    def manager_rows(self):
        return [e for e in self.driver.find_elements(By.CSS_SELECTOR, 'tr.ant-table-row') if e.is_displayed()]

    def summary(self, title):
        return int(self.visible(By.XPATH,
            '//div[normalize-space(.)=' + repr(title) + ']/following-sibling::div[1]').text.replace(',', ''))
