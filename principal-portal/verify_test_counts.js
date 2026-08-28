const { Client } = require('../finalcode-worktree/backend/node_modules/pg');
require('../finalcode-worktree/backend/node_modules/dotenv').config({ path: 'd:/Principal_Portal/.env' });

(async () => {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();

  const tables = [
    'faculty.faculties', 'principal.faculty_details', 'principal.faculty_achievements',
    'faculty.research_publications', 'faculty.patents', 'faculty.leave_applications',
    'student.students', 'principal.student_achievements', 'student.attendance_table',
    'principal.program_enrolments', 'principal.facility_stats', 'principal.accreditation_standings',
    'principal.cia_progress', 'principal.exam_schedules', 'principal.attainment_levels',
    'principal.semester_performance', 'principal.semester_results', 'principal.subject_results',
    'principal.rank_holders', 'principal.grade_slices', 'principal.result_publications',
    'principal.semester_summaries', 'principal.funded_projects', 'principal.consultancy_projects',
    'principal.scholarship_schemes', 'student.student_financials', 'principal.companies',
    'principal.placement_drives', 'principal.placement_records', 'principal.internship_records',
    'principal.approval_requests', 'principal.approval_decisions', 'principal.circulars',
    'principal.meetings', 'principal.meeting_agenda_items', 'principal.report_items',
    'principal.report_runs', 'principal.scheduled_reports', 'principal.compliance_areas',
    'principal.compliance_documents', 'principal.policy_adherence', 'principal.audit_entries',
    'faculty.notifications', 'principal.principal_profiles', 'principal.profile_education',
    'principal.profile_responsibilities', 'principal.profile_research_papers',
    'principal.profile_awards', 'principal.profile_documents'
  ];

  console.log('=====================================================================');
  console.log('VERIFYING SEEDED ROW COUNTS ACROSS ALL PRINCIPAL PORTAL DATASETS');
  console.log('=====================================================================');
  let allGood = true;

  for (const t of tables) {
    const res = await client.query(`SELECT COUNT(*) FROM ${t}`);
    const count = parseInt(res.rows[0].count, 10);
    console.log(`${t.padEnd(42)} : ${count} rows`);
    if (count === 0) {
      allGood = false;
    }
  }

  console.log('=====================================================================');
  if (allGood) {
    console.log('ALL TABLES ARE SUCCESSFULLY POPULATED WITH REAL TEST DATA! ✅');
  } else {
    console.log('WARNING: Some tables are empty!');
  }
  console.log('=====================================================================');

  await client.end();
})();
