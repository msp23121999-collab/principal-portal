const { Client } = require('pg');
const fs = require('fs');
const assert = require('assert');

const client = new Client({
  connectionString: 'postgresql://ksrce-user:ksr$2000@localhost:54320/ksrerp',
  ssl: false
});

async function run() {
  await client.connect();
  console.log('Connected to Local Docker PostgreSQL');

  // 1. Initialize Safe Environment
  await client.query(`
    DROP SCHEMA IF EXISTS principal CASCADE;
    CREATE SCHEMA principal;
    
    CREATE TABLE principal.approval_requests (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      decision text,
      remarks text,
      updated_at timestamp with time zone DEFAULT now()
    );

    CREATE TABLE principal.approval_decisions (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      source_type text NOT NULL CHECK (source_type = 'approval_request'),
      source_id text NOT NULL,
      decision text NOT NULL,
      previous_status text,
      remarks text,
      decided_by text NOT NULL,
      created_at timestamp with time zone DEFAULT now()
    );
  `);
  console.log('Tables created');

  // 2. Apply Migration
  const migrationSql = fs.readFileSync('20260815000000_atomic_decision_writes.sql', 'utf8');
  await client.query(migrationSql);
  console.log('Migration Applied');

  // 3. Seed test data
  const res = await client.query(`
    INSERT INTO principal.approval_requests (decision, remarks) 
    VALUES ('PENDING', 'Initial Request') RETURNING id;
  `);
  const reqId = res.rows[0].id;

  // 4. Test Success Scenario
  await client.query(`SELECT principal.record_decision($1, 'APPROVED', 'PENDING', 'Looks good', 'principal')`, [reqId]);
  console.log('Success Scenario Passed');

  const reqVerify = await client.query(`SELECT decision FROM principal.approval_requests WHERE id = $1`, [reqId]);
  assert.strictEqual(reqVerify.rows[0].decision, 'APPROVED');

  const auditVerify = await client.query(`SELECT * FROM principal.approval_decisions WHERE source_id = $1`, [reqId]);
  assert.strictEqual(auditVerify.rows.length, 1);
  assert.strictEqual(auditVerify.rows[0].decision, 'APPROVED');

  // 5. Test Failure Scenario (Nonexistent ID)
  try {
    const fakeId = '00000000-0000-0000-0000-000000000000';
    await client.query(`SELECT principal.record_decision($1, 'APPROVED', 'PENDING', 'Test', 'principal')`, [fakeId]);
    throw new Error('Should have failed!');
  } catch (err) {
    if (err.message.includes('not found')) {
      console.log('Nonexistent ID Scenario Passed');
    } else {
      throw err;
    }
  }

  // 6. Test Failure Scenario (Duplicate/Concurrency Status Mismatch)
  try {
    await client.query(`SELECT principal.record_decision($1, 'APPROVED', 'PENDING', 'Duplicate', 'principal')`, [reqId]);
    throw new Error('Should have failed!');
  } catch (err) {
    if (err.message.includes('Status mismatch')) {
      console.log('Duplicate Decision Scenario Passed');
    } else {
      throw err;
    }
  }

  // 7. Verify Atomicity
  // Ensure the duplicate decision attempt didn't insert a trail row
  const auditVerify2 = await client.query(`SELECT count(*) FROM principal.approval_decisions WHERE source_id = $1`, [reqId]);
  assert.strictEqual(auditVerify2.rows[0].count, '1', 'Atomicity failed: Audit trail was inserted despite error');
  console.log('Atomicity Verified');

  await client.end();
}
run().catch(console.error);
