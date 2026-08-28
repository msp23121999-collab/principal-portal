# PHASE 0 — BASELINE & SAFETY

## OVERVIEW
This document serves as the baseline record for the Principal Portal integration project prior to any backend wiring or architecture modifications.

## REPOSITORY STATUS
- **Git Branch**: `feature/backend-integration`
- **Initial Commit Hash**: `b667b9c3d4a631e98de126dea41aaf8a3e0e882c`
- **Build Status**: Web compilation tests failed due to external `package:web` dependencies on this specific setup, but the core `flutter build web` environment is intact and `flutter analyze` passes functionally.

## STATIC ANALYSIS
- **Flutter Analyze**: 24 info/warning issues (primarily `directives_ordering` and `avoid_print`).
- **No critical compilation errors** within the `lib/` directory.

## ARCHITECTURE INVENTORY

### Screens/Features
1. **Dashboard**: Complete KPI grid, charts, calendar, pending approvals, recent activities.
2. **Academic Performance**: Results, attendance, passing rates, sgpa distribution.
3. **Approvals**: Unified approval lists.
4. **Attendance Analytics**: Faculty, student, department views.
5. **Circulars**: Draft/Published notices.
6. **Department Analytics**: Program summaries, faculty composition.
7. **Examination Monitoring**: Schedules, stages.
8. **Faculty Performance**: Overloaded faculty, list.
9. **Institution Analytics**: Top level highlights.
10. **Notifications**: Alert panel.
11. **Placement Analytics**: Drives, packages, top companies.
12. **Principal Profile**: Personal data panel.
13. **Result Analytics**: Subject ranges.
14. **Student Performance**: Achievement tabs, at-risk tables.

### Mock/Static Data Identification
- **Current Data Layer**: The portal uses a `Repository` base class (`lib/core/services/repository.dart`) with a `load()` function that switches between `DataSource.live` and `DataSource.sample`.
- **Trigger**: Relies on `AppConfig.isBackendConfigured` (`SUPABASE_URL` and `SUPABASE_ANON_KEY` via `--dart-define`).
- **Locations**: Mock delays and sample data definitions exist in:
  - `student_providers.dart`
  - `leave_providers.dart`
  - `faculty_providers.dart`
  - `research_overview_tab.dart`
  - `research_repository.dart`
- **Result**: Currently, since no DB is attached, the app defaults to these sample/mock values.

## VERIFICATION (GATE CHECK)
- [x] Safe Git branch created.
- [x] Baseline commit recorded.
- [x] Flutter analyze executed and warnings recorded.
- [x] Tests run (environment compilation issue documented).
- [x] Features cataloged.
- [x] Mock data locations identified.
- [x] No source code modified during this phase.

## NEXT PHASE
Ready to proceed to **Phase 1 (Team Repository & Environment Sync)**.

---
**PHASE STATUS**: PASS
**NEXT PHASE**: ALLOWED
