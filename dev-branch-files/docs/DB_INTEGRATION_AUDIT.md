# Supabase Four-Database Integration Audit

**Date:** 2026-07-25  
**Project:** KSRCE ERP Unified System (`erp_unified`)  
**Scope:** Live Database Audit & Schema Reconciliation across Faculty, HOD, Student, and Admin Supabase Projects.

---

## 1. Executive Summary & Project Status

A live schema and data audit was conducted across all four Supabase databases using their dedicated API service role credentials specified in `d:\V2\erp_unified\.env`.

### Database Connection Overview

| Module | Supabase Project URL | Total Tables | Total Populated Tables | Total Live Records | Primary Role / Context |
|---|---|---|---|---|---|
| **Faculty DB** | `https://vasmnfhxuocseejomvhd.supabase.co` | **23** | 12 | 66 records | Faculty operational data, marks, attendance sessions, leave workflow |
| **HOD DB** | `https://stxhkolbdbautqmrvuey.supabase.co` | **10** | 3 | 5 records | HOD profile, approvals, department files, events, class advisers |
| **Student DB** | `https://kovmopqfevecpndwngvg.supabase.co` | **30** | 14 | 31 records | Student portal data, fees, library, hostel, placements, achievements |
| **Admin DB** | `https://azzuwagkwpvvgqtilmck.supabase.co` | **14** | 4 | 12 records | System administration, departments, courses, regulations, user registry |
| **TOTAL** | — | **77** | **33** | **114 records** | **Unified ERP Database Ecosystem** |

---

## 2. Detailed Live Schema Audit by Database

### 2.1. Faculty Supabase Database (`23 Tables`)

- `students` (**29 rows**): `id`, `student_id`, `roll_number`, `register_number`, `name`, `gender`, `email`, `phone`, `department_id`, `section`, `programme`, `status`, `created_at`, `updated_at`.
- `attendance_records` (**10 rows**): `id`, `session_id`, `student_id`, `status`, `remarks`, `created_at`.
- `student_marks` (**10 rows**): `id`, `student_id`, `faculty_id`, `subject_id`, `class_section_id`, `assessment_name`, `cia_score`, `assignment_score`, `lab_score`, `project_score`, `total_score`, `grade`, `remarks`, `status`, `created_at`.
- `leave_applications` (**4 rows**): `id`, `faculty_id`, `leave_type`, `from_date`, `to_date`, `days_count`, `reason`, `hospital_name`, `medical_certificate_url`, `status`, `created_at`.
- `departments` (**2 rows**): `id`, `code`, `name`, `created_at`.
- `class_sections` (**3 rows**): `id`, `department_id`, `semester`, `section`, `academic_year_id`, `name`, `created_at`.
- `lesson_plans` (**2 rows**): `id`, `faculty_id`, `subject_id`, `class_section_id`, `academic_year_id`, `month`, `week`, `day`, `period`, `topic_planned`, `status`.
- `syllabus_uploads` (**2 rows**): `id`, `faculty_id`, `subject_id`, `file_name`, `file_size`, `file_url`, `version`, `status`.
- `faculties` (**1 row**): `id`, `user_id`, `employee_id`, `name`, `role`, `designation`, `department_id`, `email`, `phone`.
- `academic_years` (**1 row**): `id`, `year_code`, `is_current`, `created_at`.
- `leave_timeline` (**1 row**): `id`, `leave_id`, `action_by_name`, `status`, `comments`, `action_time`.
- `mark_sheet_audit_logs` (**1 row**): `id`, `assessment_name`, `class_section_id`, `subject_id`, `updated_by`, `previous_values`, `new_values`, `reason`.
- *Empty Tables (0 rows)*: `attendance_sessions`, `leave_balances`, `question_banks`, `assignments`, `mark_sheet_statuses`, `notifications`, `subjects`, `timetables`, `question_bank_reviews`, `academic_calendar_events`, `faculty_subject_allocations`.

---

### 2.2. HOD Supabase Database (`10 Tables`)

- `hod_profiles` (**1 row**): `id`, `employee_id`, `full_name`, `official_email`, `personal_email`, `phone`, `emergency_contact`, `dob`, `gender`, `blood_group`, `designation`, `department`, `dept_code`, `date_of_joining`, `teaching_experience_years`, `admin_experience_years`, `ug_degree`, `pg_degree`, `phd_degree`, `specialization`, `university`, `orcid`, `scopus_id`, `google_scholar`, `research_gate`, `publication_count`, `patents_count`, `weekly_workload_hours`.
- `hod_leave_requests` (**2 rows**): `id`, `display_id`, `faculty_name`, `faculty_employee_id`, `leave_type`, `dates_description`, `start_date`, `end_date`, `days_count`, `reason`, `substitute_faculty`, `status`, `hod_remarks`.
- `hod_events` (**2 rows**): `id`, `display_id`, `event_name`, `category`, `in_charge`, `venue`, `dates_description`, `registered_count`, `status`.
- *Empty Tables (0 rows)*: `hod_class_advisers`, `hod_research_contributions`, `hod_notifications`, `hod_course_diaries`, `hod_department_files`, `hod_mentors`, `hod_profile_approvals`.

---

### 2.3. Student Supabase Database (`30 Tables`)

- `fees` (**4 rows**): `id`, `student_id`, `title`, `category`, `amount`, `due_date`, `is_paid`, `payment_date`.
- `library_books` (**4 rows**): `id`, `title`, `author`, `isbn`, `category`.
- `placements` (**3 rows**): `id`, `company`, `role`, `package`, `deadline`, `min_cgpa`.
- `extra_courses` (**3 rows**): `id`, `title`, `provider`, `duration`, `category`.
- `notice_board_posts` (**3 rows**): `id`, `title`, `category`, `content`, `author`, `post_date`.
- `student_notifications` (**3 rows**): `id`, `student_id`, `title`, `category`, `description`, `is_read`, `created_at`.
- `achievements` (**2 rows**): `id`, `student_id`, `title`, `category`, `organized_by`, `date`, `description`, `certificate_url`.
- `grievances` (**2 rows**): `id`, `student_id`, `category`, `subject`, `description`, `attachment_url`, `status`, `response`.
- `hostel_outing_requests` (**2 rows**): `id`, `student_id`, `purpose`, `destination`, `out_time`, `in_time`, `out_date`, `status`.
- `certificate_requests` (**2 rows**): `id`, `student_id`, `certificate_type`, `reason`, `request_date`, `status`, `download_url`.
- `students` (**1 row**): `id`, `student_id`, `name`, `personal_email`, `mobile_number`, `address`, `year_of_study`, `current_semester`, `department`.
- `placement_applications` (**1 row**): `student_id`, `placement_id`, `applied_date`.
- `library_transactions` (**1 row**): `id`, `student_id`, `book_id`, `type`, `due_date`, `returned_date`, `is_active`.
- `extra_course_enrollments` (**1 row**): `id`, `student_id`, `course_id`, `enrollment_date`, `status`.
- *Empty Tables (0 rows)*: `blood_donors`, `student_transport`, `blood_donation_requests`, `syllabus_records`, `exam_registration_courses`, `courses`, `academic_calendar_events`, `student_grades`, `exam_timetables`, `hostel_details`, `class_timetables`, `transport_routes`, `attendance_records`, `notice_bookmarks`, `student_enrollments`, `exam_registrations`.

---

### 2.4. Admin Supabase Database (`14 Tables`)

- `admin_departments` (**4 rows**): `id`, `dept_code`, `name`, `hod_name`, `hod_user_id`, `intake_capacity`, `status`.
- `admin_courses` (**3 rows**): `id`, `course_code`, `name`, `department_code`, `subjects_count`, `status`.
- `admin_users` (**3 rows**): `id`, `user_code`, `name`, `email`, `role`, `department`, `node`, `status`.
- `admin_regulations` (**2 rows**): `id`, `code`, `scheme`, `passing_criteria`, `total_credits`, `status`.
- *Empty Tables (0 rows)*: `admin_role_permissions`, `admin_notification_configs`, `admin_system_settings`, `admin_medical_alerts`, `admin_audit_logs`, `admin_backups`, `admin_subjects`, `admin_events`, `admin_academic_cycles`, `admin_reports`.

---

## 3. Conflict Matrix & Canonical Resolutions

| Conflict Entity | Student DB Version | Faculty DB Version | Admin / HOD Version | Canonical Resolution Strategy |
|---|---|---|---|---|
| **Students Table** | 1 row, flat attributes (`personal_email`, `mobile_number`, `year_of_study`, free-text `department`) | 29 rows, normalized attributes (`roll_number`, `register_number`, `department_id` FK, `section`) | `admin_users` has student records (`user_code`, `roll_number`, `batch`) | Combine all attributes into single canonical `students` table, linked via `auth_user_id` FK to `admin_users.id`. Faculty's 29 records become the base. |
| **Attendance** | `attendance_records` (0 rows, flat `course_id`) | `attendance_sessions` (0 rows) + `attendance_records` (10 rows, normalized `session_id`) | N/A | Adopt Faculty's normalized session model (`attendance_sessions` + `attendance_records`). Student app queries student's records by `student_id`. |
| **Marks / Grades** | `student_grades` (0 rows, simple fields `ca1`, `ca2`) | `student_marks` (10 rows, `cia_score`, `assignment_score`, audit logs) | N/A | Adopt Faculty's `student_marks` table with audit trail (`mark_sheet_audit_logs`). |
| **Courses & Subjects** | `courses` (0 rows) | `subjects` (0 rows) | `admin_courses` (3 rows) + `admin_subjects` (0 rows) | Admin `admin_courses` & `admin_subjects` act as institutional master. `subjects` table serves operational scheduling. |
| **Departments** | Free-text `department` string | `departments` table (2 rows) | `admin_departments` (4 rows, richest) | `admin_departments` is the master definition. FK references `department_id` in all tables. |
| **Timetables** | `class_timetables` (0 rows) | `timetables` (0 rows) | N/A | Adopt Faculty operational `timetables` table (`faculty_id` + `subject_id` + `class_section_id`). |
| **Calendar Events** | `academic_calendar_events` (0 rows, student view) | `academic_calendar_events` (0 rows, faculty view) | `admin_events` (0 rows) + `admin_academic_cycles` (0 rows) | Consolidate into single `academic_calendar_events` table with `audience` (`ALL`, `FACULTY`, `STUDENT`) and `owner_role`. |

---

## 4. Key Decision Points for Architecture Review

### Decision Point 1: Universal Identity Table vs Module-Specific Tables
- **Option A (Recommended)**: Consolidate authentication & user profiles into single project. `admin_users` becomes master user directory for all logins (Super Admin, HOD, Faculty, Student), while `students`, `faculties`, and `hod_profiles` retain role-specific fields linked via `user_id`.
- **Option B**: Maintain separate role tables with independent `auth.users` references.

### Decision Point 2: Calendar Events Consolidation
- **Option A (Recommended)**: Merge `academic_calendar_events` into single canonical table with `visibility_scope` column (`INSTITUTION_WIDE`, `FACULTY_ONLY`, `STUDENT_ONLY`).
- **Option B**: Keep faculty and student events separate.

### Decision Point 3: Single Supabase Project vs 4 Independent Projects
- **Option A (Recommended)**: Migrate all 4 schemas into **one consolidated Supabase database project**. This enables direct foreign keys, transactional integrity, and simplified Flutter environment keys.
- **Option B**: Maintain 4 isolated Supabase projects with HTTP API cross-syncing.

---

## 5. Security & Row Level Security (RLS) Note

Currently, tables in HOD and Admin projects use permissive RLS policies:
```sql
CREATE POLICY "Allow public read-write" ON table_name FOR ALL USING (true) WITH CHECK (true);
```
These permissive policies enable seamless rapid prototyping across modules. Strict JWT-based RLS policies can be introduced in a future release cycle.
