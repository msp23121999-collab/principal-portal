# KSRCE ERP: Supabase to AWS Migration
## Phase 1 & 2 Complete Analysis Report

**Date**: 2026-08-13
**Status**: Phases 1 & 2 ✓ COMPLETE | Phase 3 IN PROGRESS

---

## Executive Summary

The KSRCE ERP application is a comprehensive **Flutter + Node.js + Supabase** system serving 7 ERP modules (Student, Faculty, HOD, Admin, Dean, Principal, Super Admin) with 110+ PostgreSQL tables across 5 schemas.

**Key Finding**: The project currently has **multiple duplicate database schemas** and **hardcoded Supabase credentials in frontend code**, which poses significant security and maintenance risks.

**Migration Objective**: Move from Supabase → AWS (RDS PostgreSQL, API Gateway, Cognito, S3, Lambda, EventBridge) while preserving all existing ERP functionality.

---

## Phase 1: Complete Project Analysis ✓ DONE

### Current Technology Stack

#### Frontend
- **Framework**: Flutter 3.12+ (Web, Mobile, Desktop capable)
- **Dependencies**: 
  - `supabase_flutter` 2.6.0 (direct database access)
  - `firebase_core` 3.13.1 + `cloud_firestore` 5.6.9 (appears LEGACY)
  - `flutter_riverpod` 2.5.1 (state management)
  - `go_router` 17.3.0 (navigation)
  - `http` 1.2.0 (HTTP client)
- **Authentication**: Firebase initialized but Supabase credentials used
- **Storage**: Firebase Storage + Supabase Storage
- **Build Targets**: Web (primary), Mobile (iOS/Android), Desktop

#### Backend
- **Status**: MINIMAL - Only maintenance scripts exist
- **Framework**: Node.js (Express not yet used)
- **Scripts Found**:
  - `check_tables.js` - Database table inspection
  - `drop_old_faculty_tables.js` - Cleanup utility
  - `test_db_data.js` - Data testing
- **Dependencies**: Only `pg` (PostgreSQL) + `firebase-tools`
- **TODO**: Full backend API layer needs to be built

#### Database
- **Current**: Supabase PostgreSQL
- **Schemas**: 5 (public, student, faculty, admin, hod)
- **Tables**: 110+
- **Features**: UUID PKs, Foreign keys, Constraints, Functions, Triggers, Views

#### Deployment
- **Current**: Firebase Hosting (Flutter Web only)
- **Database**: Supabase cloud
- **Auth**: Supabase + Firebase (hybrid, confusing)

---

## Phase 2: Complete Supabase Dependency Map ✓ DONE

### 1. Supabase Configuration Files (5 found)

```
frontend/lib/shared/services/supabase_service.dart
├─ Global Supabase config
├─ Fallback data for all tables
└─ Main initialization point

frontend/lib/modules/student/services/supabase_service.dart
├─ Student module-specific service
└─ Methods: getStudentProfile, getStudentFamily, getStudentDocuments, etc.

frontend/lib/modules/student/services/student erp.dart
├─ Alternative service implementation
└─ Duplicates student service functionality

frontend/lib/modules/faculty/services/supabase_config.dart
├─ Faculty module configuration
├─ HARDCODED KEYS: ⚠️ CRITICAL SECURITY ISSUE
│  └─ Anon Key: sb_publishable_9-mNJ6qjq5j_pPaIHvpSAw_w5H-oaAh
│  └─ Secret Key: sb_secret_Jk1mqYX9Yf8O5UP7Jzen-w_qfN4xMMz
└─ Connection string exposed in code

frontend/lib/modules/faculty/services/supabase_client.dart
├─ Supabase REST API wrapper (HTTP-based)
├─ Methods: select(), insert(), update(), delete(), upsert()
└─ Schema routing support

frontend/lib/modules/dean/services/supabase_service.dart
├─ Dean module configuration
├─ Also has HARDCODED KEYS
└─ Alternative supabase.co instance
```

### 2. Supabase Operations Found (480 references)

**SELECT Operations** (most common)
- 40+ screens directly query Supabase tables
- Examples:
  - Student screens: students, attendance_table, marks, fees, etc.
  - Faculty screens: faculties, assignments, attendance_sessions, marks
  - HOD screens: class_advisors, leave_requests, department_files
  - Admin screens: all system tables

**INSERT Operations**
- Mark entry submissions
- Assignment uploads
- Leave applications
- Certificate requests
- Grievance registration

**UPDATE Operations**
- Profile updates
- Mark revisions
- Status changes
- Document verification

**DELETE Operations**
- Record removal
- File deletion
- Booking cancellation

**UPSERT Operations**
- Attendance records
- Grade updates
- Mark submissions

### 3. Database Tables by Module

#### Student Module Tables (50+)
```
Core Profile:
  students, student_family, student_education, student_documents, 
  student_financials

Academic:
  attendance_table, fees, certificate_requests, achievements, 
  extra_courses, placements, placement_applications

Operations:
  grievances, hostel_outing_requests, notice_board_posts, 
  notice_bookmarks, student_notifications
```

#### Faculty Module Tables (30+)
```
Core:
  faculties, faculty_course_allocations, timetables, 
  attendance_sessions

Academic:
  marks, assignments, lesson_plans, question_banks, 
  syllabus_uploads

Operations:
  leave_applications, notifications, mark_sheet_statuses
```

#### Public Schema Tables (13)
```
Master Reference:
  departments, academic_years, users, subjects, class_sections

Operational:
  students, faculties, attendance_sessions, attendance_records, 
  student_marks, timetables, academic_calendar_events
```

#### Admin Schema Tables (11+)
```
admin_users, admin_departments, admin_courses, admin_subjects, 
admin_regulations, admin_academic_cycles, admin_role_permissions, 
admin_system_settings, admin_audit_logs, admin_reports, 
admin_medical_alerts
```

#### HOD Schema Tables (6+)
```
hod_profiles, hod_leave_requests, hod_profile_approvals, 
hod_class_advisers, hod_mentors, hod_department_files
```

### 4. Authentication & Authorization

**Current Issues**:
- ✗ Firebase initialized but not fully used
- ✗ Supabase Auth credentials in frontend
- ✗ No backend JWT validation
- ✗ Supabase RLS policies currently PERMISSIVE (allow all)
- ✗ No role-based authorization implemented

**Roles Identified**:
- SUPER_ADMIN
- ADMIN / PRINCIPAL
- DEAN
- HOD
- FACULTY
- STUDENT
- PARENT (referenced but may not be implemented)

### 5. Storage Operations

**Supabase Storage Buckets** (inferred from code):
- Student profiles (photo_url)
- Student documents (file_url)
- Faculty profiles and documents
- Assignment submissions
- Syllabi and question papers
- Certificates (download_url)
- Receipt documents (receipt_url)

### 6. Scheduled Jobs / Cron

**Daily Attendance Calculation** (5:00 PM IST)
```sql
-- PostgreSQL Function:
CREATE OR REPLACE FUNCTION student.update_daily_cumulative_attendance()

-- Triggered by Supabase pg_cron:
SELECT cron.schedule('daily-student-attendance-update-5pm', '0 17 * * *', 
  'SELECT student.update_daily_cumulative_attendance();');

-- Updates: attendance_percentage in students/student table
```

**Purpose**: Calculate cumulative attendance % from attendance_table records

### 7. Modules Supabase Dependency Levels

| Module | Dependency | Tables Used | Priority |
|--------|-----------|-------------|----------|
| Student | **HEAVY** | 50+ | Critical |
| Faculty | **HEAVY** | 30+ | Critical |
| HOD | **MEDIUM** | 10+ | High |
| Admin | **HEAVY** | 11+ | Critical |
| Dean | **LIGHT** | 5+ | Medium |
| Principal | **LIGHT** | 5+ | Medium |
| Super Admin | **HEAVY** | All | Critical |

---

## Phase 3: Canonical Database Schema ✓ IN PROGRESS

### 3.1 Schema Duplication Problem

The project has **multiple duplicate table definitions** across SQL migration files:

#### Duplication #1: Students Table

**student.students** (schema.sql)
```sql
CREATE TABLE student.students (
  id uuid, student_id varchar, roll_no varchar, register_no varchar,
  full_name varchar, gender varchar, dob date, ...
  CONSTRAINT students_pkey PRIMARY KEY (id)
)
```

**public.students** (supabase_consolidation_migration.sql)
```sql
CREATE TABLE public.students (
  id UUID, user_id UUID REFERENCES public.users(id),
  student_id VARCHAR(50), roll_number VARCHAR(50),
  register_number VARCHAR(50), name VARCHAR(150), ...
  CONSTRAINT students_pkey PRIMARY KEY (id)
)
```

**Issue**: Different field names (student_id vs student_id), different primary key strategy (UUID vs UUID with user_id FK)

#### Duplication #2: Faculties Table

**faculty.faculties** (schema.sql)
```sql
CREATE TABLE faculty.faculties (
  id uuid, employee_id varchar, department_id varchar,
  full_name varchar, designation varchar, role varchar, ...
)
```

**public.faculties** (supabase_consolidation_migration.sql)
```sql
CREATE TABLE public.faculties (
  id UUID, user_id UUID REFERENCES public.users(id),
  employee_id VARCHAR(50), name VARCHAR(150), ...
)
```

#### Duplication #3: Attendance

**student.attendance_table** (session-based, schema.sql)
```sql
CREATE TABLE student.attendance_table (
  id uuid, date date, reg_no varchar, p1 boolean, p2 boolean, ...,
  attendance_percentage varchar
)
```

**public.attendance_sessions + public.attendance_records** (normalized, consolidation_migration.sql)
```sql
CREATE TABLE public.attendance_sessions (
  id UUID, faculty_id UUID, subject_id UUID, session_date DATE, ...
)

CREATE TABLE public.attendance_records (
  id UUID, session_id UUID, student_id UUID, status VARCHAR, ...
)
```

#### Duplication #4: Timetables

**faculty.timetables** (schema.sql)
```sql
CREATE TABLE faculty.timetables (
  id uuid, faculty_employee_id varchar, day_of_week varchar, ...
)
```

**public.timetables** (supabase_consolidation_migration.sql)
```sql
CREATE TABLE public.timetables (
  id UUID, faculty_id UUID, day_of_week VARCHAR, ...
)
```

#### Duplication #5: Marks

**faculty.marks** (schema.sql)
```sql
CREATE TABLE faculty.marks (
  id uuid, faculty_employee_id varchar, ...
)
```

**public.student_marks** (supabase_consolidation_migration.sql)
```sql
CREATE TABLE public.student_marks (
  id UUID, student_id UUID, faculty_id UUID, ...
)
```

**faculty.assignment_marks** (schema.sql)
```sql
CREATE TABLE faculty.assignment_marks (
  id UUID, assignment_id VARCHAR, reg_no VARCHAR, marks NUMERIC, ...
)
```

### 3.2 Schema Consolidation Strategy

**Decision**: Use `public` schema as canonical source of truth

**Rationale**:
1. public schema has normalized design with proper foreign keys
2. public schema integrates all modules (users, departments, subjects, etc.)
3. consolidation_migration.sql is more recent and better designed
4. Eliminates schema-specific duplication
5. Simplifies migration to AWS

**Actions**:
1. Create canonical `database/schema.sql` based on public schema + additional tables
2. Migrate data from `student.*` and `faculty.*` to public equivalents
3. Create migration views for compatibility during transition
4. Update all Flutter services to use public schema only
5. Archive old schemas (student.*, faculty.*) after validation

### 3.3 Field Mapping (For Data Migration)

#### Student Table Mapping
```
student.students → public.students
  student_id → student_id (unchanged)
  roll_no → roll_number (rename)
  register_no → register_number (rename)
  full_name → name (rename)
  Add: user_id FK to public.users
  Add: department_id FK to public.departments
```

#### Faculty Table Mapping
```
faculty.faculties → public.faculties
  employee_id → employee_id (unchanged)
  full_name → name (rename)
  department_id → department_id (FK to public.departments)
  Add: user_id FK to public.users
  Add: role field from existing "role" column
```

#### Attendance Table Mapping
```
student.attendance_table → public.attendance_sessions + public.attendance_records

Session Creation:
  date → session_date
  faculty_employee_id → lookup faculty_id
  subject_code → lookup subject_id
  section → lookup class_section_id
  period → period

Record Creation:
  For each student: reg_no → lookup student_id
  Attendance status from p1, p2, p3, p4, p5, p6, p7 columns
  One record per period per student
```

### 3.4 Canon ical Database Schema Outline

```
✓ Master Reference Layer (public schema)
  ├─ departments
  ├─ academic_years
  ├─ users (universal directory)
  ├─ subjects
  └─ class_sections

✓ Student Module Layer (public schema)
  ├─ students
  ├─ student_marks
  ├─ attendance_records
  ├─ fees/student_financials
  ├─ certificates/certificate_requests
  ├─ achievements
  ├─ placements/placement_applications
  └─ (additional 40+ tables from student schema)

✓ Faculty Module Layer (public schema)
  ├─ faculties
  ├─ faculty_allocations
  ├─ timetables
  ├─ marks/assignment_marks
  ├─ assignments
  ├─ lesson_plans
  ├─ question_banks
  ├─ leave_applications
  └─ (additional 20+ tables from faculty schema)

✓ Admin & HOD Layers (separate schemas or public)
  ├─ admin_users, admin_departments, admin_courses, etc.
  ├─ hod_profiles, hod_leave_requests, hod_class_advisers, etc.
  └─ (system configuration tables)

PostgreSQL Features
  ├─ Stored Procedures
  │  └─ student.update_daily_cumulative_attendance()
  │     (Will become: public.update_daily_cumulative_attendance())
  ├─ Scheduled Jobs (via EventBridge/Lambda instead of pg_cron)
  ├─ Foreign Key Relationships (comprehensive)
  ├─ Constraints & Indexes (preserved)
  └─ Compatibility Views (for legacy queries)
```

### 3.5 Data Validation Requirements

Before migration:
1. **Table Count Validation**
   - Supabase: Count rows in each table
   - RDS: Count rows in migrated tables
   - Compare: Row counts must match

2. **Primary Key Validation**
   - Verify all UUIDs are unique
   - Verify no NULL PKs
   - Verify ID sequences correct

3. **Foreign Key Validation**
   - Verify all FKs resolve to valid records
   - Identify orphaned records (if any)
   - Validate referential integrity

4. **Data Integrity Checks**
   - Check for duplicate records
   - Validate date formats
   - Verify email uniqueness
   - Confirm phone number formats
   - Check status fields for valid values

5. **Business Logic Validation**
   - Attendance percentage calculations
   - Fee status consistency
   - Mark ranges (0-100 or course-specific)
   - Department-student-faculty relationships

---

## Critical Security Issues Found ⚠️

### Issue #1: Hardcoded Supabase Keys in Frontend
**Severity**: CRITICAL
**Location**: `frontend/lib/modules/faculty/services/supabase_config.dart` (and dean config)
**Keys Exposed**:
- Anon Key: `sb_publishable_9-mNJ6qjq5j_pPaIHvpSAw_w5H-oaAh`
- Secret Key: `sb_secret_Jk1mqYX9Yf8O5UP7Jzen-w_qfN4xMMz`
- Connection String: `postgresql://postgres.jnpvzmbisqzbmhkexhwr:Paaswoord%40123@...`
**Impact**: Anyone decompiling the app can access entire database
**Fix**: Migrate to Cognito + backend API (no keys in frontend)

### Issue #2: No Backend Authorization Layer
**Severity**: CRITICAL
**Current**: Flutter directly connects to Supabase (uses RLS only)
**Problem**: RLS policies are PERMISSIVE (allow all)
**Fix**: Backend API validates JWT + role-based authorization

### Issue #3: Database Credentials in Environment
**Severity**: HIGH
**Current**: `.env.example` shows DATABASE_URL structure but actual credentials exist somewhere
**Fix**: Use AWS Secrets Manager, no credentials in code

### Issue #4: Multiple Authentication Systems
**Severity**: MEDIUM
**Current**: Firebase + Supabase + no proper role management
**Fix**: Single Cognito auth system with JWT tokens

### Issue #5: Unencrypted File Storage
**Severity**: MEDIUM
**Current**: File URLs stored as plain text, files potentially publicly accessible
**Fix**: S3 with presigned URLs, proper access control

---

## Next Steps: Phase 4 (AWS Architecture Design)

1. **RDS PostgreSQL Planning**
   - Instance type and size
   - Backup strategy
   - Multi-AZ setup
   - Security groups and subnets

2. **API Gateway Setup**
   - REST API endpoints
   - CORS configuration
   - Rate limiting
   - API key management

3. **Cognito Configuration**
   - User pool creation
   - App client setup
   - Role mapping
   - MFA options

4. **S3 Bucket Setup**
   - Bucket structure
   - Encryption at rest
   - Versioning
   - Presigned URL generation

5. **Lambda Functions**
   - Attendance calculation
   - Other scheduled jobs
   - Event processing

6. **EventBridge Rules**
   - Daily 5 PM trigger
   - Other scheduled tasks

7. **CloudWatch Setup**
   - Log groups
   - Alarms
   - Metrics

---

## Timeline Estimate

- **Phase 3**: 2-3 days (Schema consolidation, validation)
- **Phase 4**: 1-2 days (AWS architecture)
- **Phase 5**: 3-4 days (RDS migration)
- **Phase 6**: 4-5 days (Backend API development)
- **Phase 7**: 2-3 days (Cognito migration)
- **Phase 8**: 2-3 days (S3 migration)
- **Phase 9**: 3-4 days (Flutter updates)
- **Phase 10**: 2-3 days (Lambda functions)
- **Phase 11**: 2-3 days (Testing and validation)
- **Phase 12**: 1-2 days (Security audit and cleanup)

**Total Estimated**: 24-33 days (5-7 weeks) for complete migration

---

## Deliverables Summary

**Phase 1-2 Complete**:
- ✓ Current architecture documented
- ✓ All Supabase dependencies mapped (480+ references)
- ✓ Database structure analyzed (110+ tables)
- ✓ Security issues identified
- ✓ Modules dependency levels documented

**Phase 3 In Progress**:
- In Progress: Canonical schema design
- Pending: Data migration scripts
- Pending: Validation queries

**Phase 4+ To Start**:
- AWS architecture template
- Backend API scaffolding
- Migration implementation

---

**Prepared by**: GitHub Copilot
**Status**: Ready for Phase 3 completion and Phase 4 start
