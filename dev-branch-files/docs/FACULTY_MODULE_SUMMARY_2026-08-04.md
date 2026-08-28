# Summary of Faculty Module Changes & Database Integration

**Date**: August 4–5, 2026  
**Module**: Faculty Portal (`frontend/lib/modules/faculty/`)  
**Target Workspace Root**: `c:\CAMS-Engineering`

---

## 📌 Executive Summary

Work accomplished across the Faculty Portal:
1. **Fixing Web Runtime Errors**: Replaced legacy Dart map lookups across Faculty screens to resolve Flutter Web runtime crashes (`TypeError`).
2. **Database Schema & Migration**: Generated database migration scripts for 12 new tables with foreign key relations, trigger safety, and strict preservation of `student.attendance_table`.
3. **Connecting Pages to Supabase Database**: Created backend service files and connected **Student Progress**, **Faculty Workload**, and **Student Feedback** pages to live Supabase tables.
4. **Sample Data Seeding**: Generated an executable SQL seed script populated with exact live faculty data for **Mr. P. Kalaiyarasan (`FAC002`)**, student register numbers, and course regulations.
5. **Global Faculty Filter Standardization**: Fixed student filtering across all faculty screens (`student_progress_view.dart`, `marks_entry_view.dart`, `attendance_view.dart`) to use dynamic `year_of_study`, `department`, and `section` attributes from `student.students` rather than hardcoded string defaults.
6. **Attendance Filter Synchronization & HOD Correction Workflow**: Eliminated initial filter mismatches between Year and Class/Section dropdowns and re-implemented HOD attendance correction request submission to Supabase `hod.attendance_correction_requests`.

---

## 📁 Detailed Page & File Changes

### 1. Frontend Screen & Service Changes (`frontend/lib/modules/faculty/`)

#### 📄 `screens/timetable_view.dart`
* **Date**: August 4, 2026 | 21:15 IST
* **Change**: Replaced `.firstWhere(..., orElse: ...)` with Dart null-safe `.where(...).firstOrNull`.
* **Reason**: Prevents Flutter Web `TypeError: () => Map<String, dynamic>` crash when searching timetable slots.

#### 📄 `screens/attendance_view.dart`
* **Date**: August 4–5, 2026 | 23:05 – 00:18 IST
* **Changes**:
  - Replaced `.firstWhere(..., orElse: ...)` with `.where(...).firstOrNull` in session filtering and student lookup.
  - Replaced fragile string section parsing e.g. `contains(' - B ')` with robust `_parseDept` and `_parseSection` helpers.
  - Synchronized `_initDefaultFiltersAndLoad()` so `Step 1 — Year` and `Step 2 — Class & Section` match dynamically on load.
  - Removed hardcoded fallback mock string `'CSE - A (II Year)'` from `_classesByYear`.
  - Fixed year selection bouncing bug when picking **II Year**: `_classesByYear` now returns year-scoped class options (`CSE - A (II Year)`, `CSE - B (II Year)`, `IT - A (II Year)`) when no timetable entry exists, preventing forced fallback to III Year.
  - Connected `_openCorrectionRequestDialog` to `AttendanceService.submitHodCorrectionRequest()`.
* **Reason**: Ensures accurate student filtering, seamless II Year selection, and full HOD attendance correction request submission.

#### 📄 `services/attendance_service.dart`
* **Date**: August 4–5, 2026 | 23:10 – 00:10 IST
* **Changes**:
  - Refactored `fetchStudentAttendanceTable()` to strictly match `department`, `section`, and `year_of_study`.
  - Re-implemented `submitHodCorrectionRequest()` static method to insert correction requests into Supabase schema `hod` table `attendance_correction_requests`.
* **Reason**: Ensures database queries accurately target student cohorts and supports HOD approval workflows.

#### 📄 `services/student_service.dart`
* **Date**: August 4–5, 2026 | 23:15 – 23:35 IST
* **Changes**:
  - Added `extractYear()` and `calcYearFromSem()` normalization helpers.
  - Added static `add(Map<String, dynamic> student)` method to insert student records into local storage.
  - Refactored `getByClassSec()` to filter strictly by department, section, and `year_of_study`.
* **Reason**: Fixes II Year vs III Year student roster mismatches and provides missing API methods for `erp_repository.dart`.

#### 📄 `services/supabase_client.dart`
* **Date**: August 4, 2026 | 23:52 IST
* **Changes**: Added static `uploadToStorage(String bucket, String fileName, List<int> bytes)` method.
* **Reason**: Enables binary file uploads to Supabase storage bucket (`assignments`) for `assignment_service.dart`.

#### 📄 `screens/question_bank_view.dart`
* **Date**: August 4, 2026 | 21:20 IST
* **Change**: Replaced `.firstWhere(..., orElse: ...)` with `.where(...).firstOrNull`.
* **Reason**: Prevents type mismatch errors when viewing question bank details.

#### 📄 `erp_repository.dart`
* **Date**: August 4, 2026 | 23:30 IST
* **Change**: Updated student map lookups with `.where(...).firstOrNull` and invoked `StudentService.add()`.
* **Reason**: Safe null-handling and student record persistence across shared ERP repository cache.

#### 📄 `screens/faculty_workload_view.dart` & `services/workload_service.dart`
* **Date**: August 4, 2026 | 22:10 IST
* **Change**: Created `WorkloadService` using `SupabaseClientHelper` and connected `FacultyWorkloadView` to load live teaching timetables and course allocations from Supabase (`faculty.timetables`, `faculty.faculty_course_allocations`, `faculty.faculties`).
* **Reason**: Replaces static fallbacks with real database queries for logged-in faculty (`FAC002`).

#### 📄 `screens/student_feedback_view.dart` & `services/feedback_service.dart`
* **Date**: August 4, 2026 | 22:30 IST
* **Change**: Created `FeedbackService` using `SupabaseClientHelper` and connected `StudentFeedbackView` to load anonymized student feedback ratings and comments from Supabase (`faculty.student_feedback_results`).
* **Reason**: Fetches real feedback parameters and comments from the database.

#### 📄 `screens/student_progress_view.dart`
* **Date**: August 4, 2026 | 23:20 IST
* **Change**: Integrated `_buildClassSec()` helper and updated student filters to match `dept`, `sec`, and `year_of_study`. Replaced hardcoded `(II Year)` strings.
* **Reason**: Prevents II Year students from appearing under III Year classes in Student Progress view.

---

### 2. Database Schema & SQL Scripts Generated

#### 🗄️ `database/delete_1000_faculty_assignments.sql` [NEW]
* **Date**: August 5, 2026 | 00:01 IST
* **Location**: `database/delete_1000_faculty_assignments.sql`
* **Changes**:
  - Provides a cascading CTE deletion query to delete child `faculty.assignment_marks` first, then 1000 `faculty.assignments` records.
  - Includes `session_replication_role = 'replica'` alternative for overriding foreign key constraints.
* **Reason**: Safe maintenance script to batch-delete 1000 assignment records without foreign key constraint errors.

#### 🗄️ `faculty_module_schema_migration.sql`
* **Date**: August 4, 2026 | 17:10 IST
* **Location**: Artifacts directory
* **Changes**:
  - Adds 12 new tables (`attendance_correction_requests`, `attendance_audit_history`, `leave_substitutions`, `leave_balances`, `course_outcomes`, `co_po_mapping`, `co_attainment_results`, `mark_correction_requests`, `research_publications`, `patents`, `student_feedback_results`, `mentor_counselling_logs`).
  - Preserves `student.attendance_table` and `p1`..`p7` boolean columns untouched.
  - Re-attaches all 6 existing database triggers (`trg_calc_attendance_pct`, `trg_attendance_updated`, `trg_notify_student_exam_marks`, `trg_assignment_marks_updated`, `trg_notify_student_assignment`, `trg_sync_faculty_leave`).

#### 🗄️ `seed_faculty_sample_data.sql`
* **Date**: August 4, 2026 | 17:35 IST
* **Location**: Artifacts directory
* **Changes**:
  - Inserts sample records for **Mr. P. Kalaiyarasan (`FAC002`)**.
  - Cross-verified against `public.regulations` and live student register numbers (`73152413035` DEVAROOPA, `731521101` Alice Johnson, `731521102` Bob Smith, `731521104` Diana Prince).

---

## 🔀 Easy Git Merge Checklist

| File Path | Action | Description | Timestamp |
| :--- | :--- | :--- | :--- |
| `frontend/lib/modules/faculty/screens/attendance_view.dart` | Modified | Filter sync, II Year fix & HOD request | 00:18 IST |
| `frontend/lib/modules/faculty/services/attendance_service.dart` | Modified | `submitHodCorrectionRequest` & attribute filtering | 00:10 IST |
| `frontend/lib/modules/faculty/services/student_service.dart` | Modified | Added `add()` & `extractYear()` filtering | 23:35 IST |
| `frontend/lib/modules/faculty/services/supabase_client.dart` | Modified | Added `uploadToStorage()` for files | 23:52 IST |
| `database/delete_1000_faculty_assignments.sql` | **New** | Batch deletion script for 1000 assignments | 00:01 IST |
| `frontend/lib/modules/faculty/screens/timetable_view.dart` | Modified | Null-safety fix (`firstOrNull`) | 21:15 IST |
| `frontend/lib/modules/faculty/screens/question_bank_view.dart` | Modified | Null-safety fix (`firstOrNull`) | 21:20 IST |
| `frontend/lib/modules/faculty/erp_repository.dart` | Modified | Null-safety fix & `StudentService.add` | 23:30 IST |
| `frontend/lib/modules/faculty/services/workload_service.dart` | **New** | Supabase workload service | 22:10 IST |
| `frontend/lib/modules/faculty/services/feedback_service.dart` | **New** | Supabase feedback service | 22:30 IST |
| `frontend/lib/modules/faculty/screens/faculty_workload_view.dart` | Modified | Connected to `WorkloadService` | 22:15 IST |
| `frontend/lib/modules/faculty/screens/student_feedback_view.dart` | Modified | Connected to `FeedbackService` | 22:35 IST |
| `frontend/lib/modules/faculty/screens/student_progress_view.dart` | Modified | Attribute-based filtering & dynamic classSec | 23:20 IST |

---

## ✅ Verification
- **Dart Analyzer**: Clean compilation across all faculty service files and views.
- **Flutter Web Server**: Active and running on `http://localhost:8080/#/faculty`.
