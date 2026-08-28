import { closeDatabase, query } from './database';
import { hasDatabaseConfig } from '../config/env';

const inspections = {
    tables: `
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
      AND table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY table_schema, table_name
  `,
    columns: `
    SELECT table_schema, table_name, column_name, ordinal_position,
           data_type, udt_name, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY table_schema, table_name, ordinal_position
  `,
    constraints: `
    SELECT tc.table_schema, tc.table_name, tc.constraint_name,
           tc.constraint_type, kcu.column_name,
           ccu.table_schema AS foreign_table_schema,
           ccu.table_name AS foreign_table_name,
           ccu.column_name AS foreign_column_name
    FROM information_schema.table_constraints tc
    LEFT JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
     AND tc.table_schema = kcu.table_schema
    LEFT JOIN information_schema.constraint_column_usage ccu
      ON tc.constraint_name = ccu.constraint_name
     AND tc.table_schema = ccu.table_schema
    WHERE tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE')
    ORDER BY tc.table_schema, tc.table_name, tc.constraint_name
  `,
    indexes: `
    SELECT schemaname, tablename, indexname, indexdef
    FROM pg_indexes
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY schemaname, tablename, indexname
  `,
    views: `
    SELECT schemaname, viewname, definition
    FROM pg_views
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY schemaname, viewname
  `,
    functions: `
    SELECT n.nspname AS schema_name, p.proname AS function_name,
           pg_get_function_identity_arguments(p.oid) AS arguments,
           pg_get_functiondef(p.oid) AS definition
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY n.nspname, p.proname
  `,
    triggers: `
    SELECT n.nspname AS schema_name, c.relname AS table_name,
           t.tgname AS trigger_name, pg_get_triggerdef(t.oid) AS definition
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE NOT t.tgisinternal
    ORDER BY n.nspname, c.relname, t.tgname
  `,
};

const inspect = async () => {
    if (!hasDatabaseConfig()) {
        throw new Error('Set DATABASE_HOST, DATABASE_NAME, DATABASE_USER, and DATABASE_PASSWORD first');
    }

    for (const [name, statement] of Object.entries(inspections)) {
        const result = await query(statement);
        console.log(JSON.stringify({ name, rows: result.rows }, null, 2));
    }
};

inspect()
    .catch((error) => {
        console.error(error instanceof Error ? error.message : error);
        process.exitCode = 1;
    })
    .finally(async () => {
        await closeDatabase();
    });