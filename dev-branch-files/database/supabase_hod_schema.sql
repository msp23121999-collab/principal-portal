-- ============================================================================
-- SUPABASE POSTGRESQL SCHEMA FOR HOD (HEAD OF DEPARTMENT) MODULE
-- Project: KSRCE ERP Unified System
-- Module: HOD Portal
-- Date: 2026-07-25
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- 1. TABLE: hod_profiles
-- Represents detailed profiles for Department HODs & Staff
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    official_email VARCHAR(150) NOT NULL UNIQUE,
    personal_email VARCHAR(150),
    phone VARCHAR(30),
    emergency_contact VARCHAR(100),
    dob DATE,
    gender VARCHAR(20),
    blood_group VARCHAR(10),
    nationality VARCHAR(50) DEFAULT 'Indian',
    marital_status VARCHAR(20),
    address TEXT,
    designation VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    dept_code VARCHAR(20) NOT NULL,
    date_of_joining DATE,
    employment_type VARCHAR(50) DEFAULT 'Permanent / Regular',
    office_location VARCHAR(100),
    reporting_authority VARCHAR(100),
    teaching_experience_years INT DEFAULT 0,
    admin_experience_years INT DEFAULT 0,
    ug_degree VARCHAR(150),
    pg_degree VARCHAR(150),
    phd_degree VARCHAR(150),
    specialization TEXT,
    university VARCHAR(150),
    orcid VARCHAR(50),
    scopus_id VARCHAR(50),
    google_scholar VARCHAR(150),
    research_gate VARCHAR(150),
    publication_count INT DEFAULT 0,
    conference_count INT DEFAULT 0,
    books_count INT DEFAULT 0,
    patents_count INT DEFAULT 0,
    funded_projects_amount VARCHAR(100),
    weekly_workload_hours INT DEFAULT 18,
    subjects_handled TEXT[] DEFAULT '{}',
    department_roles TEXT[] DEFAULT '{}',
    awards TEXT[] DEFAULT '{}',
    certifications TEXT[] DEFAULT '{}',
    profile_completion_pct NUMERIC(5,2) DEFAULT 100.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 2. TABLE: hod_leave_requests
-- Faculty leave applications pending or reviewed by HOD
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_leave_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_id VARCHAR(30) UNIQUE,
    faculty_name VARCHAR(150) NOT NULL,
    faculty_employee_id VARCHAR(50),
    designation VARCHAR(100),
    leave_type VARCHAR(50) NOT NULL, -- e.g. Casual Leave (CL), On Duty (OD), Sick Leave (SL)
    dates_description VARCHAR(100) NOT NULL,
    start_date DATE,
    end_date DATE,
    days_count INT DEFAULT 1,
    reason TEXT NOT NULL,
    substitute_faculty VARCHAR(150),
    status VARCHAR(30) DEFAULT 'PENDING HOD', -- PENDING HOD, APPROVED, REJECTED
    hod_remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 3. TABLE: hod_profile_approvals
-- Faculty profile updates submitted to HOD for verification
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_profile_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_id VARCHAR(30) UNIQUE,
    faculty_name VARCHAR(150) NOT NULL,
    faculty_employee_id VARCHAR(50),
    update_type VARCHAR(100) NOT NULL, -- Research, Qualification, Certification
    old_value TEXT,
    new_value TEXT NOT NULL,
    document_name VARCHAR(255),
    document_url TEXT,
    status VARCHAR(30) DEFAULT 'PENDING HOD', -- PENDING HOD, APPROVED, REJECTED
    hod_remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. TABLE: hod_class_advisers
-- Class advisor assignments managed by HOD
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_class_advisers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_section VARCHAR(100) NOT NULL, -- e.g. Year 2 • Section A (Batch 2024-28)
    adviser_name VARCHAR(150) NOT NULL,
    adviser_employee_id VARCHAR(50),
    designation VARCHAR(100),
    strength VARCHAR(50), -- e.g. 60 (32M / 28F)
    attendance_pct NUMERIC(5,2) DEFAULT 0.0,
    meetings_conducted VARCHAR(50) DEFAULT '0 Conducted',
    status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 5. TABLE: hod_mentors
-- Student mentor assignments & counselling status tracking
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_mentors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mentor_name VARCHAR(150) NOT NULL,
    mentor_employee_id VARCHAR(50),
    designation VARCHAR(100),
    section VARCHAR(100) NOT NULL,
    mentees_count INT DEFAULT 0,
    last_session_date DATE,
    counselling_status VARCHAR(50) DEFAULT 'NORMAL', -- NORMAL, COUNSELLING NEEDED
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 6. TABLE: hod_department_files
-- Departmental repository files (NAAC, NBA, Syllabus, Course Diaries)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_department_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_id VARCHAR(30) UNIQUE,
    file_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL, -- Syllabus & Curriculum, NAAC / NBA Files, Course Materials
    uploaded_by VARCHAR(150) NOT NULL,
    file_size VARCHAR(30),
    upload_date DATE DEFAULT CURRENT_DATE,
    access_level VARCHAR(50) DEFAULT 'Department Public', -- Department Public, HOD Only, Faculty Only
    file_url TEXT,
    status VARCHAR(30) DEFAULT 'VERIFIED', -- VERIFIED, PENDING
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 7. TABLE: hod_events
-- Departmental events, symposiums, workshops & FDPs
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_id VARCHAR(30) UNIQUE,
    event_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL, -- National Symposium, FDP, Workshop
    in_charge VARCHAR(150) NOT NULL,
    venue VARCHAR(150) NOT NULL,
    dates_description VARCHAR(100) NOT NULL,
    start_date DATE,
    end_date DATE,
    registered_count INT DEFAULT 0,
    status VARCHAR(30) DEFAULT 'UPCOMING', -- UPCOMING, ACTIVE, COMPLETED, CANCELLED
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 8. TABLE: hod_notifications
-- Department level announcements & circular dispatches
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_id VARCHAR(30) UNIQUE,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL, -- Examination Alert, Faculty Development, Academic Circular
    priority VARCHAR(20) DEFAULT 'MEDIUM', -- HIGH, MEDIUM, LOW
    audience VARCHAR(100) NOT NULL, -- All Department Faculty, All Students & Faculty
    delivery_channels VARCHAR(100) DEFAULT 'Portal', -- Portal + Email + SMS
    read_count INT DEFAULT 0,
    total_count INT DEFAULT 0,
    status VARCHAR(30) DEFAULT 'PUBLISHED', -- PUBLISHED, DRAFT
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 9. TABLE: hod_course_diaries
-- Tracking syllabus progress and teaching hours per course
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_course_diaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_code VARCHAR(50) NOT NULL,
    subject_name VARCHAR(150) NOT NULL,
    faculty_name VARCHAR(150) NOT NULL,
    semester VARCHAR(20) NOT NULL,
    section VARCHAR(20) NOT NULL,
    total_classes_planned INT DEFAULT 45,
    classes_completed INT DEFAULT 0,
    syllabus_completion_pct NUMERIC(5,2) DEFAULT 0.0,
    status VARCHAR(30) DEFAULT 'ON TRACK', -- ON TRACK, LAG, VERIFIED
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 10. TABLE: hod_research_contributions
-- Department publications, patents, conferences & funded grants
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hod_research_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_name VARCHAR(150) NOT NULL,
    title TEXT NOT NULL,
    contribution_type VARCHAR(50) NOT NULL, -- Publication, Conference, Patent, Funded Project
    publisher_or_agency VARCHAR(200),
    academic_year VARCHAR(20),
    funding_amount NUMERIC(12,2) DEFAULT 0.00,
    doi_or_patent_no VARCHAR(100),
    status VARCHAR(30) DEFAULT 'PUBLISHED',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES & PERFORMANCE OPTIMIZATION (HOD MODULE)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_hod_profiles_dept ON public.hod_profiles(dept_code);
CREATE INDEX IF NOT EXISTS idx_hod_leave_status ON public.hod_leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_hod_approvals_status ON public.hod_profile_approvals(status);
CREATE INDEX IF NOT EXISTS idx_hod_files_category ON public.hod_department_files(category);
CREATE INDEX IF NOT EXISTS idx_hod_events_status ON public.hod_events(status);
CREATE INDEX IF NOT EXISTS idx_hod_notif_status ON public.hod_notifications(status);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.hod_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hod_leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hod_profile_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hod_class_advisers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hod_mentors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hod_department_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hod_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hod_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hod_course_diaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hod_research_contributions ENABLE ROW LEVEL SECURITY;

-- Allow anon & authenticated full access for ERP application demo
CREATE POLICY "Allow public read-write for hod_profiles" ON public.hod_profiles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for hod_leave_requests" ON public.hod_leave_requests FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for hod_profile_approvals" ON public.hod_profile_approvals FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for hod_class_advisers" ON public.hod_class_advisers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for hod_mentors" ON public.hod_mentors FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for hod_department_files" ON public.hod_department_files FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for hod_events" ON public.hod_events FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for hod_notifications" ON public.hod_notifications FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for hod_course_diaries" ON public.hod_course_diaries FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for hod_research_contributions" ON public.hod_research_contributions FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- INITIAL SEED DATA FOR HOD MODULE
-- ============================================================================
INSERT INTO public.hod_profiles (
    employee_id, full_name, official_email, personal_email, phone, emergency_contact,
    dob, gender, blood_group, designation, department, dept_code, date_of_joining,
    teaching_experience_years, admin_experience_years, ug_degree, pg_degree, phd_degree,
    specialization, university, ORCID, scopus_id, google_scholar, research_gate,
    publication_count, conference_count, patents_count, funded_projects_amount, weekly_workload_hours
) VALUES (
    'KSRCE-FAC-0042', 'Dr. M. Govindharaj', 'hod.iot@ksrce.ac.in', 'govindharaj.m@gmail.com',
    '+91 98765 43210', '+91 97654 32109 (Spouse)', '1978-03-15', 'Male', 'O+',
    'Head of Department & Associate Professor', 'Department of Internet of Things (IoT)', 'IOT', '2010-07-01',
    16, 5, 'B.E. Electronics & Communication Engineering', 'M.E. Applied Electronics, Anna University',
    'Ph.D. IoT & Edge Computing, Anna University (2019)', 'IoT, Edge Computing, Embedded Systems, AI/ML in IoT',
    'Anna University, Chennai', '0000-0002-8765-4321', '57214789632', 'scholar.google.com/govindharaj', 'researchgate.net/profile/govindharaj',
    29, 14, 3, '₹ 24.5 Lakhs (DST, AICTE, TNSCST)', 18
) ON CONFLICT (employee_id) DO NOTHING;

INSERT INTO public.hod_leave_requests (display_id, faculty_name, leave_type, dates_description, reason, substitute_faculty, status) VALUES
('LV-2026-001', 'Prof. P. Ramya', 'Casual Leave (CL)', '21-Jul to 22-Jul (2 Days)', 'Presenting paper at IEEE IoT Conference, Chennai.', 'Prof. Muththukumaran', 'PENDING HOD'),
('LV-2026-002', 'Dr. S. Karthi', 'On Duty (OD)', '21-Jul (1 Day)', 'Anna University BoS Curriculum Meeting.', 'Dr. M. Govindharaj', 'APPROVED')
ON CONFLICT (display_id) DO NOTHING;

INSERT INTO public.hod_events (display_id, event_name, category, in_charge, venue, dates_description, registered_count, status) VALUES
('EVT-2026-04', 'National IoT Symposium 2026', 'National Symposium', 'Dr. M. Govindharaj', 'KSRCE Auditorium', '28-Jul to 29-Jul-2026', 180, 'UPCOMING'),
('EVT-2026-03', 'FDP on Embedded C Programming', 'Faculty Development Program', 'Dr. S. Karthi', 'Lab IoT-01', '25-Jul-2026', 24, 'UPCOMING')
ON CONFLICT (display_id) DO NOTHING;
