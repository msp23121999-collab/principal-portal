const { Client } = require('../finalcode-worktree/backend/node_modules/pg');
require('../finalcode-worktree/backend/node_modules/dotenv').config({ path: 'd:/Principal_Portal/.env' });

(async () => {
  console.log('=====================================================================');
  console.log('POPULATING COMPLETE SAMPLE TEST DATA FOR ALL PRINCIPAL PORTAL DATASETS');
  console.log('=====================================================================');

  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();

  // Safe cleanup of deterministic test UUIDs from previous seed script runs
  console.log('--> Cleaning up old test-run artifacts...');
  const testTables = [
    'principal.program_enrolments', 'principal.facility_stats', 'principal.accreditation_standings',
    'principal.cia_progress', 'principal.exam_schedules', 'principal.attainment_levels',
    'principal.semester_performance', 'principal.rank_holders', 'principal.subject_results',
    'principal.semester_results', 'principal.grade_slices', 'principal.result_publications',
    'principal.semester_summaries', 'principal.funded_projects', 'principal.consultancy_projects',
    'principal.scholarship_schemes', 'principal.placement_records', 'principal.internship_records',
    'principal.placement_drives', 'principal.companies', 'principal.approval_decisions',
    'principal.approval_requests', 'principal.circulars', 'principal.meeting_agenda_items',
    'principal.meetings', 'principal.report_items', 'principal.report_runs',
    'principal.scheduled_reports', 'principal.compliance_areas', 'principal.compliance_documents',
    'principal.policy_adherence', 'principal.audit_entries', 'principal.profile_education',
    'principal.profile_responsibilities', 'principal.profile_research_papers',
    'principal.profile_awards', 'principal.profile_documents', 'principal.student_achievements',
    'principal.faculty_achievements'
  ];

  for (const t of testTables) {
    await client.query(`DELETE FROM ${t} WHERE id::text LIKE 'd1000%' OR id::text LIKE 'd2000%' OR id::text LIKE 'd3000%' OR id::text LIKE 'd4000%' OR id::text LIKE 'd5000%' OR id::text LIKE 'd6000%' OR id::text LIKE 'c1000%' OR id::text LIKE 'c2000%' OR id::text LIKE 'c3000%' OR id::text LIKE 'c4000%' OR id::text LIKE 'c5000%' OR id::text LIKE 'c6000%' OR id::text LIKE 'c7000%' OR id::text LIKE 'b1000%' OR id::text LIKE 'b2000%' OR id::text LIKE 'b3000%' OR id::text LIKE 'b4000%' OR id::text LIKE 'a1000%' OR id::text LIKE 'a2000%' OR id::text LIKE 'a3000%' OR id::text LIKE 'a4000%' OR id::text LIKE '91000%' OR id::text LIKE '92000%' OR id::text LIKE '81000%' OR id::text LIKE '82000%' OR id::text LIKE '83000%' OR id::text LIKE '71000%' OR id::text LIKE '72000%' OR id::text LIKE '73000%' OR id::text LIKE '61000%' OR id::text LIKE '62000%' OR id::text LIKE '63000%' OR id::text LIKE '64000%' OR id::text LIKE '51000%' OR id::text LIKE '41000%' OR id::text LIKE '42000%' OR id::text LIKE '43000%' OR id::text LIKE '44000%' OR id::text LIKE '45000%' OR id::text LIKE 'ea000%' OR id::text LIKE 'fa000%'`);
  }

  const depts = [
    { id: 'd0000001-0000-0000-0000-000000000001', code: 'CSE', name: 'Computer Science & Engineering', shortName: 'CSE' },
    { id: 'd0000002-0000-0000-0000-000000000002', code: 'ECE', name: 'Electronics & Communication Eng', shortName: 'ECE' },
    { id: 'd0000003-0000-0000-0000-000000000003', code: 'EEE', name: 'Electrical & Electronics Eng', shortName: 'EEE' },
    { id: 'd0000004-0000-0000-0000-000000000004', code: 'MECH', name: 'Mechanical Engineering', shortName: 'MECH' },
    { id: 'd0000005-0000-0000-0000-000000000005', code: 'CIVIL', name: 'Civil Engineering', shortName: 'CIVIL' },
    { id: 'd0000006-0000-0000-0000-000000000006', code: 'IT', name: 'Information Technology', shortName: 'IT' }
  ];

  // Helper for clean 36-char hex UUIDs (8-4-4-4-12)
  const makeUuid = (prefix8, i) => `${prefix8}-0000-0000-0000-${i.toString(16).padStart(12, '0')}`;

  // 0. Academic Years
  console.log('--> Populating Academic Years...');
  const acadYearRes = await client.query(`
    INSERT INTO principal.academic_years (id, label, start_date, end_date, is_current, created_at, updated_at)
    VALUES ($1, '2025-2026', '2025-06-01', '2026-05-31', true, NOW(), NOW())
    ON CONFLICT (label) DO UPDATE SET is_current=true, updated_at=NOW()
    RETURNING id;
  `, [makeUuid('99000000', 1)]);
  const acadYearId = acadYearRes.rows[0].id;

  // 1. Departments
  console.log('--> Populating Departments...');
  const deptIdMap = {};
  for (const d of depts) {
    await client.query(`
      INSERT INTO admin.departments (id, code, name, short_name, hod_name, program_count, established_year, is_active, created_at, updated_at)
      VALUES ($1, $2, $3, $4, 'Dr. HOD', 4, 2001, true, NOW(), NOW())
      ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name, short_name=EXCLUDED.short_name, updated_at=NOW();
    `, [d.id, d.code, d.name, d.shortName]);

    await client.query(`
      INSERT INTO public.departments (id, code, name, short_name, created_at)
      VALUES ($1, $2, $3, $4, NOW())
      ON CONFLICT (id) DO UPDATE SET code=$2, name=$3, short_name=$4;
    `, [d.id, d.code, d.name, d.shortName]);

    const pDeptRes = await client.query(`
      INSERT INTO principal.departments (id, code, name, short_name, hod_name, program_count, established_year, is_active, created_at, updated_at)
      VALUES ($1, $2, $3, $4, 'Dr. HOD', 4, 2001, true, NOW(), NOW())
      ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name, short_name=EXCLUDED.short_name, updated_at=NOW()
      RETURNING id;
    `, [d.id, d.code, d.name, d.shortName]);
    deptIdMap[d.code] = pDeptRes.rows[0].id;
  }

  // 2. Faculty Roster & Details (10 Faculty)
  console.log('--> Populating Faculty Roster & Details (10 records)...');
  const facNames = [
    'Dr. Arunkumar S', 'Dr. Priya V', 'Prof. Ramesh K', 'Dr. Kavitha M', 'Prof. Suresh Babu',
    'Dr. Meenakshi R', 'Prof. Anitha P', 'Dr. Dinesh Kumar', 'Prof. Lakshmi Narayanan', 'Dr. Saravanan T'
  ];
  const facDesig = ['Professor & HOD', 'Associate Professor', 'Assistant Professor', 'Professor', 'Assistant Professor'];
  const facIdMap = {};
  
  for (let i = 1; i <= 10; i++) {
    const facId = makeUuid('f0000000', i);
    const empId = `TEST_FAC_${i.toString().padStart(3, '0')}`;
    const deptObj = depts[(i - 1) % depts.length];
    const name = facNames[i - 1];
    const desig = facDesig[(i - 1) % facDesig.length];

    await client.query(`
      INSERT INTO faculty.faculties (
        id, employee_id, code, full_name, designation, role, qualification, experience, email, phone, department, status, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, 'Faculty', 'Ph.D.', '12 Years', $6, '9876543210', $3, 'active', NOW(), NOW())
      ON CONFLICT (employee_id) DO UPDATE SET full_name=$4, designation=$5, department=$3, updated_at=NOW();
    `, [facId, empId, deptObj.code, name, desig, `${empId.toLowerCase()}@ksrce.ac.in`]);

    const facRes = await client.query(`
      INSERT INTO principal.faculty_details (
        id, employee_id, weekly_teaching_hours, subjects_handled, mentees, funded_projects, appraisal_score, feedback_score, qualification, email, created_at, updated_at
      ) VALUES ($1, $2, 16, 3, 20, $3, 9.25, 4.8, 'Ph.D.', $4, NOW(), NOW())
      ON CONFLICT (employee_id) DO UPDATE SET weekly_teaching_hours=16, updated_at=NOW()
      RETURNING id;
    `, [facId, empId, i % 3, `${empId.toLowerCase()}@ksrce.ac.in`]);
    facIdMap[empId] = facRes.rows[0].id;
  }

  // 3. Faculty Achievements, Research & Patents (10 each)
  console.log('--> Populating Faculty Research, Patents & Achievements...');
  for (let i = 1; i <= 10; i++) {
    const empId = `TEST_FAC_${i.toString().padStart(3, '0')}`;
    const actualFacId = facIdMap[empId];

    await client.query(`
      INSERT INTO principal.faculty_achievements (id, faculty_detail_id, achievement, display_order, created_at, updated_at)
      VALUES ($1, $2, $3, $4, NOW(), NOW())
      ON CONFLICT (faculty_detail_id, display_order) DO UPDATE SET achievement=$3, updated_at=NOW();
    `, [makeUuid('fa000000', i), actualFacId, `Best Researcher Award (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, i]);

    await client.query(`
      INSERT INTO faculty.research_publications (id, faculty_employee_id, pub_type, title, journal_or_conf_name, publication_date, created_at)
      VALUES ($1, $2, 'Journal', $3, 'IEEE Transactions on Education', '2026-03-15', NOW())
      ON CONFLICT (id) DO UPDATE SET title=$3;
    `, [makeUuid('fb000000', i), empId, `AI in Engineering Systems (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);

    await client.query(`
      INSERT INTO faculty.patents (id, faculty_employee_id, title, application_no, patent_status, filing_date, created_at)
      VALUES ($1, $2, $3, $4, 'Granted', '2025-11-20', NOW())
      ON CONFLICT (id) DO UPDATE SET title=$3;
    `, [makeUuid('fc000000', i), empId, `Smart IoT Sensor Network (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, `PAT202600${i}`]);

    await client.query(`
      INSERT INTO faculty.leave_applications (id, faculty_employee_id, leave_type, start_date, end_date, status, total_days, reason, updated_at)
      VALUES ($1, $2, 'Casual Leave', '2026-08-25', '2026-08-26', $3, 2, $4, NOW())
      ON CONFLICT (id) DO UPDATE SET status=$3, reason=$4, updated_at=NOW();
    `, [makeUuid('fd000000', i), empId, i % 2 === 0 ? 'approved' : 'pending', `Attending National Conference (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);
  }

  // 4. Students & Student Achievements (10 Students)
  console.log('--> Populating Student Roster & Achievements (10 records)...');
  const stuNames = [
    'Adithya M', 'Bharath Kumar', 'Chitra S', 'Divya P', 'Elango R',
    'Gokul K', 'Harini V', 'Ishwarya N', 'Jaganathan B', 'Karthik S'
  ];

  for (let i = 1; i <= 10; i++) {
    const stuUuid = makeUuid('e0000000', i);
    const regNo = `731522104${i.toString().padStart(3, '0')}`;
    const name = stuNames[i - 1];
    const deptObj = depts[(i - 1) % depts.length];

    await client.query(`
      INSERT INTO student.students (
        id, student_id, roll_no, register_no, full_name, gender, dob, institute_email, mobile_number, degree, department, regulation_year, batch, year_of_study, semester, term_type, section, cgpa, attendance_percentage, status, created_at, updated_at
      ) VALUES ($1, $2, $2, $3, $4, 'Male', '2004-05-15', $5, '9123456789', 'B.E.', $6, '2022', '2022-2026', 'Year IV', 7, 'Odd', 'A', $7, $8, 'Active', NOW(), NOW())
      ON CONFLICT (student_id) DO UPDATE SET full_name=$4, department=$6, cgpa=$7, attendance_percentage=$8, updated_at=NOW();
    `, [stuUuid, `STU_${i.toString().padStart(3, '0')}`, regNo, name, `${regNo}@ksrce.ac.in`, deptObj.code, 7.5 + (i * 0.2), 80 + (i * 1.5)]);

    await client.query(`
      INSERT INTO principal.student_achievements (id, student_name, department_id, title, event, category, level, position, achieved_on, created_at, updated_at)
      VALUES ($1, $2, $3, $4, 'National Tech Symposium 2026', 'technical', 'national', '1st Place', '2026-07-10', NOW(), NOW())
      ON CONFLICT (id) DO UPDATE SET title=$4, student_name=$2, updated_at=NOW();
    `, [makeUuid('ea000000', i), name, deptIdMap[deptObj.code], `Hackathon Winner (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);

    await client.query(`
      INSERT INTO student.attendance_table (id, date, reg_no, name, dept, section, year, attendance_percentage, created_at, updated_at)
      VALUES ($1, '2026-08-20', $2, $3, $4, 'A', 'IV', $5, NOW(), NOW())
      ON CONFLICT (id) DO UPDATE SET attendance_percentage=$5, updated_at=NOW();
    `, [makeUuid('eb000000', i), regNo, name, deptObj.code, 82 + i]);
  }

  // 5. Program Enrolments & Facility Stats & Accreditation Standings (10 records each)
  console.log('--> Populating Institution, Academic & Facility Data (10 records each)...');
  const programLevels = ['UG', 'PG', 'Diploma', 'PhD'];
  for (let i = 1; i <= 10; i++) {
    const deptObj = depts[(i - 1) % depts.length];
    const deptId = deptIdMap[deptObj.code];

    if (i <= programLevels.length) {
      await client.query(`
        INSERT INTO principal.program_enrolments (id, level, current_year_count, previous_year_count, academic_year_id, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
        ON CONFLICT (level, academic_year_id) DO UPDATE SET current_year_count=$3, updated_at=NOW();
      `, [makeUuid('d1000000', i), programLevels[i - 1], 480 + (i * 10), 450 + (i * 10), acadYearId]);
    }

    await client.query(`
      INSERT INTO principal.facility_stats (id, icon_name, label, count, display_order, created_at, updated_at)
      VALUES ($1, 'computer', $2, $3, $4, NOW(), NOW())
      ON CONFLICT (label) DO UPDATE SET count=$3, updated_at=NOW();
    `, [makeUuid('d2000000', i), `Facility ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, 50 + (i * 5), i]);

    const accBodies = ['naac', 'nba', 'nirf', 'aicte'];
    if (i <= accBodies.length) {
      await client.query(`
        INSERT INTO principal.accreditation_standings (id, body, grade, score, maximum_score, valid_from, valid_to, cycle, created_at, updated_at)
        VALUES ($1, $2, 'A++', 3.85, 4.00, '2023-01-01', '2028-12-31', 'Cycle 3', NOW(), NOW())
        ON CONFLICT (body) DO UPDATE SET score=3.85, updated_at=NOW();
      `, [makeUuid('d3000000', i), accBodies[i - 1]]);
    }

    if (i <= depts.length) {
      await client.query(`
        INSERT INTO principal.cia_progress (id, department_id, cia1_percent, cia2_percent, cia3_percent, marks_entered, marks_expected, created_at, updated_at)
        VALUES ($1, $2, 95.0, 90.0, 85.0, 1200, 1200, NOW(), NOW())
        ON CONFLICT (department_id) DO UPDATE SET cia1_percent=95.0, updated_at=NOW();
      `, [makeUuid('d4000000', i), deptId]);
    }

    await client.query(`
      INSERT INTO principal.exam_schedules (id, subject_code, subject_name, department_id, semester, exam_date, session, duration_minutes, hall, candidates, stage, created_at, updated_at)
      VALUES ($1, $2, $3, $4, 'Sem 7', '2026-11-10', 'FN', 180, 'Main Hall 101', 120, 'scheduled', NOW(), NOW())
      ON CONFLICT (subject_code, exam_date, session) DO UPDATE SET candidates=120, updated_at=NOW();
    `, [makeUuid('d5000000', i), `CS800${i}`, `Subject ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, deptId]);

    await client.query(`
      INSERT INTO principal.attainment_levels (id, label, course_outcomes, program_outcomes, created_at, updated_at)
      VALUES ($1, $2, 85.5, 82.0, NOW(), NOW())
      ON CONFLICT (label) DO UPDATE SET course_outcomes=85.5, updated_at=NOW();
    `, [makeUuid('d6000000', i), `Level ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);
  }

  // 6. Results, Rank Holders & Grade Slices (10 records each)
  console.log('--> Populating Results, Rank Holders & Grade Slices (10 records each)...');
  for (let i = 1; i <= 10; i++) {
    const deptObj = depts[(i - 1) % depts.length];
    const deptId = deptIdMap[deptObj.code];

    await client.query(`
      INSERT INTO principal.semester_performance (id, semester, pass_percent, average_sgpa, display_order, created_at, updated_at)
      VALUES ($1, $2, 91.5, 8.25, $3, NOW(), NOW())
      ON CONFLICT (semester) DO UPDATE SET pass_percent=91.5, updated_at=NOW();
    `, [makeUuid('c1000000', i), `Semester ${i}`, i]);

    const semRes = await client.query(`
      INSERT INTO principal.semester_results (id, semester_label, overall_pass_percent, published_on, created_at, updated_at)
      VALUES ($1, $2, 92.0, '2026-06-30', NOW(), NOW())
      ON CONFLICT (semester_label) DO UPDATE SET overall_pass_percent=92.0, updated_at=NOW()
      RETURNING id;
    `, [makeUuid('c2000000', i), `Semester ${i}`]);

    await client.query(`
      INSERT INTO principal.subject_results (id, subject_code, subject_name, department_id, semester, faculty_employee_id, appeared, passed, average_marks, academic_year_id, created_at, updated_at)
      VALUES ($1, $2, $3, $4, '7', $5, 120, 112, 78.5, $6, NOW(), NOW())
      ON CONFLICT (subject_code, department_id, semester) DO UPDATE SET appeared=120, updated_at=NOW();
    `, [makeUuid('c3000000', i), `CS800${i}`, `Subject ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, deptId, `TEST_FAC_${i.toString().padStart(3, '0')}`, acadYearId]);

    await client.query(`
      INSERT INTO principal.rank_holders (id, semester_result_id, rank_position, student_name, student_roll_no, department_id, cgpa, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
      ON CONFLICT (semester_result_id, rank_position) DO UPDATE SET cgpa=$7, updated_at=NOW();
    `, [makeUuid('c4000000', i), semRes.rows[0].id, i, stuNames[i - 1], `731522104${i.toString().padStart(3, '0')}`, deptId, 9.9 - (i * 0.1)]);

    await client.query(`
      INSERT INTO principal.grade_slices (id, grade, student_count, display_order, created_at, updated_at)
      VALUES ($1, $2, $3, $4, NOW(), NOW())
      ON CONFLICT (grade) DO UPDATE SET student_count=$3, updated_at=NOW();
    `, [makeUuid('c5000000', i), `O Grade ${i}`, 50 + (i * 5), i]);

    await client.query(`
      INSERT INTO principal.result_publications (id, semester, exam_ended_on, papers_total, papers_evaluated, published_on, stage, created_at, updated_at)
      VALUES ($1, $2, '2026-06-30', 40, 40, '2026-07-15', 'published', NOW(), NOW())
      ON CONFLICT (semester, exam_ended_on) DO UPDATE SET stage='published', updated_at=NOW();
    `, [makeUuid('c6000000', i), `Semester ${i}`]);

    await client.query(`
      INSERT INTO principal.semester_summaries (id, semester, appeared, passed, average_sgpa, average_cgpa, backlogs, top_performer_name, top_performer_cgpa, created_at, updated_at)
      VALUES ($1, $2, 450, 420, 8.1, 8.2, 30, $3, 9.85, NOW(), NOW())
      ON CONFLICT (semester) DO UPDATE SET appeared=450, updated_at=NOW();
    `, [makeUuid('c7000000', i), `Semester ${i}`, stuNames[i - 1]]);
  }

  // 7. Research Projects, Funded Projects & Consultancy (10 records each)
  console.log('--> Populating Funded & Consultancy Projects (10 records each)...');
  for (let i = 1; i <= 10; i++) {
    const deptObj = depts[(i - 1) % depts.length];
    const deptId = deptIdMap[deptObj.code];

    await client.query(`
      INSERT INTO principal.funded_projects (id, title, principal_investigator, department_id, agency, sanctioned_amount, duration_months, sanctioned_on, stage, created_at, updated_at)
      VALUES ($1, $2, $3, $4, 'DST-SERB', 2500000.00, 36, '2025-04-10', 'ongoing', NOW(), NOW())
      ON CONFLICT (title, agency) DO UPDATE SET stage='ongoing', updated_at=NOW();
    `, [makeUuid('b1000000', i), `AI Research Project ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, facNames[i - 1], deptId]);

    await client.query(`
      INSERT INTO principal.consultancy_projects (id, title, client, department_id, lead_faculty, revenue, stage, created_at, updated_at)
      VALUES ($1, $2, 'L&T Technology Services', $3, $4, 850000.00, 'completed', NOW(), NOW())
      ON CONFLICT (title, client) DO UPDATE SET stage='completed', updated_at=NOW();
    `, [makeUuid('b2000000', i), `Industrial Automation ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, deptId, facNames[i - 1]]);

    await client.query(`
      INSERT INTO principal.scholarship_schemes (id, name, sponsor, beneficiaries, sanctioned, disbursed, created_at, updated_at)
      VALUES ($1, $2, 'Government of Tamil Nadu', 120, 1800000.00, 1800000.00, NOW(), NOW())
      ON CONFLICT (name, sponsor) DO UPDATE SET beneficiaries=120, updated_at=NOW();
    `, [makeUuid('b3000000', i), `State Merit Scholarship ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);

    await client.query(`
      INSERT INTO student.student_financials (id, student_id, fee_head, total_amount, paid_amount, balance_amount, payment_status, created_at)
      VALUES ($1, $2, 'Tuition Fee', 85000.00, 85000.00, 0.00, 'Paid', NOW())
      ON CONFLICT (id) DO UPDATE SET payment_status='Paid';
    `, [makeUuid('b4000000', i), `STU_${i.toString().padStart(3, '0')}`]);
  }

  // 8. Companies, Placement Drives, Placement Records & Internships (10 records each)
  console.log('--> Populating Companies & Placement Drives (10 records each)...');
  const compNames = ['Zoho Corporation', 'TCS', 'Infosys', 'Wipro', 'Cognizant', 'Accenture', 'HCL Tech', 'Bosch', 'Amazon', 'Microsoft'];

  for (let i = 1; i <= 10; i++) {
    const compId = makeUuid('a1000000', i);
    const compName = compNames[i - 1];
    const deptObj = depts[(i - 1) % depts.length];
    const deptId = deptIdMap[deptObj.code];

    const compRes = await client.query(`
      INSERT INTO principal.companies (id, name, sector, students_hired, avg_package_lpa, created_at, updated_at)
      VALUES ($1, $2, 'Information Technology', 25, 6.5, NOW(), NOW())
      ON CONFLICT (name) DO UPDATE SET students_hired=25, updated_at=NOW()
      RETURNING id;
    `, [compId, `${compName} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);
    const actualCompId = compRes.rows[0].id;

    await client.query(`
      INSERT INTO principal.placement_drives (id, company_id, role, visit_date, registered, shortlisted, offers_made, package_lpa, stage, created_at, updated_at)
      VALUES ($1, $2, 'Software Development Engineer', '2026-09-15', 180, 45, 20, 8.5, 'scheduled', NOW(), NOW())
      ON CONFLICT (company_id, visit_date) DO UPDATE SET role='Software Development Engineer', updated_at=NOW();
    `, [makeUuid('a2000000', i), actualCompId]);

    await client.query(`
      INSERT INTO principal.placement_records (id, student_roll_no, student_name, department_id, company_id, package_lpa, offer_date, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, 7.5, '2026-08-01', NOW(), NOW())
      ON CONFLICT (student_roll_no, company_id) DO UPDATE SET package_lpa=7.5, updated_at=NOW();
    `, [makeUuid('a3000000', i), `731522104${i.toString().padStart(3, '0')}`, stuNames[i - 1], deptId, actualCompId]);

    await client.query(`
      INSERT INTO principal.internship_records (id, company_id, department_id, domain, students, duration_weeks, monthly_stipend, converts_to_offer, created_at, updated_at)
      VALUES ($1, $2, $3, $4, 15, 12, 20000.00, true, NOW(), NOW())
      ON CONFLICT (company_id, department_id, domain) DO UPDATE SET students=15, updated_at=NOW();
    `, [makeUuid('a4000000', i), actualCompId, deptId, `Full Stack Web Dev ${i}`]);
  }

  // 9. Approvals, Circulars & Meetings (10 records each)
  console.log('--> Populating Approvals, Circulars & Meetings (10 records each)...');
  for (let i = 1; i <= 10; i++) {
    const reqId = makeUuid('91000000', i);
    const deptObj = depts[(i - 1) % depts.length];
    const deptId = deptIdMap[deptObj.code];
    const reqDate = new Date(`2026-08-${(10 + i).toString().padStart(2, '0')}T10:00:00Z`);

    const reqRes = await client.query(`
      INSERT INTO principal.approval_requests (id, category, title, requester_name, requester_role, department_id, submitted_at, summary, priority, decision, amount, created_at, updated_at)
      VALUES ($1, 'academic', $2, $3, 'Department HOD', $4, $5, 'Request for lab equipment upgrade approval', 'high', 'pending', 150000.00, NOW(), NOW())
      ON CONFLICT (title, submitted_at) DO UPDATE SET priority='high', updated_at=NOW()
      RETURNING id;
    `, [reqId, `Lab Equipment Purchase ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, facNames[i - 1], deptId, reqDate]);
    const actualReqId = reqRes.rows[0].id;

    await client.query(`
      INSERT INTO principal.approval_decisions (id, source_type, source_id, decision, remarks, decided_by, decided_at, created_at, updated_at)
      VALUES ($1, 'approval_request', $2, 'approved', 'Approved based on academic necessity', 'Principal', NOW(), NOW(), NOW())
      ON CONFLICT (id) DO UPDATE SET decision='approved', updated_at=NOW();
    `, [makeUuid('92000000', i), actualReqId]);

    await client.query(`
      INSERT INTO principal.circulars (id, reference, title, body, category, audience, status, author_name, published_at, is_pinned, recipient_count, created_at, updated_at)
      VALUES ($1, $2, $3, 'Important institutional notice details...', 'academic', 'everyone', 'published', 'Principal Office', NOW(), false, 500, NOW(), NOW())
      ON CONFLICT (reference) DO UPDATE SET title=$3, updated_at=NOW();
    `, [makeUuid('81000000', i), `KSRCE/CIRC/2026/${i.toString().padStart(3, '0')}`, `Institutional Circular ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);

    const meetId = makeUuid('82000000', i);
    const meetDate = new Date(`2026-08-${(15 + i).toString().padStart(2, '0')}T10:00:00Z`);
    const meetRes = await client.query(`
      INSERT INTO principal.meetings (id, title, meeting_type, scheduled_at, duration_minutes, venue, chairperson, attendee_count, status, minutes_recorded, created_at, updated_at)
      VALUES ($1, $2, 'academic_council', $3, 60, 'Board Room', 'Principal', 15, 'scheduled', true, NOW(), NOW())
      ON CONFLICT (title, scheduled_at) DO UPDATE SET status='scheduled', updated_at=NOW()
      RETURNING id;
    `, [meetId, `Academic Council Meeting ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, meetDate]);
    const actualMeetId = meetRes.rows[0].id;

    await client.query(`
      INSERT INTO principal.meeting_agenda_items (id, meeting_id, item, display_order, created_at, updated_at)
      VALUES ($1, $2, $3, $4, NOW(), NOW())
      ON CONFLICT (meeting_id, display_order) DO UPDATE SET item=$3, updated_at=NOW();
    `, [makeUuid('83000000', i), actualMeetId, `Syllabus Review Item ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, i]);
  }

  // 10. Reports, Compliance, Notifications & Profile Details (10 records each)
  console.log('--> Populating Reports, Compliance & Notifications (10 records each)...');
  const reportCategories = ['academic', 'attendance', 'faculty', 'placement'];
  for (let i = 1; i <= 10; i++) {
    await client.query(`
      INSERT INTO principal.report_items (id, title, category, description, created_at, updated_at)
      VALUES ($1, $2, $3, 'Comprehensive report of academic metrics', NOW(), NOW())
      ON CONFLICT (title) DO UPDATE SET description='Comprehensive report of academic metrics', updated_at=NOW();
    `, [makeUuid('71000000', i), `Report Item ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, reportCategories[(i - 1) % reportCategories.length]]);

    const reqTime = new Date(`2026-08-${(10 + i).toString().padStart(2, '0')}T12:00:00Z`);
    await client.query(`
      INSERT INTO principal.report_runs (id, title, module, format, period, requested_by, requested_at, state, size_kb, created_at, updated_at)
      VALUES ($1, $2, 'Academic', 'pdf', 'current_semester', 'Principal', $3, 'ready', 450, NOW(), NOW())
      ON CONFLICT (title, requested_at) DO UPDATE SET state='ready', updated_at=NOW();
    `, [makeUuid('72000000', i), `Report Run ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, reqTime]);

    await client.query(`
      INSERT INTO principal.scheduled_reports (id, title, module, frequency, format, next_run, is_enabled, created_at, updated_at)
      VALUES ($1, $2, 'Academic', 'weekly', 'pdf', '2026-09-01 08:00:00+00', true, NOW(), NOW())
      ON CONFLICT (title) DO UPDATE SET is_enabled=true, updated_at=NOW();
    `, [makeUuid('73000000', i), `Scheduled Report ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);

    await client.query(`
      INSERT INTO principal.compliance_areas (id, name, category, owner_name, score, maximum_score, last_reviewed, state, created_at, updated_at)
      VALUES ($1, $2, 'Statutory Compliance', 'Dr. Sundaram', 95.0, 100.0, '2026-08-01', 'compliant', NOW(), NOW())
      ON CONFLICT (name) DO UPDATE SET state='compliant', updated_at=NOW();
    `, [makeUuid('61000000', i), `Compliance Area ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);

    const compBodies = ['naac', 'nba', 'nirf', 'aicte'];
    await client.query(`
      INSERT INTO principal.compliance_documents (id, name, body, owner_name, due_on, status, created_at, updated_at)
      VALUES ($1, $2, $3, 'Principal Office', '2026-10-15', 'submitted', NOW(), NOW())
      ON CONFLICT (name, body) DO UPDATE SET status='submitted', updated_at=NOW();
    `, [makeUuid('62000000', i), `Compliance Doc ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, compBodies[(i - 1) % compBodies.length]]);

    await client.query(`
      INSERT INTO principal.policy_adherence (id, policy, owner_name, last_reviewed, next_review, adherence_percent, open_issues, created_at, updated_at)
      VALUES ($1, $2, 'IQAC Coordinator', '2026-07-01', '2027-07-01', 98.0, 0, NOW(), NOW())
      ON CONFLICT (policy) DO UPDATE SET adherence_percent=98.0, updated_at=NOW();
    `, [makeUuid('63000000', i), `Policy Adherence ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);

    const auditTime = new Date(`2026-08-${(10 + i).toString().padStart(2, '0')}T14:00:00Z`);
    await client.query(`
      INSERT INTO principal.audit_entries (id, actor, actor_role, action, module, description, occurred_at, severity, created_at, updated_at)
      VALUES ($1, 'Dr. M. Sundaram', 'Principal', 'exported', 'Reports', $2, $3, 'routine', NOW(), NOW())
      ON CONFLICT (actor, occurred_at, description) DO UPDATE SET severity='routine', updated_at=NOW();
    `, [makeUuid('64000000', i), `Audit Log Entry ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, auditTime]);

    await client.query(`
      INSERT INTO faculty.notifications (id, title, category, description, is_read, created_at)
      VALUES ($1, $2, 'System', 'Notification details...', false, NOW())
      ON CONFLICT (id) DO UPDATE SET title=$2;
    `, [makeUuid('51000000', i), `Notification Item ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`]);
  }

  // 11. Profile Sub-tables linked to Principal Profile
  console.log('--> Populating Principal Profile Sub-tables...');
  let profId = makeUuid('10000000', 1);
  const userId = makeUuid('10000000', 99);
  const profRes = await client.query(`
    INSERT INTO principal.principal_profiles (id, user_id, employee_id, name, designation, email, phone, experience_years, hod_experience_years, created_at, updated_at)
    VALUES ($1, $2, 'TEST_PRINCIPAL_PROF_001', 'Dr. M. Sundaram', 'Principal', 'principal@ksrce.ac.in', '9443322110', 25, 10, NOW(), NOW())
    ON CONFLICT (user_id) DO UPDATE SET name='Dr. M. Sundaram', updated_at=NOW()
    RETURNING id;
  `, [profId, userId]);
  profId = profRes.rows[0].id;

  for (let i = 1; i <= 10; i++) {
    await client.query(`
      INSERT INTO principal.profile_education (id, profile_id, degree, institution, year_completed, display_order, created_at, updated_at)
      VALUES ($1, $2, $3, 'Anna University', ${2000 + (i * 2)}, $4, NOW(), NOW())
      ON CONFLICT (profile_id, display_order) DO UPDATE SET degree=$3, updated_at=NOW();
    `, [makeUuid('41000000', i), profId, `Degree ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, i]);

    await client.query(`
      INSERT INTO principal.profile_responsibilities (id, profile_id, title, description, since_year, display_order, created_at, updated_at)
      VALUES ($1, $2, $3, 'Institutional administration and academic governance', 2018, $4, NOW(), NOW())
      ON CONFLICT (profile_id, display_order) DO UPDATE SET title=$3, updated_at=NOW();
    `, [makeUuid('42000000', i), profId, `Responsibility ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, i]);

    await client.query(`
      INSERT INTO principal.profile_research_papers (id, profile_id, title, journal_or_conference, year, display_order, created_at, updated_at)
      VALUES ($1, $2, $3, 'IEEE Transactions on Power Systems', ${2020 + (i % 5)}, $4, NOW(), NOW())
      ON CONFLICT (profile_id, display_order) DO UPDATE SET title=$3, updated_at=NOW();
    `, [makeUuid('43000000', i), profId, `Research Paper ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, i]);

    await client.query(`
      INSERT INTO principal.profile_awards (id, profile_id, title, issued_by, year, display_order, created_at, updated_at)
      VALUES ($1, $2, $3, 'Institution of Engineers (India)', ${2021 + (i % 4)}, $4, NOW(), NOW())
      ON CONFLICT (profile_id, display_order) DO UPDATE SET title=$3, updated_at=NOW();
    `, [makeUuid('44000000', i), profId, `Award ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, i]);

    await client.query(`
      INSERT INTO principal.profile_documents (id, profile_id, name, doc_type, uploaded_at, display_order, created_at, updated_at)
      VALUES ($1, $2, $3, 'PDF Document', NOW(), $4, NOW(), NOW())
      ON CONFLICT (profile_id, display_order) DO UPDATE SET name=$3, updated_at=NOW();
    `, [makeUuid('45000000', i), profId, `Document ${i} (TEST_PRINCIPAL_${i.toString().padStart(3, '0')})`, i]);
  }

  console.log('\n=====================================================================');
  console.log('SAMPLE DATA POPULATION COMPLETED SUCCESSFULLY! ALL DATASETS SEEDED. ✅');
  console.log('=====================================================================');

  await client.end();
})();
