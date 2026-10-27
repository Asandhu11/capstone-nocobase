# Clicker Sprint 4: Usability Testing Plan and Session Report

**Researcher:** Ayoola Morakinyo

**Project:** Clicker event-attendance system

**Branch:** sprint4-Ayoola, based on the merged Sprint 3 implementation

## Summary

All three participants reached the expected functional outcomes for the six tasks: staff sign-in, recording an entry, recording an exit, enforcing capacity, filtering reports and reading historical totals. The sessions also identified improvements to selection persistence, search, filtering, count interpretation and recovery from mistakes.

## Participants and method

Three participants with varied web and work experience took part in the sessions. They are identified as P1, P2 and P3.

| Participant | Relevant experience |
| --- | --- |
| P1 | Basic phone and web use; little dashboard experience; first-time volunteer profile |
| P2 | Front-desk, check-in, retail and event experience |
| P3 | Attendance coordination, spreadsheets and reporting |

Testing used the fictional-data Clicker installation at http://localhost:13004. Each participant had separate Arrival, Departure and Capacity scenarios. All three attempted the same tasks. Entry, exit and manager demo accounts were used as appropriate.

The facilitation protocol was to give one scenario at a time, invite the participant to think aloud, avoid directional help unless needed and record any assistance. Fresh private browser sessions were planned between role changes. Task ease was assessed on a 1-7 scale, from very difficult to very easy.

## Six-task usability testing plan

| Task | Participant scenario | Success criteria |
| --- | --- | --- |
| T1: Sign in | Start a shift using the entry-attendant account and explain how the correct role screen is identified. | Reaches Entryway attendant and identifies the role. Planned limit: 3 minutes. |
| T2: Record an arrival | One guest arrives at the assigned Arrival event and Entry Gate. Record the arrival, explain how saving is confirmed, then reload and check the saved count. | Inside changes from 2 to 3; one entry and updated venue total; count persists after reload. Planned limit: 4 minutes. |
| T3: Record the final departure | Using the exit account, record the last guest leaving the assigned Departure event; explain what happens if another exit is requested. | Inside changes from 1 to 0; saved feedback and empty-event warning; further exit blocked. Planned limit: 4 minutes. |
| T4: Handle capacity | Four guests are inside a venue holding five. Handle one arriving guest and then a second arrival at the assigned Capacity event. | First arrival brings inside to 5; another entry is blocked; capacity feedback is understood. Planned limit: 4 minutes. |
| T5: Filter reports | Using the manager account, find the active Arrival event by venue, status and event name; report totals, search for No Such Event and restore the original report. | Correct filtered row and totals; empty-search state recognized; original report restored. Expected totals are 3/0/3 when T2 records one arrival. Planned limit: 4 minutes. |
| T6: Interpret history | Find the closed Harbor Workshop at Harbor Center, report its totals and explain whether 420 entries means 420 different people. | Reads 420 entries, 420 exits and 0 inside; distinguishes entry operations from unique people. Planned limit: 3 minutes. |

## Observations: functional outcomes

| Task | Observed outcome for P1, P2 and P3 | Usability consideration |
| --- | --- | --- |
| T1 | Each reached Entryway attendant. | Application, role and account identity should be clear at sign-in. |
| T2 | Each recorded 2 to 3 inside, received saved feedback and saw 3 after reload and reselection. | Selection persistence and saved-count persistence are different behaviors. |
| T3 | Each recorded 1 to 0 inside; further exit was disabled. P2 also pressed the disabled control without changing the count. | This establishes zero-limit behavior, not availability of a correction workflow. |
| T4 | Each reached 5 inside; the next arrival was blocked. P2's additional press did not add a sixth person. | Near-capacity warning prominence remains a separate design concern. |
| T5 | Each obtained 3 entries, 0 exits and 3 inside; unmatched search showed no rows and zero summaries; restoring the search restored the report. | P3 also encountered a retained status filter when returning from history. |
| T6 | Each participant retrieved Harbor Workshop at 420 entries, 420 exits and 0 inside, with closed status. | P2 and P3 explained that entry totals include re-entry and do not count distinct guests. |

## Observations: P1

**T1 - Sign-in and role recognition.** The sign-in page displayed NocoBase without the Clicker application name. After sign-in, the heading, tab title and entry button identified the entry role. Adding the Clicker name would clarify the application's purpose before sign-in. Ease: 5/7.

**T2 - Event discovery, saving and reload.** The visible event list contained 11 similarly named options; the assigned event required typing or scrolling to find. Typing P1 Arrival narrowed the list to one option, but the control did not advertise this capability. Initially the count showed 2 inside while Recent entries showed No counts recorded yet. After recording, the count changed to 3, with a green saved banner and a new row. Reload cleared the event and station selections; the panel showed -- until the event was selected again, when the saved count of 3 remained. A short explanation of initial occupancy would help distinguish the starting count from recently recorded arrivals. Ease: 4/7.

**T3 - Final departure.** Recording the exit reduced inside to 0. The exit button became disabled, and a yellow empty-event warning appeared alongside the green saved confirmation. Review the leading minus sign in the button label and the hierarchy of simultaneous alerts for clarity. Ease: 5/7.

**T4 - Capacity limit.** Before entry, the interface displayed the grammatically incorrect 1 spaces remaining at the venue. Recording one arrival changed occupancy to 5/5; the button became disabled and a capacity warning appeared.

**T5 - Manager report.** The initial screen showed three filters, three summary totals of 1,151/422/729 and a long table. The Venue selector did not accept typed search and required scrolling through approximately 24 venues. The unmatched-event message clearly indicated that no events matched the search. Ease: 4/7.

**T6 - Historical terminology and count meaning.** The task used completed, while the filter used Closed and the badge used closed. The re-entry explanation appeared in small grey footer text away from the summary cards. Use consistent event-status terminology and place the re-entry explanation closer to the summary totals. Ease: 4/7.

**Priority improvements:** preserve event/station selection after refresh; improve event discovery through a search hint or reduced irrelevant choices; use consistent event-status terminology.

## Observations: P2

**T1 - Role and account identity.** P2 immediately recognized the role page and requested a visible signed-in account name. The header showed a person icon without an account name. Ease: 6/7.

**T2 - Counting and shift continuity.** The large counting control was described as quick and practical. Automatic refresh and the manual refresh control supported confidence in the count. The count remained 3 after reload. Reload cleared the event and station, requiring reselection. Ease: 5/7.

**T3 - Zero limit and mistake recovery.** After the last exit, pressing the disabled control did not change the count from 0. There was no dedicated undo or correction flow for an accidental count. Ease: 6/7.

**T4 - Capacity and advance warning.** The capacity block prevented a sixth entry even after another press. P2 requested a more prominent warning before the final space is filled. Ease: 6/7.

**T5 - Venue discovery.** P2 found the three filters manageable but venue-list scrolling slow.

**T6 - Re-entry interpretation.** P2 explained that a guest who leaves and returns generates another entry, so entry totals do not identify the number of distinct guests. Ease: 6/7.

**Priority improvements:** provide a way to correct the last accidental count; retain station selection across refresh; strengthen the near-capacity warning.

## Observations: P3

**T1 - Role recognition.** The entry role was identified clearly.

**T2 - Save feedback and persistence.** The arrival produced the expected saved result. The saved confirmation and the new Recent entries row provided feedback that the entry had been recorded. The count remained 3 after reload. Ease: 6/7.

**T3 - Zero limit.** The final-departure result matched the expected count and the messages were described as precise. Ease: 6/7.

**T4 - Capacity limit.** The capacity result matched expectations and the messages were described as precise. Ease: 6/7.

**T5 - Filter carry-over.** The filtered row and summaries matched at 3/0/3. When returning to an active-event report after history-style filtering, Closed remained selected. Choosing the P3 venue therefore showed no rows and 0/0/0 until the status was changed to Active. The screen did not make the leftover filter prominent or provide a Clear filters control. Changing the status back to Active restored the expected report. Ease: 5/7.

**T6 - History and reporting needs.** Harbor Center with all statuses selected showed two events with totals of 832 entries, 420 exits and 412 inside. Selecting Closed and Harbor Workshop produced 420/420/0. P3 correctly interpreted entries as including re-entry and found the footer explanation. P3 requested moving the distinction next to Total entries, adding date-range filtering and providing export. Ease: 6/7.

**Priority improvements:** label entries versus unique people beside the summary card; provide Clear filters and highlight active filters; make Venue searchable.

## Ease ratings (1-7)

| Task | P1 | P2 | P3 |
| --- | --- | --- | --- |
| T1 | 5 | 6 | - |
| T2 | 4 | 5 | 6 |
| T3 | 5 | 6 | 6 |
| T4 | - | 6 | 6 |
| T5 | 4 | - | 5 |
| T6 | 4 | 6 | 6 |

## Analysis and proposed improvements

Counting and reporting outcomes were correct across the sessions, while the main usability costs involved recovering context after refresh and understanding the scope of a report. P1's lowest ease ratings were associated with event discovery, manager filtering and historical interpretation. P2's feedback emphasized operational speed, station continuity and correcting mistakes. P3's feedback emphasized filter visibility and interpretation of reporting totals. These are small-sample qualitative findings.

| ID / proposed priority | Finding and supporting observations | Recommended change / acceptance check |
| --- | --- | --- |
| F1 / Medium | Refresh clears attendant event/station choices (P1-T2, P2-T2). | Restore valid selections for the same account/role, while revalidating permissions and active status. Reload should retain the saved count and usable shift context. |
| F2 / Medium | Manager Venue cannot be searched by typing; scrolling is required (P1-T5, P2-T5, P3 priorities). | Add case-insensitive venue-name search, keyboard selection and clear no-results feedback. |
| F3 / Low | The interface uses 1 spaces remaining (P1-T4). | Use singular for one and plural for zero or multiple spaces; check 0, 1 and 2. |
| F4 / Low | Task and interface terminology differ: completed, Closed and closed (P1-T6). | Align the task wording and interface terminology; consider Closed (completed) where clarification is useful. Validate comprehension in a follow-up session. |
| F5 / Medium | Entry-versus-unique-person explanation is distant from totals (P1-T6, P3-T6). | Put a concise definition beside Total entries. Confirm a new user can explain re-entry without searching the footer. |
| F6 / Medium | A retained Closed filter hides an active event and produces zero summaries without a clear recovery action (P3-T5). | Highlight active filters and add Clear filters; resetting must restore rows and matching totals. |
| F7 / Medium | Similar event names and no search hint make event discovery harder (P1-T2). | Advertise searchable event selection and distinguish events clearly. Separate development/test clutter from realistic participant data. |
| F8 / Medium | Initial occupancy appears beside an empty Recent entries list (P1-T2). | Explain the initial count or provide demonstration history consistent with the starting occupancy. |
| F9 / High | No dedicated correction flow for accidental counts (P2-T3 and priorities). | Define an authorized, auditable correction process with a reason, linked original operation and consistent event/venue totals. Preserve the original attendance record. |
| F10 / Medium | Application identity is absent at sign-in; the signed-in account is not named in the header (P1-T1, P2-T1). | Identify Clicker at sign-in and show the active account/role. |

## Additional feedback and follow-up checks

- P2 requested a stronger near-capacity indication before the venue becomes full (T4).
- P3 requested date-range filtering and export (T6). Treat these as reporting feature requests, with requirements and acceptance criteria to be agreed.
- Review the leading minus sign in the exit label and clarify the hierarchy of simultaneous saved and empty alerts (P1-T3).
- Use realistic, clearly differentiated event and venue names to improve discovery.
