require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const jwt = require('jsonwebtoken');
const db = fs.existsSync(path.join(__dirname, 'dist', 'database', 'database.js'))
    ? require('./dist/database/database')
    : require('./src/database/database');

const app = express();
const port = Number(process.env.PORT || 3000);
const storageRoot = path.join(__dirname, 'storage_buckets');
const allowedSchemas = new Set(
    (process.env.DATABASE_ALLOWED_SCHEMAS ||
        'student,faculty,hod,principal,admin,dean,public,timetable,storage')
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean),
);
const postgresExplorerTables = [
    ['admin', 'departments'],
    ['faculty', 'faculties'],
    ['faculty', 'leave_applications'],
    ['faculty', 'research_publications'],
    ['hod', 'class_advisors'],
    ['hod', 'department_notices'],
    ['hod', 'hod_leave_requests'],
    ['hod', 'mentor_assignments'],
    ['student', 'attendance_table'],
    ['timetable', 'class_timetables'],
].map(([schema, table]) => ({ schema, table }));
const allowedOrigins = ['*'];

app.use(cors({ origin: '*', credentials: false }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

if (!Number.isInteger(port) || port <= 0) throw new Error('PORT must be a positive integer');
if (!process.env.JWT_SECRET && !process.env.API_KEY) {
    throw new Error('Set JWT_SECRET or API_KEY before starting the backend');
}

const isProduction = process.env.NODE_ENV === 'production';
const requireAuth = String(process.env.REQUIRE_AUTH || (isProduction ? 'true' : 'false')).toLowerCase() === 'true';
const allowRawSql = String(process.env.ALLOW_RAW_SQL || 'false').toLowerCase() === 'true';
const identifier = (value) => typeof value === 'string' && /^[A-Za-z_][A-Za-z0-9_]*$/.test(value);
const quoteIdentifier = (value) => `"${value.replace(/"/g, '""')}"`;
const safeError = (error) => (isProduction ? 'Request failed' : error.message);

const authenticate = (request, response, next) => {
    if (!requireAuth) return next();
    const apiKey = request.get('x-api-key');
    if (process.env.API_KEY && apiKey) {
        const provided = Buffer.from(apiKey);
        const expected = Buffer.from(process.env.API_KEY);
        if (provided.length === expected.length && crypto.timingSafeEqual(provided, expected)) {
            return next();
        }
    }
    const header = request.get('authorization') || '';
    if (process.env.JWT_SECRET && header.startsWith('Bearer ')) {
        try {
            request.user = jwt.verify(header.slice(7), process.env.JWT_SECRET);
            return next();
        } catch (_) {
            return response.status(401).json({ success: false, error: 'Invalid authentication token' });
        }
    }
    return response.status(401).json({ success: false, error: 'Authentication required' });
};

const validateTarget = (request, response) => {
    const schema = request.params.schema || 'public';
    const table = request.params.table;
    if (!allowedSchemas.has(schema) || !identifier(schema) || !identifier(table)) {
        response.status(400).json({ success: false, error: 'Invalid or disallowed schema/table' });
        return null;
    }
    return { schema, table, target: `${quoteIdentifier(schema)}.${quoteIdentifier(table)}` };
};

app.disable('x-powered-by');
app.use(helmet({
    contentSecurityPolicy: false,
}));
app.use(cors({ origin: allowedOrigins, credentials: true }));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));
app.use((request, response, next) => {
    const started = Date.now();
    response.on('finish', () => {
        console.log(`${request.method} ${request.originalUrl} ${response.statusCode} ${Date.now() - started}ms`);
    });
    next();
});

fs.mkdirSync(storageRoot, { recursive: true });
app.use('/storage', express.static(storageRoot));
app.use(express.static(path.join(__dirname, '..')));
app.get('/database_inspector.html', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', 'database_inspector.html'));
});

app.get('/api/health', (_request, response) => {
    response.json({ success: true, status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/health/database', async (_request, response) => {
    try {
        const result = await db.query('SELECT NOW() AS now, current_database() AS database');
        response.json({ success: true, database: 'connected', ...result.rows[0] });
    } catch (error) {
        console.error('Database health check failed:', error.message);
        response.status(503).json({ success: false, database: 'unavailable', error: safeError(error) });
    }
});

app.get('/api/postgredb/tables', authenticate, (_request, response) => {
    response.json(postgresExplorerTables);
});

app.get('/api/postgredb/preview/:schema/:table', authenticate, async (request, response) => {
    const { schema, table } = request.params;
    const isAllowed = postgresExplorerTables.some(
        (entry) => entry.schema === schema && entry.table === table,
    );
    if (!isAllowed) {
        return response.status(403).json({ success: false, error: 'Table is not approved for browser preview' });
    }
    try {
        const result = await db.query(
            `SELECT * FROM ${quoteIdentifier(schema)}.${quoteIdentifier(table)} LIMIT 100`,
        );
        return response.json(result.rows);
    } catch (error) {
        return response.status(500).json({ success: false, error: safeError(error) });
    }
});

app.get('/api/db/meta/tables', async (_request, response) => {
    try {
        const result = await db.query(`
      SELECT table_schema, table_name
      FROM information_schema.tables
      WHERE table_schema = ANY($1::text[])
      ORDER BY table_schema, table_name
    `, [[...allowedSchemas]]);
        response.json({ success: true, count: result.rows.length, tables: result.rows });
    } catch (error) {
        response.status(500).json({ success: false, error: safeError(error) });
    }
});

app.get(['/api/db/:schema/:table', '/api/db/:table'], async (request, response) => {
    const target = validateTarget(request, response);
    if (!target) return;
    const { select = '*', orderBy, ascending = 'true', limit } = request.query;
    if (select !== '*' && !/^[A-Za-z0-9_.,\s*()]+$/.test(select)) {
        return response.status(400).json({ success: false, error: 'Invalid select parameter' });
    }
    const params = [];
    const filters = [];
    for (const [key, value] of Object.entries(request.query)) {
        if (['select', 'orderBy', 'ascending', 'limit', 'schema', 'table'].includes(key)) continue;
        if (identifier(key)) {
            params.push(value);
            filters.push(`${quoteIdentifier(key)} = $${params.length}`);
        }
    }
    let sql = `SELECT ${select} FROM ${target.target}`;
    if (filters.length) sql += ` WHERE ${filters.join(' AND ')}`;
    if (orderBy) {
        if (!identifier(orderBy)) return response.status(400).json({ success: false, error: 'Invalid orderBy column' });
        sql += ` ORDER BY ${quoteIdentifier(orderBy)} ${ascending === 'false' ? 'DESC' : 'ASC'}`;
    }
    if (limit !== undefined) {
        if (!/^\d+$/.test(String(limit))) return response.status(400).json({ success: false, error: 'Invalid limit' });
        sql += ` LIMIT ${Math.min(Number(limit), 1000)}`;
    }
    try {
        const result = await db.query(sql, params);
        response.json(result.rows);
    } catch (error) {
        response.status(500).json({ success: false, error: safeError(error) });
    }
});

const records = (body) => Array.isArray(body) ? body : [body];
const validFields = (record) => Object.keys(record || {}).filter(identifier);
const withFacultyCode = (target, record) => {
    if (target.schema !== 'faculty' || target.table !== 'faculties' || record.code) return record;
    const department = String(record.department || record.department_id || '').trim().toUpperCase();
    const match = department.match(/\(([A-Z]+)\)/);
    const code = match?.[1] || department.replace(/^DEPT_|^DEP-/, '').split(/[-_]/)[0] || 'CSE';
    return { ...record, code };
};

app.post(['/api/db/:schema/:table', '/api/db/:table'], authenticate, async (request, response) => {
    const target = validateTarget(request, response);
    if (!target) return;
    try {
        const inserted = [];
        for (const rawRecord of records(request.body)) {
            const record = withFacultyCode(target, rawRecord);
            const keys = validFields(record);
            if (!keys.length) continue;
            const values = keys.map((key) => record[key]);
            const columns = keys.map(quoteIdentifier).join(', ');
            const placeholders = values.map((_, index) => `$${index + 1}`).join(', ');
            const result = await db.query(`INSERT INTO ${target.target} (${columns}) VALUES (${placeholders}) RETURNING *`, values);
            inserted.push(...result.rows);
        }
        response.status(201).json(Array.isArray(request.body) ? inserted : inserted[0] || request.body);
    } catch (error) {
        response.status(500).json({ success: false, error: safeError(error) });
    }
});

app.patch(['/api/db/:schema/:table', '/api/db/:table'], authenticate, async (request, response) => {
    const target = validateTarget(request, response);
    if (!target) return;
    const matchColumn = request.query.matchColumn;
    const matchValue = request.query.matchValue;
    const keys = validFields(request.body);
    if (!identifier(matchColumn) || matchValue === undefined || !keys.length) {
        return response.status(400).json({ success: false, error: 'Valid matchColumn, matchValue, and fields are required' });
    }
    try {
        const values = keys.map((key) => request.body[key]);
        values.push(matchValue);
        const assignments = keys.map((key, index) => `${quoteIdentifier(key)} = $${index + 1}`).join(', ');
        const result = await db.query(`UPDATE ${target.target} SET ${assignments} WHERE ${quoteIdentifier(matchColumn)} = $${values.length} RETURNING *`, values);
        response.json(result.rows);
    } catch (error) {
        response.status(500).json({ success: false, error: safeError(error) });
    }
});

app.delete(['/api/db/:schema/:table', '/api/db/:table'], authenticate, async (request, response) => {
    const target = validateTarget(request, response);
    if (!target) return;
    const matchColumn = request.query.matchColumn;
    const matchValue = request.query.matchValue;
    if (!identifier(matchColumn) || matchValue === undefined) {
        return response.status(400).json({ success: false, error: 'Valid matchColumn and matchValue are required' });
    }
    try {
        const result = await db.query(`DELETE FROM ${target.target} WHERE ${quoteIdentifier(matchColumn)} = $1 RETURNING *`, [matchValue]);
        response.json({ success: true, count: result.rows.length, deleted: result.rows });
    } catch (error) {
        response.status(500).json({ success: false, error: safeError(error) });
    }
});

app.post('/api/db/query', authenticate, async (request, response) => {
    if (!allowRawSql) return response.status(403).json({ success: false, error: 'Raw SQL endpoint is disabled' });
    const { sql, params = [] } = request.body || {};
    if (typeof sql !== 'string' || !sql.trim() || sql.includes(';')) {
        return response.status(400).json({ success: false, error: 'One parameterized SQL statement is required' });
    }
    try {
        const result = await db.query(sql, params);
        response.json({ success: true, count: result.rows.length, rows: result.rows });
    } catch (error) {
        response.status(500).json({ success: false, error: safeError(error) });
    }
});

const uploadStorage = multer.diskStorage({
    destination: (request, _file, callback) => {
        const bucket = identifier(request.params.bucket) ? request.params.bucket : 'general';
        const folder = identifier(request.params.folder) ? request.params.folder : 'misc';
        const directory = path.join(storageRoot, bucket, folder);
        fs.mkdirSync(directory, { recursive: true });
        callback(null, directory);
    },
    filename: (_request, file, callback) => {
        const cleanName = file.originalname.replace(/[^A-Za-z0-9._-]/g, '_');
        callback(null, `${Date.now()}-${cleanName}`);
    },
});
const upload = multer({ storage: uploadStorage, limits: { fileSize: 50 * 1024 * 1024 } });

app.post('/api/storage/:bucket/:folder/upload', authenticate, upload.single('file'), (request, response) => {
    if (!request.file) return response.status(400).json({ success: false, error: 'No file uploaded' });
    const { bucket, folder } = request.params;
    response.status(201).json({
        success: true,
        fileName: request.file.filename,
        url: `/storage/${bucket}/${folder}/${request.file.filename}`,
    });
});

// Serve Flutter Web Frontend (Release Build) & Static assets
const frontendBuildPath = path.join(__dirname, '..', 'frontend', 'build', 'web');
if (fs.existsSync(frontendBuildPath)) {
    app.use(express.static(frontendBuildPath));
}

// Serve root database inspector and static assets
app.use(express.static(__dirname));

app.use((error, _request, response, _next) => {
    console.error('Unhandled API error:', error.message);
    response.status(500).json({ success: false, error: safeError(error) });
});


if (require.main === module) {
    const server = app.listen(port, () => console.log(`CAMS ERP API listening on port ${port}`));
    const shutdown = async () => {
        server.close(async () => {
            await db.close();
            process.exit(0);
        });
    };
    process.once('SIGINT', shutdown);
    process.once('SIGTERM', shutdown);
}

module.exports = app;

// Firebase Functions entry point. The normal Node server remains available for local development.
if (process.env.FUNCTIONS_EMULATOR || process.env.FIREBASE_CONFIG) {
    const { onRequest } = require('firebase-functions/v2/https');
    exports.api = onRequest({ region: 'us-central1', cors: true }, app);
}
