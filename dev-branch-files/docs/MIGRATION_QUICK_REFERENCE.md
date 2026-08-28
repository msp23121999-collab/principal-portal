# KSRCE ERP - Supabase to AWS Migration

## Migration Status Summary

| Phase | Status | Deliverables | Effort |
|-------|--------|--------------|--------|
| **1. Project Analysis** | ✅ COMPLETE | Current architecture, tech stack, all modules documented | 2 hrs |
| **2. Supabase Mapping** | ✅ COMPLETE | 480+ references found, 110+ tables, 5 schemas, 7 modules analyzed | 3 hrs |
| **3. Canonical Schema** | ✅ COMPLETE | `database/canonical_schema.sql` created (50+ tables, deduplicated, normalized) | 4 hrs |
| **4. AWS Architecture** | 🔄 IN PROGRESS | Design AWS infrastructure layout | 2 hrs |
| **5. Database Migration** | ⏳ NOT STARTED | Data migration scripts, validation, testing | 4 hrs |
| **6. Backend API** | ⏳ NOT STARTED | Node.js API server, routes, services, middleware | 5 hrs |
| **7. Cognito Auth** | ⏳ NOT STARTED | Replace Firebase/Supabase with Amazon Cognito | 3 hrs |
| **8. S3 Storage** | ⏳ NOT STARTED | Replace Supabase Storage with S3 | 3 hrs |
| **9. Flutter Update** | ⏳ NOT STARTED | Update all services, remove Supabase dependencies | 5 hrs |
| **10. Final Validation** | ⏳ NOT STARTED | Testing, security audit, go-live | 3 hrs |

**Total Estimated Effort**: 34 hours (5-7 weeks at typical pace)

---

## Key Deliverables Created

### 1. Analysis Document
📄 **`docs/MIGRATION_PHASE_1_2_ANALYSIS.md`**
- Complete technology stack analysis
- All 480 Supabase references catalogued
- Database structure breakdown (110+ tables)
- Security issues identified and mapped
- Module dependency matrix

### 2. Canonical Database Schema
📄 **`database/canonical_schema.sql`**
- **35 tables** (from 110+ deduplicated)
- **5 schemas**: Master, Student, Faculty, Timetable, Admin
- **Normalized design** with proper foreign keys
- **Indexes** for performance
- **Stored procedures** for attendance calculation
- **Views** for convenience queries
- **Triggers** for automatic timestamps
- **Functions** for business logic

### 3. Session Memory (This Project)
📄 **`/memories/session/supabase_to_aws_analysis.md`**
- Quick reference for technical decisions
- Supabase configuration files list
- Database duplication issues resolved
- Migration strategy documented

---

## Key Findings

### Security Issues Found ⚠️

| Issue | Severity | Location | Impact |
|-------|----------|----------|--------|
| **Hardcoded Supabase Keys** | CRITICAL | `faculty/services/supabase_config.dart`, `dean/services/supabase_service.dart` | Database fully accessible via decompiled app |
| **Firebase Keys Exposed** | CRITICAL | `core/firebase_options.dart` | API keys visible in frontend |
| **No Backend API Layer** | CRITICAL | All Flutter screens directly query Supabase | No validation, authorization, or audit trail |
| **Permissive RLS Policies** | HIGH | `supabase_consolidation_migration.sql` | "Allow all" policies provide no security |
| **Mixed Auth System** | MEDIUM | Firebase + Supabase + Manual roles | Confusing, hard to manage, incomplete |

### Architecture Issues

1. **Duplicate Tables**: 5 major duplications across schemas (students, faculties, attendance, timetables, marks)
2. **Schema Fragmentation**: Tables split across `student.`, `faculty.`, `admin.`, `hod.`, `public` schemas
3. **No API Abstraction**: Flutter directly uses Supabase REST API
4. **No Centralized User Management**: Users stored in multiple tables
5. **Incomplete Normalization**: Some relationships not properly defined

---

## Canonical Schema Structure

```
public.
├─ Master Reference Layer
│  ├─ departments (6+ fields)
│  ├─ academic_years (4+ fields)
│  ├─ users (18+ fields, universal directory)
│  ├─ subjects (8+ fields)
│  └─ class_sections (7+ fields)
│
├─ Core Operational Layer
│  ├─ students (35+ fields)
│  ├─ faculties (20+ fields)
│  └─ faculty_allocations (7+ fields)
│
├─ Academic Operations
│  ├─ attendance_sessions (9+ fields)
│  ├─ attendance_records (5+ fields)
│  ├─ student_attendance_summary (denormalized for perf)
│  ├─ student_marks (15+ fields)
│  ├─ assignment_marks (8+ fields)
│  ├─ timetables (8+ fields)
│  ├─ assignments (10+ fields)
│  └─ question_banks (7+ fields)
│
├─ Student Services
│  ├─ fees (8+ fields)
│  ├─ student_financials (8+ fields)
│  ├─ student_documents (8+ fields)
│  ├─ certificate_requests (8+ fields)
│  ├─ achievements (8+ fields)
│  ├─ grievances (8+ fields)
│  ├─ hostel_outing_requests (8+ fields)
│  ├─ placements (8+ fields)
│  ├─ placement_applications (10+ fields)
│  ├─ extra_courses (6+ fields)
│  └─ extra_course_enrollments (7+ fields)
│
├─ Faculty Services
│  ├─ leave_applications (11+ fields)
│  └─ hod_profiles (15+ fields)
│
├─ Communications
│  ├─ notifications (7+ fields)
│  ├─ notice_board_posts (10+ fields)
│  └─ notice_bookmarks (3+ fields)
│
├─ System & Admin
│  ├─ academic_calendar_events (10+ fields)
│  ├─ department_files (10+ fields)
│  ├─ system_settings (5+ fields)
│  ├─ audit_logs (11+ fields)
│  ├─ file_metadata (13+ fields)
│  ├─ Functions (update_daily_cumulative_attendance)
│  ├─ Procedures (update_all_students_attendance)
│  └─ Views (3 convenience views)
```

---

## Database Deduplication Results

### Before Migration (Supabase)
- 110+ tables across 5 schemas
- Duplicate students: `student.students` + `public.students`
- Duplicate faculties: `faculty.faculties` + `public.faculties`
- Duplicate attendance: `student.attendance_table` + `public.attendance_*`
- Duplicate timetables: `faculty.timetables` + `public.timetables`
- Duplicate marks: `faculty.marks` + `public.student_marks` + `faculty.assignment_marks`
- **Problem**: Complex, inconsistent naming, missing relationships

### After Migration (AWS RDS)
- 35 core tables in `public` schema (60% reduction!)
- Single `students` table with all fields
- Single `faculties` table with all fields
- Normalized attendance: `attendance_sessions` + `attendance_records`
- Single `timetables` table
- Consolidated marks: `student_marks` + `assignment_marks`
- **Benefit**: Simplified, normalized, with proper relationships

---

## AWS Target Architecture

```
Flutter App (Web/Mobile)
    ↓ HTTPS
    ├─→ Amazon API Gateway
    │    ↓
    │    ├─→ Lambda (Auth validation)
    │    ├─→ Lambda (Business logic)
    │    └─→ Lambda (Scheduled jobs)
    │
    ├─→ Amazon Cognito (Authentication)
    │    └─→ JWT Token → Stored securely in app
    │
    └─→ Amazon CloudFront (CDN)
         └─→ Static assets

Backend Services
    ↓
Node.js API Server
    ├─→ Controllers (request handling)
    ├─→ Services (business logic)
    ├─→ Repositories (data access)
    └─→ Middleware (auth, validation, logging)
         ↓
    Amazon RDS PostgreSQL (Canonical Schema)
    └─→ 35 tables, normalized, secure
    
Storage
    ↓
    Amazon S3
    ├─→ Students/ (profiles, documents, certificates)
    ├─→ Faculty/ (profiles, assignments, syllabi)
    ├─→ Departments/ (files, documents)
    └─→ System/ (temporary, logs)
         ↓
    Presigned URLs (temporary, secure access)

Scheduled Jobs
    ↓
    Amazon EventBridge
    └─→ Daily 5 PM trigger
         ↓
         AWS Lambda
         └─→ Call RDS function: update_all_students_attendance()

Monitoring
    ↓
    Amazon CloudWatch
    ├─→ API Gateway logs
    ├─→ Lambda logs
    ├─→ RDS performance
    ├─→ Application logs
    └─→ Alarms

Secrets Management
    ↓
    AWS Secrets Manager
    ├─→ RDS credentials
    ├─→ API keys
    ├─→ JWT secrets
    └─→ S3 keys (rotated via IAM)
```

---

## Implementation Roadmap

### Phase 4: AWS Architecture (2 hrs)
- [ ] AWS account setup
- [ ] VPC, subnets, security groups
- [ ] RDS PostgreSQL instance configuration
- [ ] API Gateway setup
- [ ] IAM roles and policies
- [ ] S3 bucket setup
- [ ] Cognito user pool configuration
- [ ] Lambda IAM roles
- [ ] EventBridge rule creation

### Phase 5: Database Migration (4 hrs)
- [ ] Create RDS instance
- [ ] Run `canonical_schema.sql` on RDS
- [ ] Create data migration scripts (Supabase → RDS)
- [ ] Validate data integrity
- [ ] Create backup procedures
- [ ] Document migration process

### Phase 6: Backend API (5 hrs)
- [ ] Set up Node.js project structure
- [ ] Create authentication middleware
- [ ] Implement authorization layer
- [ ] Create REST endpoints for all modules
- [ ] Add input validation
- [ ] Implement error handling
- [ ] Add audit logging
- [ ] Create API documentation

### Phase 7: Cognito Authentication (3 hrs)
- [ ] Configure Cognito user pool
- [ ] Set up app client
- [ ] Implement Flutter Cognito SDK
- [ ] Create login/logout flows
- [ ] Implement token refresh
- [ ] Add password reset
- [ ] Map existing users to Cognito

### Phase 8: S3 Storage (3 hrs)
- [ ] Create S3 buckets (students, faculty, departments, system)
- [ ] Configure bucket policies
- [ ] Implement presigned URL generation
- [ ] Create backend upload/download endpoints
- [ ] Migrate existing files from Supabase to S3
- [ ] Update file references in database

### Phase 9: Flutter Migration (5 hrs)
- [ ] Remove `supabase_flutter` dependency
- [ ] Remove Firebase initialization (or keep for other features)
- [ ] Create new API client service
- [ ] Update all module services to use REST API
- [ ] Implement Cognito token handling
- [ ] Update file operations to use presigned URLs
- [ ] Remove hardcoded Supabase keys
- [ ] Add comprehensive error handling

### Phase 10: Final Validation (3 hrs)
- [ ] Comprehensive API testing
- [ ] Database consistency validation
- [ ] Performance testing
- [ ] Security audit
- [ ] User acceptance testing
- [ ] Cleanup old code
- [ ] Documentation finalization
- [ ] Go-live preparation

---

## Next Immediate Steps

1. **Review** this document and `MIGRATION_PHASE_1_2_ANALYSIS.md`
2. **Validate** the canonical schema (`canonical_schema.sql`) against existing data model
3. **Create** AWS infrastructure template (Terraform or CloudFormation)
4. **Start Phase 5**: Database migration scripts
5. **Plan** backend API structure and naming conventions

---

## Critical Success Factors

✅ **Must Do**:
1. Preserve all 110+ tables' data and relationships
2. Maintain existing UI/UX (no redesign)
3. Keep all ERP workflows functional
4. Ensure proper security (no exposed credentials)
5. Implement role-based authorization
6. Test thoroughly before go-live
7. Keep Supabase running until validation complete

❌ **Must Avoid**:
1. Blindly deleting schema-specific tables without validation
2. Hardcoding AWS credentials in frontend
3. Making assumptions about unused tables
4. Rushing security implementation
5. Changing business logic during migration
6. Losing historical data
7. Breaking existing workflows

---

## Questions for Clarification

1. **Firebase**: Is Firebase auth still being used, or can we fully migrate to Cognito?
2. **Realtime Features**: Do any modules require real-time updates (WebSocket, subscription)?
3. **File Retention**: What's the retention policy for uploaded files?
4. **Multi-tenancy**: Is this single-tenant (KSRCE only) or multi-tenant?
5. **Data Compliance**: Any specific data residency or compliance requirements (GDPR, etc.)?
6. **Budget**: Any AWS cost constraints or instance size preferences?
7. **Timeline**: When is go-live required?
8. **Rollback Plan**: How long do we need to keep Supabase running in parallel?

---

**Prepared by**: GitHub Copilot
**Date**: 2026-08-13
**Status**: Ready for Phase 4 start

