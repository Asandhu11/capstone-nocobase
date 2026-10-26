# Clicker Sprint 4 usability testing plan

**Researcher:** Ayoola Morakinyo
**Branch:** `sprint4-Ayoola`, created from team `main` at `e0f3c52`
**Status:** Plan prepared; participant sessions and observations pending.

## Purpose

Find where first-time attendants and attendance managers struggle to record
accurate counts, understand limits, and interpret event totals. Use the same six
tasks for moderated sessions and Selenium end-to-end checks. Automated passing
results demonstrate functional behavior; participant evidence establishes usability.

## Participants and scheduling

Recruit at least three friends or family members who are **not in this class**.
Aim for different levels of comfort with web applications. Use P1, P2 and P3 in
the submitted notes; keep contact details outside the repository.

| Participant | Not in class confirmed | Relevant web experience | Date/time and timezone | Session completed |
| --- | --- | --- | --- | --- |
| P1 | Pending | Pending | Pending | No |
| P2 | Pending | Pending | Pending | No |
| P3 | Pending | Pending | Pending | No |

Invitation draft: “Could you spend about 30 minutes trying a class project that
records event attendance? I’m testing the website, not you. You would try six
short tasks while saying what you are thinking. You can stop at any time.”

## Setup and facilitation

1. Use a local, fictional-data installation on http://localhost:13004. Record
   the branch/commit, browser/version, operating system, viewport and device.
2. Start the app using the README. Before each participant, run
   `docker compose --profile e2e run --rm e2e python prepare_usability.py`.
   Save its printed event, venue and station names. This creates fresh T2–T4
   scenarios without deleting a previous participant's evidence.
3. Substitute the printed names for the bracketed task names below. Verify the
   starting values using a separate facilitator browser, then close it. Do not
   preselect controls in the participant's browser.
4. Use a fresh private window for each role transition so one participant is
   not affected by the previous login. The test evaluates sign-in; sign-out and
   switching roles in one window are additional exploratory checks.
5. Give the participant the role's demo email and password `admin123` on a card.
   Read only the scenario prompt, not the success criteria or Selenium steps.
6. Ask permission to take notes. Ask separately before recording audio/video;
   recording is optional. Say: “We are testing the system, not your ability.
   Please tell me what you expect to happen and anything that confuses you.”
7. Let the participant work unaided. Prompt “What are you thinking?” without
   pointing at controls. At the time limit ask whether they want to stop or get
   help; record any help and mark completion as assisted.
8. After each task ask ease on a **1–7 scale** (1 very difficult, 7 very easy)
   and “What, if anything, was confusing?” End with their top three improvements.

Allow 3 minutes for introduction, about 20 minutes for tasks, and 5 minutes for
debrief. Read tasks in order; T2–T4 have independent data so a failed task does
not prevent later tasks.

## Tasks and success criteria

| ID | Role and participant prompt | Starting state | Observable success | Limit | Selenium coverage |
| --- | --- | --- | --- | --- | --- |
| T1 | Entry attendant: “You are starting a shift. Use these account details to reach the screen for your work. Tell me how you know it is the right screen.” | Signed out; `entry@clicker.test` | Signs in and identifies Entryway attendant without help. Repeat sign-in when moving to exit and manager roles. | 3 min | `test_t1_sign_in_to_assigned_screen` covers all 3 accounts. |
| T2 | Entry attendant: “One guest arrives at [Entry Gate] for [T2 event]. Record the arrival and tell me how many people are now inside and how you know it was saved.” | 2 inside, capacity 5; nothing selected | Selects correct event/station, records exactly once, sees 3 inside, confirmation and recent entry; refresh keeps 3. | 4 min | `test_t2_record_one_entry_and_check_it_persists`; also required-selection and station filtering checks. |
| T3 | Exit attendant: “The last guest leaves [T3 event] through [Exit Gate]. Record the departure. Then explain what you would do if asked to record another exit.” | 1 inside; `exit@clicker.test` | Records one exit, sees 0 and saved feedback; recognizes empty-event warning and cannot record a negative count. | 4 min | `test_t3_record_one_exit_and_stop_at_zero`. |
| T4 | Entry attendant: “There are four guests at [T4 event], which holds five. One more arrives, then another. Handle both arrivals and explain what the system tells you.” | 4 inside, capacity 5; `entry@clicker.test` | First entry brings count to 5; second is blocked; participant understands capacity warning. | 4 min | `test_t4_fill_last_space_and_block_further_entry`. |
| T5 | Manager: “Find the active [T2 event] at [T2 venue]. Report its entries, exits and people inside. Search for an event called ‘No Such Event’, then return to the event you were reviewing.” | `manager@clicker.test`; facilitator records actual post-T2 state | Uses venue, active status and name filters; reports matching totals; recognizes no-results state and recovers. If T2 succeeded: entries 3, exits 0, inside 3. | 4 min | `test_t5_filter_manager_attendance_and_recover_from_no_results` uses independent known data: 2, 0, 2. |
| T6 | Manager: “Find the completed Harbor Workshop at Harbor Center. Tell me its total entries, exits and people still inside. Explain whether 420 entries necessarily means 420 different people.” | Existing closed Harbor Workshop | Finds closed event; reads 420 entries, 420 exits, 0 inside; notices re-entry distinction; does not change historical counts. | 3 min | `test_t6_review_closed_event_history_without_changing_counts` checks totals and read-only controls. Participant interpretation is assessed manually. |

Record completion as **unassisted / assisted / failed / not attempted**. Start
timing after reading the prompt and stop at success or abandonment. Note errors,
hesitation, wrong selections, repeated clicks, misleading feedback and recovery.
A correct final count after coaching is assisted, not unassisted.

## Observations

**No participant sessions have been conducted yet.** Fill the following records
from actual sessions. Do not present Selenium findings or predicted problems
as participant observations.

Copy this table for each participant:

| Participant | Task | Completion | Seconds | Errors / help given | Ease 1–7 | Observed behavior / exact quote | Evidence ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pending | T1 | Not attempted | — | — | — | — | — |
| Pending | T2 | Not attempted | — | — | — | — | — |
| Pending | T3 | Not attempted | — | — | — | — | — |
| Pending | T4 | Not attempted | — | — | — | — | — |
| Pending | T5 | Not attempted | — | — | — | — | — |
| Pending | T6 | Not attempted | — | — | — | — | — |

For each distinct issue, preserve every occurrence even if it will later be
merged into one team issue:

| Observation ID | Participant/task | What happened and evidence | Expected behavior / impact | Severity | Suggested change | Team issue |
| --- | --- | --- | --- | --- | --- | --- |
| Pending | — | — | — | — | — | — |

Severity: **Critical** = wrong counts, lost data or blocked core workflow;
**High** = task fails or needs substantial help; **Medium** = recoverable
confusion/delay; **Low** = minor wording or presentation problem. Frequency is
the number of participants affected out of those who attempted the task.

## Synthesis after three sessions

For each task, calculate unassisted completions / attempts, median time and
median ease rating. Describe the issue, supporting observations, impact and
proposed change. Keep observations separate from explanations you infer.
Include all findings, then rank the most pressing for the team discussion.

Completion gate for Deliverable 2: at least three non-class participants,
documented sessions covering all six tasks, an actual Observations section,
and a readable final uploaded plan. Scheduling or automated runs alone do not
complete this deliverable.
