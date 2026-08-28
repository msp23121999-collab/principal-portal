# 04 — Page by Page

Every screen, in sidebar order. For each: what it is for, its filters, its tabs,
every card, chart, table and button on it, and where the data comes from.

**Read from the actual screen and widget files**, not from memory. Card titles
below are the literal strings in the code.

**Status tags:** `COMPLETE` · `PARTIALLY IMPLEMENTED` · `UI ONLY` ·
`NOT FOUND` · `BROKEN`

---

## Two things true of every screen

**1. Every screen has three states.** Loading (grey skeleton cards), error (a
red box), and data. There is no fourth state where a plausible-looking made-up
number appears. See [09-ERROR-STATES.md](09-ERROR-STATES.md).

**2. The filter bar is shared.** Where a screen shows filters, they are the same
seven-field object every other filtered screen reads. Narrow here, and it is
still narrowed there. See [13-FILTER-SYSTEM.md](13-FILTER-SYSTEM.md).

---

# 1. Dashboard

**Route** `/dashboard` · **Tabs** none · **Status** `COMPLETE`

**What it is for.** The one page a Principal opens in the morning. Everything
important, no clicking.

**Filters:** Academic Year · Department · Programme · Batch · Year of Study
*(no Subject — it means nothing to a dashboard)*

### The six KPI cards

| Card | Subtitle | Source |
|---|---|---|
| Total Students | the current scope | `v_dashboard_summary` / filtered roll |
| Total Faculty | department, when one is chosen | `v_dashboard_summary` |
| Departments | "Across engineering & technology" | `v_dashboard_summary` |
| Today's Attendance | "Average across departments" | `v_attendance_daily` |
| Result Pass % | the semester label | `semester_results` |
| Placement % | the placement scope | `placement_records` |

### The three summary panels

| Panel | Shows |
|---|---|
| **Department Summary** | top departments, with a "+N more" subtitle |
| **Faculty Status** | Total Faculty, **Present**, **Absent**, **On Leave**, Research Papers |
| **Student Summary** | Total Students, Average Attendance, Top Performers, At Risk |

Faculty Status reads `v_faculty_attendance_today` — genuine present/absent/leave
counts, not the `status` column (which reads "Active" for everybody).

### The rest

| Section | Type | Shows |
|---|---|---|
| Attendance Snapshot | bar chart | "This week — institution-wide" |
| Result | bar chart | pass % by department for the latest semester |
| Placement Summary | panel | Placed · Average Package · Highest Package · Top Recruiter |
| Recent Activities | list | from `audit_entries` |
| Pending Approvals | list | requests awaiting a decision, "+N more" when longer |
| Academic Calendar | month view | `public.academic_calendar_events` |

**Buttons:** none that act — the dashboard is read-only by design.

> **What was removed and why.** Three "growth" charts (Academic, Student,
> Faculty) and a Quick Options block were taken out. The growth charts drew a
> trend line from stored figures that contradicted the live counts beside them,
> and Quick Options duplicated the sidebar. The calendar now takes the full
> width rather than leaving a gap where Quick Options was.

---

# 2. Institution Overview

**Route** `/institution-overview` · **Tabs** none · **Status** `COMPLETE`

**What it is for.** The institution as a whole, and how the twelve departments
compare against one another.

**Filters:** Department · Programme · Batch · Semester
**Header controls:** Academic Year · Compare With · **Export Report** ✅

### Six KPI cards

Total Students · Total Faculty · Departments · Avg. Attendance *(weighted by
student numbers)* · Avg. Placement *(weighted)* · NIRF Ranking *(as last
published)*

> "Weighted by student numbers" is stated on the card deliberately. A flat mean
> across departments treats a 400-student department the same as a 4-student
> one.

### Sections

| Section | Type | Shows |
|---|---|---|
| **Recorded Enrolment** | chart | by programme level, as registered for the year |
| **Overall Performance** | chart | Pass Percentage (%) and Average SGPA (out of 10) |
| **Faculty Status** | panel | present / absent / on leave, "N total faculty" |
| **Department Summary** | table | # · Department · Programs · Students · Faculty · Pass % · Placement % · Attendance % · Action |
| **Key Highlights** | panel | Placements Recorded · Research Funding |
| **At a Glance** | panel | campus infrastructure — classrooms, labs, library, computers |
| **Departmental Performance Comparison** | chart + tables | Pass %, Attendance %, Placement % ranked across departments |
| **Admission Trends** | line chart | new admissions over the last 6 academic years |

**Why this page changed.** It used to carry its own department/programme/
semester row with Apply and Reset buttons, *on top of* the year controls.
Narrowing there changed nothing anywhere else, and narrowing elsewhere changed
nothing here. It now uses the shared filter bar.

The Departmental Performance Comparison moved here from its own tab on
Department Performance.

> **A contradiction that was fixed here.** This page once reported **4,740
> students** while the Dashboard reported **10**. It read a figure stored in
> `kpi_snapshots`; the Dashboard counted. Total Faculty showed 12 here and 0 on
> Faculty Status. Both now count live.

---

# 3. Academic Performance

**Route** `/academic-performance` · **3 tabs** · **Status** `COMPLETE`

**Filters:** Academic Year · Department · Programme · Semester

### Tab 1 — Overview

- KPI cards
- **Pass Percentage by Department** — ranked, against the previous published
  semester. The legend names the two semesters plotted; it was once fixed to
  '2024 - 2025' and '2023 - 2024' regardless of the data.
- **Performance Trend** — overall pass % by year
- **Top Performing Departments** — by pass percentage
- **Students At Risk** — "N students flagged for intervention"
- **Semester Wise Performance** table — Semester · Appeared · Passed · Pass % ·
  Avg SGPA · Avg CGPA · Backlogs · Top Performer

### Tab 2 — SGPA / CGPA Analysis

Cards: Average SGPA · Average CGPA · **First Class with Distinction** ·
**Require Academic Support**. Each names its band from the data rather than
repeating the boundary in code.

> **These two cards showed each other's figure.** The bands arrived sorted
> backwards, so the distinction card read 520 and the support card 486 when the
> truth was 486 and 520. Fixed — see
> [17-CURRENT-VS-EXPECTED.md](17-CURRENT-VS-EXPECTED.md).

Chart: **SGPA vs CGPA by Semester** — semester average against cumulative
average. Plus **SGPA Distribution**, subtitled with the number of students with
published results.

### Tab 3 — CO / PO Attainment

Cards: Course Outcomes Measured · Programme Outcomes Measured · **Outcomes at
High Attainment**, which finds the level-3 row by its label. `attainment_levels`
has no ordering column, so reading the first row returned whichever one Postgres
happened to send — it matched level 3 by luck.

- **Attainment by Department** — average outcome score, out of 3.0
- **Departmental Attainment Status** table — target attainment is 2.40
- **CO / PO Attainment Summary** table — Attainment Level · CO · PO · Overall

> **Explain Like I'm 5**
>
> **CO/PO attainment** asks: "we said this course would teach students X — did
> it?" Level 3 means yes, strongly.

> ⚠️ These figures come from `attainment_levels` (3 rows) — recorded values, not
> calculated from marks.

---

# 4. Result

**Route** `/result-analytics` · **4 tabs** · **Status** `COMPLETE`

**Filters:** Academic Year · Department · Programme · Batch · Semester ·
**Subject** *(the only screen with a Subject filter)*

> ⚠️ The sidebar says **"Result"**; the route is `/result-analytics`. The label
> was renamed, the route was not. Cosmetic — but there is no `/result` route.

**Why this page exists in this shape.** Result analysis was in two places:
inside Academic Performance and on its own page. Two pages, same subject, free
to disagree. They were merged into this one.

### Tab 1 — Result Analysis

Cards: Students Appeared · Students Passed · Students Failed · Active Backlogs

Plus **Grade Distribution** (students awarded each letter grade), Overall
Pass %, Top Department, Needs Attention.

### Tab 2 — Subject-wise

**Subject Performance** table, with a free-text search across code, name and
faculty:

Code · Subject · Dept · Sem · Faculty · Appeared · Passed · Failed · Pass % ·
Avg · **Highest** · **Lowest**

Highest and lowest marks come from `faculty.marks` — the only genuine
per-student marks in the system.

### Tab 3 — Department-wise

**Department Pass Summary** table — Department · Appeared · Passed · Failed ·
Pass % · Status. **Strongest first**, so the weakest department is at the bottom
where it is looked for.

Summed from subject results rather than stored, so it narrows with the filters
above it. Formula in [14-BUSINESS-LOGIC.md](14-BUSINESS-LOGIC.md).

### Tab 4 — Rank Holders

Rank · Student · Roll Number · Department · CGPA. From `rank_holders` (48 rows).

---

# 5. Department Performance

**Route** `/department-performance` · **2 tabs** · **Status** `COMPLETE`

**Filters:** Academic Year · Department · Programme · Batch
**Button:** Generate Report ✅ *(exports the active tab)*

### Tab 1 — Overview

- **Department cards** — Faculty · Students · Attendance · Placement per card
- **Programme Summary** table — Department · Programme · Students ·
  Avg. Attendance · At Risk · Status
- **Department Ranking** table — Rank · Department · Faculty · Students ·
  Attendance · Avg. CGPA · Placement, sorted by a chosen metric

### Tab 2 — Administration

Cards: Budget Allocated · Budget Utilised · **Vacant Teaching Posts** *(against
sanctioned strength)* · **Ratio Norm Breaches** *(above 20:1 student-faculty)*

- **Administrative Metrics** table — Department · Allocated · Utilised · Use % ·
  Posts · Vacant · Rooms · Labs · Ratio · Norm
- **Budget Utilisation** chart

Everything reads `v_department_rollup`, which derives Use %, Vacant and Ratio on
read so they can never contradict the columns beside them.

---

# 6. Faculty Performance

**Route** `/faculty-performance` · **3 tabs** · **Status** `COMPLETE`

**Filters:** Department only — a member of staff has no batch or semester.
**Button:** **Export Report** ✅ *(genuinely downloads a CSV of the filtered
roster)*

### Tab 1 — Roster

Cards: Total Faculty · Avg. Attendance · Research Papers

**Faculty Roster** table — Name · Designation · Department · Experience ·
Attendance · Research · Performance. Clicking a row opens a **profile dialog**
with qualification, contact, teaching workload, appraisal, research output and
recognitions.

### Tab 2 — Workload & Appraisal

Cards: **Average Weekly Load** *(against the norm)* · **Above Workload Norm** ·
Average Appraisal · Student Feedback

Table — Faculty · Department · Hours/Week · Subjects · Mentees · Appraisal ·
Feedback · Load. **Heaviest teaching load first.**

### Tab 3 — Research Output

Cards: Publications on Roster · Average per Faculty · Holding Funded Projects ·
Faculty with Recognitions

Tables and charts: **Research Output by Faculty** (most published first),
**Output by Department**, **Recognitions**.

> **A silent bug fixed here.** The repository was reading the row's uuid as the
> faculty `id`. Everything that joins on `employee_id` —
> `faculty_attendance`, `research_publications` — matched **nothing**, with no
> error. Now `employee_id` is read first.

> **And a second one.** `principal.faculty_details` holds 12 rows against a
> 16-strong roster, and the four members without one were shown workload,
> subjects handled, mentee counts, a qualification guessed from their job title
> and an **email address manufactured from their name** — all generated from
> `id.hashCode`. Their real qualification and real weekly workload were sitting
> unread in `faculty.faculties` the whole time.
>
> Those columns are now read, and anything genuinely unrecorded shows an em
> dash. A blank workload also gets no "Within norm" chip: that would be a
> verdict on a figure nobody entered.

---

# 7. Student Performance

**Route** `/student-performance` · **3 tabs** · **Status** `COMPLETE`

**Filters:** all six student filters (no Subject)
**Button:** **Download Report** ✅ — writes the **filtered** roll to CSV:
Name, Register No, Department, Programme, Batch, Year, Semester, CGPA,
Attendance %, At Risk.

> *"Exports what is on screen, filters and all — a report of the whole
> institution when the Principal is looking at one department would not be the
> report they asked for."*

If nothing matches, it says so rather than downloading an empty file.

### Tab 1 — Overview

Cards: Total Students · Average Attendance · At Risk
Chart: **Department Comparison** — average attendance % by department
Tables: **Top Performers** (ranked by CGPA) and **At-Risk Students** (low
attendance or CGPA — flagged for follow-up)

Every widget here reads `filteredStudentsProvider`, so the cards, the chart and
both tables always describe the same set of students.

### Tab 2 — Placements

Cards: Eligible Students · Students Placed · Placement Rate · Highest Package
Table: **Placement by Department** — Eligible · Placed · Unplaced · Rate ·
Highest · Average · Status, strongest first
Chart: **Placement Rate** by department

### Tab 3 — Achievements

Cards: Recognitions This Year · International · National · State
Table: **Student Achievements** — Student · Dept · Achievement · Event ·
Category · Position · Date · Level, most recent first. 34 rows.

> **Top Performers lives here, and only here.** It previously appeared on three
> screens with three different definitions.

---

# 8. Attendance Analytics

**Route** `/attendance-analytics` · **4 tabs** · **Status** `COMPLETE`

**Filters:** Academic Year · Department · Programme · Year of Study

| Tab | Contents |
|---|---|
| **Overall** | Today's Attendance · 2-Week Average · Best Day, then the **Attendance Trend** line chart |
| **Department** | Department Attendance chart + detail table (Department · Students · Faculty · Attendance) |
| **Faculty** | Name · Department · Designation · Attendance — **lowest first** |
| **Student** | per-year average cards, then Name · Roll Number · Department · Semester · Attendance — **lowest first** |

**Sorted lowest first, deliberately.** A Principal opening an attendance screen
is looking for the problem, not the success.

> **A crash fixed here.** The Overall tab called `days.last`, `days.reduce` and
> divided by `days.length`. A department with nothing on the register returns an
> empty list, and all three throw — the tab went grey in release with no
> message. It now shows *"No attendance recorded for CSE."*

---

# 9. Examination Monitoring

**Route** `/examination-monitoring` · **4 tabs** · **Status** `COMPLETE`

**Filters:** Department · Semester · **Button:** Export ✅ *(active tab)*

**KPI cards:** Papers Yet to Be Held · Total Candidates · Hall Tickets Issued ·
**Hall Tickets Withheld** *(attendance shortfall or dues)* · CIA Completion ·
Results Published

| Tab | Contents |
|---|---|
| **Schedule** | Examination Timetable — Date · Session · Code · Subject · Dept · Semester · Hall · Candidates · Stage |
| **Internal Assessments** | CIA Completion by Department (CIA 1/2/3) + Mark Entry Status table |
| **Hall Tickets** | Eligible · Issued · Awaiting Issue · Withheld cards, per-department table, Issue Progress chart |
| **Results** | Result Publication Status — Semester · Exam Ended · Papers · Evaluated · Evaluation % · Published On · Stage |

---

# 10. Research & Innovation

**Route** `/research-innovation` · **4 tabs** · **Status** `COMPLETE`

**Filters:** none — research is institution-wide, credited to authors.
**Button:** Export ✅ *(active tab)*

| Tab | Contents |
|---|---|
| **Overview** | Publications (YTD) · Patents Filed · Funded Projects · Grant Funding · Consultancy Revenue · Citations; **Research Output Trend** (five-year); Publications by Department |
| **Publications** | Title · Lead Author · Venue · Dept · Type · Year · Citations · Impact · Index — most cited first |
| **Patents & IPR** | Applications on Record · Awaiting Publication · Published · Granted, then the patent table |
| **Projects & Consultancy** | Funded Projects · Currently Running · Total Sanctioned · Funding Agencies; funded-project and consultancy tables |

> **`faculty.patents` holds 0 rows.** The Patents tab is genuinely empty — the
> institution has filed none. The empty state is correct behaviour, not a
> failure.

---

# 11. Accreditation & Rankings

**Route** `/accreditation` · **4 tabs** · **Status** `COMPLETE`

**Filters:** none — NAAC, NBA and NIRF assess the institution, not a semester.
**Button:** Generate Report ✅ *(active tab)*

| Tab | Contents |
|---|---|
| **Overview** | NAAC Evidence Completion per criterion; **Upcoming Deadlines** (due within 45 days) |
| **NAAC Criteria** | Criteria Complete · Evidence Uploaded · Evidence Outstanding · Overall Completion; the Cycle-3 criteria table |
| **NBA & Rankings** | Programme accreditation table; **NIRF Engineering Rank** *(lower is better)*; Ranking Record across all frameworks |
| **Documentation** | Documents Tracked · Submitted · In Progress · **Overdue**; compliance table with **overdue items listed first** |

> **Explain Like I'm 5**
>
> **NAAC** grades the whole college. **NBA** approves individual courses.
> **NIRF** is a national league table. All three want evidence, and this page
> tracks whether it exists.

> Migration 11 widened these score columns: **NBA's maximum is 1000**, and
> `numeric(5,2)` could not hold it.

---

# 12. Finance Overview

**Route** `/finance-overview` · **4 tabs** · **Status** `COMPLETE`

**Filters:** none — budget and payroll are institutional; fee status is already
per-department. **Button:** Export Report ✅ *(active tab)*

| Tab | Contents |
|---|---|
| **Overview** | Revenue vs Expenditure *(₹ lakh)*; Collection by Payment Mode; **Departments Needing Follow-Up**; Financial Highlights — Operating Surplus, Outstanding Fee Dues, Scholarship Beneficiaries, Annual Payroll Commitment |
| **Fee Collection** | Fee Demand Raised · Amount Collected · Outstanding · Students With Dues; per-department table |
| **Scholarships** | Schemes Running · Beneficiaries · Amount Sanctioned · Amount Disbursed; scheme table; Disbursement by Sponsor |
| **Payroll & Expenditure** | Staff on Roll · Monthly Payroll · Annual Commitment · **Teaching Share**; payroll-by-category and Expenditure Against Budget tables |

---

# 13. Placement Dashboard

**Route** `/placement-dashboard` · **4 tabs** · **Status** `COMPLETE`

**Filters:** Academic Year · Department · Programme · Batch
**Button:** **Export Report** ✅ *(real CSV of the filtered offers)*

| Tab | Contents |
|---|---|
| **Overview** | Students Placed · Average Package · **Highest Package** · **Lowest Package** · Companies Visited; **Offer Distribution by Package**; **Top Recruiters** |
| **Recruitment Drives** | Drives Held · Total Registrations · **Conversion Rate** *(offers against registrations)* · Students Interning; drives table |
| **Companies & Offers** | Recruiting Companies (Company · Sector · Students Hired · Avg. Package) and Placement Offers (Student · Roll Number · Department · Company · Package · Offer Date) |
| **Internships** | Organisation · Domain · Dept · Students · Duration · Stipend · PPO Route |

> **Lowest Package is shown on purpose.** A dashboard that reports only the
> highest offer tells the Principal the best available story, not the true one.

> **Removed:** a hardcoded "2,412 offers" (against 60 real records) and a
> "60/10 = 100% placement rate". Placement % is now capped at 100 with the
> reason recorded in migration 14.

---

# 14. Approvals

**Route** `/approvals` · **5 tabs** · **Status** `COMPLETE`

**Filters:** none. **Button:** Export Queue ✅ *(the active tab's queue)*

**Tabs:** Leave · Budget · Purchase · Event & Activity · Academic

Each category tab shows: Awaiting Decision · Approved · Rejected · **Value
Awaiting Decision**, then the request cards with **Approve** and **Reject**
buttons. A decision dialog shows Request ID, Raised by, Department, Submitted,
Priority and Amount before confirming.

### The only place the portal writes outside its own schema

Approving leave sets `status` on `faculty.leave_applications` — a **row** write,
their table structure untouched, so the Faculty Portal sees the decision
immediately.

Their table has `status` and `hod_remarks` but no principal column, so there is
nowhere there to record *who* decided or *why*. That full record goes to
`principal.approval_decisions`: decider, remark, when, and what the status was
before.

> **Explain Like I'm 5**
>
> Their form has a box that says "approved / rejected", so we tick it. It has no
> box for "who decided and why", and we are not allowed to add one to their
> form — so we keep that in our own notebook, with a reference to their form.

---

# 15. Circulars & Announcements

**Route** `/circulars` · **3 tabs** · **Status** `COMPLETE`

**Tabs:** Published · Drafts · Archived
**Button:** **Create Notice** ✅ — a real dialog with Category and Audience, and
**Save as Draft**, which writes to `principal.circulars`.

Each circular card offers **Publish** and **Archive**.

The Published tab also shows notices from the other portals —
`hod.department_notices` (20) and `student.notice_board_posts` (38) — read only.

---

# 16. Meetings & Calendar

**Route** `/meetings-calendar` · **4 tabs** · **Status** `COMPLETE`

**Button:** **Schedule Meeting** ✅ — a real dialog (Forum, Date, Duration) that
writes to `principal.meetings`.

| Tab | Contents |
|---|---|
| **Calendar** | month view; **Next Meetings**; **Day Detail** for the selected date |
| **Meetings** | Upcoming Meetings · Held This Year · Minutes Pending · Open Action Items; upcoming and past meeting tables |
| **Academic Calendar** | `public.academic_calendar_events` — Entry · Type · From · To · Days · Detail |
| **Minutes** | recorded minutes with resolutions, each with a **Download** button ✅ *(one row per resolution)* |

---

# 17. Reports & Analytics

**Route** `/reports-analytics` · **4 tabs** · **Status** `COMPLETE`

| Tab | Contents |
|---|---|
| **Report Library** | available report types, each with one **Export CSV** button ✅ |
| **Generate** | Module · Period · Format, a **Generate Report** button, and a preview showing the row count you are about to get |
| **Recently Generated** | Reports Requested · This Week · Modules Covered · Most Recent, then **Report History** |
| **Scheduled** | Schedules Configured · Currently Active · Paused · Next Run |

**Generate writes a real CSV immediately**, drawn from the same providers the
named screen reads, then records the request in `report_runs`. If that record
fails you still keep the file, and the message says so.

**Format offers CSV only.** Nothing in this project can typeset a PDF or write a
native Excel workbook. It used to default to PDF.

> **What this screen used to be.** A row was written to `report_runs` and
> nothing else happened, while the table showed a file **Size**, a status of
> Queued / Generating / Ready, and a download button — for a file that never
> existed. It was the most convincing incomplete screen in the portal. The size
> column, the status chip and the download button are gone, because there is no
> queue for a report to sit in.

---

# 18. Audit & Compliance

**Route** `/audit-compliance` · **4 tabs** · **Status** `COMPLETE`

**Button:** Export Report ✅ *(active tab)*

| Tab | Contents |
|---|---|
| **Audit Log** | Actions Recorded · **Critical Actions** · Modules Touched · **Showing** *(after active filters)*; the trail — Timestamp · Actor · Role · Action · Module · Detail · IP Address · Severity |
| **Compliance** | Overall Compliance · Areas Compliant · Needing Action · Open Inspection Findings; scorecard **weakest first**; Compliance by Category |
| **Inspections** | Inspection · Authority · Date · Inspector · Major · Minor · Observations · Closed · Outcome |
| **Policy Adherence** | Policies Tracked · Average Adherence · Below Target · **Reviews Overdue**; table with **overdue reviews first** |

The page subtitle is **blank until the figures load**, rather than showing zeros
that would read as a real "0% compliant".

> ⚠️ The audit log records what has been **written into it**. It is not an
> automatic capture of everything the portal does, and — with no login — the
> "Actor" is not verified.
# 19. Notifications

**Route** `/notifications` · **Tabs** none · **Status** `COMPLETE` (read-only)

Alerts gathered from `faculty.notifications` (48) and
`student.student_notifications` (13). The sidebar badge shows the unread count.

> Marking something read changes only this browser session's copy. Nothing is
> written back — those tables belong to the other portals.

---

# 20. My Profile

**Route** `/my-profile` · **6 tabs** · **Status** `PARTIALLY IMPLEMENTED`

**Stat strip:** Teaching Experience · HOD Leadership · Research Papers · Awards
**Button:** Export Profile ✅ — a sectioned CSV of the whole record. It replaced
'Export PDF', whose handler said *"Export simulated (no backend yet)."*

| Tab | Contents |
|---|---|
| **Personal Profile** | Full Legal Name · Date of Birth · Gender · Employee ID · Email · Phone · Office Cabin · Office Hours · Address |
| **Professional & Degrees** | Total Experience · HOD Experience · Highest Qualification; Educational Qualifications |
| **Research & Teaching** | Research Publications; Awards & Recognitions |
| **Responsibilities** | roles held |
| **Documents (Verified)** | Document · Type · Uploaded |
| **Account Security** | states that sign-in is not enabled; controls disabled |

### The Account Security tab

An amber notice at the top reads **"Sign-in is not enabled"** — anyone who opens
the web address has full access, and *"Do not treat this portal as private until
sign-in is in place."* Below it, three cards with every control **disabled**:
Password, Two-Factor Authentication, and Recent Login Activity.

The controls are kept, disabled, so whoever builds authentication can see where
each piece belongs.

> **What it used to say.** *"Password — last changed 45 days ago"*, a working
> Change Password button, a two-factor toggle that moved and remembered its
> position, and two recent sign-ins with times and browsers. None of it was
> real, and it was the most dangerous screen in the portal: every other gap is
> visible, but this one told a Principal their account was protected when
> anyone with the address was already inside.

Authentication itself is still absent — see [15-SECURITY.md](15-SECURITY.md)
and `BLOCKERS.md`.

The whole profile is keyed to the literal text `'placeholder-principal'`,
because there is no user to attach it to.

---

## Removed screens

**Digital Repository** and **Settings** were removed from the portal on the
Principal's instruction. Their routes, screens, providers, repositories and
tests are deleted.

Their tables — `principal.repository_folders`, `principal.repository_documents`
and `principal.user_settings` — still exist in the database. Nothing reads them.
Dropping them is a separate, irreversible decision and was not taken here.

---

**Next:** [13-FILTER-SYSTEM.md](13-FILTER-SYSTEM.md) — how the dropdowns work,
or [14-BUSINESS-LOGIC.md](14-BUSINESS-LOGIC.md) for where the numbers come from.
