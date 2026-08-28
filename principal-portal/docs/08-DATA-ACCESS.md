# 08 — Data Access

This document replaces what would normally be "API documentation".

> **There are no API endpoints written by this project.** There is no backend,
> no controllers, no routes. What exists instead is **26 repository files**, each
> making direct PostgREST calls.
>
> If you came here looking for `POST /api/students`, it does not exist. This is
> the equivalent.

---

## How a request is actually made

```dart
final rows = await SupabaseService
    .schema(DbSchema.student)   // which shelf of the cupboard
    .from('students')           // which box
    .select();                  // give me the cards
```

That becomes one HTTPS request:

```
GET  <project>.supabase.co/rest/v1/students
Accept-Profile: student
apikey: <the public anon key>
```

**No authorization header beyond the public key**, because there is no user.

> **Explain Like I'm 5**
>
> Normally you write code on a server that says "when someone asks for
> /students, run this SQL". PostgREST skips that: every table already has a web
> address, automatically. You just say which shelf and which box.

---

## `SupabaseService` — the only place the connection lives

`lib/core/services/supabase_service.dart`

| Member | Does |
|---|---|
| `initialise()` | called once from `main()`; safe when credentials are absent |
| `isReady` | true when a live connection exists |
| `schema(name)` | returns a client scoped to one schema |

**A failed initialisation does not crash the app.** The cause is printed and
`isReady` stays false, so every screen shows its error state rather than a white
page.

### The five schema constants

```dart
class DbSchema {
  static const String principal = 'principal';  // read and write
  static const String student   = 'student';    // read only
  static const String faculty   = 'faculty';    // read only, 1 exception
  static const String hod       = 'hod';        // read only
  static const String timetable = 'timetable';  // declared, not used
}
```

> ⚠️ **`timetable` is declared but no repository uses it.** It is a placeholder.

> ⚠️ **A schema must be ticked under Settings → API → Exposed schemas** in
> Supabase, or every query against it returns *"Invalid schema"*. This is the
> single most common setup failure.

---

## `Repository` — the base class

`lib/core/services/repository.dart`. Every repository extends it.

| Method | Purpose |
|---|---|
| `load<T>()` | run a read, report where the result came from, throw honestly on failure |
| `insertRow(table, values)` | insert into a **`principal`** table |
| `updateRow(table, id, values)` | update a **`principal`** row |
| `deleteRow(table, id)` | delete a **`principal`** row |
| `gather<T>(sources)` | run several reads, keep whatever succeeds |

**The three write helpers only ever target `principal`.** The one write to
another schema is made explicitly in the approvals repository, so it is
impossible to do by accident.

### Row-reading helpers

Column names differ between the three portal schemas for what is conceptually
the same field. `SupabaseRow` handles that:

| Helper | Use |
|---|---|
| `str(key)` | trimmed string, `null` when blank |
| `intOr` / `doubleOr` / `boolOr` / `dateOr` | typed read with a fallback |
| `firstStr([keys])` | **the important one** — first non-null among several names |

```dart
row.firstStr(['roll_no', 'register_no', 'roll_number', 'student_id'])
```

That is how one model reads a student whether the source calls the column
`roll_no` or `register_no`.

---

## Every repository

### `principal` schema — read and write

| Repository | Reads | Writes |
|---|---|---|
| `dashboard_repository` | `v_dashboard_summary`, `v_attendance_daily`, `audit_entries` | — |
| `institution_repository` | `kpi_snapshots`, `institution_metrics`, `academic_years`, `program_enrolments`, `semester_performance`, `facility_stats`, `institution_highlights`, **+ `faculty.faculties`** | — |
| `department_repository` | `v_department_rollup` *(ordered `rank` ascending)* | — |
| `department_admin_repository` | `v_department_rollup` | — |
| `academic_repository` | `kpi_snapshots`, `semester_results`, `semester_result_departments`, `semester_summaries`, `subject_results` | — |
| `result_repository` | `semester_results`, `rank_holders`, **+ `faculty.marks`** | — |
| `examination_repository` | `exam_schedules`, `cia_progress`, `hall_ticket_status`, `result_publications` | — |
| `faculty_detail_repository` | `faculty_details` | — |
| `attendance_repository` | `v_attendance_daily` **or** `v_attendance_daily_by_department` | — |
| `student_achievement_repository` | `student_achievements`, `v_department_placement_summary` | — |
| `placement_repository` | `companies`, `placement_records`, `placement_drives`, `internship_records` | — |
| `accreditation_repository` | `accreditation_standings`, `criterion_progress`, `program_accreditations`, `ranking_entries`, `compliance_documents` | — |
| `finance_repository` | `kpi_snapshots`, `monthly_finance`, `department_fee_status`, `payment_mode_splits`, `scholarship_schemes`, `payroll_lines`, `expenditure_heads` | — |
| `audit_repository` | `audit_entries`, `compliance_areas`, `inspection_reports`, `policy_adherence` | — |
| `reports_repository` | `report_items`, `report_runs`, `scheduled_reports` | `report_runs` |
| `meetings_repository` | `meetings`, `meeting_minutes`, **+ `public.academic_calendar_events`** | `meetings` |
| `circulars_repository` | `circulars`, **+ `hod.department_notices`, `student.notice_board_posts`** | `circulars` |
| `principal_profile_repository` | `principal_profiles` + child tables | — |
| `research_repository` | `funded_projects`, `consultancy_projects`, `research_year_output`, **+ `faculty.research_publications`, `faculty.patents`** | — |

### Other schemas — read only

| Repository | Schema | Table |
|---|---|---|
| `student_repository` | `student` | `students` |
| `faculty_repository` | `faculty` | `faculties` *(+ `principal.v_faculty_attendance_today`)* |
| `leave_repository` | `faculty` | `leave_applications`, `faculties` |
| `notifications_repository` | `faculty` + `student` | `notifications`, `student_notifications` |

### The one cross-schema write

| Repository | Writes | To |
|---|---|---|
| `approvals_repository` | `status` | **`faculty.leave_applications`** |
| | the full decision | `principal.approval_decisions` |

Their table has `status` and `hod_remarks` but no principal column, so there is
nowhere there to record who decided or why. The row write means the Faculty
Portal sees the decision immediately; the audit record lives in our schema, so
their structure is untouched.

---

## Query patterns worth knowing

### Ordering — always state the direction

```dart
.order('rank', ascending: true)
.order('entry_date', ascending: false).limit(14)
```

**`postgrest`'s `.order()` defaults to `ascending: false`.** Every one of the 24
`.order()` calls in this project had relied on the default, so every chart was
drawn backwards — admissions rose from 2,650 to 3,410 and the chart showed them
falling. All 24 are now explicit.

**If you add an `.order()`, write the direction.**

### One view or another, chosen at call time

```dart
final view = departmentCode == null
    ? 'v_attendance_daily'
    : 'v_attendance_daily_by_department';
```

With no department, the institution-wide view. With one, the per-department
view, filtered with `.eq('department_code', departmentCode)`.

Then `.order('entry_date', ascending: false).limit(14)` — newest fourteen days —
followed by `days.reversed.toList()` so the chart reads left to right.

### Merging two schemas into one feed

```dart
final merged = await gather<AppNotification>({
  'faculty.notifications':          () => _fetch(DbSchema.faculty, 'notifications'),
  'student.student_notifications':  () => _fetch(DbSchema.student, 'student_notifications'),
});
```

`gather` keeps whatever succeeds — one schema being unavailable does not blank
the feed.

**Ids are prefixed with the schema** (`'faculty:abc-123'`) because ids are only
unique within their own table, and a merged feed would otherwise collide.

### Single-row reads keyed to a placeholder

```dart
.from('user_settings').select().eq('user_id', placeholderUserId).single()
```

`placeholderUserId` is the literal text `'placeholder-principal'`. **This is
where a real user id goes once authentication exists** — profile and settings
are the only two places it is needed.

---

## Every call is unauthenticated

Because it bears repeating: no request in this codebase carries a user identity.
The anon key is the only credential, and PostgREST grants whatever the database
grants the anon role. On `student`, `faculty` and `hod`, that currently includes
`UPDATE`.

See [15-SECURITY.md](15-SECURITY.md).

---

## Adding a new data source

1. Add the table in a **new migration**, ending with
   `select principal.apply_standard_setup('<table>');` — that applies the
   `updated_at` trigger, enables RLS, and creates the read/write policies.
2. Add a **model** in `lib/features/<area>/models/`.
3. Add a method to the area's **repository**, using `load()` and a
   `debugLabel`; read columns with `firstStr` where names may vary.
4. Expose it as a **provider**.
5. Watch it from the widget with `.when(loading:, error:, data:)` —
   **never `.value`** (see [09-ERROR-STATES.md](09-ERROR-STATES.md)).
6. **State the direction on any `.order()`.**

---

**Next:** [12-DATA-FLOWS.md](12-DATA-FLOWS.md) — the full journey, screen by
screen.
