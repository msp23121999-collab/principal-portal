# Principal Portal — Complete Project File & Architecture Map

This document provides a comprehensive structural, architectural, and component-level file map for the KSRCE Principal Portal project. It documents the purpose, connections, inputs, outputs, key logic, and justification for every core layer across the application.

---

## 1. High-Level Architecture Map

```
  [ Flutter UI Widget ]
           │
           ▼
 [ Riverpod Provider ]
           │
           ▼
     [ Repository ]
           │
           ▼
      [ ApiClient ]
           │
           │ (HTTP REST JSON over SSL/Bearer Token)
           ▼
   [ Node.js / Express ]
           │
           │ (JWT Validation & RBAC Middleware)
           ▼
    [ PostgreSQL DB ]
           │
           ▼
  [ AWS EC2 Database ]
```

### Authentication Data Flow Architecture

```
[ Login Screen ]
       │
       │ 1. Credentials (username, password)
       ▼
[ POST /api/login ] ──► Validates against admin.admin_users
       │
       │ 2. Return Signed JWT Token
       ▼
[ StorageHelperWeb ] ──► Store token in Encrypted LocalStorage
       │
       │ 3. Attach Bearer Header to ApiClient
       ▼
[ Authorization: Bearer <JWT> ]
       │
       │ 4. Express Auth Middleware
       ▼
[ RBAC Check: is_principal == true ]
       │
       │ 5. Execute Parameterized SQL Query
       ▼
[ PostgreSQL Views / Tables ]
```

---

## 2. File Connections & Relationship Matrix

```
Screen Component
    └─► Listens to Riverpod Provider
          └─► Calls Repository Interface
                └─► Invokes ApiClient methods
                      └─► Calls REST API Endpoint (`/api/db/:schema/:table`)
                            └─► Express Query Handler
                                  └─► Executes SQL on PostgreSQL View/Table
                                        └─► AWS DB Instance (`ksrerp`)
```

- **Import Pipeline:** `Import UI Dropzone` → `CsvSerializer.parse()` → `ApiClient.post('/api/import/csv')` → `Express Transaction (BEGIN ... COMMIT)` → `PostgreSQL Table`.
- **Export Pipeline:** `Export UI Button` → `Provider / Repository Data Query` → `CsvSerializer.toCsv()` → `Browser Blob Anchor Stream` → `Client File Download`.

---

## 3. Detailed File & Component Registry

### Core Application Entry & Setup

#### `lib/main.dart`
- **Purpose:** Primary application entry point.
- **What it does:** Initializes Flutter bindings, wraps the root application in a Riverpod `ProviderScope`, and boots `PrincipalPortalApp`.
- **Connects to:** `lib/app.dart`, `flutter_riverpod`.
- **Inputs:** Engine system signals.
- **Outputs:** Active Flutter Application context with state container.
- **Key Logic:** Configures global error boundary hooks and provider overrides.
- **Why it exists:** Standard Flutter initialization standard.

#### `lib/app.dart`
- **Purpose:** Core MaterialApp configuration.
- **What it does:** Configures `MaterialApp.router` with application title, color palette, responsive breakpoints, and router bindings.
- **Connects to:** `lib/core/routing/app_router.dart`, `lib/core/theme/app_theme.dart`.
- **Inputs:** `routerProvider`, theme tokens.
- **Outputs:** Root Widget tree.
- **Key Logic:** Applies Material 3 design tokens and global scroll behavior.
- **Why it exists:** Centralizes app-wide UI and routing rules.

---

### Core Services & Network Infrastructure

#### `lib/core/services/api_client.dart`
- **Purpose:** Standardized REST HTTP Client for backend communication.
- **What it does:** Handles `GET`, `POST`, `PATCH`, and `DELETE` requests to `http://localhost:3000` (or `SUPABASE_URL`), auto-attaching JWT authorization headers and parsing JSON responses.
- **Connects to:** All Repositories (`lib/features/*/data/*_repository.dart`), `finalcode-worktree/backend/server.js`.
- **Inputs:** API path, request body JSON, query parameters, auth token.
- **Outputs:** Decoded JSON Response maps or exception throws.
- **Key Logic:** Handles HTTP status codes (200 OK, 401 Unauthorized, 500 Internal Error) with structured exception throwing.
- **Why it exists:** Eliminates duplicated HTTP code across repositories and guarantees uniform auth token header propagation.

#### `lib/core/services/export/csv_serializer.dart`
- **Purpose:** Client-side CSV generation and parsing.
- **What it does:** Serializes typed model lists into RFC-4180 compliant CSV strings and parses uploaded CSV files into dynamic row maps.
- **Connects to:** `ReportsScreen`, `CsvImportDialog`, `StudentPerformanceScreen`.
- **Inputs:** List of dynamic objects or raw CSV string.
- **Outputs:** Formatted CSV string or parsed row list.
- **Key Logic:** Escapes commas, quotes, and newlines safely to prevent CSV injection vulnerabilities.
- **Why it exists:** Powers bulk import/export capabilities without requiring server-side file rendering overhead.

#### `lib/core/services/storage_helper.dart` & `storage_helper_web.dart`
- **Purpose:** Web cross-platform key-value persistence.
- **What it does:** Safely accesses browser `localStorage` to save, retrieve, and delete session tokens (`jwt_token`, `user_role`).
- **Connects to:** `ApiClient`, `LoginScreen`, `AppRouter`.
- **Inputs:** Storage key strings, target value strings.
- **Outputs:** Persisted string values or null.
- **Key Logic:** Platform-checked conditional imports avoiding Web/Native crashes.
- **Why it exists:** Maintains authentication session state across page reloads.

#### `lib/core/services/refresh_on_focus.dart`
- **Purpose:** Window focus listener service.
- **What it does:** Monitors window focus events and automatically invalidates active Riverpod providers to refresh UI metrics when the user returns to the browser tab.
- **Connects to:** `lib/main.dart`, `dashboardSummaryProvider`, `approvalsProvider`.
- **Inputs:** Window visibility state events.
- **Outputs:** Provider refresh triggers.
- **Key Logic:** Debounces focus callbacks to prevent excessive backend polling.
- **Why it exists:** Keeps executive dashboard metrics fresh without constant background polling network spam.

---

### Navigation & Routing

#### `lib/core/routing/app_router.dart`
- **Purpose:** Declarative routing controller.
- **What it does:** Uses `go_router` to map URL paths to screen widgets and enforces authentication redirect guards.
- **Connects to:** All Screen components (`lib/features/*/screens/*.dart`), `StorageHelper`.
- **Inputs:** Browser URL change events, auth state providers.
- **Outputs:** Active Screen Widget rendered inside scaffold.
- **Key Logic:** Inspects JWT presence; redirects unauthenticated users to `/login`.
- **Why it exists:** Provides web URL deep-linking support and route protection.

---

### Feature Modules & Domain Layers

#### 1. Dashboard (`lib/features/dashboard/`)
- **Primary Screen:** `dashboard_screen.dart`
- **Key Provider:** `dashboardSummaryProvider`
- **Purpose:** Executive home view displaying institutional KPIs (Total Enrolled, Faculty Count, Pass %, Placed %).
- **Connects to:** `v_dashboard_summary` view via `InstitutionRepository`.
- **Inputs:** Global filter state (Academic Year, Department).
- **Outputs:** Summary KPI cards, urgent action feeds, quick navigation cards.

#### 2. Institution & Department (`lib/features/institution/` & `lib/features/department/`)
- **Primary Screen:** `institution_analytics_screen.dart`
- **Key Provider:** `departmentRollupProvider`
- **Purpose:** Comparative analytics across all college academic departments.
- **Connects to:** `v_department_rollup` database view.
- **Inputs:** Department filter ID.
- **Outputs:** Department comparison charts, student strength metrics, faculty distribution.

#### 3. Academic & Results (`lib/features/academic/` & `lib/features/results/`)
- **Primary Screen:** `result_analytics_screen.dart`
- **Key Provider:** `resultAnalyticsProvider`
- **Purpose:** Semester result analytics, grade point distributions, and arrear counts.
- **Connects to:** `semester_summaries` view.
- **Inputs:** Batch year, semester number.
- **Outputs:** Grade distribution charts, pass/fail percentage rollups, department pass summary table.

#### 4. Faculty Management (`lib/features/faculty/`)
- **Primary Screen:** `faculty_overview_screen.dart`
- **Key Provider:** `facultyRosterProvider`
- **Purpose:** Tracks faculty designations, workloads, research papers, and feedback scores.
- **Connects to:** `faculty.faculty_details` and `v_faculty_attendance_today`.
- **Inputs:** Search query, department filter.
- **Outputs:** Designation bar chart, faculty roster table, workload details modal.

#### 5. Student Performance (`lib/features/students/`)
- **Primary Screen:** `student_performance_screen.dart`
- **Key Provider:** `studentPerformanceProvider`
- **Purpose:** Student list, attendance tracking, arrear monitoring, and achievement records.
- **Connects to:** `student.students` and `student.achievements`.
- **Inputs:** Search text, attendance threshold filter.
- **Outputs:** Student data tables, attendance progress indicators, student profile dialog.

#### 6. Approvals Workflow (`lib/features/approvals/`)
- **Primary Screen:** `approvals_screen.dart`
- **Key Provider:** `approvalsProvider`
- **Purpose:** Principal executive approval portal for budget requests, leave applications, and requisitions.
- **Connects to:** `principal.approval_requests`.
- **Inputs:** Filter status (Pending/Approved/Rejected), approval decision (Approve/Reject).
- **Outputs:** Pending request cards, decision feedback dialog, optimistic UI updates.

#### 7. Campus Placements (`lib/features/placements/`)
- **Primary Screen:** `placement_analytics_screen.dart`
- **Key Provider:** `placementStatsProvider`
- **Purpose:** Placement drive metrics, salary CTC breakdown, top recruiters list.
- **Connects to:** `student.placements` and `placement_drives`.
- **Inputs:** Academic year selector.
- **Outputs:** CTC distribution chart, recruiters data table, placed student count cards.

#### 8. Research & Publications (`lib/features/research/`)
- **Primary Screen:** `research_innovation_screen.dart`
- **Key Provider:** `researchProvider`
- **Purpose:** Tracks funded research grants, patents filed/granted, and journal publications.
- **Connects to:** `faculty.research_projects` and `faculty.publications`.
- **Inputs:** Faculty ID or department.
- **Outputs:** Grant funding totals, publication list tabs, patent status badges.

#### 9. Meetings & Calendar (`lib/features/meetings/`)
- **Primary Screen:** `meetings_calendar_screen.dart`
- **Key Provider:** `meetingsProvider`
- **Purpose:** Academic calendar tracking and committee meeting scheduling.
- **Connects to:** `public.academic_meetings`.
- **Inputs:** Meeting title, date, agenda, attendee list.
- **Outputs:** Monthly calendar grid, upcoming meeting cards, schedule meeting modal.

#### 10. Notifications & Circulars (`lib/features/notifications/`)
- **Primary Screen:** `notifications_screen.dart`
- **Key Provider:** `notificationsProvider`
- **Purpose:** Publish and view official college circulars and departmental notices.
- **Connects to:** `public.notifications`.
- **Inputs:** Notice title, content payload, target audience.
- **Outputs:** Notice list feed, create notice dialog, read confirmation log.

#### 11. Reports Engine (`lib/features/reports/`)
- **Primary Screen:** `reports_screen.dart`
- **Key Provider:** `reportsProvider`
- **Purpose:** Generate, schedule, and download executive institutional reports.
- **Connects to:** `ReportsRepository`, `CsvSerializer`.
- **Inputs:** Report template type, date range, export format (CSV/PDF).
- **Outputs:** Downloadable report file, scheduled report execution history.

#### 12. Principal Profile (`lib/features/profile/`)
- **Primary Screen:** `principal_profile_screen.dart`
- **Key Provider:** `principalProfileProvider`
- **Purpose:** Principal professional profile, qualification history, and account security.
- **Connects to:** `principal.principal_profiles`.
- **Inputs:** Password change inputs, profile updates.
- **Outputs:** Profile stat strip, tabs for degrees, responsibilities, and security preferences.

---

### Backend Components (`finalcode-worktree/backend/`)

#### `server.js`
- **Purpose:** Central REST API Gateway and PostgreSQL connection manager.
- **What it does:** Listens on HTTP port 3000, manages PostgreSQL client connection pool (`pg.Pool`), handles user authentication (`POST /api/login`), validates JWT tokens, parses REST route parameters into SQL queries, and streams JSON data back to Flutter.
- **Connects to:** AWS PostgreSQL Database (`ksrerp`), `ApiClient` (`flutter`).
- **Inputs:** HTTP REST Requests (`GET`, `POST`, `PATCH`), environment variables (`.env`).
- **Outputs:** JSON REST responses, HTTP status codes, server logs.
- **Key Logic:** Safe SQL query parameterization ($1, $2) preventing SQL injection attacks; handles view aliasing and schema routing dynamically.
- **Why it exists:** Serves as the single secure bridge between the web client and the relational database.

---

### Configuration & Infrastructure Files

#### `pubspec.yaml`
- **Purpose:** Flutter project manifest and dependency specification.
- **What it does:** Specifies Dart SDK boundaries (`^3.11.0`), Flutter packages (`flutter_riverpod`, `go_router`, `fl_chart`, `data_table_2`), asset asset paths (fonts, icons), and build configurations.
- **Why it exists:** Package manager configuration for Flutter.

#### `analysis_options.yaml`
- **Purpose:** Linter and static code quality rules.
- **What it does:** Enforces Dart linter standards, strict typing, and style conventions (`directives_ordering`, `avoid_print`).
- **Why it exists:** Guarantees zero code smells and high code quality.

---

*Document Version 1.0.0 — KSRCE Principal Portal Architecture Map*
