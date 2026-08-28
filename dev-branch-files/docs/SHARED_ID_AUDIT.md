# Cross-Project Shared ID Audit (`SHARED_ID_AUDIT.md`)

**Date:** 2026-07-25  
**Project:** KSRCE ERP Unified System (`erp_unified`)  
**Architecture:** 4 Independent Supabase Projects connected via API Aggregation Layer  

---

## 1. Overview of the Shared ID Convention

Across 4 independent Supabase projects, foreign key constraints cannot cross Postgres database boundaries. Entity relationships are maintained using a **Shared ID Convention**:
1. **Master Identity Directory (`admin_users`)**: Hosted in Admin DB (`azzuwagkwpvvgqtilmck`). Every student, faculty, HOD, and admin is assigned a single master UUID (`id`).
2. **Role Tables (`user_id` Foreign Key Column)**: Role-specific tables (`faculties` & `students` in Faculty DB, `students` in Student DB, `hod_profiles` in HOD DB) reference the matching `admin_users.id` via a `user_id` column.
3. **Department Mapping (`department_id`)**: `admin_departments` in Admin DB serves as the master department registry, mapped by department code across Faculty DB's `departments` and Student DB's `students.department`.

---

## 2. Live Entity Audit & Matching Matrix

Live queries were executed against all 4 Supabase projects using their respective service-role keys:

| Entity Type | Admin DB (`azzuwagkwpvvgqtilmck`) | Faculty DB (`vasmnfhxuocseejomvhd`) | Student DB (`kovmopqfevecpndwngvg`) | HOD DB (`stxhkolbdbautqmrvuey`) | Clean Matches | Orphans / Mismatches Needing Backfill |
|---|---|---|---|---|---|---|
| **Users / Identity Directory** | `admin_users` (3 rows) | `faculties` (1 row), `students` (29 rows) | `students` (1 row) | `hod_profiles` (1 row) | **0 Clean Matches** | **35 Orphaned Rows** across projects missing `user_id` linkages |
| **Departments** | `admin_departments` (4 rows: `CSE`, `IT`, `ME`, `CE`) | `departments` (2 rows: `CSE`, `IT`) | `students.department` (free-text string) | `hod_profiles.department` (`IOT`) | **2 Code Matches** (`CSE`, `IT`) | `ME`, `CE`, `IOT` missing from Faculty/HOD database lookup tables |
| **Courses & Subjects** | `admin_courses` (3 rows), `admin_subjects` (0 rows) | `subjects` (0 rows) | `courses` (0 rows) | `hod_course_diaries` (0 rows) | **0 Rows** | Table definitions present, operational records empty |
| **Calendar Events** | `admin_events` (0 rows) | `academic_calendar_events` (0 rows) | `academic_calendar_events` (0 rows) | `hod_events` (2 rows) | **0 Rows** | Standarization of `visibility_scope` required |

---

## 3. Discovered Orphans & Mismatches

### 3.1. User Directory Mismatches (`admin_users`)
1. **Admin DB `admin_users`** currently contains 3 master records:
   - `f50ce22a-3cbb-4c21-aca9-edfa3761233e` -> Dr. Suresh Kumar (`Department HOD`, `suresh.kumar@campus.edu`)
   - `8c13881b-c05c-4a06-bdc6-c28dd4ec5975` -> Prof. Anjali Sharma (`Faculty`, `anjali.sharma@campus.edu`)
   - `2379b9e4-2d92-46c7-9af3-cfb1f0548126` -> Admin Staff (`Registrar`, `admin.staff@campus.edu`)

2. **Faculty DB `faculties`** contains 1 record:
   - `4cd9db79-d192-4ad3-a754-c8504951f0b3` -> DR. S. MALLIGA (`FAC73124`, `malliga@ksrce.ac.in`). Missing matching `admin_users` row and `user_id` link.

3. **Faculty DB `students`** contains 29 student records (`20CS001`, `20CS002`, ...):
   - Currently missing `user_id` column to reference `admin_users.id`.

4. **Student DB `students`** contains 1 student record:
   - `99999999-9999-9999-9999-999999999999` -> arun kumar (`student_id`: `1234567890`). Missing `user_id` reference to `admin_users`.

5. **HOD DB `hod_profiles`** contains 1 record:
   - `84737252-2cea-4c72-b1a8-aece8ea194c8` -> Dr. M. Govindharaj (`KSRCE-FAC-0042`, `hod.iot@ksrce.ac.in`). Missing matching `admin_users` record.

---

## 4. Backfill & Schema Amendment Actions Required (Step 0 Resolution)

Before deploying the 5 API Aggregator Endpoints (Step 1):

1. **Add `user_id uuid` Columns**:
   - Execute SQL in Faculty DB: `ALTER TABLE public.students ADD COLUMN IF NOT EXISTS user_id uuid; ALTER TABLE public.faculties ADD COLUMN IF NOT EXISTS user_id uuid;`
   - Execute SQL in Student DB: `ALTER TABLE public.students ADD COLUMN IF NOT EXISTS user_id uuid;`
   - Execute SQL in HOD DB: `ALTER TABLE public.hod_profiles ADD COLUMN IF NOT EXISTS user_id uuid;`

2. **Backfill Master User Entries (`admin_users`)**:
   - Seed missing user entries in Admin DB `admin_users` for Dr. M. Govindharaj (HOD), DR. S. MALLIGA (Faculty), and arun kumar / student roster.
   - Populate `user_id` in Faculty DB, Student DB, and HOD DB with matching master UUIDs.
