-- ============================================================================
-- SUPABASE POSTGRESQL STORED PROCEDURE & DAILY CRON JOB (5:00 PM)
-- Project: KSRCE ERP Unified System
-- Schema: student
-- Table Source: student.attendance_table (or student.attendance)
-- Target Column: attendance_percentage IN student.student / student.students
-- ============================================================================

-- 1. Ensure student schema exists
CREATE SCHEMA IF NOT EXISTS student;

-- 2. Create student.attendance_table if not existing (or view alias)
CREATE TABLE IF NOT EXISTS student.attendance_table (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    reg_no VARCHAR(50) NOT NULL,
    roll_no VARCHAR(50),
    name VARCHAR(150),
    dept VARCHAR(50),
    section VARCHAR(20),
    year VARCHAR(20),
    p1 VARCHAR(10) DEFAULT '',
    p2 VARCHAR(10) DEFAULT '',
    p3 VARCHAR(10) DEFAULT '',
    p4 VARCHAR(10) DEFAULT '',
    p5 VARCHAR(10) DEFAULT '',
    p6 VARCHAR(10) DEFAULT '',
    p7 VARCHAR(10) DEFAULT '',
    attendance_percentage VARCHAR(20) DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Stored Procedure: student.update_daily_cumulative_attendance()
-- Calculates cumulative attendance percentage for all dates of each student
-- and updates the 'attendance_percentage' column in student.student everyday after 5 PM.
CREATE OR REPLACE FUNCTION student.update_daily_cumulative_attendance()
RETURNS void AS $$
DECLARE
    rec RECORD;
    t_marked INT;
    t_present INT;
    pct_str VARCHAR(20);
BEGIN
    -- Loop through each distinct student in attendance_table
    FOR rec IN 
        SELECT DISTINCT reg_no FROM student.attendance_table WHERE reg_no IS NOT NULL AND reg_no <> ''
    LOOP
        -- Calculate total marked periods and present/OD periods across ALL dates
        SELECT 
            COUNT(period_status) FILTER (WHERE period_status IS NOT NULL AND period_status <> ''),
            COUNT(period_status) FILTER (WHERE UPPER(period_status) IN ('P', 'OD'))
        INTO t_marked, t_present
        FROM (
            SELECT p1 AS period_status FROM student.attendance_table WHERE reg_no = rec.reg_no
            UNION ALL
            SELECT p2 FROM student.attendance_table WHERE reg_no = rec.reg_no
            UNION ALL
            SELECT p3 FROM student.attendance_table WHERE reg_no = rec.reg_no
            UNION ALL
            SELECT p4 FROM student.attendance_table WHERE reg_no = rec.reg_no
            UNION ALL
            SELECT p5 FROM student.attendance_table WHERE reg_no = rec.reg_no
            UNION ALL
            SELECT p6 FROM student.attendance_table WHERE reg_no = rec.reg_no
            UNION ALL
            SELECT p7 FROM student.attendance_table WHERE reg_no = rec.reg_no
        ) sub;

        -- Format percentage string (e.g. "88.5%")
        IF t_marked > 0 THEN
            pct_str := ROUND((t_present::NUMERIC / t_marked::NUMERIC) * 100.0, 1)::TEXT || '%';
        ELSE
            pct_str := '0.0%';
        END IF;

        -- Update attendance_percentage column in student.student / student.students
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'student' AND table_name = 'student') THEN
            UPDATE student.student 
            SET attendance_percentage = pct_str 
            WHERE reg_no = rec.reg_no OR register_no = rec.reg_no OR roll = rec.reg_no;
        END IF;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'student' AND table_name = 'students') THEN
            UPDATE student.students 
            SET attendance_percentage = pct_str 
            WHERE reg_no = rec.reg_no OR register_no = rec.reg_no OR roll = rec.reg_no;
        END IF;

    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 4. Enable pg_cron and schedule execution everyday after 5:00 PM (17:00 IST / UTC)
-- Run SQL command in Supabase SQL Editor:
-- SELECT cron.schedule('daily-student-attendance-update-5pm', '0 17 * * *', 'SELECT student.update_daily_cumulative_attendance();');
