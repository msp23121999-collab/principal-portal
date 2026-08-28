import { Pool } from 'pg';
import { config } from './env';

export const pool = new Pool({
  host: config.database.host,
  port: config.database.port,
  database: config.database.name,
  user: config.database.user,
  password: config.database.password,
  max: config.database.poolMax,
  ssl: config.database.ssl ? { rejectUnauthorized: false } : false,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client', err);
});

export async function checkDatabaseConnection(): Promise<boolean> {
  try {
    const res = await pool.query('SELECT NOW() AS now, current_database() AS db_name');
    console.log(`AWS RDS PostgreSQL Connected: Database '${res.rows[0].db_name}' at ${res.rows[0].now}`);
    return true;
  } catch (err: any) {
    console.error(`AWS RDS PostgreSQL Connection Failure: ${err.message}`);
    return false;
  }
}

export async function closeDatabaseConnection(): Promise<void> {
  await pool.end();
}
