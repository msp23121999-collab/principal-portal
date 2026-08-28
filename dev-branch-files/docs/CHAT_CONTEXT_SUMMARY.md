# Complete Conversation Context & Technical Architecture Summary

**Project Root**: `d:\V2\erp_unified`  
**Target Environment**: Web / Flutter Web  
**Live Hosting URL**: [https://ksrce-erp-76eff.web.app](https://ksrce-erp-76eff.web.app)  
**Database**: Supabase (`https://jnpvzmbisqzbmhkexhwr.supabase.co`)

---

## 1. Database Connection & Credentials

| Credential / Setting | Value |
| :--- | :--- |
| **Supabase URL** | `https://jnpvzmbisqzbmhkexhwr.supabase.co` |
| **PostgreSQL Connection String** | `postgresql://postgres.jnpvzmbisqzbmhkexhwr:Paaswoord%40123@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres` |
| **Publishable Key (`SUPABASE_ANON_KEY`)** | `sb_publishable_9-mNJ6qjq5j_pPaIHvpSAw_w5H-oaAh` |
| **Secret Key (`SUPABASE_SERVICE_ROLE_KEY`)**| `sb_secret_Jk1mqYX9Yf8O5UP7Jzen-w_qfN4xMMz` |
| **JWT Secret** | `3e54a447-696a-40c0-b881-c59da6d6c195` |
| **Active Faculty Session** | `FAC002` (Mr. P. Kalaiyarasan - Dept: IT, Sec: A, Sem: 4) |
| **Active Student Session** | `119519` (DEVAROOPA E - Dept: BE CSE, Roll: 2024CEUCS035, Reg: 73152413035) |

---

## 2. Technical Issues Resolved

### A. Browser 401 Secret API Key Error
- **Symptom**: Browser console error: `401 Forbidden use of secret API key in browser. Secret API keys can only be used in a protected environment.`
- **Root Cause**: `FacultySupabaseConfig.activeKey` returned the `serviceRoleKey` (`sb_secret_...`) for browser requests. Supabase API Gateway rejects secret role keys originating from web browser clients.
- **Fix**: Updated `FacultySupabaseConfig.activeKey` in `lib/modules/faculty/services/supabase_config.dart` to strictly prioritize `anonKey` (`sb_publishable_...`) for all browser requests.

### B. POST / Write Operation Representation Failures
- **Symptom**: `POST` and `PATCH` requests succeeded on the server but returned empty bodies in Flutter web, causing null assignment crashes.
- **Root Cause**: Missing `'Prefer': 'return=representation'` header in `SupabaseClientHelper.insert` and `SupabaseClientHelper.update`.
- **Fix**: Included `'Prefer': 'return=representation'` in `FacultySupabaseConfig.headers` so PostgREST returns created/updated JSON objects on write operations.

### C. Missing `marks` Table 404 Error
- **Symptom**: `POST | 404 | /rest/v1/marks` error when submitting internal assessment marks.
- **Root Cause**: The API endpoint was querying `/rest/v1/marks`, but no `marks` table or view existed in the database schema.
- **Fix**: Created the `faculty.marks` table and `public.marks` mirror view in PostgreSQL.

### D. `.env` Network Exposure Fix
- **Symptom**: `.env` file was being fetched over browser network requests (`GET /assets/.env`).
- **Root Cause**: `- .env` was listed under `flutter.assets` in `pubspec.yaml`, and `dotenv.load(fileName: '.env')` was invoked on boot.
- **Fix**: Removed `- .env` from `pubspec.yaml`, removed `dotenv.load` calls from `lib/main.dart` and `lib/modules/faculty/main.dart`, and re-added `"**/.*"` to `firebase.json` ignore list.

### E. Minified Exception (`minified:a06`)
- **Symptom**: `Supabase SELECT faculties Exception: Instance of 'minified:a06'` in web console.
- **Root Cause**: Accessing `dotenv.env['SUPABASE_URL']` without loading `.env` threw a Dart `NotInitializedException` (minified in release mode to `minified:a06`).
- **Fix**: Updated `FacultySupabaseConfig` getters to check `if (dotenv.isInitialized)` before attempting to read `dotenv.env`. When uninitialized, it returns live string constants safely.

### F. Student Module Null Check & Schema Cache Errors
- **Symptom**: `Null check operator used on a null value` and `Could not find the table 'faculty.students' in the schema cache`.
- **Root Cause**: `SupabaseService` used unsafe `client!.from(...)` calls, and default queries pointed to `schema: 'faculty'` instead of `schema: 'student'`.
- **Fix**: Updated `SupabaseService` and `student erp.dart` to call `SupabaseClientHelper.select(table, schema: 'student')`, sending `Accept-Profile: student` and `Content-Profile: student` headers.

---

## 3. Database Schema Overview

### Multi-Schema Layout

```
                  ┌──────────────────────────────────────────────┐
                  │                 POSTGREST API                │
                  │             (https://...supabase.co)         │
                  └──────────────────────┬───────────────────────┘
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        ▼                                ▼                                ▼
┌──────────────┐                 ┌──────────────┐                 ┌──────────────┐
│    PUBLIC    │                 │   STUDENT    │                 │   FACULTY    │
│ Mirror Views │                 │ Main Domain  │                 │ Shared Domain│
└──────────────┘                 └──────────────┘                 └──────────────┘
```

---

## 4. Master DDL SQL Script for Student & Faculty Schemas

```sql
-- 1. SCHEMAS INITIALIZATION
CREATE SCHEMA IF NOT EXISTS student;
CREATE SCHEMA IF NOT EXISTS faculty;
CREATE SCHEMA IF NOT EXISTS public;

-- 2. MASTER STUDENTS TABLE
CREATE TABLE IF NOT EXISTS student.students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) UNIQUE NOT NULL,
  roll_no VARCHAR(50) UNIQUE NOT NULL,
  register_no VARCHAR(50) UNIQUE NOT NULL,
  application_no VARCHAR(50),
  full_name VARCHAR(100) NOT NULL,
  gender VARCHAR(20) NOT NULL,
  dob DATE NOT NULL,
  age INTEGER,
  blood_group VARCHAR(10),
  photo_url TEXT,
  qr_code_id VARCHAR(50),
  institute_email VARCHAR(100) UNIQUE NOT NULL,
  personal_email VARCHAR(100),
  mobile_number VARCHAR(20) NOT NULL,
  address TEXT,
  district VARCHAR(50),
  state VARCHAR(50),
  pincode VARCHAR(20),
  community VARCHAR(50),
  caste VARCHAR(50),
  religion VARCHAR(50),
  nationality VARCHAR(50) DEFAULT 'INDIAN',
  mother_tongue VARCHAR(50) DEFAULT 'Tamil',
  aadhaar_no VARCHAR(20),
  scholar_type VARCHAR(20) DEFAULT 'Dayscholar',
  degree VARCHAR(100) NOT NULL,
  department VARCHAR(100) NOT NULL,
  batch VARCHAR(20) NOT NULL,
  date_of_admission DATE,
  admission_type VARCHAR(50) DEFAULT 'Regular',
  admitted_type VARCHAR(50) DEFAULT 'Regular',
  year_of_study VARCHAR(10) NOT NULL,
  semester INTEGER NOT NULL,
  term_type VARCHAR(10) NOT NULL,
  semester_type VARCHAR(10) DEFAULT 'ODD',
  section VARCHAR(10) NOT NULL,
  regulation_year VARCHAR(20) NOT NULL,
  academic_year VARCHAR(20) NOT NULL,
  status VARCHAR(20) DEFAULT 'Continuing',
  class_advisor VARCHAR(100),
  class_advisor_name VARCHAR(100),
  class_advisor_id VARCHAR(50),
  cgpa NUMERIC(4,2) DEFAULT 0.00,
  attendance_percentage NUMERIC(5,2) DEFAULT 100.00,
  earned_credits INTEGER DEFAULT 0,
  credits_earned INTEGER DEFAULT 126,
  total_credits INTEGER DEFAULT 160,
  pending_fees_total NUMERIC(10,2) DEFAULT 0.00,
  pending_fees NUMERIC(10,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. FAMILY DETAILS TABLE
CREATE TABLE IF NOT EXISTS student.student_family (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  relation VARCHAR(30) NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  dob DATE,
  mobile_number VARCHAR(20),
  email VARCHAR(100),
  occupation VARCHAR(100),
  annual_income VARCHAR(50),
  aadhaar_no VARCHAR(20),
  blood_group VARCHAR(10),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. DOCUMENTS TABLE
CREATE TABLE IF NOT EXISTS student.student_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  document_name VARCHAR(100) NOT NULL,
  file_name VARCHAR(150) NOT NULL,
  file_url TEXT NOT NULL,
  verification_status VARCHAR(50) DEFAULT 'Verified',
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. FINANCIAL LEDGERS TABLE
CREATE TABLE IF NOT EXISTS student.student_financials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  fee_head VARCHAR(150) NOT NULL,
  total_amount NUMERIC(10,2) NOT NULL,
  paid_amount NUMERIC(10,2) DEFAULT 0.00,
  balance_amount NUMERIC(10,2) DEFAULT 0.00,
  payment_status VARCHAR(30) DEFAULT 'Unpaid',
  receipt_no VARCHAR(50),
  receipt_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. STUDENT NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS student.student_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  category VARCHAR(50) DEFAULT 'GENERAL',
  description TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. FEES TABLE
CREATE TABLE IF NOT EXISTS student.fees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  category VARCHAR(50) DEFAULT 'Tuition',
  amount NUMERIC(10,2) NOT NULL,
  due_date DATE,
  payment_date DATE,
  receipt_no VARCHAR(50),
  is_paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. HOSTEL OUTING REQUESTS TABLE
CREATE TABLE IF NOT EXISTS student.hostel_outing_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  purpose VARCHAR(200) NOT NULL,
  destination VARCHAR(200) NOT NULL,
  out_time TIMESTAMPTZ,
  in_time TIMESTAMPTZ,
  out_date DATE,
  status VARCHAR(30) DEFAULT 'Pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. GRIEVANCES TABLE
CREATE TABLE IF NOT EXISTS student.grievances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL,
  subject VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  status VARCHAR(30) DEFAULT 'Pending',
  response TEXT DEFAULT 'Under review by student welfare committee.',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. CERTIFICATE REQUESTS TABLE
CREATE TABLE IF NOT EXISTS student.certificate_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  certificate_type VARCHAR(100) NOT NULL,
  reason TEXT NOT NULL,
  request_date DATE DEFAULT CURRENT_DATE,
  status VARCHAR(30) DEFAULT 'Pending',
  download_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. ACHIEVEMENTS TABLE
CREATE TABLE IF NOT EXISTS student.achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  category VARCHAR(50) NOT NULL,
  organized_by VARCHAR(200),
  date VARCHAR(50),
  description TEXT,
  status VARCHAR(30) DEFAULT 'Verified',
  points INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. EXTRA COURSES & ENROLLMENTS
CREATE TABLE IF NOT EXISTS student.extra_courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(200) NOT NULL,
  provider VARCHAR(100),
  duration VARCHAR(50),
  category VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS student.extra_course_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  course_id VARCHAR(50) NOT NULL,
  status VARCHAR(30) DEFAULT 'Enrolled',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. PLACEMENTS & APPLICATIONS
CREATE TABLE IF NOT EXISTS student.placements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company VARCHAR(100) NOT NULL,
  role VARCHAR(100) NOT NULL,
  package VARCHAR(50),
  deadline DATE,
  min_cgpa NUMERIC(3,2) DEFAULT 6.00,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS student.placement_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  placement_id VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. NOTICE BOARD & BOOKMARKS
CREATE TABLE IF NOT EXISTS student.notice_board_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(200) NOT NULL,
  category VARCHAR(50) DEFAULT 'General',
  author VARCHAR(100) DEFAULT 'Admin',
  post_date DATE DEFAULT CURRENT_DATE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS student.notice_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id VARCHAR(50) NOT NULL REFERENCES student.students(student_id) ON DELETE CASCADE,
  notice_id VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. PUBLIC & FACULTY MIRROR VIEWS
DROP VIEW IF EXISTS public.students, public.student_family, public.student_documents, public.student_financials, public.student_notifications, public.fees, public.hostel_outing_requests, public.grievances, public.certificate_requests, public.achievements, public.extra_courses, public.extra_course_enrollments, public.placements, public.placement_applications, public.notice_board_posts, public.notice_bookmarks CASCADE;

DROP VIEW IF EXISTS faculty.students, faculty.student_family, faculty.student_documents, faculty.student_financials, faculty.student_notifications, faculty.fees, faculty.hostel_outing_requests, faculty.grievances, faculty.certificate_requests, faculty.achievements, faculty.extra_courses, faculty.extra_course_enrollments, faculty.placements, faculty.placement_applications, faculty.notice_board_posts, faculty.notice_bookmarks CASCADE;

-- Public Schema Mirror Views
CREATE OR REPLACE VIEW public.students AS SELECT * FROM student.students;
CREATE OR REPLACE VIEW public.student_family AS SELECT * FROM student.student_family;
CREATE OR REPLACE VIEW public.student_documents AS SELECT * FROM student.student_documents;
CREATE OR REPLACE VIEW public.student_financials AS SELECT * FROM student.student_financials;
CREATE OR REPLACE VIEW public.student_notifications AS SELECT * FROM student.student_notifications;
CREATE OR REPLACE VIEW public.fees AS SELECT * FROM student.fees;
CREATE OR REPLACE VIEW public.hostel_outing_requests AS SELECT * FROM student.hostel_outing_requests;
CREATE OR REPLACE VIEW public.grievances AS SELECT * FROM student.grievances;
CREATE OR REPLACE VIEW public.certificate_requests AS SELECT * FROM student.certificate_requests;
CREATE OR REPLACE VIEW public.achievements AS SELECT * FROM student.achievements;
CREATE OR REPLACE VIEW public.extra_courses AS SELECT * FROM student.extra_courses;
CREATE OR REPLACE VIEW public.extra_course_enrollments AS SELECT * FROM student.extra_course_enrollments;
CREATE OR REPLACE VIEW public.placements AS SELECT * FROM student.placements;
CREATE OR REPLACE VIEW public.placement_applications AS SELECT * FROM student.placement_applications;
CREATE OR REPLACE VIEW public.notice_board_posts AS SELECT * FROM student.notice_board_posts;
CREATE OR REPLACE VIEW public.notice_bookmarks AS SELECT * FROM student.notice_bookmarks;

-- Faculty Schema Mirror Views
CREATE OR REPLACE VIEW faculty.students AS SELECT * FROM student.students;
CREATE OR REPLACE VIEW faculty.student_family AS SELECT * FROM student.student_family;
CREATE OR REPLACE VIEW faculty.student_documents AS SELECT * FROM student.student_documents;
CREATE OR REPLACE VIEW faculty.student_financials AS SELECT * FROM student.student_financials;
CREATE OR REPLACE VIEW faculty.student_notifications AS SELECT * FROM student.student_notifications;
CREATE OR REPLACE VIEW faculty.fees AS SELECT * FROM student.fees;
CREATE OR REPLACE VIEW faculty.hostel_outing_requests AS SELECT * FROM student.hostel_outing_requests;
CREATE OR REPLACE VIEW faculty.grievances AS SELECT * FROM student.grievances;
CREATE OR REPLACE VIEW faculty.certificate_requests AS SELECT * FROM student.certificate_requests;
CREATE OR REPLACE VIEW faculty.achievements AS SELECT * FROM student.achievements;
CREATE OR REPLACE VIEW faculty.extra_courses AS SELECT * FROM student.extra_courses;
CREATE OR REPLACE VIEW faculty.extra_course_enrollments AS SELECT * FROM student.extra_course_enrollments;
CREATE OR REPLACE VIEW faculty.placements AS SELECT * FROM student.placements;
CREATE OR REPLACE VIEW faculty.placement_applications AS SELECT * FROM student.placement_applications;
CREATE OR REPLACE VIEW faculty.notice_board_posts AS SELECT * FROM student.notice_board_posts;
CREATE OR REPLACE VIEW faculty.notice_bookmarks AS SELECT * FROM student.notice_bookmarks;

-- 16. PERMISSION GRANTS
GRANT USAGE ON SCHEMA student, faculty, public TO anon, authenticated, service_role, postgres;
GRANT ALL ON ALL TABLES IN SCHEMA student, faculty, public TO anon, authenticated, service_role, postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA student, faculty, public TO anon, authenticated, service_role, postgres;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA student GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA faculty GRANT ALL ON TABLES TO anon, authenticated, service_role;

NOTIFY pgrst, 'reload schema';
```

---

## 5. Build and Deployment Commands

To build and deploy the updated application manually from `d:\V2\erp_unified`:

```powershell
# 1. Compile Release Web Build
flutter build web --release

# 2. Deploy to Firebase Hosting
npx firebase-tools deploy --only hosting
```
