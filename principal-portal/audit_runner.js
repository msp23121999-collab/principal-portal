const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { Client } = require('../finalcode-worktree/backend/node_modules/pg');
require('../finalcode-worktree/backend/node_modules/dotenv').config({ path: 'd:/Principal_Portal/.env' });

async function getJwtToken(role = 'PRINCIPAL', email = 'principal@ksrce.ac.in') {
  return new Promise((resolve, reject) => {
    const jwt = require('../finalcode-worktree/backend/node_modules/jsonwebtoken');
    const token = jwt.sign(
      { id: 'aaaaaaaa-0000-0000-0000-000000000001', role, email },
      process.env.JWT_SECRET,
      { expiresIn: '8h' }
    );
    resolve(token);
  });
}

async function makeApiRequest(path, options = {}) {
  return new Promise((resolve) => {
    const req = http.request(`http://localhost:3000${path}`, options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body }));
    });
    req.on('error', (err) => resolve({ status: 500, error: err.message }));
    if (options.body) req.write(options.body);
    req.end();
  });
}

async function runAudit() {
  console.log('=== STARTING EVIDENCE-BASED AUDIT & VERIFICATION ===');
  
  // 1. RBAC & Auth Verification
  console.log('\n--- 1. Auth & RBAC Verification ---');
  const validToken = await getJwtToken('PRINCIPAL');
  const badRoleToken = await getJwtToken('STUDENT');
  
  const test1 = await makeApiRequest('/api/db/principal/v_dashboard_summary', {
    method: 'GET',
    headers: { 'Authorization': `Bearer ${validToken}` }
  });
  console.log(`Valid Token (Principal) Access to principal.v_dashboard_summary: Status ${test1.status}`);

  const test2 = await makeApiRequest('/api/db/principal/v_dashboard_summary', {
    method: 'GET',
    headers: { 'Authorization': `Bearer ${badRoleToken}` }
  });
  console.log(`Unauthorized Role (Student) Access to principal.v_dashboard_summary: Status ${test2.status}`);

  const test3 = await makeApiRequest('/api/db/principal/v_dashboard_summary', {
    method: 'GET',
    headers: { 'Authorization': `Bearer invalid.jwt.token` }
  });
  console.log(`Invalid Token Access to principal.v_dashboard_summary: Status ${test3.status}`);

  const test4 = await makeApiRequest('/api/db/principal/v_dashboard_summary', {
    method: 'GET'
  });
  console.log(`Missing Token Access to principal.v_dashboard_summary: Status ${test4.status}`);

  // 2. Database Schema Inspection
  console.log('\n--- 2. Database Schema & Object Inspection ---');
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  try {
    await client.connect();
    console.log('Connected to PostgreSQL successfully.');

    const tablesRes = await client.query(`
      SELECT table_schema, table_name, table_type 
      FROM information_schema.tables 
      WHERE table_schema IN ('principal', 'faculty', 'student', 'public', 'admin', 'hod', 'dean')
      ORDER BY table_schema, table_name;
    `);
    console.log(`Total database tables/views discovered in relevant schemas: ${tablesRes.rowCount}`);

    const constraintsRes = await client.query(`
      SELECT constraint_name, table_schema, table_name, constraint_type 
      FROM information_schema.table_constraints 
      WHERE table_schema IN ('principal', 'faculty', 'student', 'public', 'admin')
    `);
    console.log(`Total constraints (PK, FK, UNIQUE, CHECK) discovered: ${constraintsRes.rowCount}`);

  } catch (err) {
    console.error('Database connection error:', err.message);
  }

  // 3. Multi-Viewport Route Testing in Chromium
  console.log('\n--- 3. Multi-Viewport Route Testing in Chromium ---');
  const routes = [
    '/#/dashboard',
    '/#/institution-overview',
    '/#/academic-performance',
    '/#/result-analytics',
    '/#/department-performance',
    '/#/faculty-performance',
    '/#/student-performance',
    '/#/attendance-analytics',
    '/#/examination-monitoring',
    '/#/research-innovation',
    '/#/scholarships',
    '/#/placement-dashboard',
    '/#/approvals',
    '/#/circulars',
    '/#/meetings-calendar',
    '/#/reports-analytics',
    '/#/audit-compliance',
    '/#/notifications',
    '/#/my-profile'
  ];

  const viewports = [
    { width: 1440, height: 900, name: '1440x900' },
    { width: 1024, height: 768, name: '1024x768' },
    { width: 768, height: 1024, name: '768x1024' },
    { width: 375, height: 812, name: '375x812' }
  ];

  const browser = await chromium.launch({ headless: true });
  const routeResults = [];

  for (const vp of viewports) {
    console.log(`\nTesting Viewport: ${vp.name}`);
    const context = await browser.newContext({ viewport: { width: vp.width, height: vp.height } });
    const page = await context.newPage();

    const consoleErrors = [];
    const pageErrors = [];
    const failedRequests = [];

    page.on('console', msg => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });
    page.on('pageerror', err => pageErrors.push(err.message));
    page.on('response', res => {
      if (res.status() >= 400) {
        failedRequests.push(`${res.request().method()} ${res.url()} -> ${res.status()}`);
      }
    });

    // Authenticate session
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
    await page.evaluate(jwt => window.localStorage.setItem('principal_portal_token', jwt), validToken);

    for (const r of routes) {
      const startErrors = consoleErrors.length;
      const startPageErrors = pageErrors.length;
      const startFailed = failedRequests.length;

      try {
        await page.goto(`http://localhost:8080${r}`, { waitUntil: 'load', timeout: 10000 });
        await page.waitForTimeout(1000);

        const newErrors = consoleErrors.length - startErrors;
        const newPageErrors = pageErrors.length - startPageErrors;
        const newFailed = failedRequests.length - startFailed;

        routeResults.push({
          route: r,
          viewport: vp.name,
          status: (newPageErrors === 0 && newFailed === 0) ? 'PASS' : 'FAIL',
          consoleErrors: newErrors,
          pageErrors: newPageErrors,
          failedRequests: newFailed
        });
      } catch (err) {
        routeResults.push({
          route: r,
          viewport: vp.name,
          status: 'FAIL',
          error: err.message
        });
      }
    }

    await context.close();
  }

  await browser.close();
  if (client) await client.end();

  console.log('\n--- Route Testing Summary ---');
  const totalRouteTests = routeResults.length;
  const passedRouteTests = routeResults.filter(r => r.status === 'PASS').length;
  console.log(`Total Route-Viewport Tests Executed: ${totalRouteTests}`);
  console.log(`Passed: ${passedRouteTests}`);
  console.log(`Failed: ${totalRouteTests - passedRouteTests}`);

  fs.writeFileSync('audit_results.json', JSON.stringify({
    rbac: { test1, test2, test3, test4 },
    routeResults
  }, null, 2));

  console.log('\nAudit execution complete. Saved to audit_results.json');
}

runAudit().catch(err => console.error(err));
