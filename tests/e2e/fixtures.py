"""Synthetic scenario setup only. User actions under test use Selenium.

Each scenario has its own venue, stations and event. Existing demonstration
counts are never reset. Use the isolated runner to keep test data separate.
"""
import json
import os
import urllib.parse
import urllib.request
import uuid


class FixtureAPI:
    def __init__(self):
        self.base = os.environ.get('CLICKER_TEST_URL', 'http://localhost:13004').rstrip('/')
        self.token = None
        self.token = self.request('auth:signIn', {
            'email': 'admin@nocobase.com', 'password': 'admin123',
        })['token']

    def request(self, route, data=None, **params):
        query = urllib.parse.urlencode({
            k: json.dumps(v) if isinstance(v, dict) else v for k, v in params.items()
        })
        headers = {'Content-Type': 'application/json', 'X-Authenticator': 'basic'}
        if self.token:
            headers.update({'Authorization': 'Bearer ' + self.token, 'X-Role': 'root'})
        req = urllib.request.Request(
            self.base + '/api/' + route + ('?' + query if query else ''),
            data=None if data is None else json.dumps(data).encode(), headers=headers,
        )
        with urllib.request.urlopen(req, timeout=60) as response:
            return json.load(response)['data']

    def scenario(self, label, inside=2, capacity=5, status='active'):
        prefix = 'S4 ' + label + ' ' + uuid.uuid4().hex[:8]
        venue = self.request('venues:create', {
            'name': prefix + ' Venue', 'maxCapacity': capacity,
            'currentCount': inside, 'status': 'open', 'timezone': 'America/New_York',
        })
        stations = {}
        for label_, direction, active in [('Entry Gate', 'in', True),
                                           ('Exit Gate', 'out', True),
                                           ('Inactive Gate', 'in', False)]:
            stations[label_] = self.request('entrances:create', {
                'name': prefix + ' ' + label_, 'venueId': venue['id'],
                'directionType': direction, 'active': active,
            })
        event = self.request('attendanceEvents:create', {
            'name': prefix + ' Event', 'venueId': venue['id'],
            'startsAt': '2026-10-22T18:00:00-04:00', 'status': status,
            'totalEntries': inside, 'totalExits': 0, 'currentInside': inside,
        })
        return {'event': event, 'venue': venue, 'stations': stations,
                'event_option': event['name'] + ' - ' + venue['name']}

    def event(self, scenario):
        return self.request('attendanceEvents:list', filter={'id': scenario['event']['id']})[0]

    def venue(self, scenario):
        return self.request('venues:list', filter={'id': scenario['venue']['id']})[0]
