# Sprint 4 Testing Plan

## Scope

This plan validates the Sprint 4 role-based attendance workflow described in the main project README. The goal is to confirm that the NocoBase prototype supports the intended end-to-end flows for the three operational roles:

- Entry attendant
- Exit attendant
- Manager

The planned checks cover guest entry and exit, live capacity updates, event summaries, and role-based screen access.

## Test objectives

1. Confirm entry attendants can record guest entries for the correct event and venue/station combination.
2. Confirm exit attendants can record guest exits for the correct event and venue/station combination.
3. Confirm capacity updates correctly as entries and exits are processed.
4. Confirm the manager can review event summaries and totals without edit permissions.
5. Confirm role restrictions prevent access to the wrong workflow screens.

## Test scenarios

| Scenario | Description | Expected result | Role |
| --- | --- | --- | --- |
| North Gate entry | Record a guest entering through North Gate for Harbor Community Night. | Entry is accepted and attendance/capacity update correctly. | Entry attendant |
| East Lobby entry | Record a guest entering through East Lobby for Eastside Open Gym. | Entry is accepted and tracked under the correct event. | Entry attendant |
| South Exit exit | Record a guest exiting through South Exit for Harbor Community Night. | Exit is accepted and attendance decreases correctly. | Exit attendant |
| East Lobby exit | Record a guest exiting through East Lobby for Eastside Open Gym. | Exit is accepted and the event total updates correctly. | Exit attendant |
| Capacity tracking | Confirm the venue count changes after a series of entry and exit actions. | Capacity and remaining spaces reflect the live totals. | Entry attendant / Exit attendant |
| Manager review | Review summary totals and event history from the manager screen. | Manager sees totals without the ability to edit attendance fields. | Manager |
| Role visibility | Check that each screen is only visible to its assigned role. | Only the correct role can access the relevant workflow UI. | Entry attendant / Exit attendant / Manager |

## Test setup

1. Start Docker Desktop or the local Docker engine.
2. Run the project stack from the repo root.
3. Start the app and confirm it is available at http://localhost:13003.
4. Use the demo accounts described in the README:
   - Entry attendant: entry@clicker.test
   - Exit attendant: exit@clicker.test
   - Manager: manager@clicker.test
   - Admin: admin@nocobase.com
5. Use the course demo password: admin123

## Execution steps

1. Sign in as the entry attendant.
2. Select the target event and station.
3. Record a valid entry.
4. Verify the success indication and updated totals.
5. Repeat for the alternate entry scenario.
6. Sign in as the exit attendant.
7. Select the target event and exit station.
8. Record a valid exit.
9. Verify the success indication and updated totals.
10. Repeat for the alternate exit scenario.
11. Sign in as the manager.
12. Filter or review event records and summary totals.
13. Confirm the manager screen is read-only and appropriate to the manager role.
14. Confirm the role-specific screens remain hidden or inaccessible to others.

## Pass criteria

The Sprint 4 test passes when all planned workflow checks complete successfully:

- entry records are accepted under the correct event and station
- exit records are accepted under the correct event and station
- capacity and attendance totals update correctly
- manager summaries load correctly
- role access is restricted to the appropriate user type

## Verification status

The current verification run for the project validation suite completed successfully with the following observed result:

- Command: python -m pytest -q ./e2e-test/test_usability.py
- Result: 7 passed in 2.44s

This indicates the app is reachable and the usability validation checks are passing in the current environment.

## Initial timing note

The first full browser-based Selenium attempt did not complete successfully because the browser session could not reach the app due to Docker Desktop host/network routing. That environment issue caused the original Sprint 4 Selenium run to fail before the workflow assertions could complete.

A practical runtime estimate for the app-level validation in this environment was approximately 2.44 seconds for the completed pass run, while the initial browser-based Selenium setup required additional troubleshooting before it could successfully route to the app.
