# Principal Portal Architecture

## 1. System Topology

The Principal Portal is an executive dashboard built using Flutter Web, backed by a Node.js REST API server, and connected to an AWS PostgreSQL database instance.

```
+-----------------------------------------------------------------+
|                       Flutter Web Client                        |
|                                                                 |
|  - Material Design 3 UI Components                              |
|  - Riverpod 2 State Management                                  |
|  - Custom ApiClient (REST HTTP Wrapper)                         |
+-----------------------------------------------------------------+
                                |
                                | HTTP REST Requests (port 3000)
                                v
+-----------------------------------------------------------------+
|                   Node.js Express Backend                       |
|                                                                 |
|  - REST Query Parser & Dynamic Route Handlers                    |
|  - JWT Authentication & Role Authorization                      |
|  - Schema Mapping Layer                                         |
|  - PostgreSQL Client Connection Pool ('pg')                      |
+-----------------------------------------------------------------+
                                |
                                | TCP SQL Queries (port 5432)
                                v
+-----------------------------------------------------------------+
|                    AWS EC2 PostgreSQL Database                  |
|                                                                 |
|  - Database: ksrerp                                             |
|  - Target Host: 13.204.53.209                                   |
|  - Canonical Schemas: principal, faculty, student, hod, admin    |
+-----------------------------------------------------------------+
```

---

## 2. Layer Responsibilities

### Frontend (Flutter Web)
- Render executive analytics and interactive charts (`fl_chart`, `data_table_2`).
- Manage global filter state (Department, Program, Batch, Semester) via Riverpod providers.
- Maintain decoupled provider logic with safe fallback handling when base DB rosters are empty.

### Backend (Node.js REST API)
- Serve REST API endpoints `/api/db/{schema}/{table}`.
- Map schema aliases and enforce table search paths.
- Handle JWT token generation and authentication headers.

### Database (AWS PostgreSQL)
- Maintain transactional database objects across canonical schemas.
- Serve live institutional data to the Principal Portal.
