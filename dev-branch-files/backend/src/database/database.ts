import { Pool, PoolClient, QueryResultRow } from 'pg';
import { config, hasDatabaseConfig } from '../config/env';

export let pool: Pool | undefined;

export const getPool = (): Pool => {
    if (!hasDatabaseConfig()) {
        throw new Error('Database configuration is missing on the API server');
    }

    if (!pool) {
        pool = new Pool({
            host: config.database.host,
            port: config.database.port,
            database: config.database.name,
            user: config.database.user,
            password: config.database.password,
            max: config.database.poolMax,
            ssl: config.database.ssl ? { rejectUnauthorized: false } : undefined,
        });
        pool.on('error', (error) => {
            console.error('Unexpected PostgreSQL pool error', error);
        });
    }

    return pool;
};

export const query = async <T extends QueryResultRow = QueryResultRow>(
    text: string,
    values: unknown[] = [],
) => getPool().query<T>(text, values);

export const withTransaction = async <T>(
    operation: (client: PoolClient) => Promise<T>,
): Promise<T> => {
    const client = await getPool().connect();
    try {
        await client.query('BEGIN');
        const result = await operation(client);
        await client.query('COMMIT');
        return result;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};

export const closeDatabase = async (): Promise<void> => {
    if (pool) {
        await pool.end();
        pool = undefined;
    }
};