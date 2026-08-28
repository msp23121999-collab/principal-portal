-- ============================================================================
-- SUPABASE POSTGRESQL SCHEMA FOR ADMIN MODULE
-- Project: KSRCE ERP Unified System
-- Module: Admin Portal & System Administration
-- Date: 2026-07-25
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- 1. TABLE: admin_users
-- Central User Registry across all roles (Students, Faculty, HOD, Registrar, Super Admin)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_code VARCHAR(30) UNIQUE, -- USR001, USR002, etc.
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    role VARCHAR(50) NOT NULL, -- Super Admin, Department HOD, Faculty, Student, Registrar
    department VARCHAR(100) NOT NULL,
    node VARCHAR(50) DEFAULT 'Active Node', -- Active Node, Inactive Node
    status VARCHAR(30) DEFAULT 'Active', -- Active, Inactive, Pending

    -- Student-specific attributes
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

-- ----------------------------------------------------------------------------
-- 2. TABLE: admin_departments
-- Department master setup & HOD mapping
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dept_code VARCHAR(20) NOT NULL UNIQUE, -- CSE, IT, ME, CE, ECE, EEE
    name VARCHAR(150) NOT NULL,
    hod_name VARCHAR(150),
    hod_user_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    intake_capacity INT DEFAULT 60,
    status VARCHAR(30) DEFAULT 'Active', -- Active, Inactive
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 3. TABLE: admin_courses
-- Degree courses offered under departments
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_code VARCHAR(30) NOT NULL UNIQUE, -- e.g. BTECH-CSE, MTECH-SE
    name VARCHAR(150) NOT NULL,
    department_code VARCHAR(20) NOT NULL,
    subjects_count INT DEFAULT 0,
    status VARCHAR(30) DEFAULT 'Active', -- Active, Inactive
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. TABLE: admin_subjects
-- Master subject catalog under courses
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_code VARCHAR(30) NOT NULL UNIQUE, -- CS-301, CS-391
    name VARCHAR(150) NOT NULL,
    course_code VARCHAR(30) REFERENCES public.admin_courses(course_code) ON DELETE CASCADE,
    subject_type VARCHAR(30) DEFAULT 'Theory', -- Theory, Lab, Elective
    credits INT DEFAULT 3,
    status VARCHAR(30) DEFAULT 'Active', -- Active, Inactive
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 5. TABLE: admin_regulations
-- Regulation schemes master (CBCS, NEP 2020)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_regulations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(30) NOT NULL UNIQUE, -- REG-2023, REG-2024-NEP
    scheme VARCHAR(150) NOT NULL, -- Choice Based Credit System, NEP Scheme
    passing_criteria VARCHAR(150) NOT NULL,
    total_credits INT DEFAULT 160,
    status VARCHAR(30) DEFAULT 'Active', -- Active, Archival
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 6. TABLE: admin_academic_cycles
-- Academic year & semester calendar configurations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_academic_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cycle_code VARCHAR(30) UNIQUE,
    name VARCHAR(150) NOT NULL, -- e.g. Academic Year 2026-27 (Fall)
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'Active', -- Active, Pending, Completed
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 7. TABLE: admin_role_permissions
-- RBAC Matrix per role and module
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name VARCHAR(50) NOT NULL, -- Super Admin, Principal Admin, Registrar, Department HOD, Faculty Staff, Student Node
    module_name VARCHAR(100) NOT NULL, -- User Management, Academic Config, Financial Records, Node Governance
    can_read BOOLEAN DEFAULT FALSE,
    can_write BOOLEAN DEFAULT FALSE,
    can_delete BOOLEAN DEFAULT FALSE,
    can_audit BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(role_name, module_name)
);

-- ----------------------------------------------------------------------------
-- 8. TABLE: admin_system_settings
-- System-wide administrative settings & portal parameters
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portal_title VARCHAR(150) DEFAULT 'CAMS Admin Portal',
    max_attachment_size_mb INT DEFAULT 10,
    dark_mode_enabled BOOLEAN DEFAULT FALSE,
    maintenance_mode BOOLEAN DEFAULT FALSE,
    allow_registration BOOLEAN DEFAULT TRUE,
    session_timeout_minutes INT DEFAULT 30,
    mfa_required BOOLEAN DEFAULT FALSE,
    api_gateway_key VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 9. TABLE: admin_audit_logs
-- System security & operational audit trails
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    log_code VARCHAR(30) UNIQUE,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    description TEXT NOT NULL,
    operator_name VARCHAR(150) NOT NULL,
    operator_user_id UUID,
    level VARCHAR(20) DEFAULT 'Info', -- Info, Warning, Critical
    ip_address VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 10. TABLE: admin_reports
-- System generated analytical reports (Attendance, Marks, Defaulters)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_code VARCHAR(30) NOT NULL UNIQUE, -- REP-992-01
    title VARCHAR(255) NOT NULL,
    category VARCHAR(50) DEFAULT 'General',
    format VARCHAR(20) DEFAULT 'PDF', -- PDF, Excel, CSV
    status VARCHAR(30) DEFAULT 'Completed', -- Completed, Processing, Failed
    file_url TEXT,
    generated_by VARCHAR(150),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 11. TABLE: admin_medical_alerts
-- Campus medical dashboard alerts & blood donation requests
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_medical_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_code VARCHAR(30) UNIQUE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    alert_date DATE DEFAULT CURRENT_DATE,
    blood_group_required VARCHAR(10),
    hospital_partner VARCHAR(150),
    status VARCHAR(30) DEFAULT 'Active', -- Active, Completed, Pending
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 12. TABLE: admin_events
-- Institutional events & campus activities
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_code VARCHAR(30) UNIQUE,
    title VARCHAR(255) NOT NULL,
    coordinator VARCHAR(150) NOT NULL,
    venue VARCHAR(150) NOT NULL,
    event_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'Active', -- Active, Pending, Completed
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 13. TABLE: admin_notification_configs
-- Gateway configurations for SMS, Email, and Push Notifications
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_notification_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_name VARCHAR(100) NOT NULL UNIQUE, -- Email Gateway, SMS Gateway, Push Notification
    provider VARCHAR(100) NOT NULL, -- AWS SES, Twilio, Firebase FCM
    is_enabled BOOLEAN DEFAULT TRUE,
    api_key VARCHAR(255),
    sender_id VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 14. TABLE: admin_backups
-- Automated & manual database snapshot logs
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_backups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    backup_name VARCHAR(150) NOT NULL,
    backup_type VARCHAR(50) DEFAULT 'Automated Daily', -- Full, Incremental, Automated Daily
    file_size VARCHAR(30),
    status VARCHAR(30) DEFAULT 'COMPLETED', -- COMPLETED, IN_PROGRESS, FAILED
    storage_path TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES & PERFORMANCE OPTIMIZATION (ADMIN MODULE)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON public.admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_users_dept ON public.admin_users(department);
CREATE INDEX IF NOT EXISTS idx_admin_users_status ON public.admin_users(status);
CREATE INDEX IF NOT EXISTS idx_admin_depts_code ON public.admin_departments(dept_code);
CREATE INDEX IF NOT EXISTS idx_admin_courses_dept ON public.admin_courses(department_code);
CREATE INDEX IF NOT EXISTS idx_admin_subjects_course ON public.admin_subjects(course_code);
CREATE INDEX IF NOT EXISTS idx_admin_audit_level ON public.admin_audit_logs(level);
CREATE INDEX IF NOT EXISTS idx_admin_medical_status ON public.admin_medical_alerts(status);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_regulations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_academic_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_medical_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_notification_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_backups ENABLE ROW LEVEL SECURITY;

-- Allow public read-write for ERP application demo
CREATE POLICY "Allow public access for admin_users" ON public.admin_users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_departments" ON public.admin_departments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_courses" ON public.admin_courses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_subjects" ON public.admin_subjects FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_regulations" ON public.admin_regulations FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_academic_cycles" ON public.admin_academic_cycles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_role_permissions" ON public.admin_role_permissions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_system_settings" ON public.admin_system_settings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_audit_logs" ON public.admin_audit_logs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_reports" ON public.admin_reports FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_medical_alerts" ON public.admin_medical_alerts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_events" ON public.admin_events FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_notification_configs" ON public.admin_notification_configs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access for admin_backups" ON public.admin_backups FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- INITIAL SEED DATA FOR ADMIN MODULE
-- ============================================================================
INSERT INTO public.admin_users (user_code, name, email, role, department, node, status) VALUES
('USR001', 'Dr. Suresh Kumar', 'suresh.kumar@campus.edu', 'Department HOD', 'Computer Science', 'Active Node', 'Active'),
('USR002', 'Prof. Anjali Sharma', 'anjali.sharma@campus.edu', 'Faculty', 'Information Technology', 'Active Node', 'Active'),
('USR004', 'Admin Staff', 'admin.staff@campus.edu', 'Registrar', 'Administration', 'Active Node', 'Active')
ON CONFLICT (email) DO NOTHING;

INSERT INTO public.admin_departments (dept_code, name, hod_name, intake_capacity, status) VALUES
('CSE', 'Computer Science & Engineering', 'Dr. Suresh Kumar', 120, 'Active'),
('IT', 'Information Technology', 'Prof. Anjali Sharma', 60, 'Active'),
('ME', 'Mechanical Engineering', 'Dr. Vikram Sen', 90, 'Active'),
('CE', 'Civil Engineering', 'Prof. Pooja Hegde', 60, 'Inactive')
ON CONFLICT (dept_code) DO NOTHING;

INSERT INTO public.admin_courses (course_code, name, department_code, subjects_count, status) VALUES
('BTECH-CSE', 'B.Tech in Computer Science', 'CSE', 40, 'Active'),
('BTECH-IT', 'B.Tech in Information Technology', 'IT', 38, 'Active'),
('MTECH-SE', 'M.Tech in Software Engineering', 'CSE', 18, 'Active')
ON CONFLICT (course_code) DO NOTHING;

INSERT INTO public.admin_regulations (code, scheme, passing_criteria, total_credits, status) VALUES
('REG-2023', 'Choice Based Credit System', '40% Marks per subject', 160, 'Active'),
('REG-2024-NEP', 'National Education Policy Scheme', 'Letter Grade D Minimum', 164, 'Active')
ON CONFLICT (code) DO NOTHING;
