# 19 — Complete Feature Matrix

Everything, in one table. Use this to answer "does the portal do X?" in one
lookup.

---

## Totals

| | Count |
|---|---|
| Screens | **20** |
| Tabbed screens | 17 |
| Tabs | **65** |
| Screens carrying filters | 10 |
| Filter fields | 7 |
| Dart files | 302 |
| Lines of Dart | ~31,000 |
| Packages | **9** |
| `principal` tables | **62** |
| `principal` views | **7** |
| Read-only source tables | 13, across 4 schemas |
| Removed screens | Digital Repository, Settings |
| Migrations | 20 |
| Tests | **114**, all passing |
| Static-analysis issues | **0** |
| REST endpoints written by this project | **0** — there is no backend |
| Authentication mechanisms | **0** |
| Roles | 1, unenforced |

---

## Screens

| # | Screen | Route | Tabs | Filters | Writes? | Export | Status |
|---|---|---|:-:|:-:|:-:|:-:|---|
| 1 | Dashboard | `/dashboard` | — | 5 | — | — | `COMPLETE` |
| 2 | Institution Overview | `/institution-overview` | — | 4 | — | ✅ | `COMPLETE` |
| 3 | Academic Performance | `/academic-performance` | 3 | 4 | — | — | `COMPLETE` |
| 4 | Result | `/result-analytics` | 4 | 6 | — | — | `COMPLETE` |
| 5 | Department Performance | `/department-performance` | 2 | 4 | — | ✅ | `COMPLETE` |
| 6 | Faculty Performance | `/faculty-performance` | 3 | 1 | — | ✅ | `COMPLETE` |
| 7 | Student Performance | `/student-performance` | 3 | 6 | — | ✅ | `COMPLETE` |
| 8 | Attendance Analytics | `/attendance-analytics` | 4 | 4 | — | — | `COMPLETE` |
| 9 | Examination Monitoring | `/examination-monitoring` | 4 | 2 | — | ✅ | `COMPLETE` |
| 10 | Research & Innovation | `/research-innovation` | 4 | — | — | ✅ | `COMPLETE` |
| 11 | Accreditation & Rankings | `/accreditation` | 4 | — | — | ✅ | `COMPLETE` |
| 12 | Finance Overview | `/finance-overview` | 4 | — | — | ✅ | `COMPLETE` |
| 13 | Placement Dashboard | `/placement-dashboard` | 4 | 4 | — | ✅ | `COMPLETE` |
| 14 | Approvals | `/approvals` | 5 | — | **✅ ¹** | ✅ | `COMPLETE` |
| 15 | Circulars & Announcements | `/circulars` | 3 | — | ✅ | — | `COMPLETE` |
| 16 | Meetings & Calendar | `/meetings-calendar` | 4 | — | ✅ | ✅ | `COMPLETE` |
| 17 | Reports & Analytics | `/reports-analytics` | 4 | — | ✅ ² | ✅ | `COMPLETE` |
| 18 | Audit & Compliance | `/audit-compliance` | 4 | — | — | ✅ | `COMPLETE` |
| 19 | Notifications | `/notifications` | — | — | — | — | `COMPLETE` |
| 20 | My Profile | `/my-profile` | 6 | — | — | ✅ | `PARTIALLY IMPLEMENTED` ⁴ |

¹ The only write outside `principal`: `status` on
`faculty.leave_applications`, plus the full record in `approval_decisions`.
² Writes a real CSV immediately, and records the request in `report_runs`.
⁴ Account Security states plainly that sign-in is not enabled; its controls are
disabled.

---

## Features

| Feature | Status | Note |
|---|---|---|
| **Viewing** | | |
| Whole-college dashboard | `COMPLETE` | |
| Department comparison | `COMPLETE` | |
| Result analysis by subject and department | `COMPLETE` | |
| Rank holders | `COMPLETE` | |
| Attendance — overall, department, faculty, student | `COMPLETE` | |
| Faculty roster, workload, research | `COMPLETE` | |
| Student roll, top performers, at-risk | `COMPLETE` | |
| Placements incl. **lowest** offer | `COMPLETE` | |
| Exams, hall tickets, CIA, publication | `COMPLETE` | |
| Research, patents, funded projects | `COMPLETE` | patents genuinely 0 |
| Accreditation and rankings | `COMPLETE` | |
| Finance, fees, scholarships, payroll | `COMPLETE` | |
| Audit trail, compliance, inspections | `COMPLETE` | recorded, not auto-captured |
| Notifications from other portals | `COMPLETE` | read-only |
| **Acting** | | |
| Approve / reject leave | `COMPLETE` | writes to two schemas |
| Approve / reject budget, purchase, event, academic | `COMPLETE` | |
| Create and publish a circular | `COMPLETE` | |
| Schedule a meeting | `COMPLETE` | |
| Generate a report | `COMPLETE` | writes a real CSV immediately |
| **Filtering and search** | | |
| Portal-wide filter that follows you | `COMPLETE` | 7 fields, 10 screens |
| Filter hierarchy (dept clears programme + subject) | `COMPLETE` | |
| Option lists derived from live rows | `COMPLETE` | never hardcoded |
| Global search (students, faculty, departments) | `COMPLETE` | was previously a dead box |
| **Export** | | |
| CSV — every export button | `COMPLETE` | 12 controls, all writing the filtered table in view |
| PDF | `NOT FOUND` | |
| Excel (native) | `NOT FOUND` | CSV opens in Excel |
| **Absent** | | |
| Login / logout | `NOT FOUND` | |
| Roles / permissions | `NOT FOUND` | |
| Password change / 2FA | `NOT FOUND` | the screen now says so and its controls are disabled |
| File upload / storage | `NOT FOUND` | the Digital Repository screen that recorded document details has been removed |
| Email / SMS notifications | `NOT FOUND` | |
| Backend server / REST API | `NOT FOUND` | by design |
| Docker / CI / CD | `NOT FOUND` | |
| Offline support | `NOT FOUND` | |
| Mobile app | `NOT FOUND` | the web app is responsive |
| Real-time updates | `NOT FOUND` | data loads on navigation |

---

## Data sources per screen

| Screen | Reads |
|---|---|
| Dashboard | `v_dashboard_summary`, `v_attendance_daily`, `v_faculty_attendance_today`, `audit_entries`, `approval_requests`, `public.academic_calendar_events` |
| Institution Overview | `academic_years`, `institution_metrics`, `program_enrolments`, `semester_performance`, `facility_stats`, `institution_highlights`, `kpi_snapshots`, `v_department_rollup`, `faculty.faculties` |
| Academic Performance | `kpi_snapshots`, `semester_summaries`, `semester_results`, `semester_result_departments`, `subject_results`, `sgpa_bands`, `grade_slices`, `attainment_levels`, `at_risk_reasons`, `yearly_pass_rates` |
| Result | `semester_results`, `semester_result_departments`, `rank_holders`, `subject_results`, `grade_slices`, `faculty.marks` |
| Department Performance | `v_department_rollup`, `department_admin_metrics` |
| Faculty Performance | `faculty.faculties`, `faculty_details`, `faculty.research_publications`, `v_faculty_attendance_today` |
| Student Performance | `student.students`, `student_achievements`, `v_department_placement_summary` |
| Attendance Analytics | `v_attendance_daily`, `v_attendance_daily_by_department`, `student.students`, `faculty.faculties`, `faculty_attendance` |
| Examination Monitoring | `exam_schedules`, `cia_progress`, `hall_ticket_status`, `result_publications` |
| Research & Innovation | `faculty.research_publications`, `faculty.patents`, `funded_projects`, `consultancy_projects`, `research_year_output` |
| Accreditation | `accreditation_standings`, `criterion_progress`, `program_accreditations`, `ranking_entries`, `compliance_documents` |
| Finance Overview | `kpi_snapshots`, `monthly_finance`, `department_fee_status`, `payment_mode_splits`, `scholarship_schemes`, `payroll_lines`, `expenditure_heads` |
| Placement Dashboard | `placement_records`, `placement_drives`, `placement_drive_departments`, `companies`, `internship_records`, `v_package_bands` |
| Approvals | `approval_requests`, `approval_decisions`, `faculty.leave_applications` |
| Circulars | `circulars`, `circular_acknowledgements`, `hod.department_notices`, `student.notice_board_posts` |
| Meetings & Calendar | `meetings`, `meeting_agenda_items`, `meeting_minutes`, `meeting_minute_decisions`, `public.academic_calendar_events` |
| Reports & Analytics | `report_items`, `report_runs`, `scheduled_reports`, `scheduled_report_recipients` |
| Audit & Compliance | `audit_entries`, `compliance_areas`, `inspection_reports`, `policy_adherence` |
| Notifications | `faculty.notifications`, `student.student_notifications` |
| My Profile | `principal_profiles`, `profile_education`, `profile_research_papers`, `profile_awards`, `profile_documents`, `profile_responsibilities` |

---

## Row counts, read live on 10 August 2026

**Read-only sources**

`student.students` 10 · `student.attendance_table` 47 ·
`student.notice_board_posts` 38 · `student.student_notifications` 13 ·
`faculty.faculties` 16 · `faculty.marks` 18 ·
`faculty.leave_applications` 10 · `faculty.notifications` 48 ·
`faculty.research_publications` 8 · **`faculty.patents` 0** ·
`hod.department_notices` 20 · **`hod.hod_departments` 0** ·
`public.academic_calendar_events` 3

**Views**

`v_department_rollup` 12 · `v_dashboard_summary` 1 · `v_attendance_daily` 15 ·
`v_attendance_daily_by_department` 15 · `v_faculty_attendance_today` 2 ·
`v_department_placement_summary` 12 · `v_package_bands` 5

**`principal` tables** — full list with counts in
[06-DATABASE.md](06-DATABASE.md). Largest: `faculty_attendance` 180 ·
`meeting_agenda_items` 81 · `semester_result_departments` 72 ·
`repository_documents` 64 · `placement_records` 60 · `subject_results` 60.

---

## Risk register

| Risk | Severity | Owner |
|---|---|---|
| Anon key can write to `student` / `faculty` | **CRITICAL** | database team + portal owners |
| No authentication | **CRITICAL** | college decision |
| Account Security tab implies protection that does not exist | HIGH | this team |
| Reports and Repository imply files that do not exist | HIGH | this team |
| At-risk thresholds duplicated in Dart and SQL | MEDIUM | this team |
| Two teams migrating one database | MEDIUM | cross-team process |
| `faculty_attendance` in the wrong schema | LOW, knowing | Faculty Portal, eventually |
| Browser-side filtering at scale | LOW today | this team, when the roll grows |

---

**Next:** [18-GLOSSARY.md](18-GLOSSARY.md) — what the words mean.
