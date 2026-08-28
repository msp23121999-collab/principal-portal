# 17 — Current vs Expected

What the portal does today, what a Principal would reasonably expect it to do,
and the honest distance between the two.

> **Updated after the improvement pass of 11 August 2026.** Items marked
> ✅ **FIXED** were closed in that pass; see `IMPROVEMENT_REPORT.md` for what
> changed and `BLOCKERS.md` for what could not be. Everything still open is
> open because it needs a decision or a team outside this repository.

---

## How to read the status tags

| Tag | Meaning |
|---|---|
| `COMPLETE` | Works end to end against real data |
| `PARTIALLY IMPLEMENTED` | Works, but not the whole way |
| `UI ONLY` | The screen exists; nothing behind it |
| `NOT FOUND` | Does not exist anywhere in the codebase |
| `MOCK / STATIC DATA` | Reads seeded values, not derived ones |
| `BROKEN` | Exists and fails |

> **There is no `BROKEN` item in this portal.** `flutter analyze` reports 0
> issues, 114 tests pass, and all 20 routes render. The gaps below are things
> that are *missing* or *incomplete*, not things that crash.

---

# Priority 1 — Blocks real deployment

## 1.1 No authentication `NOT FOUND`

**Expected:** log in, and the portal knows who you are.
**Actual:** no login page, no session, no roles. Anyone with the address is the
Principal.

**Impact:** cannot be deployed to a public address.
**Fix:** a college decision on which identity system to use, then a login route
and a shell guard. Full detail in [15-SECURITY.md](15-SECURITY.md).

## 1.2 The public key can edit student marks `BROKEN` *(database, not app)*

**Expected:** a public key can read what it is allowed to read and change
nothing.
**Actual:** **proven** — a `PATCH` with the anon key changed a real student's
CGPA from 8.62 to 9.99, then restored it. RLS is off on `student`, `faculty`
and `hod`.

**Impact:** anyone can alter marks, attendance or fees from their own computer.
**Fix:** the owning teams write RLS policies and enable RLS per table. Cannot be
done from this repository without breaking three other portals.

## 1.3 Account Security tab claimed protection that does not exist ✅ FIXED

**Was:** *"Password — last changed 45 days ago"*, a working Change Password
button, a two-factor toggle that moved and remembered its position, and two
recent sign-ins with times and browsers. None of it was real.

**Now:** an amber notice reading **"Sign-in is not enabled"**, and every control
disabled. The controls are kept so whoever builds authentication can see where
each piece belongs; the fabricated values are gone.

Authentication itself is still absent — see 1.1 and `BLOCKERS.md`.

---

# Priority 2 — Visible to the Principal, misleading

## 2.1 Reports produced no file ✅ FIXED

**Was:** a row written to `report_runs` recording that a report was requested,
while the screen showed a size, a `Queued / Generating / Ready` status and a
download button for a file that never existed.

**Now:** **Generate writes a real CSV immediately**, drawn from the same
providers the corresponding screen reads. Format offers CSV only — nothing here
can typeset a PDF or write a native Excel workbook, and the default used to be
PDF. "Recently Generated" is now **Report History**: the size column, the status
chip and the download button are gone, because there is no queue for a report to
sit in.

## 2.2 Twelve export buttons did nothing ✅ FIXED

**Was:** 3 of 12 wrote a file. Nine showed a message.

**Now:** all twelve write a CSV of **the table in view, after filtering**. On
tabbed screens the button exports the active tab, using a new
`TabbedPage.onTabChanged` and `activeTabProvider`. `TableExport.run()` wraps the
empty check, the download and the confirmation once.

One download button is deliberately **disabled** rather than wired up — the
per-document one on My Profile → Documents. There is no file to fetch and the
tooltip says so.

## 2.3 The repository stored no files ✅ RESOLVED BY REMOVAL

**Was:** the screen offered upload and download for files that were never
stored — it recorded a document's name, type, owner, size and version only.

**Outcome:** the Digital Repository screen was removed from the portal entirely
on the Principal's instruction, so there is no longer a screen implying file
storage. `repository_folders` and `repository_documents` remain in the database,
unread.

---

# Priority 3 — Data, not code

## 3.1 The student roll holds 10 rows `MOCK / STATIC DATA`

**Expected:** several thousand students across 12 departments.
**Actual:** **10 students**, and **10 of the 12 departments have nobody.**

**Impact:** most `0.0%` and `—` on screen are honest empties, not bugs. But they
make the portal look broken to anyone who does not know.

**This is not a code defect.** It resolves when the Student Portal's roll is
populated. Several capped or guarded calculations exist purely because of it —
see 3.2.

## 3.2 Placement % had to be capped at 100 — a symptom of 3.1

60 placement records are divided by a 10-student roll. IOT came out at **125%
placed**. Migration 14 caps it at 100.

The calculation is not wrong. The two populations do not match yet. It corrects
itself once both describe the same students.

## 3.3 SGPA cannot be calculated `NOT FOUND` — and should not be faked

**Expected:** SGPA per student, per semester.
**Actual:** `faculty.marks` holds **18 rows, 8 students, 3 subjects**, and every
row is `CIA - I`, `CIA - II` or `Model Exam`. **There are no end-semester
results.**

SGPA is calculated from end-semester grade points and credits. Neither exists.

**Building this today would mean renaming internal-assessment marks as SGPA** —
inventing a number the college does not have. That is refused, and recorded here
instead.

**Fix:** the Examination team enters end-semester results. Then it is a
straightforward calculation.

## 3.4 Three tables are empty

| Table | Rows | Is that correct? |
|---|---|---|
| `faculty.patents` | 0 | ✅ Yes — the institution has filed none |
| `principal.faculty_achievements` | 0 | ⚠️ Not seeded |
| `principal.approval_decisions` | 0 | ✅ Yes — no decision has been made yet |
| `hod.hod_departments` | 0 | ⚠️ The HOD team has not populated theirs |

`hod_departments` being empty is why `principal.departments` exists as its own
master list of 12. If the HOD team fills theirs, the two need reconciling.

---

# Priority 4 — Architecture and process

## 4.1 Filtering happens in the browser

The whole roll is fetched, then narrowed in Dart. Fine at 10 students. At 10,000
it means downloading 10,000 rows to show 40.

**Fix when the roll grows:** push the filters into the PostgREST query.

## 4.2 Two teams migrating one database `PARTIALLY IMPLEMENTED`

`supabase db push` refuses — the remote history contains **five migrations not
in this repository**. Migrations 19 and 20 were applied with direct statements
rather than repairing a history this portal does not own.

**Fix:** one shared migration repository, or agreed schema ownership.

## 4.3 One rule written in two languages ✅ GUARDED

At-risk and top-performer thresholds still exist twice — in Dart
(`StudentRepository.atRiskCgpa` and friends) and in SQL (`v_dashboard_summary`).
With no backend there is no way for the two to share one definition.

**They can no longer drift silently.** `test/threshold_drift_test.dart` reads the
numbers out of the migration and compares them to the Dart constants, so changing
one side alone fails the build with a message naming both. The constants are now
public, and each side carries a comment pointing at the other.

## 4.4 `faculty_attendance` is in the wrong schema, knowingly

Nothing recorded daily staff attendance, so the Principal Portal records it.
Migration 17 states plainly that the Faculty Portal is the natural owner.

**Fix when they add one:** make this a view over theirs, or reconcile with a
sync job.

## 4.5 No CI/CD, no Docker, no deployment pipeline `NOT FOUND`

Builds are run by hand with `run-live.bat`.

---

# What was fixed during this work

Recorded so it is not re-broken.

| Was | Now |
|---|---|
| Institution said 4,740 students, Dashboard said 10 | both count live |
| Total Faculty: 12 on one screen, 0 on another | one source |
| Attendance: 14.60% next to 86.4% on one screen | one weighted calculation |
| All 24 `.order()` calls sorted **descending** by default — every chart drawn backwards | direction stated explicitly on every call |
| Academic Year dropdown asserted on every build (hardcoded list missing its own default) | reads `principal.academic_years` |
| Attendance Overall tab crashed on an empty department | shows an empty state |
| ~20 `.value` calls that rethrow on error | `valueOrNull` |
| `performer_records` — 36 "top" rows, 17 distinct names, 3 CGPA values, one student in two departments | dropped (migration 20) |
| Hardcoded `+1.2%`, "2,412 offers" (60 real), "34 funded projects" (10 real), "100% placement rate" | removed |
| Two stale institution highlights the database contradicted | dropped (migration 18) |
| Faculty repository read the uuid where every join needs `employee_id` | reads `employee_id` first |
| Chart axes: repeated `2026 2026 2026`, `4262` wrapped to `426`/`2`, `92.00%` clipped to `92.0…` | fixed reserves and formatter |
| Top Performers in three places with three definitions | one place — Student Performance |
| 27 mock-data files | deleted |
| **`_simpleList` sorted 3 lookup tables backwards**, swapping the "distinction" and "needs support" cards (520 / 486 the wrong way round) and drawing the pass-rate trend falling when it rose | `ascending: true` stated; guarded by `test/query_safety_test.dart` |
| **`FacultyDetail.forFaculty` invented workload, subjects, mentees, a qualification and an email address from `id.hashCode`** for 4 real named staff | deleted; real columns read, unrecorded fields render as an em dash |
| "Outcomes at High Attainment" read `levels.first` on an unordered list | selects the level-3 row by label |
| Faculty cards printed the literal text `NaN` when a department had no staff | guarded; `test/empty_scope_test.dart` |
| Four captions stated a year in code (`2025-26`, `April - May 2025`, a chart legend fixed to `2024 - 2025`) | derived from the rows on screen |
| **Two fabricated growth figures** on Research — `17.8% vs 2023-24`, `26.3% vs 2023-24` | computed from `research_year_output`, absent when there is no prior year |
| Upload crashed with no folders; four `.single()` reads surfaced raw driver errors | guarded; `maybeSingle()` with plain messages |

---

# Recommended order of work

Items 4, 5 and 6 from the original list are done. What is left:

| # | Item | Effort | Blocks |
|---|---|---|---|
| 1 | Decide the identity system (1.1) | decision | everything below |
| 2 | RLS on `student`/`faculty`/`hod` (1.2) | cross-team | deployment |
| 3 | Populate the student roll (3.1) | data entry | most empty screens |
| 4 | End-semester results, then SGPA (3.3) | data entry, then small | Academic screens |
| 5 | Agree migration ownership (4.2) | process | future changes |
| 7 | Server-side filtering (4.1) | medium | only at scale |

**1 to 5 all need someone outside this repository.** They are written up with
owners in `BLOCKERS.md`.

---

**Next:** [19-COMPLETE-FEATURE-MATRIX.md](19-COMPLETE-FEATURE-MATRIX.md) —
everything in one table.
