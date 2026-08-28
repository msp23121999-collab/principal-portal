# 🛠️ Today's ERP System & Engineering Memory Context (`chat_context.md`)
*Created: 28 July 2026*

---

## 1. Database Schema & Supabase Architecture Alignment

### **A. Schema Refinements & Modifications**
1. **`faculty.marks` Schema Upgrade**:
   - Dropped obsolete `class_sec` column.
   - Added explicit filtering columns: `department`, `section`, `year_of_study`, and `year`.
   - Payload columns: `marks_id`, `student_id`, `student_roll`, `student_name`, `faculty_employee_id`, `subject`, `assessment`, `department`, `section`, `year_of_study`, `year`, `cia`, `assignment`, `lab`, `project`, `total`, `percentage`, `grade`, `status`.
   - Unique Constraint for Upsert: `UNIQUE(student_roll, subject, assessment)`.

2. **CIA I vs CIA II Distinct Marks Isolation**:
   - Fixed the issue where loading student marks populated the same mark for both CIA I and CIA II.
   - Separate assessment rows (`CIA - I` vs `CIA - II`) are stored in `faculty.marks`.
   - `MarksService.fetchStudentMarksFromSupabase` groups DB rows per student and assigns `cia1` ONLY from `CIA - I` records and `cia2` ONLY from `CIA - II` records.

3. **`student.attendance_table` Metadata & Format Fixes**:
   - `year_of_study` column added to support year filtering.
   - `p1` through `p7` period statuses stored as PostgreSQL `BOOLEAN` (`true` for Present/OD, `false` for Absent/ML, `null` for unentered).
   - `dept`, `section`, and `year` extracted from `classSec` so attendance updates never pass empty strings (`''`).
   - `attendance_percentage` calculated as `NUMERIC`.
   - Unique Constraint for Upsert: `UNIQUE(reg_no, date)`.
   - Daily cumulative attendance updates `student.students.attendance_percentage` via `UPDATE` (PATCH) on `register_no`.

4. **`faculty.assignment_marks` & `student.student_notifications`**:
   - `faculty.assignment_marks` updated with `year_of_study`, `department`, `section`, `subject_code`, `marks`, `assignment_file`, and `status`.
   - Unique Constraint: `UNIQUE(assignment_id, reg_no)`.
   - Student notifications send to `student.student_notifications` with fields `student_id`, `title`, `category`, `description`, `is_read`.

---

## 2. SQL DDL Applied / Recommended for Supabase SQL Editor

```sql
-- 1. faculty.marks: Remove obsolete class_sec, add department, section, year_of_study
ALTER TABLE faculty.marks DROP COLUMN IF EXISTS class_sec;
ALTER TABLE faculty.marks ADD COLUMN IF NOT EXISTS department VARCHAR(50);
ALTER TABLE faculty.marks ADD COLUMN IF NOT EXISTS section VARCHAR(10);
ALTER TABLE faculty.marks ADD COLUMN IF NOT EXISTS year_of_study VARCHAR(20);

-- 2. student.attendance_table: Add year_of_study column
ALTER TABLE student.attendance_table ADD COLUMN IF NOT EXISTS year_of_study VARCHAR(20);

-- 3. faculty.assignment_marks: Add year_of_study column
ALTER TABLE faculty.assignment_marks ADD COLUMN IF NOT EXISTS year_of_study VARCHAR(20);

-- 4. Unique Constraints for PostgREST Upserts
ALTER TABLE faculty.marks DROP CONSTRAINT IF EXISTS uq_marks_student_subject_section;
ALTER TABLE faculty.marks DROP CONSTRAINT IF EXISTS uq_marks_student_assessment;
ALTER TABLE faculty.marks ADD CONSTRAINT uq_marks_student_assessment UNIQUE (student_roll, subject, assessment);

ALTER TABLE faculty.assignment_marks DROP CONSTRAINT IF EXISTS uq_asgn_reg;
ALTER TABLE faculty.assignment_marks ADD CONSTRAINT uq_asgn_reg UNIQUE (assignment_id, reg_no);

ALTER TABLE student.attendance_table DROP CONSTRAINT IF EXISTS uq_att_reg_date;
ALTER TABLE student.attendance_table ADD CONSTRAINT uq_att_reg_date UNIQUE (reg_no, date);
```

---

## 3. Frontend & App Feature Improvements

### **A. Attendance Module (`attendance_view.dart`)**
- **Timetable Period Validation**: Attendance entry/submission is disabled with an error banner if no timetable period is scheduled for the faculty/class on the selected date.
- **Immediate Roster Refresh**: Parses boolean/string statuses (`P`, `A`, `OD`, `ML`) and re-fetches `_loadStudents()` automatically after save to reflect marked attendance live on UI.
- **HOD Progress Bar Tracker**: The 4-step workflow tracker (`Submitted` → `Pending HOD` → `Decision` → `Updated`) is hidden by default and displays **only after the "Request HOD" button is clicked**.

### **B. Student Section Isolation (`student_service.dart`)**
- **Strict Section Matching**: Fixed `StudentService.getByClassSec` by removing fallback return of all students. Prevents Section A students from leaking into Section B rosters or `faculty.marks`.

### **C. Unified Filter System across Attendance, Marks Entry, & Assignment Pages**
- **Student Year Filter**: `I Year`, `II Year`, `III Year`, `IV Year` dropdown dynamically filters available handling classes of the faculty.
- **Single Subject Auto-Lock**: If a faculty handles only **1 subject** for the selected Class & Section, the Subject dropdown is automatically selected and locked (disabled). Enabled only if multiple subjects are assigned.
- **Assignment Page Cleanup**: Removed the obsolete Semester filter dropdown from the Assignment page.

---

## 4. Build & Deployment Status

- **Static Analysis**: `flutter analyze` passed with 0 errors.
- **Web Bundle**: `flutter build web --release` compiled successfully.
- **Hosting URL**: **[https://ksrce-erp-76eff.web.app](https://ksrce-erp-76eff.web.app)**
