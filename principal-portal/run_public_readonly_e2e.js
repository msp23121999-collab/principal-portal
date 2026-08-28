const { chromium } = require('playwright');

const apiUrl = (process.env.PORTAL_API_URL || 'http://localhost:3000').replace(/\/$/, '');
const webUrl = process.env.PORTAL_WEB_URL;

async function fetchStatus(path, options = {}) {
  const response = await fetch(`${apiUrl}${path}`, options);
  return { status: response.status, body: await response.text() };
}

async function main() {
  const checks = [];
  const health = await fetchStatus('/api/health');
  checks.push(['health endpoint returns 200', health.status === 200]);

  const dashboard = await fetchStatus('/api/db/principal/v_dashboard_summary');
  checks.push(['dashboard GET is not blocked by authentication', ![401, 403].includes(dashboard.status)]);

  const write = await fetchStatus('/api/db/principal/circulars', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{}',
  });
  checks.push(['anonymous writes are denied', [403, 503].includes(write.status)]);

  if (webUrl) {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    const consoleErrors = [];
    page.on('console', (message) => {
      if (message.type() === 'error') consoleErrors.push(message.text());
    });
    await page.goto(webUrl, { waitUntil: 'networkidle' });
    checks.push(['browser does not show a login route', !page.url().toLowerCase().includes('login')]);
    checks.push(['browser console has no errors', consoleErrors.length === 0]);
    await browser.close();
  }

  for (const [name, passed] of checks) console.log(`${passed ? 'PASS' : 'FAIL'} — ${name}`);
  if (checks.some(([, passed]) => !passed)) process.exitCode = 1;
}

main().catch((error) => {
  console.error(`Public read-only verification failed: ${error.message}`);
  process.exitCode = 1;
});
