# KSRCE ERP Backend

TypeScript and Express API boundary between the Flutter ERP and the existing PostgreSQL 16 database.

## Safety

- The API does not run migrations or create/alter/drop database objects.
- Database credentials belong only in `backend/.env`, which is not committed.
- The current `scripts/drop_old_faculty_tables.js` is destructive and must not be run.
- Schema inspection uses PostgreSQL catalog `SELECT` statements only.

## Local setup

```powershell
Set-Location backend
npm install
Copy-Item .env.example .env
# Edit .env with server-only AWS/Docker PostgreSQL values.
npm run build
npm run dev
```

Health endpoints:

```text
GET http://localhost:3000/api/health
GET http://localhost:3000/api/health/database
```

The first endpoint does not require database credentials. The second requires valid server-side credentials and executes only `SELECT NOW()`.

## Live schema inspection

After setting valid server-side credentials:

```powershell
npm run inspect:schema
```

This reads tables, columns, constraints, indexes, views, functions, and user/application triggers. It does not execute DDL or DML.