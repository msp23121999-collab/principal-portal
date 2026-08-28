-- ============================================================================
-- KSRCE ERP - CANONICAL POSTGRESQL SCHEMA (AWS RDS)
-- Single Source of Truth - Consolidates all Supabase schemas
-- Project: KSRCE ERP Unified System
-- Target: Amazon RDS PostgreSQL
-- Date: 2026-08-13
-- ============================================================================
-- 
-- MIGRATION NOTES:
-- This schema consolidates 110+ tables from 5 Supabase schemas:
--   - public (13 tables)
--   - student (50+ tables)
--   - faculty (30+ tables)
--   - admin (11+ tables)
--   - hod (6+ tables)
--
-- DEDUPLICATION: This schema resolves duplicate table definitions:
--   - student.students  ->  public.students (canonical)
--   - faculty.faculties  ->  public.faculties (canonical)
--   - Attendance tables consolidated to normalized form
--   - Timetables and marks deduplicated
--
-- RLS: Row Level Security policies DISABLED by default (will be re-enabled
--       after backend API validation layer is in place)
--
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA public;

-- ============================================================================
-- STEP 1: MASTER REFERENCE TABLES (Universal Master Data)
-- ============================================================================

-- 1.1 Departments Master
CREATE TABLE public.departments (
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
CREATE INDEX idx_departments_code ON public.departments(code);
CREATE INDEX idx_departments_status ON public.departments(status);

-- 1.2 Academic Years / Cycles
CREATE TABLE public.academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150),
    start_date DATE,
    end_date DATE,
    is_current BOOLEAN DEFAULT FALSE,
    status VARCHAR(30) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_academic_years_current ON public.academic_years(is_current);
CREATE INDEX idx_academic_years_status ON public.academic_years(status);

-- 1.3 Universal User Directory (All Roles)
-- Central registry for Students, Faculty, HOD, Admin, etc.
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE, -- References external auth system (Cognito)
    user_code VARCHAR(30) UNIQUE,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(30),
    role VARCHAR(50) NOT NULL, -- STUDENT, FACULTY, HOD, ADMIN, SUPER_ADMIN, DEAN, PRINCIPAL
    
    -- Employee/Student ID Reference
    employee_id VARCHAR(50),
    student_id VARCHAR(50),
    
    -- Department Association
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    
    -- Personal Info (Optional, depending on role)
    gender VARCHAR(20),
    date_of_birth DATE,
    blood_group VARCHAR(10),
    
    -- Status & Audit
    status VARCHAR(30) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_department_id ON public.users(department_id);
CREATE INDEX idx_users_status ON public.users(status);

-- 1.4 Subjects Master Catalog
CREATE TABLE public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    course_code VARCHAR(30),
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    subject_type VARCHAR(30) DEFAULT 'Theory', -- Theory, Lab, Elective, Practical
    semester VARCHAR(20),
    credits INT DEFAULT 3,
    status VARCHAR(30) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_subjects_code ON public.subjects(subject_code);
CREATE INDEX idx_subjects_department_id ON public.subjects(department_id);
CREATE INDEX idx_subjects_status ON public.subjects(status);

-- 1.5 Class Sections
CREATE TABLE public.class_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL, -- E.g., "Year 2 • Section A"
    department_id UUID REFERENCES public.departments(id) ON DELETE CASCADE,
    semester VARCHAR(20) NOT NULL,
    section VARCHAR(10) NOT NULL,
    academic_year_id UUID REFERENCES public.academic_years(id) ON DELETE SET NULL,
    strength INT DEFAULT 60,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(department_id, semester, section, academic_year_id)
);
CREATE INDEX idx_class_sections_department_id ON public.class_sections(department_id);
CREATE INDEX idx_class_sections_academic_year_id ON public.class_sections(academic_year_id);

-- ============================================================================
-- STEP 2: CORE OPERATIONAL TABLES
-- ============================================================================

-- 2.1 Students (Consolidated from student.students)
CREATE TABLE public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Student Identifiers
    student_id VARCHAR(50) NOT NULL UNIQUE,
    roll_number VARCHAR(50) NOT NULL UNIQUE,
    register_number VARCHAR(50),
    
    -- Personal Information
    full_name VARCHAR(150) NOT NULL,
    gender VARCHAR(20),
    date_of_birth DATE,
    blood_group VARCHAR(10),
    
    -- Contact Information
    institute_email VARCHAR(150),
    personal_email VARCHAR(150),
    mobile_number VARCHAR(30),
    address TEXT,
    
    -- Academic Information
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    programme VARCHAR(50),
    regulation_year VARCHAR(20),
    batch VARCHAR(20),
    year_of_study VARCHAR(20),
    current_semester INT,
    section VARCHAR(10),
    
    -- Academic Performance
    cgpa NUMERIC(4,2) DEFAULT 0.00,
    attendance_percentage NUMERIC(5,2) DEFAULT 100.00,
    earned_credits INT DEFAULT 0,
    total_credits INT DEFAULT 160,
    
    -- Financial Information
    pending_fees_total NUMERIC(12,2) DEFAULT 0.00,
    
    -- Admission Details
    date_of_admission DATE,
    admission_type VARCHAR(50) DEFAULT 'Regular',
    scholar_type VARCHAR(50) DEFAULT 'Dayscholar',
    
    -- Status
    status VARCHAR(30) DEFAULT 'Continuing', -- Continuing, Graduated, Discontinued
    class_advisor_id VARCHAR(50),
    class_advisor_name VARCHAR(150),
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_students_student_id ON public.students(student_id);
CREATE INDEX idx_students_roll_number ON public.students(roll_number);
CREATE INDEX idx_students_register_number ON public.students(register_number);
CREATE INDEX idx_students_department_id ON public.students(department_id);
CREATE INDEX idx_students_status ON public.students(status);
CREATE INDEX idx_students_user_id ON public.students(user_id);

-- 2.2 Faculties (Consolidated from faculty.faculties)
CREATE TABLE public.faculties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Employee Information
    employee_id VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    
    -- Professional Details
    designation VARCHAR(100) NOT NULL,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    
    -- Role and Assignments
    role VARCHAR(50) DEFAULT 'Faculty',
    assigned_subjects TEXT[],
    
    -- Contact Information
    institute_email VARCHAR(150) NOT NULL UNIQUE,
    personal_email VARCHAR(150),
    phone VARCHAR(30),
    
    -- Academic Details
    qualification VARCHAR(255),
    experience_years INT DEFAULT 0,
    specialization TEXT,
    
    -- Research & Publications
    research_interests TEXT,
    publication_count INT DEFAULT 0,
    conference_count INT DEFAULT 0,
    
    -- Photo/Profile
    photo_url TEXT,
    
    -- Status
    status VARCHAR(30) DEFAULT 'Active',
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_faculties_employee_id ON public.faculties(employee_id);
CREATE INDEX idx_faculties_department_id ON public.faculties(department_id);
CREATE INDEX idx_faculties_user_id ON public.faculties(user_id);
CREATE INDEX idx_faculties_status ON public.faculties(status);

-- 2.3 Faculty Course Allocations
CREATE TABLE public.faculty_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID NOT NULL REFERENCES public.faculties(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    class_section_id UUID NOT NULL REFERENCES public.class_sections(id) ON DELETE CASCADE,
    academic_year_id UUID REFERENCES public.academic_years(id) ON DELETE SET NULL,
    
    -- Allocation Details
    semester VARCHAR(20),
    regulation_year VARCHAR(20),
    
    -- Status
    status VARCHAR(30) DEFAULT 'Active',
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(faculty_id, subject_id, class_section_id, academic_year_id)
);
CREATE INDEX idx_faculty_allocations_faculty_id ON public.faculty_allocations(faculty_id);
CREATE INDEX idx_faculty_allocations_subject_id ON public.faculty_allocations(subject_id);
CREATE INDEX idx_faculty_allocations_class_section_id ON public.faculty_allocations(class_section_id);

-- ============================================================================
-- STEP 3: ATTENDANCE MANAGEMENT (Normalized)
-- ============================================================================

-- 3.1 Attendance Sessions (Faculty creates session)
CREATE TABLE public.attendance_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID NOT NULL REFERENCES public.faculties(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    class_section_id UUID REFERENCES public.class_sections(id) ON DELETE SET NULL,
    
    -- Session Details
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    period VARCHAR(20), -- Period 1, 2, 3, etc.
    day_of_week VARCHAR(20),
    time_slot VARCHAR(50),
    
    -- Content
    topic_covered TEXT,
    remarks TEXT,
    
    -- Status
    status VARCHAR(30) DEFAULT 'Completed', -- Scheduled, InProgress, Completed, Cancelled
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_attendance_sessions_faculty_id ON public.attendance_sessions(faculty_id);
CREATE INDEX idx_attendance_sessions_session_date ON public.attendance_sessions(session_date);
CREATE INDEX idx_attendance_sessions_class_section_id ON public.attendance_sessions(class_section_id);

-- 3.2 Attendance Records (Per student per session)
CREATE TABLE public.attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.attendance_sessions(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    
    -- Attendance Status
    status VARCHAR(20) NOT NULL, -- PRESENT, ABSENT, OD (On Duty), LATE, MEDICAL
    
    -- Additional Info
    remarks TEXT,
    recorded_by_faculty_id UUID REFERENCES public.faculties(id) ON DELETE SET NULL,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(session_id, student_id)
);
CREATE INDEX idx_attendance_records_session_id ON public.attendance_records(session_id);
CREATE INDEX idx_attendance_records_student_id ON public.attendance_records(student_id);
CREATE INDEX idx_attendance_records_status ON public.attendance_records(status);

-- 3.3 Cumulative Attendance Percentage (Denormalized for performance)
CREATE TABLE public.student_attendance_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL UNIQUE REFERENCES public.students(id) ON DELETE CASCADE,
    
    -- Summary Statistics
    total_sessions INT DEFAULT 0,
    present_count INT DEFAULT 0,
    absent_count INT DEFAULT 0,
    od_count INT DEFAULT 0,
    late_count INT DEFAULT 0,
    medical_count INT DEFAULT 0,
    
    -- Calculated Percentage
    attendance_percentage NUMERIC(5,2) DEFAULT 100.00,
    
    -- Metadata
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_student_attendance_summary_student_id ON public.student_attendance_summary(student_id);

-- ============================================================================
-- STEP 4: MARKS & ASSESSMENT
-- ============================================================================

-- 4.1 Student Marks (Consolidated from faculty.marks and public.student_marks)
CREATE TABLE public.student_marks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    faculty_id UUID REFERENCES public.faculties(id) ON DELETE SET NULL,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    class_section_id UUID REFERENCES public.class_sections(id) ON DELETE SET NULL,
    academic_year_id UUID REFERENCES public.academic_years(id) ON DELETE SET NULL,
    
    -- Assessment Components
    assessment_name VARCHAR(100) NOT NULL, -- CIA 1, CIA 2, Assignment, EndSem, Lab
    
    -- Scores
    cia_score NUMERIC(5,2) DEFAULT 0.0,
    assignment_score NUMERIC(5,2) DEFAULT 0.0,
    lab_score NUMERIC(5,2) DEFAULT 0.0,
    project_score NUMERIC(5,2) DEFAULT 0.0,
    end_semester_score NUMERIC(5,2) DEFAULT 0.0,
    total_score NUMERIC(6,2) DEFAULT 0.0,
    
    -- Grade
    grade VARCHAR(5),
    grade_points NUMERIC(3,2),
    
    -- Additional Info
    remarks TEXT,
    status VARCHAR(30) DEFAULT 'Draft', -- Draft, Submitted, Approved, Published
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ
);
CREATE INDEX idx_student_marks_student_id ON public.student_marks(student_id);
CREATE INDEX idx_student_marks_faculty_id ON public.student_marks(faculty_id);
CREATE INDEX idx_student_marks_subject_id ON public.student_marks(subject_id);
CREATE INDEX idx_student_marks_status ON public.student_marks(status);
CREATE UNIQUE INDEX idx_student_marks_unique ON public.student_marks(student_id, subject_id, assessment_name, academic_year_id);

-- 4.2 Assignment Marks (Consolidated from faculty.assignment_marks)
CREATE TABLE public.assignment_marks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL,
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    
    -- Assignment Submission
    marks NUMERIC(5,2),
    submission_file_url TEXT,
    submitted_at TIMESTAMPTZ,
    
    -- Grading
    marks_awarded NUMERIC(5,2) DEFAULT 0.0,
    feedback TEXT,
    graded_at TIMESTAMPTZ,
    
    -- Status
    status VARCHAR(30) DEFAULT 'Pending', -- Pending, Submitted, Graded, Returned
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(assignment_id, student_id)
);
CREATE INDEX idx_assignment_marks_student_id ON public.assignment_marks(student_id);
CREATE INDEX idx_assignment_marks_assignment_id ON public.assignment_marks(assignment_id);

-- ============================================================================
-- STEP 5: TIMETABLES
-- ============================================================================

CREATE TABLE public.timetables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID REFERENCES public.faculties(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    class_section_id UUID REFERENCES public.class_sections(id) ON DELETE CASCADE,
    
    -- Timetable Entry
    day_of_week VARCHAR(20) NOT NULL, -- Monday, Tuesday, etc.
    period VARCHAR(20) NOT NULL,
    time_slot VARCHAR(50), -- HH:MM - HH:MM
    
    -- Location
    room_no VARCHAR(50),
    building VARCHAR(50),
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(faculty_id, class_section_id, day_of_week, period)
);
CREATE INDEX idx_timetables_faculty_id ON public.timetables(faculty_id);
CREATE INDEX idx_timetables_class_section_id ON public.timetables(class_section_id);
CREATE INDEX idx_timetables_subject_id ON public.timetables(subject_id);

-- ============================================================================
-- STEP 6: ASSIGNMENTS & QUESTION BANKS
-- ============================================================================

-- 6.1 Assignments
CREATE TABLE public.assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID NOT NULL REFERENCES public.faculties(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    class_section_id UUID REFERENCES public.class_sections(id) ON DELETE SET NULL,
    
    -- Assignment Details
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assignment_type VARCHAR(50) DEFAULT 'Programming', -- Programming, Theory, Research, etc.
    
    -- Dates
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    
    -- File
    assignment_file_url TEXT,
    
    -- Grading
    max_marks INT DEFAULT 10,
    
    -- Status
    status VARCHAR(30) DEFAULT 'Published', -- Draft, Published, Closed, Archived
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_assignments_faculty_id ON public.assignments(faculty_id);
CREATE INDEX idx_assignments_subject_id ON public.assignments(subject_id);
CREATE INDEX idx_assignments_due_date ON public.assignments(due_date);

-- 6.2 Question Bank
CREATE TABLE public.question_banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID NOT NULL REFERENCES public.faculties(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    
    -- Question Details
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) DEFAULT 'MCQ', -- MCQ, Essay, TrueFalse, ShortAnswer
    difficulty_level VARCHAR(20) DEFAULT 'Medium', -- Easy, Medium, Hard
    
    -- Answers & Solutions
    correct_answer TEXT,
    explanation TEXT,
    
    -- Marks
    marks INT DEFAULT 1,
    
    -- Status
    status VARCHAR(30) DEFAULT 'Active',
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_question_banks_faculty_id ON public.question_banks(faculty_id);
CREATE INDEX idx_question_banks_subject_id ON public.question_banks(subject_id);

-- ============================================================================
-- STEP 7: FEES & FINANCIAL
-- ============================================================================

-- 7.1 Student Financials
CREATE TABLE public.student_financials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id VARCHAR(50) NOT NULL, -- Can be student_id or register_no
    
    -- Fee Details
    fee_head VARCHAR(100) NOT NULL, -- Tuition, Lab, Hostel, Transport, etc.
    total_amount NUMERIC(12,2) NOT NULL,
    paid_amount NUMERIC(12,2) DEFAULT 0.00,
    balance_amount NUMERIC(12,2) DEFAULT 0.00,
    
    -- Payment
    payment_status VARCHAR(30) DEFAULT 'Unpaid', -- Unpaid, Partial, Paid
    receipt_no VARCHAR(50),
    receipt_url TEXT,
    payment_date DATE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_student_financials_student_id ON public.student_financials(student_id);
CREATE INDEX idx_student_financials_payment_status ON public.student_financials(payment_status);

-- 7.2 Fees Master
CREATE TABLE public.fees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id VARCHAR(50) NOT NULL,
    
    -- Fee Information
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) DEFAULT 'Tuition', -- Tuition, Lab, Hostel, Transport
    amount NUMERIC(12,2) NOT NULL,
    
    -- Dates
    due_date DATE,
    
    -- Payment
    is_paid BOOLEAN DEFAULT FALSE,
    payment_date DATE,
    receipt_no VARCHAR(50),
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_fees_student_id ON public.fees(student_id);
CREATE INDEX idx_fees_is_paid ON public.fees(is_paid);

-- ============================================================================
-- STEP 8: CERTIFICATES, DOCUMENTS & FILES
-- ============================================================================

-- 8.1 Student Documents
CREATE TABLE public.student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id VARCHAR(50) NOT NULL,
    
    -- Document Details
    document_name VARCHAR(150) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL, -- S3 URL
    
    -- Verification
    verification_status VARCHAR(30) DEFAULT 'Pending', -- Pending, Verified, Rejected
    verified_by VARCHAR(150),
    verification_date TIMESTAMPTZ,
    
    -- Metadata
    file_size VARCHAR(50),
    mime_type VARCHAR(50),
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_student_documents_student_id ON public.student_documents(student_id);
CREATE INDEX idx_student_documents_verification_status ON public.student_documents(verification_status);

-- 8.2 Certificate Requests
CREATE TABLE public.certificate_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id VARCHAR(50) NOT NULL,
    
    -- Request Details
    certificate_type VARCHAR(50) NOT NULL, -- Bonafide, Conduct, Transfer, CourseCompletion
    reason TEXT NOT NULL,
    
    -- Request Tracking
    request_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(30) DEFAULT 'Pending', -- Pending, Approved, Generated, Delivered
    
    -- Generated Certificate
    download_url TEXT,
    generated_at TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_certificate_requests_student_id ON public.certificate_requests(student_id);
CREATE INDEX idx_certificate_requests_status ON public.certificate_requests(status);

-- 8.3 Achievements
CREATE TABLE public.achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id VARCHAR(50) NOT NULL,
    
    -- Achievement Details
    title VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL, -- Academic, Sports, Cultural, Technical
    organized_by VARCHAR(150),
    achievement_date DATE,
    
    -- Description
    description TEXT,
    
    -- Verification
    status VARCHAR(30) DEFAULT 'Pending', -- Pending, Verified, Approved
    points INT DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_achievements_student_id ON public.achievements(student_id);
CREATE INDEX idx_achievements_status ON public.achievements(status);

-- ============================================================================
-- STEP 9: GRIEVANCES, LEAVES, REQUESTS
-- ============================================================================

-- 9.1 Student Grievances
CREATE TABLE public.grievances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id VARCHAR(50) NOT NULL,
    
    -- Grievance Details
    category VARCHAR(50) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    
    -- Status & Response
    status VARCHAR(30) DEFAULT 'Pending', -- Pending, UnderReview, Resolved, Closed
    response TEXT,
    resolved_date TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_grievances_student_id ON public.grievances(student_id);
CREATE INDEX idx_grievances_status ON public.grievances(status);

-- 9.2 Hostel Outing Requests
CREATE TABLE public.hostel_outing_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id VARCHAR(50) NOT NULL,
    
    -- Outing Details
    purpose VARCHAR(255) NOT NULL,
    destination VARCHAR(150),
    out_date DATE,
    out_time TIMESTAMPTZ,
    in_time TIMESTAMPTZ,
    
    -- Status
    status VARCHAR(30) DEFAULT 'Pending', -- Pending, Approved, Rejected
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_hostel_outing_requests_student_id ON public.hostel_outing_requests(student_id);
CREATE INDEX idx_hostel_outing_requests_status ON public.hostel_outing_requests(status);

-- 9.3 Faculty Leave Applications
CREATE TABLE public.leave_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID NOT NULL REFERENCES public.faculties(id) ON DELETE CASCADE,
    
    -- Leave Details
    leave_type VARCHAR(50) NOT NULL, -- CL (Casual), SL (Sick), OD (On Duty), EL (Earned)
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days INT NOT NULL,
    
    -- Reason & Details
    reason TEXT NOT NULL,
    substitute_faculty_id UUID REFERENCES public.faculties(id) ON DELETE SET NULL,
    
    -- Approval Status
    status VARCHAR(30) DEFAULT 'PendingHOD', -- PendingHOD, ApprovedHOD, RejectedHOD
    hod_remarks TEXT,
    hod_response_date TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_leave_applications_faculty_id ON public.leave_applications(faculty_id);
CREATE INDEX idx_leave_applications_status ON public.leave_applications(status);
CREATE INDEX idx_leave_applications_start_date ON public.leave_applications(start_date);

-- ============================================================================
-- STEP 10: PLACEMENTS & EXTRA COURSES
-- ============================================================================

-- 10.1 Placements
CREATE TABLE public.placements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Company & Position
    company_name VARCHAR(150) NOT NULL,
    job_title VARCHAR(150) NOT NULL,
    job_description TEXT,
    
    -- Compensation
    ctc VARCHAR(50),
    package_details TEXT,
    
    -- Requirements
    min_cgpa NUMERIC(4,2) DEFAULT 6.00,
    
    -- Recruitment Timeline
    registration_deadline DATE,
    interview_date DATE,
    
    -- Status
    status VARCHAR(30) DEFAULT 'Upcoming', -- Upcoming, Ongoing, Completed, Cancelled
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_placements_status ON public.placements(status);
CREATE INDEX idx_placements_registration_deadline ON public.placements(registration_deadline);

-- 10.2 Placement Applications
CREATE TABLE public.placement_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    placement_id UUID NOT NULL REFERENCES public.placements(id) ON DELETE CASCADE,
    
    -- Application Details
    status VARCHAR(30) DEFAULT 'Applied', -- Applied, Shortlisted, Rejected, Offered, Accepted
    
    -- Interview Results
    written_test_score NUMERIC(5,2),
    technical_interview_score NUMERIC(5,2),
    hr_interview_score NUMERIC(5,2),
    overall_result VARCHAR(30), -- Pass, Fail
    
    -- Offer & Acceptance
    offer_letter_url TEXT,
    acceptance_date TIMESTAMPTZ,
    
    -- Metadata
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, placement_id)
);
CREATE INDEX idx_placement_applications_student_id ON public.placement_applications(student_id);
CREATE INDEX idx_placement_applications_placement_id ON public.placement_applications(placement_id);
CREATE INDEX idx_placement_applications_status ON public.placement_applications(status);

-- 10.3 Extra Courses
CREATE TABLE public.extra_courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Course Details
    title VARCHAR(255) NOT NULL,
    description TEXT,
    provider VARCHAR(150), -- Coursera, Udemy, etc.
    
    -- Course Info
    duration VARCHAR(50),
    category VARCHAR(50), -- Programming, DataScience, WebDevelopment, etc.
    
    -- Status
    status VARCHAR(30) DEFAULT 'Available',
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10.4 Extra Course Enrollments
CREATE TABLE public.extra_course_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id VARCHAR(50) NOT NULL,
    extra_course_id UUID NOT NULL REFERENCES public.extra_courses(id) ON DELETE CASCADE,
    
    -- Enrollment Status
    status VARCHAR(30) DEFAULT 'Enrolled', -- Enrolled, InProgress, Completed, Dropped
    enrollment_date TIMESTAMPTZ DEFAULT NOW(),
    completion_date TIMESTAMPTZ,
    
    -- Certificate
    certificate_url TEXT,
    score NUMERIC(5,2),
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, extra_course_id)
);
CREATE INDEX idx_extra_course_enrollments_student_id ON public.extra_course_enrollments(student_id);

-- ============================================================================
-- STEP 11: NOTIFICATIONS & COMMUNICATIONS
-- ============================================================================

-- 11.1 Notifications
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id VARCHAR(50), -- Can be user_id or student_id/emp_id
    recipient_type VARCHAR(30), -- STUDENT, FACULTY, HOD, ADMIN
    
    -- Notification Details
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'General', -- Academic, Admission, Financial, Administrative
    
    -- Metadata
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notifications_recipient_id ON public.notifications(recipient_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);

-- ============================================================================
-- STEP 12: NOTICE BOARD & ANNOUNCEMENTS
-- ============================================================================

-- 12.1 Notice Board Posts
CREATE TABLE public.notice_board_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Post Details
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'General', -- Academic, Administrative, EventManagement
    
    -- Post Metadata
    author_name VARCHAR(150) DEFAULT 'Admin',
    author_id UUID,
    post_date DATE DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    -- Status
    status VARCHAR(30) DEFAULT 'Published', -- Draft, Published, Archived
    
    -- Attachments
    attachment_url TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notice_board_posts_category ON public.notice_board_posts(category);
CREATE INDEX idx_notice_board_posts_status ON public.notice_board_posts(status);

-- 12.2 Notice Bookmarks
CREATE TABLE public.notice_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id VARCHAR(50) NOT NULL,
    notice_id UUID NOT NULL REFERENCES public.notice_board_posts(id) ON DELETE CASCADE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, notice_id)
);
CREATE INDEX idx_notice_bookmarks_student_id ON public.notice_bookmarks(student_id);

-- ============================================================================
-- STEP 13: ACADEMIC CALENDAR & EVENTS
-- ============================================================================

CREATE TABLE public.academic_calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Event Details
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    
    -- Event Type
    event_type VARCHAR(50) DEFAULT 'Academic', -- Academic, Exam, Holiday, Symposium, Workshop
    scope VARCHAR(30) DEFAULT 'All', -- All, Faculty, Student, HOD, Admin
    
    -- Timing
    start_time TIME,
    end_time TIME,
    
    -- Location
    location VARCHAR(150),
    
    -- Metadata
    color_code VARCHAR(20) DEFAULT '#2563EB',
    owner_role VARCHAR(30) DEFAULT 'Admin',
    created_by UUID,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_academic_calendar_events_event_date ON public.academic_calendar_events(event_date);
CREATE INDEX idx_academic_calendar_events_event_type ON public.academic_calendar_events(event_type);

-- ============================================================================
-- STEP 14: SYSTEM & ADMIN TABLES
-- ============================================================================

-- 14.1 System Settings
CREATE TABLE public.system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT,
    data_type VARCHAR(30), -- STRING, INT, BOOLEAN, JSON
    description TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_system_settings_key ON public.system_settings(setting_key);

-- 14.2 Audit Logs
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Actor
    actor_id UUID,
    actor_name VARCHAR(150),
    actor_role VARCHAR(50),
    
    -- Action
    action VARCHAR(50), -- CREATE, READ, UPDATE, DELETE
    entity_type VARCHAR(50), -- Students, Marks, Attendance, etc.
    entity_id UUID,
    
    -- Changes
    old_value JSONB,
    new_value JSONB,
    change_summary TEXT,
    
    -- Audit Info
    ip_address VARCHAR(50),
    user_agent TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_audit_logs_actor_id ON public.audit_logs(actor_id);
CREATE INDEX idx_audit_logs_entity_type ON public.audit_logs(entity_type);
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs(created_at);

-- 14.3 File Metadata (For S3 integration)
CREATE TABLE public.file_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- File Info
    file_name VARCHAR(255) NOT NULL,
    file_size INT,
    mime_type VARCHAR(50),
    
    -- S3 Details
    s3_bucket VARCHAR(100) NOT NULL,
    s3_key VARCHAR(500) NOT NULL, -- Path in S3
    s3_url TEXT NOT NULL,
    
    -- Upload Details
    uploaded_by_id UUID,
    uploaded_by_name VARCHAR(150),
    
    -- Access Control
    access_level VARCHAR(30) DEFAULT 'Private', -- Private, Internal, Public
    owner_id VARCHAR(50),
    owner_type VARCHAR(30), -- Student, Faculty, Admin
    
    -- Lifecycle
    is_active BOOLEAN DEFAULT TRUE,
    delete_requested BOOLEAN DEFAULT FALSE,
    delete_requested_date TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    accessed_at TIMESTAMPTZ
);
CREATE INDEX idx_file_metadata_owner_id ON public.file_metadata(owner_id);
CREATE INDEX idx_file_metadata_created_at ON public.file_metadata(created_at);

-- ============================================================================
-- STEP 15: HOD & ADMIN SPECIFIC TABLES
-- ============================================================================

-- 15.1 HOD Profiles (Extended faculty info)
CREATE TABLE public.hod_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID NOT NULL UNIQUE REFERENCES public.faculties(id) ON DELETE CASCADE,
    
    -- HOD Role Info
    start_date DATE,
    end_date DATE,
    
    -- Extended Profile
    office_location VARCHAR(100),
    office_phone VARCHAR(30),
    research_specialization TEXT,
    publication_count INT DEFAULT 0,
    orcid VARCHAR(50),
    
    -- Department Management
    department_strength INT,
    last_performance_review DATE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15.2 Department Files
CREATE TABLE public.department_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- File Details
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL, -- S3 URL
    file_size VARCHAR(50),
    
    -- Classification
    category VARCHAR(100) NOT NULL, -- Syllabus, NAAC, NBA, CurriculumDocs, etc.
    subcategory VARCHAR(100),
    
    -- Owner
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    uploaded_by_id UUID,
    uploaded_by_name VARCHAR(150),
    
    -- Versioning
    version VARCHAR(20) DEFAULT '1.0',
    is_current BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_department_files_department_id ON public.department_files(department_id);
CREATE INDEX idx_department_files_category ON public.department_files(category);

-- ============================================================================
-- STEP 16: STORED PROCEDURES & FUNCTIONS
-- ============================================================================

-- 16.1 Function: Update Daily Cumulative Attendance Percentage
-- (Replaces Supabase pg_cron job)
CREATE OR REPLACE FUNCTION public.calculate_student_attendance_percentage(
    p_student_id UUID
)
RETURNS void AS $$
DECLARE
    v_total_sessions INT;
    v_present_count INT;
    v_od_count INT;
    v_absent_count INT;
    v_late_count INT;
    v_medical_count INT;
    v_attendance_pct NUMERIC;
BEGIN
    -- Count attendance records for the student
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'PRESENT'),
        COUNT(*) FILTER (WHERE status = 'OD'),
        COUNT(*) FILTER (WHERE status = 'ABSENT'),
        COUNT(*) FILTER (WHERE status = 'LATE'),
        COUNT(*) FILTER (WHERE status = 'MEDICAL')
    INTO v_total_sessions, v_present_count, v_od_count, v_absent_count, v_late_count, v_medical_count
    FROM public.attendance_records
    WHERE student_id = p_student_id;
    
    -- Calculate attendance percentage (Present + OD considered as present)
    IF v_total_sessions > 0 THEN
        v_attendance_pct := ((v_present_count + v_od_count)::NUMERIC / v_total_sessions::NUMERIC) * 100.0;
    ELSE
        v_attendance_pct := 100.0;
    END IF;
    
    -- Update student record
    UPDATE public.students
    SET attendance_percentage = v_attendance_pct,
        updated_at = NOW()
    WHERE id = p_student_id;
    
    -- Update summary table
    INSERT INTO public.student_attendance_summary (
        student_id, total_sessions, present_count, absent_count, 
        od_count, late_count, medical_count, attendance_percentage
    ) VALUES (
        p_student_id, v_total_sessions, v_present_count, v_absent_count,
        v_od_count, v_late_count, v_medical_count, v_attendance_pct
    )
    ON CONFLICT (student_id) DO UPDATE SET
        total_sessions = v_total_sessions,
        present_count = v_present_count,
        absent_count = v_absent_count,
        od_count = v_od_count,
        late_count = v_late_count,
        medical_count = v_medical_count,
        attendance_percentage = v_attendance_pct,
        last_updated = NOW();
        
END;
$$ LANGUAGE plpgsql;

-- 16.2 Procedure: Update All Student Attendance (Batch Operation)
-- Called by Lambda function at 5 PM IST daily
CREATE OR REPLACE PROCEDURE public.update_all_students_attendance()
AS $$
DECLARE
    v_student_id UUID;
BEGIN
    -- Iterate through all active students
    FOR v_student_id IN SELECT id FROM public.students WHERE status = 'Continuing'
    LOOP
        PERFORM public.calculate_student_attendance_percentage(v_student_id);
    END LOOP;
    
    COMMIT;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 17: VIEWS (For compatibility and convenience queries)
-- ============================================================================

-- 17.1 Student with Department Info
CREATE OR REPLACE VIEW public.vw_students_with_department AS
SELECT 
    s.id,
    s.student_id,
    s.roll_number,
    s.full_name,
    s.cgpa,
    s.attendance_percentage,
    d.code AS department_code,
    d.name AS department_name,
    s.programme,
    s.current_semester,
    s.status
FROM public.students s
LEFT JOIN public.departments d ON s.department_id = d.id;

-- 17.2 Faculty Workload View
CREATE OR REPLACE VIEW public.vw_faculty_workload AS
SELECT 
    f.id,
    f.employee_id,
    f.full_name,
    d.name AS department_name,
    COUNT(DISTINCT fa.subject_id) AS subjects_assigned,
    COUNT(DISTINCT fa.class_section_id) AS class_sections,
    f.status
FROM public.faculties f
LEFT JOIN public.departments d ON f.department_id = d.id
LEFT JOIN public.faculty_allocations fa ON f.id = fa.faculty_id
GROUP BY f.id, f.employee_id, f.full_name, d.name, f.status;

-- 17.3 Attendance Summary View
CREATE OR REPLACE VIEW public.vw_attendance_summary AS
SELECT 
    s.id,
    s.student_id,
    s.full_name,
    d.name AS department_name,
    s.attendance_percentage,
    sa.total_sessions,
    sa.present_count,
    sa.absent_count
FROM public.students s
LEFT JOIN public.departments d ON s.department_id = d.id
LEFT JOIN public.student_attendance_summary sa ON s.id = sa.student_id;

-- ============================================================================
-- STEP 18: INDEXES (Performance optimization)
-- ============================================================================
-- All indexes created inline with table definitions above

-- ============================================================================
-- STEP 19: CONSTRAINTS & TRIGGERS
-- ============================================================================

-- 19.1 Trigger: Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at column
DO $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT t.tablename FROM pg_tables t
        WHERE t.schemaname = 'public'
        AND EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = t.tablename
            AND column_name = 'updated_at'
        )
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS trg_set_updated_at_%s ON public.%I;
            CREATE TRIGGER trg_set_updated_at_%s BEFORE UPDATE ON public.%I
            FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();
        ', table_name, table_name, table_name, table_name);
    END LOOP;
END $$;

-- ============================================================================
-- STEP 20: ROW LEVEL SECURITY
-- ============================================================================
-- NOTE: RLS is DISABLED by default. Will be enabled after backend API
--       validation layer is in place.
--
-- Example policy (to be enabled later):
-- ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY students_own_records ON public.students
--     USING (auth.uid() = user_id)
--     WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- SCHEMA COMPLETION
-- ============================================================================

-- Summary statistics
DO $$
DECLARE
    table_count INT;
    view_count INT;
    function_count INT;
BEGIN
    SELECT COUNT(*) INTO table_count FROM information_schema.tables
    WHERE table_schema = 'public';
    
    SELECT COUNT(*) INTO view_count FROM information_schema.views
    WHERE table_schema = 'public';
    
    SELECT COUNT(*) INTO function_count FROM information_schema.routines
    WHERE routine_schema = 'public';
    
    RAISE NOTICE 'Schema created successfully!';
    RAISE NOTICE 'Tables: %', table_count;
    RAISE NOTICE 'Views: %', view_count;
    RAISE NOTICE 'Functions/Procedures: %', function_count;
END $$;

-- ============================================================================
-- END OF CANONICAL SCHEMA
-- ============================================================================
