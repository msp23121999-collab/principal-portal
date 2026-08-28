# KSRCE Principal Portal — Primary Single Source of Truth

The **Principal Portal** is an enterprise-grade, executive decision-support system and administrative management platform designed for College Principals and senior institutional leadership at KSRCE. It unifies academic, financial, operational, institutional, research, placement, and governance metrics into a single real-time executive dashboard.

---

## 1. Project Overview

The KSRCE Principal Portal serves as the institutional command center. It bridges high-level executive visualization with granular database auditing, enabling college principals to monitor real-time academic performance, review faculty workloads, track placement statistics, manage administrative approval workflows, publish institution-wide notices, schedule committee meetings, and generate official compliance reports.

- **Target Audience:** College Principals, Vice-Principals, Deans, and Executive Directors.
- **Primary Objective:** Provide complete visibility and operational control over institutional metrics without compromising database integrity or performance.
- **Repository Context:** CAMS Engineering Ecosystem (`https://github.com/cubeaisolutionstech/CAMS-Engineering`).

---

## 2. What the Principal Portal Does

1. **Executive Monitoring:** Surfaces key performance indicators (KPIs) across all college departments, academic terms, and administrative divisions.
2. **Approval Management:** Provides a centralized workflow for approving or rejecting budget proposals, leave requests, research grants, and purchase requisitions.
3. **Academic Analytics:** Tracks pass percentages, SGPA/CGPA distribution, arrear counts, and semester performance trends.
4. **Faculty & Staff Audit:** Monitors faculty attendance, designation rollups, teaching workloads, and publication outputs.
5. **Placement & Career Tracking:** Analyzes campus drive results, package distributions (highest/average CTC), company recruitment counts, and student placement rates.
6. **Governance & Compliance:** Manages accreditation tracking (NAAC/NBA/NIRF), committee meeting minutes, official circular distribution, and executive report exports.

---

## 3. Main Features

- **Real-Time KPI Dashboards:** Institutional Overview, Department Performance, Academic Analytics, and Student Achievement.
- **Interactive Multi-Tab Views:** Seamless navigation across 19 dedicated screens with 30+ sub-tabs.
- **Approval Engine:** Synchronous atomic approval decisions with optimistic UI updates and backend audit logging.
- **Notice & Circular Publisher:** Target notices by department, role, or institution-wide audience.
- **Meeting Scheduler:** Track upcoming academic calendar events and record committee meeting minutes.
- **Data Import & Export:** Bulk CSV/Excel data ingestion pipeline and structured report exporter (CSV, PDF, JSON).
- **Responsive Layout:** Adaptive UI supporting Desktop (1920x1080), Standard Laptop (1440x900), Tablet (768x1024), and Mobile (375x812) viewports.

---

## 4. Technology Stack

| Layer | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Frontend UI** | Flutter Web (Dart 3.11+) | Multi-platform declarative Web application |
| **State Management** | Flutter Riverpod (`^2.6.1`) | Reactive state management & provider dependency injection |
| **Routing** | GoRouter (`^14.6.2`) | Declarative browser routing and preserved navigation branches |
| **Data Visualization** | `fl_chart` (`^0.69.2`) | Canvas-rendered interactive bar, line, & pie charts |
| **Data Tables** | `data_table_2` (`^2.5.15`) | Infinite-scroll & pagination enterprise data tables |
| **HTTP REST Client** | Custom `ApiClient` (`package:http`) | Standardized unauthenticated read client and protected-write boundary |
| **Backend API** | Node.js + Express.js (`server.js`) | Lightweight REST service with parameterized query handling |
| **Database Pool** | `pg` (`node-postgres`) | Connection pooling to AWS PostgreSQL DB |
| **Database Engine** | AWS EC2 PostgreSQL (`ksrerp`) | Relational database hosting 79+ tables & 8 analytical views |
| **Testing** | Flutter Test Suite & Playwright E2E | Unit, widget, accessibility, & cross-browser automation |

---

## 5. Complete Architecture

The application follows a clean 3-Tier Enterprise Architecture:

```
[ Flutter Web Frontend ]
       │
       │ (HTTP REST JSON; public GET reads)
       ▼
[ Node.js / Express REST API ]
       │
       │ (PostgreSQL Connection Pool)
       ▼
[ AWS PostgreSQL Database (ksrerp) ]
```

---

## 6. Frontend Architecture

The Flutter Web frontend is structured according to **Feature-First Architecture**:

- `lib/core/`: Shared infrastructure (Config, Routing, Services, Theme, Shared Widgets).
- `lib/features/`: Self-contained feature modules (Data, Models, Providers, Screens, Widgets).
- **Unidirectional Data Flow:** `UI Widget` → `Riverpod Provider` → `Repository` → `ApiClient` → `HTTP REST API`.

---

## 7. Backend Architecture

The backend consists of a Node.js Express server (`server.js`) serving as an API Gateway and Query Broker:

- **Route Handling:** Resolves dynamic paths such as `/api/db/:schema/:table`.
- **Query Parser:** Transforms frontend request parameters into safe, parameterized SQL statements.
- **Connection Manager:** Utilizes `pg.Pool` for efficient database socket reuse and transaction lifecycle control.
- **Sanitization & Mapping:** Resolves natural keys, table aliases, and view joins dynamically.

---

## 8. Database Architecture

The PostgreSQL database (`ksrerp`) is logically divided into domain schemas:

- `principal`: Analytical views (`v_dashboard_summary`, `v_department_rollup`, `v_attendance_daily`, `v_faculty_attendance_today`) and approval records.
- `student`: Core student profile, academic marks, attendance logs, and placement history.
- `faculty`: Faculty profiles, designations, department assignments, and appraisals.
- `hod`: Departmental governance, budget requests, and course allocations.
- `admin`: System user credentials (`admin_users`), roles, and audit trails.
- `public`: Shared reference sequences, circulars, and institutional metadata.

---

## 9. Public Read Access and Protected Writes

The Principal Portal is a direct-access dashboard. Dashboard and analytics GET requests do not require a login, JWT, browser token, or client API key. PostgreSQL remains the source of truth, and unavailable data is rendered through the existing loading, empty, or error states.

Administrative operations are not public. INSERT, UPDATE, DELETE, raw SQL, CSV import, and file upload routes require the server-side `API_KEY`; if it is not configured, writes remain disabled. The write key must never be embedded in the Flutter Web bundle.

---

## 10. API Architecture

The API endpoints adhere to REST conventions:

- `GET /api/db/principal/:view_name`: Public analytical view queries.
- `GET /api/db/:schema/:table`: Generalized query endpoint with filtering, sorting, and pagination.
- `POST /api/db/:schema/:table`: Protected record creation (e.g., Notices, Meetings).
- `PATCH /api/db/:schema/:table`: Protected record status updates (e.g., Approvals).
- `POST /api/import/:table`: Protected CSV transactional data ingestion.

---

## 11. Flutter Providers

Riverpod providers manage data lifecycle, state caching, and reactive UI binding:

- `dashboardSummaryProvider`: Fetches overall KPI metrics for the executive home screen.
- `departmentRollupProvider`: Supplies department-by-department comparison metrics.
- `approvalsProvider`: Manages pending approval requests and handles status state mutations.
- `studentPerformanceProvider`: Delivers student marks, arrear counts, and class statistics.
- `facultyRosterProvider`: Maintains faculty list, workloads, and appraisal data.
- `placementStatsProvider`: Powers campus placement analytics and top recruiter tables.
- `notificationsProvider`: Tracks circular distribution and read/unread statuses.

---

## 12. Repositories

Repositories abstract REST API communication and provide typed models to providers:

- `InstitutionRepository`: Interface for institutional highlights, KPIs, and department rollups.
- `StudentRepository`: Interface for student profiles, attendance logs, and academic records.
- `FacultyRepository`: Interface for faculty details, workloads, and department counts.
- `ApprovalsRepository`: Interface for fetching and processing principal approval actions.
- `MeetingsRepository`: Interface for calendar events and meeting minutes.
- `PlacementRepository`: Interface for recruitment drives, company details, and offers.
- `ReportsRepository`: Interface for report templates, scheduling, and execution history.

---

## 13. Services

- `ApiClient`: Standardized HTTP wrapper for public GET reads and backend-protected write requests. Handles server error codes.
- `CsvSerializer`: Client-side parser and serializer for importing/exporting structured CSV datasets.
- `ReadStateStore`: Browser-local storage for notification read/unread state only; it does not store credentials or tokens.
- `RefreshOnFocus`: Window focus listener that automatically triggers provider invalidation to refresh UI metrics upon user re-entry.

---

## 14. Routing

Declarative routing is implemented via **GoRouter** (`lib/core/routing/app_router.dart`):

- `/`: Principal Dashboard (Default home route).
- `/institution`: Institutional Analytics & Department Rollup.
- `/academic`: Academic & Examination Performance.
- `/faculty`: Faculty Roster & Appraisals.
- `/students`: Student Performance & Achievements.
- `/approvals`: Principal Approval Workflows.
- `/placements`: Campus Placements & Recruitment.
- `/research`: Research Grants & Publications.
- `/meetings`: Academic Calendar & Meetings.
- `/notifications`: Circulars & Notices.
- `/reports`: Executive Reports & Downloads.
- `/profile`: Principal Profile & Security Settings.

---

## 15. Screens & Pages

2. **DashboardScreen:** Executive KPI cards, alert feeds, and quick navigation.
3. **InstitutionAnalyticsScreen:** Department-wise comparisons, student trends, accreditation cards.
4. **AcademicPerformanceScreen:** Semester results, SGPA distributions, arrear heatmaps.
5. **FacultyOverviewScreen:** Designation breakdown, workload distributions, appraisal lists.
6. **StudentPerformanceScreen:** Student search, attendance breakdowns, top achievers.
7. **ApprovalsScreen:** Categorized tabs for pending, approved, and rejected requests.
8. **PlacementAnalyticsScreen:** Placement percentage charts, top recruiters, package metrics.
9. **ResearchInnovationScreen:** Funded projects, patents, journal publications.
10. **MeetingsCalendarScreen:** Interactive calendar view and upcoming meetings.
11. **NotificationsScreen:** Notice board, circular creator, and distribution list.
12. **ReportsScreen:** Configurable report builder, scheduled reports, and download history.
13. **PrincipalProfileScreen:** Principal profile, responsibilities, documents, and professional details.

---

## 16. Tabs

Major screens feature nested tabbed interfaces:

- **Approvals:** `Pending Requests`, `Approved History`, `Rejected History`.
- **Placement:** `Overview & Charts`, `Placement Drives`, `Companies & Offers`, `Internships`.
- **Research:** `Overview`, `Publications`, `Patents`, `Projects & Consultancy`.
- **Results:** `Result Analysis`, `Subject Analysis`, `Rank Holders`.
- **Profile:** `Personal Info`, `Responsibilities`, `Degrees`, `Research & Teaching`, and `Documents`.

---

## 17. CRUD Features

- **Create:** Publish new circulars (`CreateNoticeDialog`), schedule committee meetings (`ScheduleMeetingDialog`), upload research projects.
- **Read:** Perform filtered queries across all student, faculty, and institutional entities.
- **Update:** Approve or reject administrative requests (`ApprovalsScreen`), update profile details.
- **Delete:** Revoke circulars or draft reports.

---

## 18. Import Features

- **CSV Ingestion Pipeline:** Bulk uploading of student rosters, examination marks, and attendance logs via `test_csv_import_pipeline.js` or UI file dropzone.
- **Transaction Safety:** Data imports are executed inside PostgreSQL database transactions (`BEGIN ... COMMIT`) to ensure zero partial writes on failure.

---

## 19. Export Features

- **Data Export Engine:** Convert structured table data to CSV, JSON, or formatted report structures.
- **Client-Side Serializer:** `CsvSerializer` formats data rows into sanitized CSV strings, auto-escaping delimiters and special characters.

---

## 20. Download Features

- **Blob Downloads:** Generates instant client-side download streams for reports and CSV exports using web browser anchor elements.
- **Export Formats:** Direct download support for CSV datasets and executive summary printouts.

---

## 21. Database Connection Flow

```
Flutter Web App
     │ (HTTP POST/GET)
     ▼
Node.js Express (server.js)
     │ (pg.Pool Connection)
     ▼
AWS EC2 PostgreSQL (13.204.53.209:5432)
     │ (Schema Resolution)
     ▼
Query Execution & Result Array Return
```

---

## 22. API → Database Flow

1. Express endpoint intercepts request: `GET /api/db/principal/v_department_rollup`.
2. Validates the requested schema/table against the public-read allow-list.
3. Constructs parameterized SQL query targeting `principal.v_department_rollup`.
4. Executes query using connection pool: `pool.query(sql, params)`.
5. Returns formatted JSON response object to client.

---

## 23. UI → Provider → Repository → API Flow

```
User Action (Click / Filter)
     │
     ▼
UI Widget triggers Riverpod Provider
     │
     ▼
Provider calls Repository method
     │
     ▼
Repository invokes ApiClient.get()
     │
     ▼
ApiClient sends HTTP Request to Backend REST API
     │
     ▼
Backend returns JSON response → Repository parses Model → Provider updates State → UI Renders
```

---

## 24. Public Read / Protected Write Flow

```
1. Browser opens Flutter Web directly
2. Flutter loads the dashboard route without a login screen
3. Riverpod provider calls a feature repository
4. ApiClient sends an HTTPS GET to the Express API without credentials
5. Express validates the public read target and queries PostgreSQL
6. Real database rows return to Flutter and render in the existing UI
7. Administrative writes are denied unless a server-side API key is supplied
```

---

## 25. Local Development Setup

### Prerequisites
- **Flutter SDK:** Version 3.19.0 or later (Dart 3.11+)
- **Node.js:** Version 18.0.0 or later
- **Google Chrome:** Installed for web debugging

---

## 26. Environment Variables

Create or configure `.env` in the root workspace directory:

```env
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/DATABASE
DATABASE_SSL=true
DATABASE_POOL_MAX=20
API_KEY=<write-only-administrative-api-key>
ALLOW_RAW_SQL=false
CORS_ORIGINS=https://ksrce-principal-portal.web.app,https://ksrce-principal-portal.firebaseapp.com
```

> [!IMPORTANT]
> Never commit passwords, private keys, or production JWT secrets to public version control.

---

## 27. Backend Run Commands

From the backend directory (`finalcode-worktree/backend`):

```bash
# Install dependencies
npm install

# Check syntax
node --check server.js

# Start REST API server
node server.js
```

---

## 28. Flutter Run Commands

From the Flutter directory (`principal-portal`):

```bash
# Get dependencies
flutter pub get

# Run application on Chrome target
flutter run -d chrome --dart-define=SUPABASE_URL=http://localhost:3000
```

---

## 29. Testing Commands

```bash
# Static Code Analysis
flutter analyze

# Execute Unit & Widget Test Suite (206 Tests)
flutter test

# Run Backend Syntax Validation
node --check ../finalcode-worktree/backend/server.js
```

---

## 30. Production Build

To compile the Flutter Web application for production deployment:

```bash
flutter build web --release
```

Output bundle generated in `build/web/`.

---

## 31. Project Folder Structure

```
Principal_Portal/
├── finalcode-worktree/        # Node.js Express REST Backend & Database Scripts
│   └── backend/
│       ├── server.js          # REST API Gateway & PostgreSQL Pool Manager
│       └── package.json       # Backend Dependencies
└── principal-portal/          # Flutter Web Application
    ├── assets/                # Images, Icons, and Fonts
    ├── docs/                  # Architecture & File Purpose Documentation
    │   └── PROJECT_FILE_MAP.md
    ├── lib/
    │   ├── main.dart          # Entry point & Riverpod Scope
    │   ├── app.dart           # Routing & Theme Configuration
    │   ├── core/              # Services, Routing, Theme, Shared Widgets
    │   └── features/          # Feature Modules (13 Domain Areas)
    ├── test/                  # Test Suites (206 Passing Tests)
    ├── pubspec.yaml           # Flutter Dependencies
    └── README.md              # Project Documentation
```

---

## 32. Important Files and Their Purpose

- `lib/main.dart`: Application bootstrapping, ProviderScope initialization.
- `lib/app.dart`: App MaterialApp routing setup and global theme definitions.
- `lib/core/services/api_client.dart`: Central HTTP REST communication service.
- `lib/core/routing/app_router.dart`: Router configuration mapping paths to screens.
- `finalcode-worktree/backend/server.js`: Node.js API server connected to PostgreSQL.
- `docs/PROJECT_FILE_MAP.md`: Complete architectural and file mapping guide.

---

## 33. Git Branch Workflow

- **Repository:** `https://github.com/cubeaisolutionstech/CAMS-Engineering`
- **Target Feature Branch:** `surya`
- **Branch Workflow Rule:** Feature updates are developed on verified working branches and submitted via Pull Request to `surya` for team review. Direct hard resets, forced pushes, or unverified merges on shared branches are strictly prohibited.

---

## 34. Deployment Notes

- Deploy backend Node.js process using process manager (e.g., PM2 or Docker).
- Serve compiled Flutter Web assets (`build/web/`) via Nginx or Cloudfront CDN.
- Ensure backend API endpoint is accessible via HTTPS in production.

---

## 35. Security Rules

1. **Zero Raw SQL Exposure:** Client application never sends raw SQL queries.
2. **Parameterized Backend Queries:** All database calls utilize safe parameter placeholders ($1, $2) to prevent SQL injection.
3. **Strict Secret Isolation:** Credentials, database passwords, and JWT keys must remain exclusively inside environment variables.
4. **RBAC Validation:** Access privileges are validated server-side on every API call.

---

## 36. Current QA Status

- **Flutter Analyze:** PASSED (0 Issues found).
- **Flutter Test Suite:** PASSED (206 of 206 tests passing).
- **Flutter Web Build:** PASSED (`flutter build web --release` successful).
- **Backend Validation:** PASSED (`node --check server.js` successful).
- **Database Integrity:** PASSED (AWS PostgreSQL connection verified).

---

## 37. Remaining Deployment Configuration Tasks

*(To be finalized by cloud infrastructure & deployment team during release window)*:

1. Configure production CORS origin whitelist on Node.js backend.
2. Terminate SSL/TLS certificates on AWS ALB / Reverse Proxy.
3. Inject production environment variables (`JWT_SECRET`, DB passwords) into cloud key vault.
4. Set up production health monitor alarms for node backend process.

---

*Document Version 1.0.0 — KSRCE CAMS Engineering Team*
