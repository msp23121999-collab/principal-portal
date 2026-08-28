const http = require('http');

const baseUrl = process.env.PORTAL_API_URL || 'http://localhost:3000';
const url = new URL(baseUrl);

function request(path, { method = 'GET', headers = {}, body } = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      { hostname: url.hostname, port: url.port, path, method, headers },
      (res) => {
        let responseBody = '';
        res.on('data', (chunk) => { responseBody += chunk; });
        res.on('end', () => resolve({ status: res.statusCode, body: responseBody }));
      },
    );
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

async function run() {
  const checks = [];
  const health = await request('/api/health');
  checks.push(['health is public', health.status === 200]);

  const dashboard = await request('/api/db/principal/v_dashboard_summary');
  checks.push(['dashboard is not blocked by obsolete auth', dashboard.status !== 401 && dashboard.status !== 403]);

  const metadata = await request('/api/db/meta/tables');
  checks.push(['metadata is protected', metadata.status === 403 || metadata.status === 503]);

  const write = await request('/api/db/principal/circulars', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{}',
  });
  checks.push(['anonymous writes are blocked', write.status === 403 || write.status === 503]);

  const results = checks.map(([name, passed]) => `${passed ? 'PASS' : 'FAIL'} — ${name}`);
  console.log(results.join('\n'));
  if (checks.some(([, passed]) => !passed)) process.exitCode = 1;
}

run().catch((error) => {
  console.error(`Unable to reach ${baseUrl}: ${error.message}`);
  process.exitCode = 1;
});
