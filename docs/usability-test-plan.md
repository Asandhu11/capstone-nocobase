# Clicker Usability Test Plan

**Author:** Amninder Sandhu  |  **Sprint:** 4, Deliverable 1  |  **System under test:** the team's Clicker website (`main`, Sprint 3 screens)

## 1. What we are testing and why

Clicker counts people entering and leaving a venue so that a manager always knows how many are inside and whether the venue is near capacity. Three kinds of people use the website:

| User group | What they do | Screen |
| --- | --- | --- |
| Entryway attendant | Stands at a gate and counts each person who comes in | Entryway attendant |
| Exit attendant | Stands at an exit and counts each person who leaves | Exit attendant |
| Attendance manager | Watches how busy each event is; does not change counts | Manager attendance |

**Goals.** Find out whether a first-time user can finish each everyday job without help, how quickly they can do it, how often they make mistakes, how easily they recover, and how they feel about the site. These map to the usability attributes from class: learnability, efficiency, errors, safety, and satisfaction. Memorability is covered by an optional repeat session a week later.

**Type of test.** Moderated, mostly qualitative with a few quantitative measures (task success and time on task). Run in person or remotely over screen share. Participants think aloud.

## 2. Participants and facilitator

- At least **5 per user group** (attendants, managers), following the NN/g guidance, so 10 in all. Attendants should be people who have worked a door or checked in guests (event staff, front-desk or gym workers). Managers should be people who supervise a venue or team.
- Participants give **consent** before starting (voluntary, can stop any time, screen and voice may be recorded, no personal data is kept; the demo accounts hold only fictional data).
- A **facilitator** reads the script, gives tasks one at a time, and does not help unless a participant is stuck for more than two minutes. A second team member takes notes.

## 3. The six tasks

Task wording describes a situation, not buttons, so we do not give away the interface.

| # | Who | Task as read to the participant | Success means | Main attributes |
| --- | --- | --- | --- | --- |
| 1 | Entryway attendant | "You are working the North Gate at Harbor Community Night. A guest has just walked in. Make sure the system knows one more person is inside." | Count for that event goes up by exactly 1 and a confirmation is shown | Learnability, efficiency, errors |
| 2 | Exit attendant | "You are working the South Exit at the same event. A guest is leaving. Record it." | Count goes down by exactly 1 and a confirmation is shown | Learnability, efficiency, errors |
| 3 | Manager | "How many people are inside across all events right now? A little later, your attendant lets someone in. Confirm the system has picked that up." | Reads the correct total, then finds the total one higher after a refresh | Efficiency, satisfaction |
| 4 | Manager | "You want to know whether any workshops at Harbor Center are still running. Find out." | Narrows the list to Harbor Center workshops and correctly concludes none is active | Learnability, errors |
| 5 | Any attendant | "Your shift is starting. Sign in using the card you were given." (The card's password has one deliberate slip so we can watch recovery.) | Notices the error and signs in within two extra attempts | Errors, satisfaction |
| 6 | Attendant and manager | Attendant: "Your supervisor asks how many people have left today. Show me how you would find out." Manager: "The total looks wrong; correct it." | Participant realises their role cannot do this and says who to ask; no data is changed | Safety, errors |

## 4. What we measure

| Measure | How | Target |
| --- | --- | --- |
| Task success | Observer marks each task: completed alone / completed with a hint / failed | Tasks 1, 2, 4: at least 90% alone. Tasks 3, 5, 6: at least 80% alone |
| Time on task | Stopwatch from the end of the task script until the participant says "done" | Tasks 1 and 2: median 30 seconds or less. Tasks 3 and 4: 90 seconds or less |
| Errors | Count wrong selections, wrong button, or repeated clicks; note if recovered | Fewer than 1 uncorrected error per task |
| Ease rating | After each task, "How easy was that?" from 1 (very hard) to 7 (very easy) | Average 5.5 or higher |
| Overall satisfaction | Short 5-question questionnaire at the end | Average 4 out of 5 or higher |
| Comments | Think-aloud remarks and facial reactions, noted by observer | Used to explain the numbers |

## 5. Test script (what the facilitator reads)

1. **Welcome.** "Thank you for helping. We are testing the website, not you. There are no wrong answers, and you can stop at any time."
2. **Consent and background.** Explain recording, collect consent. Ask: role or experience with counting guests, how often they use similar tools, comfort with websites (1 to 5).
3. **Purpose.** "Clicker keeps a live count of how many people are inside a venue."
4. **Think aloud.** Ask them to say what they are looking at and what they expect to happen.
5. **Tasks 1 to 6** in the order above (attendants do 1 or 2, then 5 and 6; managers do 3, 4 and 6). Read each task card, then stay quiet.
6. **Interview.** What was easiest? What was confusing? Anything you expected that was missing? Would you trust the number on screen? How could the site be better?
7. **Closing.** Thank them, remind them that no personal data is stored.

## 6. After the test

Combine the notes into a report: a table of success, time, errors, and ratings per task, the top problems ranked by how many participants hit them and how serious they were, and recommended fixes. Re-test after fixes.

## 7. Automated end-to-end tests (Selenium)

The automated tests in `e2e/` follow the same six tasks through a real browser, signing in with the demo accounts and clicking the screens the way a person would. They prove that each task *can* be completed and that the site gives the right feedback and numbers. They do **not** measure how easy, fast, or pleasant the tasks feel, so they complement the human sessions above and do not replace them.

| Task | Test in `e2e/test_usability_tasks.py` | What it checks |
| --- | --- | --- |
| 1 | `test_task1_entry_attendant_records_one_person_entering` | Record button disabled until choices are made; only the North Gate is offered; count +1; confirmation and new row shown |
| 2 | `test_task2_exit_attendant_records_one_person_leaving` | Same checks for exits through the South Exit; count -1 |
| 3 | `test_task3_manager_checks_current_attendance_and_sees_new_activity` | Summary cards agree with the table; a new entry by an attendant appears for the manager; the exit puts the total back |
| 4 | `test_task4_manager_narrows_the_list_to_find_one_event` | Venue filter, search box, and status filter narrow the list; a clear message appears when nothing matches |
| 5 | `test_task5_attendant_recovers_from_a_wrong_password` | A wrong password shows an error and keeps the person on the sign-in page; the right one then works |
| 6 | `test_task6_attendants_only_see_their_own_screen` and `test_task6_manager_screen_is_read_only` | Attendants cannot see other roles' screens or buttons; the manager screen has no record, edit, or delete controls |

Not automated: reading and judging the wording, layout, speed, or the feelings of a real person. Those come from the human sessions.
