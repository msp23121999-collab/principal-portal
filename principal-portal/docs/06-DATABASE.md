# 06 — Database

Every table the Principal Portal touches. **Row counts were read live from the
database on 10 August 2026** — they are real, not estimates.

---

## What a database is

> **Explain Like I'm 5**
>
> A **database** is a big cupboard.
>
> A **schema** is one shelf in the cupboard. This cupboard has five shelves, and
> different people own each one.
>
> A **table** is one box on a shelf. One box holds students. Another holds
> meetings.
>
> A **column** is one label on the box — "name", "roll number", "marks".
>
> A **row** is one card inside the box — one student, one meeting.
>
> A **primary key** is the unique number on each card so two cards are never
> confused, even if two students share a name.
>
> A **foreign key** is a card that says "see card 12 in the other box" — that is
> how boxes are linked.
>
> A **view** is a note on the wall, not a box: "count the cards in box 1 and box
> 2". You read it and get today's answer, never a stale one.

---

## The five shelves

| Schema | Owner | Portal's rights | Tables used |
|---|---|---|---|
| `principal` | **This portal** | read **and** write | 62 tables + 7 views |
| `student` | Student Portal | **read only** | 4 |
| `faculty` | Faculty Portal | read only, one row-level exception | 6 |
| `hod` | HOD Portal | read only | 1 |
| `public` | shared | read only | 1 |

**The one exception:** approving leave sets `status` on
`faculty.leave_applications`. That changes a row's contents, never the table's
shape. The full decision record goes to `principal.approval_decisions`.

---

## Read-only source tables

These belong to the other portals. **Never write to them.**

| Table | Holds | Rows | Used by |
|---|---|---|---|
| `student.students` | the student roll | **10** | Dashboard, Student Perf, Attendance, filters, search |
| `student.attendance_table` | daily register, periods p1–p8 | 47 | Attendance |
| `student.notice_board_posts` | student notices | 38 | Circulars |
| `student.student_notifications` | student alerts | 13 | Notifications |
| `faculty.faculties` | the staff list | 16 | Faculty Perf, Institution, Attendance, search |
| `faculty.marks` | internal assessment marks | **18** | Result (subject high/low) |
| `faculty.leave_applications` | leave requests | 10 | Approvals |
| `faculty.notifications` | staff alerts | 48 | Notifications |
| `faculty.research_publications` | published papers | 8 | Research |
| `faculty.patents` | patents | **0** | Research |
| `hod.department_notices` | department notices | 20 | Circulars |
| `hod.hod_departments` | official department roster | **0** | — see warning below |
| `public.academic_calendar_events` | shared calendar | 3 | Meetings, Dashboard |

> ⚠️ **Two data realities that explain most "empty" screens**
>
> **`student.students` holds 10 rows** across 12 departments. Ten departments
> have nobody. Every `0.0%` and `—` you see for those departments is honest, not
> a bug.
>
> **`faculty.marks` holds 18 rows**, all `CIA - I`, `CIA - II` or `Model Exam` —
> **no end-semester results**. This is why a real SGPA cannot be calculated. See
> [17-CURRENT-VS-EXPECTED.md](17-CURRENT-VS-EXPECTED.md).
>
> **`hod.hod_departments` is empty**, which is why `principal.departments` exists
> as its own master list. When the HOD team fills theirs, the two will need
> reconciling — recorded in migration 01.

---

## The `principal` schema — all 62 tables

Every table has `id uuid primary key`, `created_at`, `updated_at`. The
`updated_at` column is kept current by one shared trigger,
`principal.set_updated_at()`.

### Core

| Table | Purpose | Rows |
|---|---|---|
| `departments` | master department list — the hub everything joins to | 12 |
| `academic_years` | which years exist, which is current | 4 |
| `kpi_snapshots` | stored headline figures, split by `module` | 18 |

### Institution

| Table | Purpose | Rows |
|---|---|---|
| `institution_metrics` | multi-year series (admission, growth) | 24 |
| `program_enrolments` | recorded enrolment per programme level | 4 |
| `semester_performance` | pass % and average SGPA per semester | 8 |
| `facility_stats` | classrooms, labs, library, computers | 4 |
| `institution_highlights` | recorded achievements (accreditations, ranking) | 3 |

### Academic and results

| Table | Purpose | Rows |
|---|---|---|
| `subject_results` | per subject: appeared, passed, average | 60 |
| `semester_summaries` | per semester totals | 8 |
| `semester_results` | published semester result headline | 6 |
| `semester_result_departments` | that result, split by department | 72 |
| `rank_holders` | semester rank list | 48 |
| `sgpa_bands` | grade-point histogram bands | 5 |
| `grade_slices` | letter-grade counts | 6 |
| `attainment_levels` | CO/PO attainment | 3 |
| `at_risk_reasons` | why students are flagged | 3 |
| `yearly_pass_rates` | pass % by year | 5 |

### Department and faculty

| Table | Purpose | Rows |
|---|---|---|
| `department_admin_metrics` | budget, posts, facilities per department | 12 |
| `faculty_details` | workload and appraisal detail | 12 |
| `faculty_achievements` | staff achievements | **0** |
| `faculty_attendance` | **daily staff register** — present / absent / on leave | 180 |

> `faculty_attendance` is the Principal Portal's own table because nothing else
> records it. `faculty.faculties.status` reads "Active" for everyone — that is an
> employment state, not whether somebody came in. Ownership risk is noted in
> migration 17: the Faculty Portal is the natural owner long-term.

### Examinations

| Table | Purpose | Rows |
|---|---|---|
| `exam_schedules` | the exam timetable | 48 |
| `cia_progress` | internal assessment completion | 12 |
| `hall_ticket_status` | issued / withheld / pending | 12 |
| `result_publications` | publication state per semester | 8 |

### Accreditation

| Table | Purpose | Rows |
|---|---|---|
| `accreditation_standings` | NAAC / NBA / NIRF standing | 4 |
| `criterion_progress` | NAAC criteria evidence | 7 |
| `program_accreditations` | per-programme accreditation | 12 |
| `ranking_entries` | ranking history | 10 |
| `compliance_documents` | documents and due dates | 16 |

### Finance

| Table | Purpose | Rows |
|---|---|---|
| `monthly_finance` | revenue vs expenditure per month | 36 |
| `department_fee_status` | demand, collected, students paid | 12 |
| `payment_mode_splits` | how fees were paid | 5 |
| `scholarship_schemes` | schemes and disbursement | 8 |
| `payroll_lines` | headcount and monthly cost | 6 |
| `expenditure_heads` | budgeted vs actual | 10 |

### Placements

| Table | Purpose | Rows |
|---|---|---|
| `companies` | recruiting companies | 20 |
| `placement_records` | one row per offer | 60 |
| `placement_drives` | recruitment drives | 20 |
| `internship_records` | internships | 24 |

> `placement_records` has **no batch column**. The batch is read from the
> register number (`22CSE001` → 2022 → "2022–2026"), so it can never disagree
> with the number it came from. See [14-BUSINESS-LOGIC.md](14-BUSINESS-LOGIC.md).

### Approvals, meetings, circulars

| Table | Purpose | Rows |
|---|---|---|
| `approval_requests` | requests awaiting decision | 30 |
| `approval_decisions` | **audit trail** of every decision | 0 |
| `meetings` | scheduled meetings | 17 |
| `meeting_agenda_items` | agenda per meeting | 81 |
| `meeting_minutes` | recorded minutes | 7 |
| `circulars` | the Principal's own notices | 20 |

### Reports, audit, repository

| Table | Purpose | Rows |
|---|---|---|
| `report_items` | report types available | 10 |
| `report_runs` | requested runs (**no file produced**) | 10 |
| `scheduled_reports` | recurring schedules | 8 |
| `audit_entries` | recorded actions | 20 |
| `compliance_areas` | compliance scoring | 12 |
| `inspection_reports` | external inspections | 8 |
| `policy_adherence` | policies and review dates | 10 |
| `repository_folders` | document folders | 8 ⚠️ |
| `repository_documents` | document **details only, no files** | 64 ⚠️ |

> ⚠️ **Three tables are no longer read by anything.** The Digital Repository and
> Settings screens were removed from the portal, so `repository_folders`,
> `repository_documents` and `user_settings` sit unused. They were left in place
> rather than dropped — that is an irreversible change to a shared database and
> a separate decision.

### Profile, settings, students, research

| Table | Purpose | Rows |
|---|---|---|
| `principal_profiles` | the Principal's record (+5 child tables) | 1 |
| `user_settings` | preferences | 1 ⚠️ |
| `student_achievements` | prizes and recognitions | 34 |
| `funded_projects` | externally funded research | 10 |
| `consultancy_projects` | consultancy work | 8 |
| `research_year_output` | yearly research totals | 5 |

---

## The seven views

A view stores nothing. It recalculates every time it is read, so a total can
never drift from the rows it describes.

| View | Works out | Rows | Read by |
|---|---|---|---|
| `v_department_rollup` | per department: live student and staff counts, attendance, pass %, placement %, rank | 12 | Institution, Department, Dashboard |
| `v_dashboard_summary` | every headline dashboard figure, one row | 1 | Dashboard |
| `v_attendance_daily` | average attendance per day, whole college | 15 | Attendance, Dashboard |
| `v_attendance_daily_by_department` | the same, per department | 15 | Attendance |
| `v_faculty_attendance_today` | present / absent / on leave per department | 2 | Dashboard, Faculty |
| `v_department_placement_summary` | offers against roll per department | 12 | Student Perf |
| `v_package_bands` | offers grouped into salary bands | 5 | Placements |

> **Why views and not stored totals**
>
> A stored total is written once and goes stale silently. That is exactly how
> this project ended up showing **4,740 students on one screen and 10 on
> another** — one read a stored figure, the other counted. Counting on read
> makes that impossible.

---

## Migrations

20 files in `supabase/migrations/`, applied in filename order. A migration is a
recorded, repeatable change to the database's shape.

| File | What it did |
|---|---|
| `…0001_principal_schema_and_shared` | created the schema, `set_updated_at()`, departments, academic years, KPI snapshots |
| `…0002_institution` | institution metrics, enrolment, performance, facilities, highlights |
| `…0003_policy_helper` | `apply_standard_setup(table)` — trigger + RLS + policies in one call |
| `…0004_academic_and_results` | subject results, semester summaries, bands, slices |
| `…0005_department_faculty_exams` | department metrics, faculty details, exam tables |
| `…0006_accreditation_and_finance` | accreditation and finance tables |
| `…0007_placements_and_approvals` | companies, placements, drives, approvals |
| `…0008_meetings_reports_audit` | meetings, reports, audit |
| `…0009_repository_profile_settings_circulars` | repository, profile, settings, circulars |
| `…0010_views` | the first five views |
| `…0011_widen_accreditation_scores` | NBA maximum is 1000; `numeric(5,2)` could not hold it |
| `…0012_natural_keys_for_idempotent_seed` | unique keys so re-seeding cannot double every table |
| `…0013_extend_department_rollup` | added columns to the rollup |
| `…0014_cap_placement_percent` | capped placement % at 100 |
| `…0015_research_projects` | funded and consultancy projects, yearly output |
| `…0016_student_achievements` | student achievements |
| `…0017_faculty_attendance` | the staff register + `v_faculty_attendance_today` |
| `…0018_drop_countable_highlights` | removed two stale highlights the database contradicted |
| `…0019_attendance_by_department` | `v_attendance_daily_by_department` |
| `…0020_drop_performer_records` | dropped an unused table of degenerate seed data |

Every migration carries a `-- ROLLBACK:` comment saying how to undo it.

> ⚠️ **Migration ownership warning.** `supabase db push` currently refuses: the
> remote history contains **five migrations that are not in this repository**.
> Another team is changing this database. Migrations 19 and 20 were therefore
> applied with direct statements rather than by repairing a shared history this
> portal does not own. Two teams migrating uncoordinated will eventually
> collide.

---

## Security state of the database

**RLS (row-level security)** is the database's own lock — it decides which rows
a request may read or change, independently of the app.

| Schema | RLS | Effect |
|---|---|---|
| `principal` | **ON**, permissive policies | Locked, but the policies currently allow everything, ready to tighten when login exists |
| `student` | **OFF** | ⚠️ anyone with the public key can read **and write** |
| `faculty` | **OFF** | ⚠️ same |
| `hod` | **OFF** | ⚠️ same |

This is not theoretical. It was tested. See
[15-SECURITY.md](15-SECURITY.md).

---

**Next:** [07-DATABASE-RELATIONSHIPS.md](07-DATABASE-RELATIONSHIPS.md) — how the
tables connect.
