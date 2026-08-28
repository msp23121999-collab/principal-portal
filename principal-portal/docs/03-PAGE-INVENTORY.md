# 03 — Page Inventory

Every screen in the Principal Portal. Routes are copied verbatim from
`lib/core/router/app_routes.dart`; nav labels from
`lib/core/constants/nav_destinations.dart`; tabs from each screen file.

**20 screens · 17 of them tabbed · 65 tabs in total · 10 screens carry filters**

> **Digital Repository and Settings were removed** from the portal on the
> Principal's instruction. Their routes, screens, providers and repositories
> are deleted. The `principal.repository_folders`,
> `principal.repository_documents` and `principal.user_settings` tables still
> exist in the database but nothing reads them.

---

## Navigation tree

This is the sidebar, top to bottom, exactly as it appears:

```
Principal Portal
│
├── Dashboard                      /dashboard
├── Institution Overview           /institution-overview
├── Academic Performance           /academic-performance
├── Result                         /result-analytics
├── Department Performance         /department-performance
├── Faculty Performance            /faculty-performance
├── Student Performance            /student-performance
├── Attendance Analytics           /attendance-analytics
├── Examination Monitoring         /examination-monitoring
├── Research & Innovation          /research-innovation
├── Accreditation & Rankings       /accreditation
├── Finance Overview               /finance-overview
├── Placement Dashboard            /placement-dashboard
├── Approvals                      /approvals            🔴 badge: pending count
├── Circulars & Announcements      /circulars
├── Meetings & Calendar            /meetings-calendar
├── Reports & Analytics            /reports-analytics
├── Audit & Compliance             /audit-compliance
├── Notifications                  /notifications        🔴 badge: unread count
└── My Profile                     /my-profile
```

> ⚠️ The nav label **"Result"** points at the route `/result-analytics`. The
> route was not renamed when the label was, so they differ. This is cosmetic —
> nothing is broken — but do not expect a `/result` route to exist.

---

## Master inventory

**Filters** = does the screen carry the shared filter bar?
`AY` academic year · `D` department · `P` programme · `B` batch ·
`Y` year of study · `S` semester · `Su` subject

| # | Screen | Route | Purpose | Tabs | Filters | Reads | Status |
|---|---|---|---|---|---|---|---|
| 1 | Dashboard | `/dashboard` | Whole college on one page | — | AY D P B Y | `v_dashboard_summary`, `v_attendance_daily`, `audit_entries` | COMPLETE |
| 2 | Institution Overview | `/institution-overview` | Institution-wide statistics and department comparison | — | D P B S | `academic_years`, `institution_metrics`, `program_enrolments`, `semester_performance`, `facility_stats`, `institution_highlights`, `kpi_snapshots`, `faculty.faculties` | COMPLETE |
| 3 | Academic Performance | `/academic-performance` | Grade-point spread and outcome attainment | 3 | AY D P S | `kpi_snapshots`, `semester_summaries`, `semester_results`, `semester_result_departments`, `subject_results` | COMPLETE |
| 4 | Result | `/result-analytics` | All result analysis in one place | 4 | AY D P B S Su | `semester_results`, `rank_holders`, `subject_results`, `faculty.marks` | COMPLETE |
| 5 | Department Performance | `/department-performance` | Compare departments; programme split; admin metrics | 2 | AY D P B | `v_department_rollup` | COMPLETE |
| 6 | Faculty Performance | `/faculty-performance` | Staff roster, workload, research, attendance | 3 | D | `faculty.faculties`, `faculty_details`, `v_faculty_attendance_today` | COMPLETE |
| 7 | Student Performance | `/student-performance` | The roll, top performers, at-risk, placements | 3 | AY D P B Y S | `student.students`, `student_achievements`, `v_department_placement_summary` | COMPLETE |
| 8 | Attendance Analytics | `/attendance-analytics` | Attendance overall, by dept, staff, student | 4 | AY D P Y | `v_attendance_daily`, `v_attendance_daily_by_department`, `student.students`, `faculty.faculties` | COMPLETE |
| 9 | Examination Monitoring | `/examination-monitoring` | Exam schedule, CIA, hall tickets, publication | 4 | D S | `exam_schedules`, `cia_progress`, `hall_ticket_status`, `result_publications` | COMPLETE |
| 10 | Research & Innovation | `/research-innovation` | Publications, patents, funded projects, consultancy | 4 | — | `faculty.research_publications`, `faculty.patents`, `funded_projects`, `consultancy_projects`, `research_year_output` | COMPLETE ¹ |
| 11 | Accreditation & Rankings | `/accreditation` | NAAC, NBA, NIRF, compliance documents | 4 | — | `accreditation_standings`, `criterion_progress`, `program_accreditations`, `ranking_entries`, `compliance_documents` | COMPLETE |
| 12 | Finance Overview | `/finance-overview` | Fees, scholarships, payroll, expenditure | 4 | — | `kpi_snapshots`, `monthly_finance`, `department_fee_status`, `payment_mode_splits`, `scholarship_schemes`, `payroll_lines`, `expenditure_heads` | COMPLETE |
| 13 | Placement Dashboard | `/placement-dashboard` | Offers, drives, companies, internships | 4 | AY D P B | `placement_records`, `placement_drives`, `companies`, `internship_records` | COMPLETE |
| 14 | Approvals | `/approvals` | Decide requests and leave | 5 | — | `approval_requests`, `faculty.leave_applications` | COMPLETE ² |
| 15 | Circulars & Announcements | `/circulars` | Publish and read notices | 3 | — | `circulars`, `hod.department_notices`, `student.notice_board_posts` | COMPLETE |
| 16 | Meetings & Calendar | `/meetings-calendar` | Schedule meetings, read minutes | 4 | — | `meetings`, `meeting_minutes`, `public.academic_calendar_events` | COMPLETE |
| 17 | Reports & Analytics | `/reports-analytics` | Request and schedule reports | 4 | — | `report_items`, `report_runs`, `scheduled_reports` | PARTIALLY IMPLEMENTED ³ |
| 18 | Audit & Compliance | `/audit-compliance` | Action trail, compliance, inspections | 4 | — | `audit_entries`, `compliance_areas`, `inspection_reports`, `policy_adherence` | COMPLETE |
| 19 | Notifications | `/notifications` | Alerts from the other portals | — | — | `faculty.notifications`, `student.student_notifications` | COMPLETE ⁴ |
| 20 | My Profile | `/my-profile` | The Principal's own record | 6 | — | `principal_profiles` + 5 child tables | PARTIALLY IMPLEMENTED ⁵ |

**Notes**

1. `faculty.patents` genuinely holds **0 rows**. The empty state is correct —
   the institution has filed no patents.
2. Approving leave writes `status` to `faculty.leave_applications` (a row
   change, not a structural one) and the full decision to
   `principal.approval_decisions`.
3. Reports records **that a report was requested**. No file is produced. See
   [17-CURRENT-VS-EXPECTED.md](17-CURRENT-VS-EXPECTED.md).
4. Read-only. Marking something read changes only this session's copy.
5. Keyed to the fixed text `'placeholder-principal'` because there is no login.

---

## Every tab

| Screen | Tab | What it shows |
|---|---|---|
| Academic Performance | Overview | KPI cards, pass rate by department, at-risk reasons |
| | SGPA / CGPA Analysis | Grade-point bands and distribution |
| | CO / PO Attainment | Outcome attainment levels and department status |
| Result | Result Analysis | Appeared / passed / failed / backlogs, grades, trend |
| | Subject-wise | Per subject: appeared, passed, failed, pass %, avg, highest, lowest |
| | Department-wise | Pass summary per department + pass-rate chart |
| | Rank Holders | Semester rank list |
| Department Performance | Overview | Department cards, programme summary, ranking table |
| | Administration | Budget, sanctioned vs filled posts, facilities, ratio |
| Faculty Performance | Roster | Staff list with designation, experience, attendance |
| | Workload & Appraisal | Teaching hours, appraisal scores |
| | Research Output | Publications per member |
| Student Performance | Overview | Summary cards, department comparison, top and at-risk |
| | Placements | Department placement summary and rates |
| | Achievements | Prizes and recognitions |
| Attendance Analytics | Overall | Today, 2-week average, best day, trend |
| | Department | Attendance per department |
| | Faculty | Attendance per staff member |
| | Student | Year-wise averages + per-student table |
| Examination Monitoring | Schedule | Exam timetable |
| | Internal Assessments | CIA completion per department |
| | Hall Tickets | Issued / withheld / pending |
| | Results | Publication status per semester |
| Research & Innovation | Overview | Totals, yearly output, per-department publications |
| | Publications | Publication list with index and impact |
| | Patents & IPR | Patent list (**0 rows — genuinely empty**) |
| | Projects & Consultancy | Funded research projects and consultancy engagements |
| Accreditation | Overview | Standings and upcoming deadlines |
| | NAAC Criteria | Evidence completion per criterion |
| | NBA & Rankings | Programme accreditation, ranking history |
| | Documentation | Compliance documents and due dates |
| Finance Overview | Overview | Revenue vs expenditure, payment modes, highlights |
| | Fee Collection | Demand, collected, outstanding per department |
| | Scholarships | Schemes, beneficiaries, disbursement |
| | Payroll & Expenditure | Headcount, monthly cost, budget vs actual |
| Placement Dashboard | Overview | Placed, packages incl. highest **and lowest**, companies |
| | Recruitment Drives | Drives, registrations, offers |
| | Companies & Offers | Company list and offer table |
| | Internships | Internship records |
| Approvals | Leave | Leave requests with approve / reject |
| | Budget | Budget requests |
| | Purchase | Purchase requests |
| | Event & Activity | Event requests |
| | Academic | Academic requests |
| Circulars & Announcements | Published | Live notices, plus HOD and student notices |
| | Drafts | Unpublished circulars |
| | Archived | Withdrawn circulars |
| Meetings & Calendar | Calendar | Month view with events |
| | Meetings | Upcoming and past meetings |
| | Academic Calendar | Institution calendar |
| | Minutes | Recorded minutes and decisions |
| Reports & Analytics | Report Library | Available report types |
| | Generate | Choose module, format, period |
| | Recently Generated | Requested runs (**no file produced**) |
| | Scheduled | Recurring schedules |
| Audit & Compliance | Audit Log | Recorded actions, filterable |
| | Compliance | Compliance areas and scores |
| | Inspections | External inspection reports |
| | Policy Adherence | Policies, review dates, open issues |
| My Profile | Personal Profile | Name, ID, contact, office |
| | Professional & Degrees | Experience and educational qualifications |
| | Research & Teaching | Papers and awards |
| | Responsibilities | Roles held |
| | Documents (Verified) | Document list |
| | Account Security | ⚠️ **UI ONLY** — no authentication exists |

---

## Why 12 screens have no filters

Not an oversight. The shared filter narrows by department, programme, batch,
year and semester. Those mean nothing to a circular, a meeting, an audit entry,
a stored document, a notification, the Principal's own profile, or a settings
page. Accreditation, Finance and Research are institution-wide by nature.

A control that changes nothing is worse than no control: it invites the
Principal to narrow the scope and then silently ignores them.

Full reasoning in [13-FILTER-SYSTEM.md](13-FILTER-SYSTEM.md).

---

**Next:** [04-PAGE-BY-PAGE.md](04-PAGE-BY-PAGE.md) — every card, chart, table,
button and filter, screen by screen.
