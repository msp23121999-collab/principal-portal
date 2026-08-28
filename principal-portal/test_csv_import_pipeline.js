const http = require('http');
const fs = require('fs');
const path = require('path');
const jwt = require('../finalcode-worktree/backend/node_modules/jsonwebtoken');
require('../finalcode-worktree/backend/node_modules/dotenv').config({ path: 'd:/Principal_Portal/.env' });

const secret = process.env.JWT_SECRET;
const token = jwt.sign(
  { id: 'aaaaaaaa-0000-0000-0000-000000000001', role: 'PRINCIPAL', email: 'principal@ksrce.ac.in' },
  secret,
  { expiresIn: '1h' }
);

function uploadCSV(filename, content, mimeType = 'text/csv') {
  return new Promise((resolve) => {
    const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
    let body = '';
    body += `--${boundary}\r\n`;
    body += `Content-Disposition: form-data; name="file"; filename="${filename}"\r\n`;
    body += `Content-Type: ${mimeType}\r\n\r\n`;
    body += content;
    body += `\r\n--${boundary}--\r\n`;

    const req = http.request('http://localhost:3000/api/import/student_achievements', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': Buffer.byteLength(body)
      }
    }, (res) => {
      let resBody = '';
      res.on('data', chunk => resBody += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(resBody || '{}') }));
    });

    req.on('error', (err) => resolve({ status: 500, error: err.message }));
    req.write(body);
    req.end();
  });
}

async function run() {
  console.log('=== CSV IMPORT PIPELINE VERIFICATION MATRIX ===\n');

  const ts = Date.now();

  // 1. Success Case
  const validCSV = `student_name,department_code,title,event,category,level,position,achieved_on
TEST_IMPORT_${ts}_1,CSE,AI Challenge Win,National AI Summit ${ts},technical,national,1st Place,2026-05-15
TEST_IMPORT_${ts}_2,ECE,Robotics Championship,RoboCon ${ts},technical,international,Runner Up,2026-06-20`;

  const r1 = await uploadCSV('valid_import.csv', validCSV);
  console.log(`1. Valid CSV Import -> Status: ${r1.status} (Expected: 201), Count: ${r1.body.count || 0} -> ${r1.status === 201 ? 'PASS ✅' : 'FAIL ❌'}`);

  // 2. Wrong File Extension
  const r2 = await uploadCSV('invalid_file.txt', validCSV, 'text/plain');
  console.log(`2. Wrong Extension (.txt) -> Status: ${r2.status} (Expected: 400), Error: "${r2.body.error}" -> ${r2.status === 400 ? 'PASS ✅' : 'FAIL ❌'}`);

  // 3. Missing Required Column
  const missingColCSV = `student_name,department_code,event,category,level,position,achieved_on
TEST_FAIL_1,CSE,Event X,technical,national,1st Place,2026-05-15`;
  const r3 = await uploadCSV('missing_col.csv', missingColCSV);
  console.log(`3. Missing Required Header -> Status: ${r3.status} (Expected: 400), Error: "${r3.body.error}" -> ${r3.status === 400 ? 'PASS ✅' : 'FAIL ❌'}`);

  // 4. Invalid Enum Value
  const invalidEnumCSV = `student_name,department_code,title,event,category,level,position,achieved_on
TEST_FAIL_2,CSE,Title Y,Event Y,technical,intergalactic,1st Place,2026-05-15`;
  const r4 = await uploadCSV('invalid_enum.csv', invalidEnumCSV);
  console.log(`4. Invalid Enum Value -> Status: ${r4.status} (Expected: 400), Errors: ${JSON.stringify(r4.body.details || r4.body.error)} -> ${r4.status === 400 ? 'PASS ✅' : 'FAIL ❌'}`);

  // 5. Invalid Foreign Key (Department Code)
  const invalidFKCSV = `student_name,department_code,title,event,category,level,position,achieved_on
TEST_FAIL_3,NONEXISTENT_DEPT,Title Z,Event Z,technical,national,1st Place,2026-05-15`;
  const r5 = await uploadCSV('invalid_fk.csv', invalidFKCSV);
  console.log(`5. Invalid Foreign Key -> Status: ${r5.status} (Expected: 400), Errors: ${JSON.stringify(r5.body.details || r5.body.error)} -> ${r5.status === 400 ? 'PASS ✅' : 'FAIL ❌'}`);

  // 6. Invalid Date Format
  const invalidDateCSV = `student_name,department_code,title,event,category,level,position,achieved_on
TEST_FAIL_4,CSE,Title W,Event W,technical,national,1st Place,2026/13/45`;
  const r6 = await uploadCSV('invalid_date.csv', invalidDateCSV);
  console.log(`6. Invalid Date Format -> Status: ${r6.status} (Expected: 400), Errors: ${JSON.stringify(r6.body.details || r6.body.error)} -> ${r6.status === 400 ? 'PASS ✅' : 'FAIL ❌'}`);

  // 7. Duplicate Record in CSV
  const dupCSV = `student_name,department_code,title,event,category,level,position,achieved_on
TEST_DUP_1,CSE,Dup Title,Dup Event,technical,national,1st Place,2026-05-15
TEST_DUP_1,CSE,Dup Title,Dup Event,technical,national,1st Place,2026-05-15`;
  const r7 = await uploadCSV('dup_record.csv', dupCSV);
  console.log(`7. Duplicate Record in File -> Status: ${r7.status} (Expected: 400), Errors: ${JSON.stringify(r7.body.details || r7.body.error)} -> ${r7.status === 400 ? 'PASS ✅' : 'FAIL ❌'}`);

  // 8. Empty CSV File
  const emptyCSV = ``;
  const r8 = await uploadCSV('empty.csv', emptyCSV);
  console.log(`8. Empty CSV File -> Status: ${r8.status} (Expected: 400), Error: "${r8.body.error}" -> ${r8.status === 400 ? 'PASS ✅' : 'FAIL ❌'}`);

  // 9. Existing DB Duplicate Violation
  const r9 = await uploadCSV('db_dup.csv', validCSV);
  console.log(`9. DB Duplicate Violation -> Status: ${r9.status} (Expected: 400), Error: "${r9.body.error}" -> ${r9.status === 400 ? 'PASS ✅' : 'FAIL ❌'}`);

  const allPass = r1.status === 201 && r2.status === 400 && r3.status === 400 && r4.status === 400 && r5.status === 400 && r6.status === 400 && r7.status === 400 && r8.status === 400 && r9.status === 400;
  console.log(`\nCSV IMPORT PIPELINE RESULT: ${allPass ? 'ALL TESTS PASSED ✅' : 'SOME TESTS FAILED ❌'}`);
}

run();
