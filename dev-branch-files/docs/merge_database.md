# Complete Database Integration & Consolidation Specification (`merge_database.md`)

**Date:** 2026-07-25  
**Project:** KSRCE ERP Unified System (`erp_unified`)  
**Target:** Unified Single-Project Supabase Schema & Cross-Module Architecture  
**Source Database Environments Audited:**
- Faculty Supabase: `https://vasmnfhxuocseejomvhd.supabase.co` (23 Tables, 66 Records)
- HOD Supabase: `https://stxhkolbdbautqmrvuey.supabase.co` (10 Tables, 5 Records)
- Student Supabase: `https://kovmopqfevecpndwngvg.supabase.co` (30 Tables, 31 Records)
- Admin Supabase: `https://azzuwagkwpvvgqtilmck.supabase.co` (14 Tables, 12 Records)

---

## 1. Executive Summary & Ground Truth Audit

A live schema and data audit was conducted across all four Supabase databases using their dedicated API service role credentials specified in `d:\V2\erp_unified\.env`.

```
                      ┌─────────────────────────────────────────┐
                      │    SUPABASE UNIFIED ERP DATABASE        │
                      └────────────────────┬────────────────────┘
                                           │
         ┌──────────────────┬──────────────┴───────┬──────────────────┐
         │                  │                      │                  │
┌────────┴────────┐┌────────┴────────┐  ┌──────────┴────────┐┌────────┴────────┐
│  ADMIN MODULE   ││   HOD MODULE    │  │  FACULTY MODULE  ││ STUDENT MODULE  │
│  (14 Tables)    ││   (10 Tables)   │  │   (23 Tables)    ││   (30 Tables)   │
└─────────────────┘└─────────────────┘  └──────────────────┘└─────────────────┘
```

- **Total Analyzed Tables**: **77 Tables** across 4 databases.
- **Deduplicated & Canonical Tables**: **64 Core Tables** in the consolidated single-project schema.
- **Master Reference Models**: Department Master (`departments`), Subject Catalog (`subjects`), Class Sections (`class_sections`), Academic Terms (`academic_years`), Regulation Master (`admin_regulations`).
- **Master User Directory**: `users` (`admin_users`) serving as the universal identity directory for Super Admins, Registrars, HODs, Faculty Staff, and Students.

---

## 2. Step 0 Audit & Schema Conflict Resolutions

| Conflict Domain | Student DB Version | Faculty DB Version | Admin / HOD Version | Canonical Resolution & Data Model |
|---|---|---|---|---|
| **1. Students Table** | `students` (1 row, flat attributes: `personal_email`, `mobile_number`, free-text `department`) | `students` (29 rows, normalized: `roll_number`, `register_number`, `department_id` FK, `section`) | `admin_users` (student records with `user_code`, `batch`, `blood_group`) | **Merged `students` Table**: Faculty's 29 records form the operational base table with `user_id` FK pointing to `users.id`. Contains union of all contact, academic, and profile fields. |
| **2. Attendance** | `attendance_records` (0 rows, flat `course_id`) | `attendance_sessions` (0 rows) + `attendance_records` (10 rows, session-based normalized) | N/A | **Adopted Faculty Session Model**: Operational attendance uses `attendance_sessions` (date, period, section) + `attendance_records` (student status). Student portal queries this by `student_id`. |
| **3. Marks & Grades** | `student_grades` (0 rows, simple `ca1`, `ca2`) | `student_marks` (10 rows, `cia_score`, `assignment_score`, audit logs) | N/A | **Adopted Faculty `student_marks`**: Complete score breakdown with `mark_sheet_audit_logs` & `mark_sheet_statuses`. Student app reads from `student_marks`. |
| **4. Courses & Subjects** | `courses` (0 rows, `course_code`, `credits`) | `subjects` (0 rows, `code`, `department_id`, `semester`) | `admin_courses` (3 rows) + `admin_subjects` (0 rows) | **Separated Program vs Subject Catalog**: `admin_courses` defines degree programs (B.Tech CSE). `subjects` defines subject catalog (Data Structures). Retired student `courses` in favor of `subjects`. |
| **5. Departments** | `department` (text string) | `departments` (2 rows, `code`, `name`) | `admin_departments` (4 rows, intake, HOD) | **Master `departments`**: `admin_departments` is the institutional master. All other tables store `department_id` FK or `dept_code` FK. |
| **6. Timetables** | `class_timetables` (0 rows, `course_id`, `time`) | `timetables` (0 rows, `faculty_id`, `subject_id`, `class_section_id`, `slot`) | N/A | **Adopted Faculty `timetables`**: Operational timetable entered by faculty/HOD. Student portal queries timetables by `class_section_id`. |
| **7. Calendar Events** | `academic_calendar_events` (0 rows, student view) | `academic_calendar_events` (0 rows, faculty view) | `admin_events` (0 rows) | **Unified `academic_calendar_events`**: Single table with `scope` column (`ALL`, `FACULTY`, `STUDENT`, `HOD`) and `color_code`. |

---

## 3. Step 1 — Target Consolidated Single-Project Architecture

### 3.1. Master Reference Tables (Admin-Owned, Shared Read)
- `departments`: Canonicalized from `admin_departments` + faculty `departments`.
- `academic_years`: Reconciled academic terms & cycles.
- `users`: Universal identity table for auth, roles, and profiles.
- `subjects`: Master subject catalog (`subject_code`, `name`, `department_id`, `credits`).
- `class_sections`: Section definitions (`department_id`, `semester`, `section`).

### 3.2. Canonical Operational Tables
- `students`: Unified student directory with foreign keys to `users.id` and `departments.id`.
- `faculties`: Faculty directory with foreign keys to `users.id` and `departments.id`.
- `attendance_sessions` & `attendance_records`: Normalized session-based attendance.
- `student_marks`: Assessment score entries with `mark_sheet_audit_logs`.
- `timetables`: Timetable matrix (`faculty_id` + `subject_id` + `class_section_id`).
- `academic_calendar_events`: Institution-wide events with `scope` (`ALL`, `FACULTY`, `STUDENT`).

---

## 4. Step 2 — Cross-Module Access Requirements

- **Faculty Module Needs**:
  - Student rosters per `class_section_id` via `students` to generate class mark sheets and attendance lists.
  - Allocation mappings via `faculty_subject_allocations`.
- **Student Module Needs**:
  - Read-only access to own `student_marks`, `attendance_records`, `timetables`, `subjects`, and `syllabus_uploads`.
- **HOD Module Needs**:
  - Access to `faculties`, `leave_applications` (view over faculty leave requests), `class_sections`, `hod_profiles`, and `hod_course_diaries`.
- **Admin Module Needs**:
  - Full write access to master reference tables (`departments`, `subjects`, `academic_years`, `users`, `admin_regulations`).

---

## 5. Step 3 — Migration Plan & SQL DDL Scripts

The full migration script is stored in [supabase_consolidation_migration.sql](file:///d:/V2/erp_unified/supabase_consolidation_migration.sql).

### SQL Compatibility Views for Retired Tables

```sql
-- 1. Compatibility View for Retired `courses` Table
CREATE OR REPLACE VIEW public.courses AS
SELECT 
    id,
    subject_code AS course_code,
    name AS course_title,
    department_id AS department,
    credits,
    created_at
FROM public.subjects;

-- 2. Compatibility View for Retired `class_timetables` Table
CREATE OR REPLACE VIEW public.class_timetables AS
SELECT 
    id,
    subject_id AS course_id,
    day_of_week,
    time_slot AS start_time,
    room_no,
    created_at
FROM public.timetables;

-- 3. Compatibility View for Retired `student_grades` Table
CREATE OR REPLACE VIEW public.student_grades AS
SELECT 
    id,
    student_id,
    subject_id AS course_id,
    assessment_name,
    cia_score AS ca1,
    assignment_score AS ca2,
    total_score AS total_marks,
    grade,
    created_at
FROM public.student_marks;
```

---

## 6. Step 4 — Flutter Data-Layer Code Diffs

### 6.1. Unified Supabase Client (`lib/modules/faculty/services/supabase_client.dart`)

```dart
class SupabaseClientHelper {
  static const String _supabaseUrl = 'https://vasmnfhxuocseejomvhd.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  static final SupabaseClient client = SupabaseClient(_supabaseUrl, _supabaseAnonKey);
}
```

### 6.2. Student Module Service Query Update (`lib/modules/student/services/student_service.dart`)

```diff
- // OLD: Querying retired student_grades table
- final response = await client.from('student_grades').select().eq('student_id', studentId);

+ // NEW: Querying canonical student_marks table
+ final response = await client.from('student_marks')
+     .select('id, assessment_name, cia_score, assignment_score, total_score, grade, subjects(name, subject_code)')
+     .eq('student_id', studentId);
```

### 6.3. Attendance Service Query Update (`lib/modules/student/services/attendance_service.dart`)

```diff
- // OLD: Querying flat attendance_records table
- final response = await client.from('attendance_records').select().eq('student_id', studentId);

+ // NEW: Querying canonical session-linked attendance_records
+ final response = await client.from('attendance_records')
+     .select('id, status, remarks, attendance_sessions(session_date, period, topic_covered, subjects(name))')
+     .eq('student_id', studentId);
```
