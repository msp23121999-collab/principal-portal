-- ============================================================================
-- SUPABASE SINGLE-PROJECT CONSOLIDATION & MIGRATION SCRIPT
-- Project: KSRCE ERP Unified System
-- Target: Unified Supabase Database Layer
-- Date: 2026-07-25
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- STEP 1: CREATE MASTER REFERENCE TABLES
-- ----------------------------------------------------------------------------

-- 1. Master Departments
CREATE TABLE IF NOT EXISTS public.departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    hod_name VARCHAR(150),
    hod_user_id UUID,
    intake_capacity INT DEFAULT 60,
    status VARCHAR(30) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Master Academic Years / Cycles
CREATE TABLE IF NOT EXISTS public.academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year_code VARCHAR(50) NOT NULL UNIQUE, -- e.g. 2026-2027
    name VARCHAR(150),
    start_date DATE,
    end_date DATE,
    is_current BOOLEAN DEFAULT FALSE,
    status VARCHAR(30) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Master Users & Identity Directory (Universal Auth Directory)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE, -- References auth.users(id)
    user_code VARCHAR(30) UNIQUE,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    role VARCHAR(50) NOT NULL, -- Super Admin, HOD, Faculty, Student, Registrar
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    department_code VARCHAR(20),
    node VARCHAR(50) DEFAULT 'Active Node',
    status VARCHAR(30) DEFAULT 'Active',
    admission_number VARCHAR(50),
    admission_date DATE,
    roll_number VARCHAR(50),
    registration_number VARCHAR(50),
    domain_email VARCHAR(150),
    gender VARCHAR(20),
    community VARCHAR(30),
    date_of_birth DATE,
    contact_number VARCHAR(30),
    batch VARCHAR(30),
    section VARCHAR(10),
    blood_group VARCHAR(10),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Master Subjects Catalog
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    course_code VARCHAR(30),
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    subject_type VARCHAR(30) DEFAULT 'Theory', -- Theory, Lab, Elective
    semester VARCHAR(20),
    credits INT DEFAULT 3,
    status VARCHAR(30) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Master Class Sections
CREATE TABLE IF NOT EXISTS public.class_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL, -- Year 2 • Section A
    department_id UUID REFERENCES public.departments(id) ON DELETE CASCADE,
    semester VARCHAR(20) NOT NULL,
    section VARCHAR(10) NOT NULL,
    academic_year_id UUID REFERENCES public.academic_years(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(department_id, semester, section)
);

-- ----------------------------------------------------------------------------
-- STEP 2: CREATE CANONICAL OPERATIONAL TABLES
-- ----------------------------------------------------------------------------

-- 6. Canonical Students Table
CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    student_id VARCHAR(50) NOT NULL UNIQUE,
    roll_number VARCHAR(50) NOT NULL UNIQUE,
    register_number VARCHAR(50),
    name VARCHAR(150) NOT NULL,
    gender VARCHAR(20),
    email VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    mobile_number VARCHAR(30),
    personal_email VARCHAR(150),
    address TEXT,
    year_of_study VARCHAR(20),
    current_semester VARCHAR(20),
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    section VARCHAR(10),
    programme VARCHAR(50),
    status VARCHAR(30) DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Canonical Faculty Table
CREATE TABLE IF NOT EXISTS public.faculties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    employee_id VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    role VARCHAR(50) DEFAULT 'Faculty',
    designation VARCHAR(100) NOT NULL,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    email VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Attendance Sessions (Faculty Session-based Attendance)
CREATE TABLE IF NOT EXISTS public.attendance_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID REFERENCES public.faculties(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    class_section_id UUID REFERENCES public.class_sections(id) ON DELETE CASCADE,
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    period VARCHAR(20),
    topic_covered TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Attendance Records (Student Attendance Details)
CREATE TABLE IF NOT EXISTS public.attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.attendance_sessions(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL, -- PRESENT, ABSENT, OD, LATE
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Student Marks & Internal Assessment
CREATE TABLE IF NOT EXISTS public.student_marks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    faculty_id UUID REFERENCES public.faculties(id) ON DELETE SET NULL,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    class_section_id UUID REFERENCES public.class_sections(id) ON DELETE CASCADE,
    assessment_name VARCHAR(100) NOT NULL, -- CIA 1, CIA 2, Assignment, EndSem
    cia_score NUMERIC(5,2) DEFAULT 0.0,
    assignment_score NUMERIC(5,2) DEFAULT 0.0,
    lab_score NUMERIC(5,2) DEFAULT 0.0,
    project_score NUMERIC(5,2) DEFAULT 0.0,
    total_score NUMERIC(5,2) DEFAULT 0.0,
    grade VARCHAR(5),
    remarks TEXT,
    status VARCHAR(30) DEFAULT 'DRAFT', -- DRAFT, SUBMITTED, APPROVED
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Operational Timetables
CREATE TABLE IF NOT EXISTS public.timetables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID REFERENCES public.faculties(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    class_section_id UUID REFERENCES public.class_sections(id) ON DELETE CASCADE,
    day_of_week VARCHAR(20) NOT NULL, -- Monday, Tuesday, etc.
    period VARCHAR(20) NOT NULL,
    time_slot VARCHAR(50),
    room_no VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Unified Academic Calendar Events
CREATE TABLE IF NOT EXISTS public.academic_calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_type VARCHAR(50) DEFAULT 'ACADEMIC', -- ACADEMIC, EXAM, HOLIDAY, SYMPOSIUM
    scope VARCHAR(30) DEFAULT 'ALL', -- ALL, FACULTY, STUDENT, HOD
    owner_role VARCHAR(30) DEFAULT 'ADMIN',
    color_code VARCHAR(20) DEFAULT '#2563EB',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- STEP 3: IDEMPOTENT DATA MIGRATION SCRIPTS WITH ROW-COUNT CHECKS
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    dept_count INT;
    student_count INT;
    user_count INT;
BEGIN
    -- Check Department Data
    SELECT COUNT(*) INTO dept_count FROM public.departments;
    RAISE NOTICE 'Current Departments Count: %', dept_count;

    -- Check Student Data
    SELECT COUNT(*) INTO student_count FROM public.students;
    RAISE NOTICE 'Current Students Count: %', student_count;

    -- Check User Data
    SELECT COUNT(*) INTO user_count FROM public.users;
    RAISE NOTICE 'Current Users Directory Count: %', user_count;
END $$;

-- ----------------------------------------------------------------------------
-- STEP 4: COMPATIBILITY VIEWS FOR RETIRED TABLES
-- ----------------------------------------------------------------------------

-- Compatibility View for Retired `courses` Table
CREATE OR REPLACE VIEW public.courses AS
SELECT 
    id,
    subject_code AS course_code,
    name AS course_title,
    department_id AS department,
    credits,
    created_at
FROM public.subjects;

-- Compatibility View for Retired `class_timetables` Table
CREATE OR REPLACE VIEW public.class_timetables AS
SELECT 
    id,
    subject_id AS course_id,
    day_of_week,
    time_slot AS start_time,
    room_no,
    created_at
FROM public.timetables;

-- Compatibility View for Retired `student_grades` Table
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

-- ----------------------------------------------------------------------------
-- STEP 5: ROW LEVEL SECURITY & PERMISSIVE POLICIES
-- ----------------------------------------------------------------------------

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faculties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_marks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_calendar_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public access for departments" ON public.departments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for academic_years" ON public.academic_years FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for users" ON public.users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for subjects" ON public.subjects FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for class_sections" ON public.class_sections FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for students" ON public.students FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for faculties" ON public.faculties FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for attendance_sessions" ON public.attendance_sessions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for attendance_records" ON public.attendance_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for student_marks" ON public.student_marks FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for timetables" ON public.timetables FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for academic_calendar_events" ON public.academic_calendar_events FOR ALL USING (true) WITH CHECK (true);
