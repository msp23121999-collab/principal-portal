student schema:

-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE student.students (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL UNIQUE,
  roll_no character varying NOT NULL UNIQUE,
  register_no character varying NOT NULL UNIQUE,
  application_no character varying,
  full_name character varying NOT NULL,
  gender character varying NOT NULL,
  dob date NOT NULL,
  blood_group character varying,
  photo_url text,
  nationality character varying DEFAULT 'INDIAN'::character varying,
  religion character varying,
  community character varying,
  caste character varying,
  mother_tongue character varying,
  aadhaar_no character varying,
  scholar_type character varying DEFAULT 'Dayscholar'::character varying,
  institute_email character varying NOT NULL UNIQUE,
  personal_email character varying,
  mobile_number character varying NOT NULL,
  address text,
  degree character varying NOT NULL,
  department character varying NOT NULL,
  regulation_year character varying NOT NULL,
  batch character varying NOT NULL,
  date_of_admission date,
  admission_type character varying DEFAULT 'Regular'::character varying,
  year_of_study character varying NOT NULL,
  semester integer NOT NULL,
  term_type character varying NOT NULL,
  section character varying NOT NULL,
  academic_year character varying NOT NULL,
  status character varying DEFAULT 'Continuing'::character varying,
  class_advisor character varying,
  cgpa numeric DEFAULT 0.00,
  attendance_percentage numeric DEFAULT 100.00,
  earned_credits integer DEFAULT 0,
  total_credits integer DEFAULT 160,
  pending_fees_total numeric DEFAULT 0.00,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  age integer,
  qr_code_id character varying,
  district character varying,
  state character varying,
  pincode character varying,
  admitted_type character varying DEFAULT 'Regular'::character varying,
  semester_type character varying DEFAULT 'ODD'::character varying,
  class_advisor_name character varying,
  class_advisor_id character varying,
  credits_earned integer DEFAULT 126,
  pending_fees numeric DEFAULT 0.00,
  CONSTRAINT students_pkey PRIMARY KEY (id)
);
CREATE TABLE student.student_family (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  relation character varying NOT NULL,
  full_name character varying NOT NULL,
  dob date,
  mobile_number character varying,
  email character varying,
  occupation character varying,
  annual_income character varying,
  aadhaar_no character varying,
  blood_group character varying,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_family_pkey PRIMARY KEY (id),
  CONSTRAINT student_family_student_id_fkey FOREIGN KEY (student_id) REFERENCES student.students(student_id)
);
CREATE TABLE student.student_documents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  document_name character varying NOT NULL,
  file_name character varying NOT NULL,
  file_url text NOT NULL,
  verification_status character varying DEFAULT 'Verified'::character varying,
  uploaded_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_documents_pkey PRIMARY KEY (id),
  CONSTRAINT student_documents_student_id_fkey FOREIGN KEY (student_id) REFERENCES student.students(student_id)
);
CREATE TABLE student.student_financials (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  fee_head character varying NOT NULL,
  total_amount numeric NOT NULL,
  paid_amount numeric DEFAULT 0.00,
  balance_amount numeric DEFAULT 0.00,
  payment_status character varying DEFAULT 'Unpaid'::character varying,
  receipt_no character varying,
  receipt_url text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_financials_pkey PRIMARY KEY (id),
  CONSTRAINT student_financials_student_id_fkey FOREIGN KEY (student_id) REFERENCES student.students(student_id)
);
CREATE TABLE student.student_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  title character varying NOT NULL,
  category character varying DEFAULT 'GENERAL'::character varying,
  description text,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_notifications_pkey PRIMARY KEY (id)
);
CREATE TABLE student.fees (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  title character varying NOT NULL,
  category character varying DEFAULT 'Tuition'::character varying,
  amount numeric NOT NULL,
  due_date date,
  is_paid boolean DEFAULT false,
  payment_date date,
  receipt_no character varying,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fees_pkey PRIMARY KEY (id)
);
CREATE TABLE student.hostel_outing_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  purpose character varying NOT NULL,
  destination character varying NOT NULL,
  out_time timestamp with time zone,
  in_time timestamp with time zone,
  out_date date,
  status character varying DEFAULT 'Pending'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT hostel_outing_requests_pkey PRIMARY KEY (id)
);
CREATE TABLE student.grievances (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  category character varying NOT NULL,
  subject character varying NOT NULL,
  description text NOT NULL,
  status character varying DEFAULT 'Pending'::character varying,
  response text DEFAULT 'Under review by student welfare committee.'::text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT grievances_pkey PRIMARY KEY (id)
);
CREATE TABLE student.certificate_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  certificate_type character varying NOT NULL,
  reason text NOT NULL,
  request_date date DEFAULT CURRENT_DATE,
  status character varying DEFAULT 'Pending'::character varying,
  download_url text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT certificate_requests_pkey PRIMARY KEY (id)
);
CREATE TABLE student.achievements (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  title character varying NOT NULL,
  category character varying NOT NULL,
  organized_by character varying,
  date character varying,
  description text,
  status character varying DEFAULT 'Verified'::character varying,
  points integer DEFAULT 100,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT achievements_pkey PRIMARY KEY (id)
);
CREATE TABLE student.extra_courses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title character varying NOT NULL,
  provider character varying,
  duration character varying,
  category character varying,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT extra_courses_pkey PRIMARY KEY (id)
);
CREATE TABLE student.extra_course_enrollments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  course_id uuid NOT NULL,
  status character varying DEFAULT 'Enrolled'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT extra_course_enrollments_pkey PRIMARY KEY (id),
  CONSTRAINT fk_enrollment_course FOREIGN KEY (course_id) REFERENCES student.extra_courses(id)
);
CREATE TABLE student.placements (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  company character varying NOT NULL,
  role character varying NOT NULL,
  package character varying,
  deadline date,
  min_cgpa numeric DEFAULT 6.00,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT placements_pkey PRIMARY KEY (id)
);
CREATE TABLE student.placement_applications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  placement_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT placement_applications_pkey PRIMARY KEY (id),
  CONSTRAINT fk_application_placement FOREIGN KEY (placement_id) REFERENCES student.placements(id)
);
CREATE TABLE student.notice_board_posts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title character varying NOT NULL,
  category character varying DEFAULT 'General'::character varying,
  author character varying DEFAULT 'Admin'::character varying,
  post_date date DEFAULT CURRENT_DATE,
  content text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notice_board_posts_pkey PRIMARY KEY (id)
);
CREATE TABLE student.notice_bookmarks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id character varying NOT NULL,
  notice_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notice_bookmarks_pkey PRIMARY KEY (id),
  CONSTRAINT fk_bookmark_notice FOREIGN KEY (notice_id) REFERENCES student.notice_board_posts(id)
);
CREATE TABLE student.attendance_table (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  date date NOT NULL,
  reg_no character varying NOT NULL,
  name character varying,
  dept character varying,
  section character varying,
  year character varying,
  p1 boolean,
  p2 boolean,
  p3 boolean,
  p4 boolean,
  p5 boolean,
  p6 boolean,
  p7 boolean,
  attendance_percentage numeric,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT attendance_table_pkey PRIMARY KEY (id)
);



---------------------------------------------------------------


Faculty Schema:

-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE faculty.faculties (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  employee_id character varying NOT NULL UNIQUE,
  department_id character varying NOT NULL,
  full_name character varying NOT NULL,
  designation character varying NOT NULL,
  role character varying NOT NULL,
  qualification character varying NOT NULL,
  experience character varying,
  photo_url text,
  research_interests text,
  email character varying NOT NULL UNIQUE,
  phone character varying NOT NULL,
  address text,
  department character varying NOT NULL,
  assigned_subjects ARRAY,
  status character varying DEFAULT 'Active'::character varying,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT faculties_pkey PRIMARY KEY (id)
);
CREATE TABLE faculty.faculty_course_allocations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  faculty_employee_id character varying NOT NULL,
  regulation_year character varying NOT NULL,
  course_code character varying NOT NULL,
  department character varying NOT NULL,
  section character varying NOT NULL,
  academic_year character varying NOT NULL,
  CONSTRAINT faculty_course_allocations_pkey PRIMARY KEY (id),
  CONSTRAINT fk_faculty_emp FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.timetables (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  faculty_employee_id character varying NOT NULL,
  regulation_year character varying NOT NULL,
  course_code character varying NOT NULL,
  day_of_week character varying NOT NULL,
  period_code character varying NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  subject_name character varying NOT NULL,
  department character varying NOT NULL,
  section character varying NOT NULL,
  room_number character varying NOT NULL,
  class_type character varying DEFAULT 'Theory'::character varying,
  academic_year character varying NOT NULL,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT timetables_pkey PRIMARY KEY (id),
  CONSTRAINT timetables_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id),
  CONSTRAINT timetables_regulation_year_course_code_fkey FOREIGN KEY (regulation_year) REFERENCES public.regulations(regulation_year),
  CONSTRAINT timetables_regulation_year_course_code_fkey FOREIGN KEY (course_code) REFERENCES public.regulations(course_code)
);
CREATE TABLE faculty.attendance_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_code character varying NOT NULL UNIQUE,
  faculty_employee_id character varying NOT NULL,
  attendance_date date NOT NULL,
  period_code character varying NOT NULL,
  subject_name character varying NOT NULL,
  department character varying NOT NULL,
  section character varying NOT NULL,
  present_count integer DEFAULT 0,
  absent_count integer DEFAULT 0,
  od_count integer DEFAULT 0,
  ml_count integer DEFAULT 0,
  is_marked boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT attendance_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT attendance_sessions_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.mark_sheet_statuses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  faculty_employee_id character varying NOT NULL,
  assessment_type character varying NOT NULL,
  department character varying NOT NULL,
  section character varying NOT NULL,
  course_code character varying NOT NULL,
  subject_name character varying NOT NULL,
  status character varying DEFAULT 'Draft'::character varying,
  academic_year character varying NOT NULL,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT mark_sheet_statuses_pkey PRIMARY KEY (id),
  CONSTRAINT mark_sheet_statuses_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.lesson_plans (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  faculty_employee_id character varying NOT NULL,
  course_code character varying NOT NULL,
  subject_name character varying NOT NULL,
  unit_number integer NOT NULL,
  topic_title character varying NOT NULL,
  planned_date date,
  completed_date date,
  status character varying DEFAULT 'Pending'::character varying,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT lesson_plans_pkey PRIMARY KEY (id),
  CONSTRAINT lesson_plans_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.assignments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  faculty_employee_id character varying NOT NULL,
  course_code character varying NOT NULL,
  subject_name character varying NOT NULL,
  department character varying NOT NULL,
  section character varying NOT NULL,
  title character varying NOT NULL,
  description text,
  due_date date NOT NULL,
  total_marks integer DEFAULT 100,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT assignments_pkey PRIMARY KEY (id),
  CONSTRAINT assignments_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  faculty_employee_id character varying NOT NULL,
  title character varying NOT NULL,
  category character varying DEFAULT 'GENERAL'::character varying,
  description text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.leave_applications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  faculty_employee_id character varying,
  leave_type character varying,
  start_date date,
  end_date date,
  status character varying DEFAULT 'Pending'::character varying,
  CONSTRAINT leave_applications_pkey PRIMARY KEY (id),
  CONSTRAINT leave_applications_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.syllabus_uploads (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  faculty_employee_id character varying,
  course_code character varying,
  file_url text,
  CONSTRAINT syllabus_uploads_pkey PRIMARY KEY (id),
  CONSTRAINT syllabus_uploads_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.question_banks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  faculty_employee_id character varying,
  course_code character varying,
  file_url text,
  CONSTRAINT question_banks_pkey PRIMARY KEY (id),
  CONSTRAINT question_banks_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.marks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  marks_id character varying UNIQUE,
  student_id character varying,
  student_roll character varying,
  student_name character varying,
  faculty_employee_id character varying DEFAULT 'FAC002'::character varying,
  faculty_id character varying,
  subject character varying,
  assessment character varying,
  class_sec character varying,
  cia numeric,
  assignment numeric,
  lab numeric,
  project numeric,
  total numeric,
  percentage numeric,
  grade character varying,
  status character varying DEFAULT 'Submitted'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  year text,
  CONSTRAINT marks_pkey PRIMARY KEY (id),
  CONSTRAINT marks_faculty_employee_id_fkey FOREIGN KEY (faculty_employee_id) REFERENCES faculty.faculties(employee_id)
);
CREATE TABLE faculty.assignment_marks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  assignment_id uuid NOT NULL,
  reg_no character varying NOT NULL,
  name character varying,
  department character varying,
  section character varying,
  subject_code character varying,
  marks numeric,
  assignment_file text,
  status character varying DEFAULT 'Not Submitted'::character varying,
  submitted_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT assignment_marks_pkey PRIMARY KEY (id),
  CONSTRAINT fk_assignment_marks_assignment FOREIGN KEY (assignment_id) REFERENCES faculty.assignments(id)
);




_-------------------------------------------------------------------

hod schema:


-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE hod.hod_departments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  department_code character varying NOT NULL UNIQUE,
  department_name character varying NOT NULL UNIQUE,
  description text,
  hod_name character varying,
  hod_email character varying,
  student_count integer DEFAULT 0,
  faculty_count integer DEFAULT 0,
  status boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT hod_departments_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.hod_profiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  employee_id character varying NOT NULL UNIQUE,
  department_id uuid,
  full_name character varying NOT NULL,
  official_email character varying NOT NULL UNIQUE,
  personal_email character varying,
  phone character varying,
  emergency_contact character varying,
  dob character varying,
  gender character varying,
  blood_group character varying,
  nationality character varying DEFAULT 'Indian'::character varying,
  marital_status character varying,
  address text,
  designation character varying DEFAULT 'Head of Department'::character varying,
  department character varying,
  date_of_joining character varying,
  employment_type character varying DEFAULT 'Permanent / Regular'::character varying,
  office_location character varying,
  reporting_authority character varying,
  teaching_experience_years integer DEFAULT 0,
  admin_experience_years integer DEFAULT 0,
  ug_degree character varying,
  pg_degree character varying,
  phd_degree character varying,
  specialization text,
  university character varying,
  orcid character varying,
  scopus_id character varying,
  google_scholar text,
  research_gate text,
  publication_count integer DEFAULT 0,
  conference_count integer DEFAULT 0,
  patents_count integer DEFAULT 0,
  funded_projects_amount character varying,
  weekly_workload_hours integer DEFAULT 18,
  photo_url text,
  status boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT hod_profiles_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.faculty_profile_approvals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  display_id character varying UNIQUE,
  faculty_id uuid,
  faculty_name character varying NOT NULL,
  department_id uuid,
  update_type character varying NOT NULL,
  old_value text,
  new_value text,
  document_name character varying,
  document_url text,
  status character varying DEFAULT 'PENDING HOD'::character varying,
  hod_remarks text,
  approved_by uuid,
  approved_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT faculty_profile_approvals_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.hod_leave_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  display_id character varying UNIQUE,
  faculty_id uuid,
  faculty_name character varying NOT NULL,
  department_id uuid,
  leave_type character varying NOT NULL,
  dates character varying,
  from_date date,
  to_date date,
  reason text,
  substitute_faculty character varying,
  status character varying DEFAULT 'PENDING HOD'::character varying,
  hod_remarks text,
  approved_by uuid,
  approved_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT hod_leave_requests_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.hod_profile_approvals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  display_id character varying UNIQUE,
  faculty_id uuid,
  faculty_name character varying,
  department_id uuid,
  update_type character varying,
  old_value text,
  new_value text,
  document_name character varying,
  document_url text,
  status character varying DEFAULT 'PENDING HOD'::character varying,
  hod_remarks text,
  approved_by uuid,
  approved_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT hod_profile_approvals_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.department_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  display_id character varying UNIQUE,
  department_id uuid,
  name character varying NOT NULL,
  category character varying,
  in_charge character varying,
  venue character varying,
  dates character varying,
  start_date timestamp with time zone,
  end_date timestamp with time zone,
  registered_count integer DEFAULT 0,
  status character varying DEFAULT 'UPCOMING'::character varying,
  description text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT department_events_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.department_notices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  display_id character varying UNIQUE,
  department_id uuid,
  title character varying NOT NULL,
  category character varying,
  priority character varying DEFAULT 'MEDIUM'::character varying,
  audience character varying DEFAULT 'All Department Faculty'::character varying,
  delivery character varying DEFAULT 'Portal + Email'::character varying,
  read_count integer DEFAULT 0,
  total_count integer DEFAULT 0,
  content text,
  source character varying DEFAULT 'HOD Office'::character varying,
  is_high_priority boolean DEFAULT false,
  attachment_url text,
  status character varying DEFAULT 'PUBLISHED'::character varying,
  publish_date date DEFAULT CURRENT_DATE,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT department_notices_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.mentor_assignments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  department_id uuid,
  faculty_id uuid,
  mentor_name character varying NOT NULL,
  designation character varying,
  section character varying,
  mentees_count integer DEFAULT 0,
  last_session character varying,
  counselling_status character varying DEFAULT 'NORMAL'::character varying,
  status character varying DEFAULT 'ACTIVE'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT mentor_assignments_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.class_advisers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  department_id uuid,
  faculty_id uuid,
  class_section character varying NOT NULL,
  adviser_name character varying NOT NULL,
  designation character varying,
  strength character varying,
  attendance_pct character varying DEFAULT '95.0%'::character varying,
  meetings_conducted character varying DEFAULT '0 Conducted'::character varying,
  status character varying DEFAULT 'ACTIVE'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT class_advisers_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.research_projects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  department_id uuid,
  faculty_id uuid,
  principal_investigator character varying NOT NULL,
  project_title character varying NOT NULL,
  funding_agency character varying,
  sanctioned_amount numeric DEFAULT 0.00,
  sanction_date date,
  duration_months integer,
  project_type character varying DEFAULT 'Funded Project'::character varying,
  status character varying DEFAULT 'Ongoing'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT research_projects_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.department_timetable (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  department_id uuid,
  subject_code character varying NOT NULL,
  subject_name character varying NOT NULL,
  faculty_id uuid,
  faculty_name character varying,
  room_no character varying,
  section character varying,
  semester character varying,
  day_of_week character varying,
  timing character varying,
  status character varying DEFAULT 'Scheduled'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT department_timetable_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.department_files (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  display_id character varying UNIQUE,
  department_id uuid,
  name character varying NOT NULL,
  category character varying,
  uploaded_by character varying,
  size character varying,
  upload_date character varying,
  access character varying DEFAULT 'Department Public'::character varying,
  status character varying DEFAULT 'VERIFIED'::character varying,
  file_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT department_files_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.course_diary (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  department_id uuid,
  subject_code character varying NOT NULL,
  subject_name character varying NOT NULL,
  faculty_name character varying,
  semester character varying,
  section character varying,
  syllabus_completion_pct numeric DEFAULT 0.00,
  exam_evaluation_status character varying DEFAULT 'PENDING'::character varying,
  log_status character varying DEFAULT 'IN_PROGRESS'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT course_diary_pkey PRIMARY KEY (id)
);
CREATE TABLE hod.audit_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  department_id uuid,
  user_name character varying NOT NULL,
  action character varying NOT NULL,
  description text,
  ip_address character varying,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT audit_logs_pkey PRIMARY KEY (id)
);




---------------------------------------------------------------------


public schema:

-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.regulations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  regulation_year character varying NOT NULL,
  course_code character varying NOT NULL UNIQUE,
  course_name character varying NOT NULL,
  department character varying NOT NULL,
  semester integer NOT NULL,
  credits numeric NOT NULL,
  course_type character varying NOT NULL,
  CONSTRAINT regulations_pkey PRIMARY KEY (id)
);
CREATE TABLE public.academic_calendar_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title character varying NOT NULL,
  event_type character varying NOT NULL,
  event_date date NOT NULL,
  start_time time without time zone,
  end_time time without time zone,
  venue character varying,
  department character varying,
  academic_year character varying NOT NULL,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT academic_calendar_events_pkey PRIMARY KEY (id)
);