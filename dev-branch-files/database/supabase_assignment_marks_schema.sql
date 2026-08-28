-- ============================================================================
-- SUPABASE POSTGRESQL SCHEMA FOR FACULTY ASSIGNMENT MARKS
-- Project: KSRCE ERP Unified System
-- Schema: faculty
-- Table: faculty.assignment_marks
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS faculty;

-- Create assignment_marks table linked with faculty.assignments
CREATE TABLE IF NOT EXISTS faculty.assignment_marks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id VARCHAR(50) NOT NULL,
    reg_no VARCHAR(50) NOT NULL,
    name VARCHAR(150),
    department VARCHAR(50),
    section VARCHAR(20),
    year VARCHAR(20),
    subject_code VARCHAR(30),
    marks NUMERIC(5,2),
    assignment_file TEXT,
    status VARCHAR(30) DEFAULT 'Submitted',
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_assignment_student UNIQUE (assignment_id, reg_no)
);
