require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
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
const PUBLIC_READ_TARGETS = new Set([
    'principal.student_achievements',
    'principal.v_department_placement_summary',
    'principal.kpi_snapshots',
    'principal.monthly_finance',
    'principal.department_fee_status',
    'principal.payment_mode_splits',
    'principal.scholarship_schemes',
    'principal.payroll_lines',
    'principal.expenditure_heads',
    'principal.principal_profiles',
    'principal.v_faculty_attendance_today',
    'principal.semester_results',
    'principal.semester_summaries',
    'principal.sgpa_bands',
    'principal.grade_slices',
    'principal.attainment_levels',
    'principal.at_risk_reasons',
    'principal.yearly_pass_rates',
    'principal.rank_holders',
    'principal.faculty_details',
    'principal.approval_requests',
    'principal.approval_decisions',
    'principal.exam_schedules',
    'principal.cia_progress',
    'principal.hall_ticket_status',
    'principal.result_publications',
    'principal.companies',
    'principal.placement_records',
    'principal.placement_drives',
    'principal.internship_records',
    'principal.funded_projects',
    'principal.consultancy_projects',
    'principal.research_year_output',
    'principal.v_department_rollup',
    'principal.audit_entries',
    'principal.inspection_reports',
    'principal.policy_adherence',
    'principal.report_items',
    'principal.report_runs',
    'principal.scheduled_reports',
    'principal.circulars',
    'principal.meetings',
    'principal.meeting_agenda_items',
    'principal.meeting_minutes',
    'principal.meeting_minute_decisions',
    'principal.semester_result_departments',
    'principal.subject_results',
    'principal.institution_metrics',
    'principal.academic_years',
    'principal.semester_performance',
    'principal.facility_stats',
    'principal.institution_highlights',
    'principal.v_dashboard_summary',
    'principal.v_attendance_daily',
    'principal.v_attendance_daily_by_department',
    'principal.v_students',
    'faculty.research_publications',
    'faculty.patents',
    'faculty.notifications',
    'faculty.faculties',
    'faculty.leave_applications',
    'faculty.marks',
    'student.student_notifications',
    'student.notice_board_posts',
    'hod.department_notices',
    'public.academic_calendar_events',
    'public.notice_board_posts',
]);

const defaultCorsOrigins = [
    'https://ksrce-principal-portal.web.app',
    'https://ksrce-principal-portal.firebaseapp.com',
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://localhost:8080',
    'http://127.0.0.1:8080',
    'http://localhost:5000',
    'http://127.0.0.1:5000'
];
const envCorsOrigins = (process.env.CORS_ORIGINS || '')
    .split(',')
    .map((o) => o.trim())
    .filter((o) => o && o !== '*');
const allowedOrigins = [...new Set([...defaultCorsOrigins, ...envCorsOrigins])];

const corsOptions = {
    origin: (origin, callback) => {
        if (
            !origin ||
            allowedOrigins.includes(origin) ||
            /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
        ) {
            callback(null, true);
        } else {
            console.warn(`CORS rejected for origin: ${origin}`);
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'x-api-key', 'X-Requested-With', 'Accept'],
    optionsSuccessStatus: 200
};
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

if (!Number.isInteger(port) || port <= 0) throw new Error('PORT must be a positive integer');
const isProduction = process.env.NODE_ENV === 'production';
const allowRawSql = String(process.env.ALLOW_RAW_SQL || 'false').toLowerCase() === 'true';
const identifier = (value) => typeof value === 'string' && /^[A-Za-z_][A-Za-z0-9_]*$/.test(value);
const quoteIdentifier = (value) => `"${value.replace(/"/g, '""')}"`;
const safeError = (_error) => 'Request failed';

const requireWriteAccess = (request, response, next) => {
    const configuredKey = process.env.API_KEY;
    const providedKey = request.get('x-api-key');
    if (!configuredKey) {
        return response.status(503).json({
            success: false,
            error: 'Write operations are disabled until an API key is configured',
        });
    }
    if (!providedKey) {
        return response.status(403).json({ success: false, error: 'Write access is not public' });
    }
    try {
        const provided = Buffer.from(providedKey);
        const expected = Buffer.from(configuredKey);
        if (provided.length === expected.length && crypto.timingSafeEqual(provided, expected)) {
            request.user = { role: 'ADMIN' };
            return next();
        }
    } catch (_) {
      // Fall through to the same generic denial response.
    }
    return response.status(403).json({ success: false, error: 'Invalid write access key' });
};

const SCHEMA_ALIASES = {
    'student.student_achievements': { schema: 'principal', table: 'student_achievements' },
    'faculty.faculty_details': { schema: 'principal', table: 'faculty_details' },
    'public.program_enrolments': { schema: 'principal', table: 'program_enrolments' },
    'public.exam_schedules': { schema: 'principal', table: 'exam_schedules' },
    'public.cia_progress': { schema: 'principal', table: 'cia_progress' },
    'public.hall_ticket_status': { schema: 'principal', table: 'hall_ticket_status' },
    'public.result_publications': { schema: 'principal', table: 'result_publications' },
    'student.semester_results': { schema: 'principal', table: 'semester_results' },
    'student.rank_holders': { schema: 'principal', table: 'rank_holders' },
    'student.marks': { schema: 'faculty', table: 'marks' },
    'faculty.funded_projects': { schema: 'principal', table: 'funded_projects' },
    'faculty.consultancy_projects': { schema: 'principal', table: 'consultancy_projects' },
    'faculty.research_year_output': { schema: 'principal', table: 'research_year_output' },
    'public.companies': { schema: 'principal', table: 'companies' },
    'student.placement_records': { schema: 'principal', table: 'placement_records' },
    'student.placement_drives': { schema: 'principal', table: 'placement_drives' },
    'student.internship_records': { schema: 'principal', table: 'internship_records' },
    'principal.leave_applications': { schema: 'faculty', table: 'leave_applications' },
    'admin.meeting_minutes': { schema: 'principal', table: 'meeting_minutes' },
    'admin.academic_calendar_events': { schema: 'public', table: 'academic_calendar_events' },
    'admin.report_items': { schema: 'principal', table: 'report_items' },
    'admin.report_runs': { schema: 'principal', table: 'report_runs' },
    'admin.scheduled_reports': { schema: 'principal', table: 'scheduled_reports' },
    'admin.department_notices': { schema: 'hod', table: 'department_notices' },
    'public.notice_board_posts': { schema: 'public', table: 'notice_board_posts' },
    'principal.purchase_requisitions': { schema: 'principal', table: 'purchase_requisitions' },
    'principal.budget_proposals': { schema: 'principal', table: 'budget_proposals' },
};

const validateTarget = (request, response) => {
    let schema = request.params.schema || 'public';
    let table = request.params.table;

    const aliasKey = `${schema}.${table}`;
    if (SCHEMA_ALIASES[aliasKey]) {
        if (SCHEMA_ALIASES[aliasKey].empty) {
            response.json([]);
            return null;
        }
        schema = SCHEMA_ALIASES[aliasKey].schema;
        table = SCHEMA_ALIASES[aliasKey].table;
    }

    if (!allowedSchemas.has(schema) || !identifier(schema) || !identifier(table)) {
        response.status(400).json({ success: false, error: 'Invalid or disallowed schema/table' });
        return null;
    }

    if (!PUBLIC_READ_TARGETS.has(`${schema}.${table}`)) {
        response.status(404).json({ success: false, error: 'Resource not found' });
        return null;
    }
    
    return { schema, table, target: `${quoteIdentifier(schema)}.${quoteIdentifier(table)}` };
};

app.disable('x-powered-by');
app.use(helmet({
    contentSecurityPolicy: false,
}));
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
app.get('/storage/:bucket/:folder/:file', requireWriteAccess, (request, response) => {
    const { bucket, folder, file } = request.params;
    const safeSegment = (value) => /^[A-Za-z0-9._-]+$/.test(value) && !value.includes('..');
    if (![bucket, folder, file].every(safeSegment)) {
        return response.status(400).json({ success: false, error: 'Invalid storage path' });
    }
    const resolved = path.resolve(storageRoot, bucket, folder, file);
    if (!resolved.startsWith(`${path.resolve(storageRoot)}${path.sep}`)) {
        return response.status(400).json({ success: false, error: 'Invalid storage path' });
    }
    return response.sendFile(resolved, (error) => {
        if (error && !response.headersSent) response.status(error.statusCode === 404 ? 404 : 500).json({ success: false, error: error.statusCode === 404 ? 'File not found' : 'File access failed' });
    });
});
// Do not serve the repository root: it contains configuration and storage paths.
// The production frontend is served by Firebase Hosting; only the explicit
// database inspector route and the configured frontend build below are exposed.

app.get('/database_inspector.html', requireWriteAccess, (_req, res) => {
    res.sendFile(path.join(__dirname, '..', 'database_inspector.html'));
});

app.get('/api/health', (_request, response) => {
    response.json({ success: true, status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/api/health/database', async (_request, response) => {
    try {
        const res = await db.query('SELECT 1 AS connected');
        response.json({ success: true, database: 'connected', timestamp: new Date().toISOString() });
    } catch (err) {
        response.status(500).json({ success: false, database: 'disconnected', error: safeError(err) });
    }
});

app.get('/api/db/meta/tables', requireWriteAccess, async (_request, response) => {
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
    if (select !== '*' && !/^[A-Za-z0-9_.,\s*()!]+$/.test(select.replace(/\([^)]*\)/g, ''))) {
        return response.status(400).json({ success: false, error: 'Invalid select parameter' });
    }
    const params = [];
    const filters = [];
    for (const [key, rawValue] of Object.entries(request.query)) {
        if (['select', 'orderBy', 'ascending', 'limit', 'schema', 'table'].includes(key)) continue;
        const parts = key.split('.');
        const cleanKey = (parts.length > 1 && parts[0] === target.table ? parts[1] : parts[0]).replace(/!.*$/, '');
        if (identifier(cleanKey)) {
            let operator = '=';
            let value = rawValue;
            if (typeof value === 'string') {
                if (value.startsWith('eq.')) { operator = '='; value = value.slice(3); }
                else if (value.startsWith('neq.')) { operator = '<>'; value = value.slice(4); }
                else if (value.startsWith('like.')) { operator = 'LIKE'; value = value.slice(5); }
                else if (value.startsWith('ilike.')) { operator = 'ILIKE'; value = value.slice(6); }
                else if (value.startsWith('gt.')) { operator = '>'; value = value.slice(3); }
                else if (value.startsWith('gte.')) { operator = '>='; value = value.slice(4); }
                else if (value.startsWith('lt.')) { operator = '<'; value = value.slice(3); }
                else if (value.startsWith('lte.')) { operator = '<='; value = value.slice(4); }
                else if (value.startsWith('is.')) { 
                    operator = 'IS'; 
                    value = value.slice(3).toUpperCase();
                    if (value === 'NULL' || value === 'NOT NULL') {
                        filters.push(`t.${quoteIdentifier(cleanKey)} ${operator} ${value}`);
                        continue;
                    }
                }
                else if (value.startsWith('in.')) {
                    const list = value.slice(3).replace(/^\((.*)\)$/, '$1').split(',');
                    const placeholders = list.map(v => { params.push(v); return `$${params.length}`; });
                    filters.push(`t.${quoteIdentifier(cleanKey)} IN (${placeholders.join(', ')})`);
                    continue;
                }
                else if (value.includes('%')) { operator = 'LIKE'; }
            }
            params.push(value);
            filters.push(`t.${quoteIdentifier(cleanKey)} ${operator} $${params.length}`);
        }
    }

    let parsedSelect = [];
    let inParen = false;
    let currentToken = '';
    for (let i = 0; i < select.length; i++) {
        const char = select[i];
        if (char === '(') inParen = true;
        else if (char === ')') inParen = false;
        if (char === ',' && !inParen) {
            if (currentToken.trim()) parsedSelect.push(currentToken.trim());
            currentToken = '';
        } else {
            currentToken += char;
        }
    }
    if (currentToken.trim()) parsedSelect.push(currentToken.trim());

    const finalSelects = [];
    for (const token of parsedSelect) {
        const match = token.match(/^([A-Za-z0-9_]+)(?:![A-Za-z0-9_]+)?\((.*)\)$/);
        if (match) {
            const relTable = match[1];
            const rawCols = match[2];
            let relCols = '*';
            if (rawCols && !rawCols.includes('(')) {
                const validCols = rawCols.split(',').map(c => c.trim()).filter(c => identifier(c));
                if (validCols.length) relCols = validCols.map(quoteIdentifier).join(', ');
            }

            const fks = {
                departments: { type: 'many-to-one', col: 'department_id' },
                companies: { type: 'many-to-one', col: 'company_id' },
                scheduled_report_recipients: { type: 'one-to-many', col: 'scheduled_report_id' },
                meeting_agenda_items: { type: 'one-to-many', col: 'meeting_id' },
                faculty_achievements: { type: 'one-to-many', col: 'faculty_detail_id' },
                profile_education: { type: 'one-to-many', col: 'profile_id' },
                profile_research_papers: { type: 'one-to-many', col: 'profile_id' },
                profile_awards: { type: 'one-to-many', col: 'profile_id' },
                profile_documents: { type: 'one-to-many', col: 'profile_id' },
                profile_responsibilities: { type: 'one-to-many', col: 'profile_id' },
                placement_drive_departments: { type: 'one-to-many', col: 'placement_drive_id' },
                semester_result_departments: { type: 'one-to-many', col: 'semester_result_id' },
                semester_results: { type: 'many-to-one', col: 'semester_result_id' },
                meeting_minute_decisions: { type: 'one-to-many', col: 'meeting_minutes_id' },
                meetings: { type: 'many-to-one', col: 'meeting_id', schema: 'admin' }
            };

            const rel = fks[relTable];
            const relSchema = rel?.schema || target.schema;
            if (rel && rel.type === 'one-to-many') {
                finalSelects.push(`(SELECT coalesce(json_agg(row_to_json(sub)), '[]'::json) FROM (SELECT ${relCols} FROM ${quoteIdentifier(relSchema)}.${quoteIdentifier(relTable)} WHERE ${quoteIdentifier(rel.col)} = t.id) sub) AS ${quoteIdentifier(relTable)}`);
            } else {
                const fkCol = rel ? rel.col : (relTable.endsWith('ies') ? relTable.slice(0, -3) + 'y' : (relTable.endsWith('s') && !relTable.endsWith('ss') ? relTable.slice(0, -1) : relTable)) + '_id';
                finalSelects.push(`(SELECT row_to_json(sub) FROM (SELECT ${relCols} FROM ${quoteIdentifier(relSchema)}.${quoteIdentifier(relTable)} WHERE id = t.${quoteIdentifier(fkCol)}) sub) AS ${quoteIdentifier(relTable)}`);
            }
        } else {
            finalSelects.push(token === '*' ? 't.*' : `t.${quoteIdentifier(token)}`);
        }
    }

    let sql = `SELECT ${finalSelects.join(', ')} FROM ${target.target} AS t`;
    if (filters.length) sql += ` WHERE ${filters.join(' AND ')}`;
    if (orderBy) {
        if (!identifier(orderBy)) return response.status(400).json({ success: false, error: 'Invalid orderBy column' });
        sql += ` ORDER BY t.${quoteIdentifier(orderBy)} ${ascending === 'false' ? 'DESC' : 'ASC'}`;
    }
    if (limit !== undefined) {
        if (!/^\d+$/.test(String(limit))) return response.status(400).json({ success: false, error: 'Invalid limit' });
        sql += ` LIMIT ${Math.min(Number(limit), 1000)}`;
    }
    try {
        const result = await db.query(sql, params);
        response.json(result.rows);
    } catch (error) {
        console.error('API Error:', request.url, error.code || error.message);
        const status = error.code === '42P01' ? 404 : error.code === '42703' || error.code === '22P02' ? 400 : 500;
        response.status(status).json({ success: false, error: status === 404 ? 'Resource not found' : status === 400 ? 'Invalid request' : safeError(error) });
    }
});

const records = (body) => Array.isArray(body) ? body : [body];
const validFields = (record) => Object.keys(record || {}).filter(identifier);


app.post('/api/db/query', requireWriteAccess, async (request, response) => {
    if (!allowRawSql) return response.status(403).json({ success: false, error: 'Raw SQL endpoint is disabled' });
    if (request.user?.role !== 'ADMIN') return response.status(403).json({ success: false, error: 'Forbidden: Admin access required for raw SQL queries' });
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

app.post('/api/db/rpc/:schema/:function', requireWriteAccess, async (request, response) => {
    const { schema, function: func } = request.params;
    if (!identifier(schema) || !identifier(func)) {
        return response.status(400).json({ success: false, error: 'Invalid schema or function name' });
    }
    
    // Only allow specific safe functions
    const allowedFunctions = ['record_decision'];
    if (!allowedFunctions.includes(func)) {
        return response.status(403).json({ success: false, error: 'Function not allowed' });
    }
    
    try {
        const params = request.body || {};
        const keys = Object.keys(params);
        const values = keys.map(k => params[k]);
        const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');
        
        const sql = `SELECT ${quoteIdentifier(schema)}.${quoteIdentifier(func)}(${placeholders})`;
        const result = await db.query(sql, values);
        
        response.json(result.rows[0] || {});
    } catch (error) {
        response.status(500).json({ success: false, error: safeError(error) });
    }
});


app.post(['/api/db/:schema/:table', '/api/db/:table'], requireWriteAccess, async (request, response) => {
    const target = validateTarget(request, response);
    if (!target) return;
    try {
        const inserted = [];
        for (const record of records(request.body)) {
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

app.patch(['/api/db/:schema/:table', '/api/db/:table'], requireWriteAccess, async (request, response) => {
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

app.delete(['/api/db/:schema/:table', '/api/db/:table'], requireWriteAccess, async (request, response) => {
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



const sensitiveUploadName = (name) => /(^|[._-])(env|pem|key|crt|p12|pfx)$|(^|[._-])(credential|secret|private)([._-]|$)/i.test(path.basename(name));
const validateStorageRoute = (request, response, next) => {
    if (![request.params.bucket, request.params.folder].every(identifier)) {
        return response.status(400).json({ success: false, error: 'Invalid storage path' });
    }
    next();
};

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

app.post('/api/storage/:bucket/:folder/upload', requireWriteAccess, validateStorageRoute, upload.single('file'), (request, response) => {
    if (!request.file) return response.status(400).json({ success: false, error: 'No file uploaded' });
    if (sensitiveUploadName(request.file.originalname)) {
        fs.unlinkSync(request.file.path);
        return response.status(400).json({ success: false, error: 'Sensitive file types are not accepted' });
    }
    const { bucket, folder } = request.params;
    response.status(201).json({
        success: true,
        fileName: request.file.filename,
        url: `/storage/${bucket}/${folder}/${request.file.filename}`,
    });
});

function parseCSVLine(line) {
    const result = [];
    let cur = '';
    let inQuotes = false;
    for (let i = 0; i < line.length; i++) {
        const c = line[i];
        if (c === '"') {
            if (inQuotes && line[i + 1] === '"') {
                cur += '"';
                i++;
            } else {
                inQuotes = !inQuotes;
            }
        } else if (c === ',' && !inQuotes) {
            result.push(cur);
            cur = '';
        } else {
            cur += c;
        }
    }
    result.push(cur);
    return result;
}

function parseCSV(text) {
    const lines = text.split(/\r?\n/).filter(line => line.trim().length > 0);
    if (lines.length < 2) throw new Error('CSV file is empty or missing header row');
    
    const headers = parseCSVLine(lines[0]).map(h => h.trim().toLowerCase().replace(/^["']|["']$/g, ''));
    const rows = [];
    for (let i = 1; i < lines.length; i++) {
        const values = parseCSVLine(lines[i]);
        if (values.length === 1 && values[0].trim() === '') continue;
        const row = {};
        headers.forEach((h, idx) => {
            row[h] = values[idx] !== undefined ? values[idx].trim().replace(/^["']|["']$/g, '') : '';
        });
        row._line = i + 1;
        rows.push(row);
    }
    return { headers, rows };
}

app.post('/api/import/:table', requireWriteAccess, upload.single('file'), async (request, response) => {
    try {
        if (!request.file) {
            return response.status(400).json({ success: false, error: 'No file uploaded' });
        }
        
        const ext = path.extname(request.file.originalname).toLowerCase();
        if (ext !== '.csv') {
            if (fs.existsSync(request.file.path)) fs.unlinkSync(request.file.path);
            return response.status(400).json({ success: false, error: 'Invalid file extension. Only .csv files are supported.' });
        }
        
        const fileContent = fs.readFileSync(request.file.path, 'utf8');
        if (fs.existsSync(request.file.path)) fs.unlinkSync(request.file.path);
        
        let parsed;
        try {
            parsed = parseCSV(fileContent);
        } catch (parseErr) {
            return response.status(400).json({ success: false, error: `Malformed CSV: ${parseErr.message}` });
        }
        
        const { headers, rows } = parsed;
        if (rows.length === 0) {
            return response.status(400).json({ success: false, error: 'CSV file contains no data rows.' });
        }
        
        const rawTable = request.params.table;
        const cleanTable = rawTable.replace(/^principal\./, '');
        if (cleanTable !== 'student_achievements') {
            return response.status(400).json({ success: false, error: `Unsupported target table for CSV import: ${rawTable}` });
        }
        
        const reqCols = ['student_name', 'title', 'event', 'category', 'level', 'position', 'achieved_on'];
        const missingCols = reqCols.filter(col => !headers.includes(col));
        if (!headers.includes('department_code') && !headers.includes('department_id')) {
            missingCols.push('department_code');
        }
        if (missingCols.length > 0) {
            return response.status(400).json({
                success: false,
                error: `Missing required CSV header columns: ${missingCols.join(', ')}`
            });
        }
        
        const deptsRes = await db.query('SELECT id, code FROM principal.departments');
        const deptMapByCode = {};
        const deptMapById = {};
        deptsRes.rows.forEach(d => {
            deptMapByCode[d.code.toUpperCase()] = d.id;
            deptMapById[d.id] = d.id;
        });
        
        const validCategories = new Set(['technical', 'sports', 'cultural', 'academic', 'social']);
        const validLevels = new Set(['institutional', 'state', 'national', 'international']);
        
        const errors = [];
        const recordsToInsert = [];
        const seenKeys = new Set();
        
        rows.forEach((row, idx) => {
            const lineNo = row._line || (idx + 2);
            
            if (!row.student_name) errors.push(`Line ${lineNo}: 'student_name' is required`);
            if (!row.title) errors.push(`Line ${lineNo}: 'title' is required`);
            if (!row.event) errors.push(`Line ${lineNo}: 'event' is required`);
            if (!row.position) errors.push(`Line ${lineNo}: 'position' is required`);
            
            let deptId = null;
            if (row.department_code) {
                deptId = deptMapByCode[row.department_code.toUpperCase()];
                if (!deptId) errors.push(`Line ${lineNo}: Invalid department_code '${row.department_code}'`);
            } else if (row.department_id) {
                deptId = deptMapById[row.department_id];
                if (!deptId) errors.push(`Line ${lineNo}: Invalid department_id '${row.department_id}'`);
            }
            
            const cat = (row.category || '').toLowerCase();
            if (!validCategories.has(cat)) {
                errors.push(`Line ${lineNo}: Invalid category '${row.category}'. Allowed: technical, sports, cultural, academic, social`);
            }
            
            const lvl = (row.level || '').toLowerCase();
            if (!validLevels.has(lvl)) {
                errors.push(`Line ${lineNo}: Invalid level '${row.level}'. Allowed: institutional, state, national, international`);
            }
            
            const dateStr = row.achieved_on || '';
            if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr) || isNaN(Date.parse(dateStr))) {
                errors.push(`Line ${lineNo}: Invalid achieved_on date '${dateStr}'. Must be in YYYY-MM-DD format`);
            }
            
            const dupKey = `${row.student_name}|${row.title}|${row.event}|${dateStr}`.toLowerCase();
            if (seenKeys.has(dupKey)) {
                errors.push(`Line ${lineNo}: Duplicate achievement record found in CSV for '${row.student_name}' - '${row.title}'`);
            }
            seenKeys.add(dupKey);
            
            recordsToInsert.push({
                student_name: row.student_name,
                department_id: deptId,
                title: row.title,
                event: row.event,
                category: cat,
                level: lvl,
                position: row.position,
                achieved_on: dateStr
            });
        });
        
        if (errors.length > 0) {
            return response.status(400).json({
                success: false,
                error: `CSV validation failed with ${errors.length} error(s)`,
                details: errors
            });
        }
        
        const inserted = await db.withTransaction(async (client) => {
            const results = [];
            for (const rec of recordsToInsert) {
                const res = await client.query(
                    `INSERT INTO principal.student_achievements 
                    (student_name, department_id, title, event, category, level, position, achieved_on)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
                    [rec.student_name, rec.department_id, rec.title, rec.event, rec.category, rec.level, rec.position, rec.achieved_on]
                );
                results.push(res.rows[0]);
            }
            return results;
        });
        
        return response.status(201).json({
            success: true,
            count: inserted.length,
            message: `Successfully imported ${inserted.length} record(s).`,
            inserted
        });
    } catch (err) {
        console.error('Import Error:', err);
        if (err.code === '23505') {
            return response.status(400).json({
                success: false,
                error: 'Database constraint violation: duplicate record already exists',
                details: [err.detail || err.message]
            });
        }
        return response.status(500).json({ success: false, error: safeError(err) });
    }
});

// Serve Flutter Web Frontend (Release Build) & Static assets
const frontendBuildPath = path.join(__dirname, '..', 'frontend', 'build', 'web');
if (fs.existsSync(frontendBuildPath)) {
    app.use(express.static(frontendBuildPath));
}

// No broad backend-directory static serving. Explicit API and frontend-build
// routes above are the only server-owned resources exposed.


app.use((error, _request, response, _next) => {
    console.error('Unhandled API error:', error.code || error.message);
    if (error instanceof multer.MulterError) {
        return response.status(400).json({ success: false, error: 'Invalid file upload' });
    }
    if (error.message === 'Not allowed by CORS') {
        return response.status(403).json({ success: false, error: 'Origin not allowed' });
    }
    response.status(500).json({ success: false, error: 'Request failed' });
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
