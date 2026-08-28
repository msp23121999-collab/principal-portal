# Supabase to AWS PostgreSQL Migration Map

Audit date: 2026-08-19

Scope: read-only audit of the active Flutter source, existing backend folder, and checked-in PostgreSQL schema snapshots. No live database connection or database-changing operation was performed.

## Executive Summary

- The active Flutter app is in `frontend/` and boots from `frontend/lib/main.dart`.
- Navigation is centralized in `frontend/lib/app/router.dart` and currently routes directly to portal screens. The `/login` route redirects to `/`, so a backend login flow is not implemented in the active router.
- The app still depends on `supabase_flutter`, `flutter_dotenv`, Firebase packages, `http`, and the unused `postgres` Dart package.
- Supabase access is spread across shared, student, faculty, HOD, Dean, and Admin services. The student service is the largest first migration slice.
- The existing `backend/` directory is not an API server yet. It contains `pg` as a dependency, an `.env.example`, Firebase deployment metadata, and database scripts.
- The checked-in `database/canonical_schema.sql` is not equivalent to the reported live database. It must not be treated as the live source of truth for query generation.
- Before migration work continues, exposed Supabase credentials must be rotated and the destructive database script must be quarantined or removed after user approval.

## Current Runtime Architecture

```text
Flutter Web
  -> GoRouter portal screens
  -> module-specific Supabase service/helper
  -> Supabase PostgREST / Supabase PostgreSQL

Firebase initialization also runs from frontend/lib/main.dart, but no Firebase Auth package or active sign-in flow was found in the audited source.
```

Target architecture:

```text
Flutter Web
  -> centralized HTTPS API client
  -> AWS Node.js/TypeScript/Express API
  -> pg connection pool
  -> existing PostgreSQL 16 database and its functions/triggers/views
```

Flutter must not contain database host, port, username, password, or a PostgreSQL connection string.

## Audited Application Surfaces

| Area | Current implementation | Migration implication |
| --- | --- | --- |
| Bootstrap | `frontend/lib/main.dart` | Keep Flutter bootstrap; add API client initialization and backend session restoration. |
| Routing | `frontend/lib/app/router.dart` | Add authenticated route guards after auth exists; preserve portal screen structure. |
| State | Riverpod at app level; student `AppStateProvider`; module-local state | Keep state ownership; replace service calls behind stable module-facing APIs. |
| Auth | No active backend login flow; `/login` redirects home | Inspect live identity/password source before implementing JWT. Do not invent password migration. |
| Database access | Supabase wrappers and direct Supabase client calls | Replace with HTTP repositories; do not connect Flutter to PostgreSQL. |
| Storage | Supabase storage-style/upload paths and generated URLs in student service | Inspect live storage tables and object storage first; use backend-issued signed URLs. |
| Fallbacks | Hardcoded fallback data in shared and module services | Mark fallback data as development-only and remove from authenticated production paths after API cutover. |
| Backend | No Express/TypeScript API implementation | Create incrementally under `backend/src`; keep existing scripts read-only until reviewed. |

## Supabase Integration Inventory

### Shared Supabase boundary

| Current file | Responsibilities | New boundary |
| --- | --- | --- |
| `frontend/lib/shared/services/supabase_service.dart` | Global initialization, generic `fetchTable`, insert, and fallback data | `ApiClient`, typed repositories, and explicit API endpoints |
| `frontend/lib/modules/faculty/services/supabase_client.dart` | Shared Supabase helper for select/insert/update/delete/upsert and schema selection | `ApiClient` plus module repositories; schema names stay server-side |
| `frontend/lib/modules/faculty/services/supabase_config.dart` | Supabase URL/anon key and a hardcoded PostgreSQL connection string | Remove database connection data from Flutter; replace with one API base URL configuration |
| `frontend/lib/modules/admin/services/supabase_client_helper.dart` | Generic schema-qualified CRUD helper | Admin repository methods with allow-listed table/query ownership |
| `frontend/lib/modules/admin/shared/services/supabase_service.dart` | Admin generic CRUD wrapper | Admin service/repository layer behind role-protected API routes |
| `frontend/lib/modules/admin/services/admin_supabase_client.dart` | Admin select/insert/update/delete/order operations | Explicit admin endpoints with server-side validation and authorization |
| `frontend/lib/modules/admin/services/admin_supabase_service.dart` | Admin domain operations including circulars, meetings, audits, approvals, attendance, and more | Separate Admin, Audit, Approval, Calendar, and Attendance repositories |

### Student module: first migration slice

Primary owner: `frontend/lib/modules/student/services/supabase_service.dart`

| Existing operation | Supabase source | Proposed API | Server-side PostgreSQL responsibility |
| --- | --- | --- | --- |
| Student profile | `student.students` | `GET /api/student/profile` | Query the actual student identity mapping; enforce current-user scope |
| Family and education | `student.student_family`, `student.student_education` | `GET /api/student/family`, `GET /api/student/education` | Parameterized queries using authenticated student identity |
| Documents | `student.student_documents` with public/faculty fallbacks | `GET /api/student/documents` | Resolve canonical table from live catalog; return signed URLs, not database paths |
| Document upload | Inserts into student and public copies | `POST /api/student/documents` | One canonical write only; use storage transaction/metadata policy after inspection |
| Financials and fees | `student.student_financials`, `student.fees` | `GET /api/student/fees` | Preserve existing fee semantics; do not duplicate payment calculations |
| Profile update | `student.students` update | `PATCH /api/student/profile` | Allow-list mutable fields and audit the change |
| Notifications | `student.student_notifications` | `GET /api/student/notifications`, `PATCH /api/student/notifications/:id/read` | Preserve notification triggers and recipient logic |
| Library | `student.library_books`, `student.library_transactions` | `GET /api/student/library`, `POST /api/student/library/transactions`, `PATCH /api/student/library/transactions/:id` | Enforce student ownership and transaction rules |
| Hostel/outings | `student.hostel_outing_requests` | `GET /api/student/hostel/outings`, `POST /api/student/hostel/outings` | Validate dates and ownership; preserve approval workflow |
| Grievances | `student.grievances` | `GET /api/student/grievances`, `POST /api/student/grievances`, `PATCH /api/student/grievances/:id` | Reuse `student.process_grievance_recipient()` or equivalent live function/trigger |
| Certificates | `student.certificate_requests` | `GET /api/student/certificates`, `POST /api/student/certificates` | Preserve status transitions and audit entries |
| Achievements | `student.achievements` | `GET /api/student/achievements`, `POST /api/student/achievements` | Validate ownership and payload |
| Extra courses | `student.extra_courses`, `student.extra_course_enrollments` | `GET /api/student/extra-courses`, `POST /api/student/extra-courses/:id/enroll` | Enforce duplicate enrollment constraints server-side |
| Placements | `student.placements`, `student.placement_applications` | `GET /api/student/placements`, `GET/POST /api/student/placement-applications` | Enforce application uniqueness and eligibility |
| Notice board | `student.notice_board_posts`, `student.notice_bookmarks` | `GET /api/student/notices`, bookmark POST/DELETE endpoints | Enforce bookmark ownership |
| Marks | `faculty.assignment_marks`, faculty tables, faculty lookup | `GET /api/student/marks`, `GET /api/student/assignment-marks` | Reuse existing marks functions/triggers; do not recalculate in Flutter |
| Attendance | `student.attendance_table` with reg/student/roll fallback lookup | `GET /api/student/attendance` | Resolve canonical identifier from live schema; call existing attendance functions/views |
| Timetable | `faculty.timetables` | `GET /api/student/timetable` | Filter by authenticated student section |
| Syllabus/materials | `faculty.syllabus_uploads`, `faculty.course_materials` | `GET /api/student/syllabus`, `GET /api/student/course-materials` | Return metadata and signed file URLs |
| Exams/calendar | `public.exam_time_table`, `public.academic_calendar_events`, `public.academic_calendar` | `GET /api/student/exams`, `GET /api/student/calendar` | Select one canonical live source after catalog inspection |
| Assignments | `faculty.assignments`, assignment upload path, `faculty.assignment_marks` | `GET /api/student/assignments`, `POST /api/student/assignments/:id/submission` | Use backend upload handling and preserve assignment-mark triggers |
| Faculty/course allocations | `faculty.faculties`, `faculty.faculty_course_allocations` | `GET /api/student/faculty`, `GET /api/student/course-allocations` | Return only data visible to the student’s section/course |
| Regulations/years | `public.regulations`, academic year tables | `GET /api/student/regulations`, `GET /api/academic-years` | Read-only catalog endpoints |
| Feedback logs | Inserts to grievance/feedback tables | `POST /api/student/feedback` | Validate payload and audit; do not treat arbitrary JSON as trusted data |
| Transport | `student.transport_buses`, `student.transport_passes` | `GET /api/student/transport`, `GET /api/student/transport/pass` | Enforce current-student scope |

Student initialization currently loads profile, academic years, and multiple dashboard datasets through `AppStateProvider`; the API client should support a dashboard aggregate endpoint to avoid a request storm.

### Faculty, HOD, Dean, Principal, and Admin map

| Module | Current owners | Proposed API boundary | Priority |
| --- | --- | --- | --- |
| Faculty | `frontend/lib/modules/faculty/services/*_service.dart`, `erp_repository.dart` | `/api/faculty/dashboard`, `/profile`, `/students`, `/attendance`, `/marks`, `/assignments`, `/leave`, `/notifications`, `/timetable`, `/research` | Phase 5 |
| HOD | `frontend/lib/modules/hod/services/supabase_service.dart` and HOD screens | `/api/hod/dashboard`, `/students`, `/faculty`, `/attendance`, `/marks`, `/leave`, `/reports`, `/notifications` | Phase 6 |
| Dean | `frontend/lib/modules/dean/services/supabase_service.dart` and Dean screens | `/api/dean/dashboard`, `/departments`, `/faculty`, `/approvals`, `/reports`, `/analytics` | Phase 7 |
| Principal | `frontend/lib/modules/principal/main.dart` and connected services | `/api/principal/dashboard`, `/departments`, `/faculty`, `/students`, `/analytics`, `/reports`, `/approvals` | Phase 8 |
| Admin | `frontend/lib/modules/admin/services/*`, admin pages, and `erp_repository.dart` | `/api/admin/dashboard`, `/students`, `/faculty`, `/departments`, `/reports`, plus explicit calendar/approval/audit/config endpoints | Phase 9 |

The module endpoint list is a target boundary, not a claim that every listed screen is currently data-backed. Each endpoint requires a call-site and live-schema check before implementation.

## Authentication and Authorization Findings

- `frontend/lib/main.dart` initializes Firebase, but `firebase_auth` was not found in the audited dependency/source path.
- `frontend/lib/app/router.dart` defines a login route that redirects to `/`; this is navigation, not authentication.
- Several screens contain password fields or success messages, but those are not evidence of a working credential backend.
- No password hash table or authoritative identity source was established by this audit.

Required next step: inspect the live database catalog and existing user records, then identify whether password hashes exist in an application table or whether an external identity provider must remain in place. Do not implement password verification until that is known.

Proposed API contract:

```text
POST /api/auth/login
POST /api/auth/logout
GET  /api/auth/me
POST /api/auth/refresh
```

The API should issue a short-lived access token and refresh mechanism only after the identity source is confirmed. Every module route must use `authenticate` followed by role and ownership checks. Schema names and table names should remain server-side.

## Backend Starting Point

`backend/` currently has:

- `package.json` with `pg` and Firebase deployment tooling, but no Express, TypeScript, Zod, JWT, Helmet, CORS, rate limiting, or test framework.
- `.env.example` with `PORT`, `DATABASE_URL`, `JWT_SECRET`, and a Supabase service-role placeholder. It does not yet contain the requested split PostgreSQL settings or CORS/API configuration.
- `scripts/check_tables.js` and `scripts/test_db_data.js`, which call Supabase REST using embedded service credentials.
- `scripts/drop_old_faculty_tables.js`, which contains a destructive `DROP TABLE ... CASCADE` loop and must never be used for this migration.

Recommended backend shape after approval:

```text
backend/src/
  app.ts
  config/env.ts
  database/database.ts
  middleware/authenticate.ts
  middleware/authorize-role.ts
  middleware/error-handler.ts
  routes/health.ts
  routes/auth.ts
  routes/student.ts
  repositories/
  services/
  validators/
```

First implementation slice: read-only `GET /api/health`, `GET /api/health/database`, then student profile/dashboard reads. No schema migration is required for that slice.

## Database Evidence and Required Live Inspection

The checked-in `database/canonical_schema.sql` contains a consolidated design with 37 tables, 3 views, 2 functions, 0 triggers, and 41 `REFERENCES` occurrences by simple text count. The user-provided live baseline is approximately 238 tables, 125 foreign keys, and 83 user triggers across `_test_copy`, `admin`, `dean`, `faculty`, `hod`, `principal`, `public`, `storage`, `student`, and `timetable`.

Therefore, before repository queries are written, run these read-only catalog queries against the AWS database using a restricted inspection account or approved backend connection:

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, ordinal_position,
       data_type, udt_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position;

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
ORDER BY tc.table_schema, tc.table_name, tc.constraint_name;

SELECT n.nspname AS schema_name, c.relname AS table_name,
       t.tgname AS trigger_name, pg_get_triggerdef(t.oid) AS definition
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE NOT t.tgisinternal
ORDER BY n.nspname, c.relname, t.tgname;

SELECT n.nspname AS schema_name, p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS arguments,
       pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, p.proname;

SELECT schemaname, viewname, definition
FROM pg_views
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, viewname;
```

Record the resulting counts before any migration work and compare them after each deployment. Do not run DDL, DML, migrations, resets, deletes, truncates, or drops during this phase.

## Security Blockers

1. `frontend/lib/modules/faculty/services/supabase_config.dart` contains a hardcoded Supabase PostgreSQL connection string.
2. `backend/scripts/check_tables.js` and `backend/scripts/test_db_data.js` contain embedded Supabase service credentials.
3. `backend/scripts/drop_old_faculty_tables.js` can drop nearly every public table with `CASCADE`.
4. `backend/.env.example` references `SUPABASE_SERVICE_ROLE_KEY`, which should not be part of the AWS API configuration after migration.
5. The worktree currently contains generated build changes and zip/extracted-source changes unrelated to this audit; they should be reviewed separately and not bundled into the API migration.

Recommended operational response: rotate/revoke the exposed credentials in their respective providers, remove secrets from tracked history according to the repository’s secret-remediation process, and quarantine the destructive script. Those actions are separate from the read-only migration audit and should be approved before execution.

## Incremental Migration Checklist

### Before implementation

- [x] Flutter entrypoint and routing inspected.
- [x] Supabase dependencies and service owners inventoried.
- [x] Existing backend folder inspected.
- [x] Checked-in schema snapshots compared with the reported live baseline.
- [ ] Live PostgreSQL catalog exported read-only.
- [ ] Password/hash and identity source confirmed.
- [ ] PostgreSQL backup and restore test confirmed by the database owner.
- [ ] Exposed credentials rotated.

### Implementation order

1. Add TypeScript/Express backend scaffolding and configuration without changing database structure.
2. Add pool and read-only health endpoints.
3. Add API client and token storage in Flutter, keeping Supabase code intact.
4. Implement and test auth only after identity-source confirmation.
5. Migrate student profile, dashboard, attendance, marks, assignments, and notifications.
6. Migrate faculty, HOD, Dean, Principal, and Admin one module at a time.
7. Migrate file access and notifications after storage/trigger inspection.
8. Remove Supabase dependencies only after all call sites and fallback paths are migrated and verified.

## Remaining Supabase Dependencies

At audit time, the remaining active dependency surface includes:

- Flutter package: `supabase_flutter`.
- Shared Supabase initialization/configuration.
- Student Supabase service and helper operations.
- Faculty Supabase client/config and faculty services.
- HOD and Dean Supabase services.
- Admin Supabase helpers, client, and service wrappers.
- Schema-qualified PostgREST reads/writes across student, faculty, admin, principal, public, and related schemas.
- Supabase-oriented upload/URL logic in student assignment/document paths.
- Supabase REST inspection scripts in `backend/scripts`.

The exact count of remaining call sites should be regenerated after each module migration; this audit intentionally does not delete or rewrite them.

## Audit Conclusion

The safest first coding step is a non-destructive backend health slice followed by a read-only student profile endpoint, after live catalog inspection. The current codebase is not ready for a blanket Supabase removal because authentication ownership, duplicate schema/table names, storage behavior, and trigger/function contracts are not yet proven against the live AWS database.