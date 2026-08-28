# 14 — Business Logic

Every number on every screen, with its formula, its inputs, where it is
calculated, and a worked example.

> **Explain Like I'm 5**
>
> This document answers one question: **"where did that number come from?"**
>
> If the Principal points at "86.4%" and asks "is that right?", this page shows
> the sum that produced it.

---

## Where calculations live

There are exactly two places. Knowing which is which saves hours.

| Where | Used for | Example |
|---|---|---|
| **Postgres views** (`supabase/migrations/`) | anything that combines tables or is always true | students per department |
| **Riverpod providers** (`lib/features/*/providers/`) | anything that responds to a filter | students per department **in the current scope** |

> **Explain Like I'm 5**
>
> The database does the sums that never change based on what you clicked.
>
> The app does the sums that *do*.

---

## 1. Student thresholds — "top performer" and "at risk"

**Defined in:** `lib/features/students/data/student_repository.dart:15-17`

```dart
static const double _atRiskCgpa       = 6.5;
static const double _atRiskAttendance = 75;
static const double _topPerformerCgpa = 8.5;
```

| Flag | Rule |
|---|---|
| **Top performer** | `cgpa >= 8.5` |
| **At risk** | `(cgpa > 0 AND cgpa < 6.5)` **OR** `(attendance > 0 AND attendance < 75)` |

**The `> 0` condition matters.** A student whose CGPA has never been entered is
stored as `0`. Without that guard, *every unrecorded student* would be flagged
at risk — a screen full of red for students nobody has marked yet.

**Worked example**

| Student | CGPA | Attendance | Top? | At risk? |
|---|---|---|---|---|
| A | 8.62 | 88 | ✅ (≥8.5) | ❌ |
| B | 6.10 | 92 | ❌ | ✅ (CGPA below 6.5) |
| C | 7.80 | 68 | ❌ | ✅ (attendance below 75) |
| D | 0 | 0 | ❌ | ❌ — **not recorded, not judged** |

> ⚠️ These thresholds are **the portal's own definition**, not a college policy
> read from anywhere. They are named constants in one file so the definition is
> stated once and can be changed in one place.

---

## 2. Averages that skip zeros

This pattern appears throughout the portal. It is worth understanding once.

```dart
double average(Iterable<double> values) {
  final recorded = values.where((v) => v > 0);
  if (recorded.isEmpty) return 0;
  return recorded.reduce((a, b) => a + b) / recorded.length;
}
```

In SQL the same idea is written `avg(nullif(cgpa, 0))`.

> **Explain Like I'm 5**
>
> Ten students. Two have marks: 80 and 90. Eight have not been marked yet, so
> the computer stores 0 for them.
>
> **Wrong way:** (80 + 90 + 0×8) ÷ 10 = **17**. That looks like a disaster.
>
> **Right way:** (80 + 90) ÷ 2 = **85**. That is the truth about the students
> we actually have marks for.
>
> A blank is not a zero. Treating it as one is how a good department looks
> like a failing one.

**This was a real bug.** The Attendance "Overall Total" once showed **14.60%**
next to a card showing **86.4%** — a flat mean over ten zeros against a
weighted one. Same data, two different sums, contradicting each other on one
screen.

---

## 3. Attendance

### 3.1 Daily institution attendance — `v_attendance_daily`

```sql
select
  a.date                                          as entry_date,
  round(avg(nullif(a.attendance_percentage, 0))::numeric, 2) as overall_percent,
  count(*)                                        as records
from student.attendance_table a
where a.date is not null
group by a.date
```

**Input:** `student.attendance_table` — genuine per-student, per-period rows
(periods p1–p8), **47 rows** today.
**Output:** one row per date, **15 rows**.

### 3.2 The same, per department — `v_attendance_daily_by_department`

Identical, plus a join to `principal.departments`:

```sql
left join principal.departments d
  on upper(coalesce(a.dept, '')) like '%' || d.code || '%'
```

Two things to notice:

- The join matches on the **code found inside the text**, not on the raw value.
  `dept` arrives spelt several ways; matching raw would split one department
  into several.
- It is a **`left join`**, so rows whose department cannot be resolved are still
  counted — under a `null` department. An institution total taken from this
  view does not quietly lose them.

**Why this view exists:** the Attendance screen has four filters above it. Until
this view was added, the headline figures and trend chart could not answer the
department filter. Four controls that change nothing is worse than no controls.

### 3.3 Attendance by year of study

**Calculated in:** `attendance_providers.dart` → `attendanceByYearProvider`

Groups the **filtered** roll by `yearOfStudy`, then averages `attendancePercent`
skipping zeros (§2).

**Years with nobody on the roll are omitted, not shown as 0%.** Zero percent
reads as terrible attendance; absent reads as no data. They are different
statements.

Sorted by the Roman numeral's *meaning* — `I, II, III, IV, V` — not
alphabetically, which would put II before I and IV before III.

### 3.4 Faculty attendance — `v_faculty_attendance_today`

```sql
with latest as (
  select max(attendance_date) as on_date from principal.faculty_attendance
)
select
  fa.department_code,
  count(*)                                       as total_faculty,
  count(*) filter (where fa.status = 'present')  as present_count,
  count(*) filter (where fa.status = 'absent')   as absent_count,
  count(*) filter (where fa.status = 'on_leave') as on_leave_count,
  round(count(*) filter (where fa.status = 'present')::numeric
        / nullif(count(*), 0) * 100, 2)          as present_percent
from principal.faculty_attendance fa
join latest l on l.on_date = fa.attendance_date
group by fa.department_code, l.on_date
```

**It reports against the most recent date on record, not `current_date`.**
Otherwise the section is blank every morning until somebody marks the register —
which reads as "nobody came in" rather than "not marked yet".

`nullif(count(*), 0)` prevents division by zero: it returns `null`, and the
screen shows a dash.

> **Why this table exists at all.** `faculty.faculties.status` reads `"Active"`
> for every row. That is an *employment* state — it does not say whether someone
> came in today. Nothing recorded daily staff attendance, so the Principal
> Portal records it. Ownership risk is stated plainly in migration 17: the
> Faculty Portal is the natural long-term owner.

---

## 4. Department rollup — `v_department_rollup`

The most-read view in the system. **12 rows, one per active department.**

### 4.1 The cross-schema join

```sql
left join student.students s
  on upper(coalesce(s.department, '')) like '%' || d.code || '%'
  or upper(coalesce(s.department, '')) = d.code
```

Department names in the live tables are spelt **five different ways**. This
matches on the code inside the text, which is the SQL twin of
`DepartmentNormalizer.codeFor()` in Dart (see
[13-FILTER-SYSTEM.md](13-FILTER-SYSTEM.md)).

`left join` again — a department with no students returns **0**, not a missing
row.

### 4.2 The calculated columns

| Column | Formula |
|---|---|
| `student_count` | `count(s.*)` — counted live from `student.students` |
| `faculty_count` | `count(f.*)` — counted live from `faculty.faculties` |
| `avg_cgpa` | `avg(nullif(s.cgpa, 0))`, rounded to 2 dp |
| `attendance_percent` | `avg(nullif(s.attendance_percentage, 0))`, 2 dp |
| `pass_percent` | from `semester_result_departments` for the **latest published semester only** |
| `placement_percent` | `least(placed ÷ student_count × 100, 100)` |
| `budget_utilisation_percent` | `budget_utilised ÷ budget_allocated × 100`, `null` when allocated is 0 |
| `vacant_posts` | `sanctioned_posts − filled_posts` |
| `staffing_percent` | `filled_posts ÷ sanctioned_posts × 100` |
| `faculty_student_ratio` | `student_count ÷ faculty_count`, `null` when there is no staff |
| `rank` | `rank() over (order by avg_cgpa desc)` |

### 4.3 Three decisions worth knowing

**Pass % uses the latest published semester only.** From the migration comment:

> *"Averaging every semester ever recorded would bury a bad term under years of
> history."*

**Placement % is capped at 100** (`least(…, 100)`). Migration 14 explains why:

> *"The rollup divides seeded placement records by the LIVE student roll. Those
> two populations do not match today: 60 placements were seeded, while
> `student.students` holds 10 real rows. IOT came out at **125% placed**."*

A percentage above 100 is never right. The cap keeps the figure visible and
roughly indicative while stopping the screen claiming something impossible. The
underlying mismatch resolves on its own once the roll is realistic.

**Ratios return `null`, not `0`, when the divisor is zero.** A `null` renders as
an em dash. `0` would read as "this department has a 0:1 staff ratio", which is
a claim, not an absence.

---

## 5. Results

### 5.1 Pass percentage

**Formula:** `passed ÷ appeared × 100`

**Calculated in:** `result_providers.dart` → `departmentPassSummaryProvider`

Summed from `subject_results` rather than stored, so the table cannot drift from
the papers behind it, **and so it answers the same filters the rest of the
Result page does.**

```dart
for (final subject in subjects) {
  final code = DepartmentNormalizer.codeFor(subject.departmentCode);
  appeared[code] = (appeared[code] ?? 0) + subject.appeared;
  passed[code]   = (passed[code]   ?? 0) + subject.passed;
}
…
failed:      sat - through,
passPercent: sat == 0 ? 0 : through / sat * 100,
```

**Worked example** — CSE, three subjects:

| Subject | Appeared | Passed |
|---|---|---|
| Data Structures | 60 | 55 |
| DBMS | 60 | 58 |
| Operating Systems | 60 | 51 |
| **Total** | **180** | **164** |

Pass % = 164 ÷ 180 × 100 = **91.11%**
Failed = 180 − 164 = **16**

Rows are sorted by pass % descending, so the weakest department is at the
bottom where it is looked for.

### 5.2 Matching a text semester to a number filter

`subject_results.semester` stores text (`'Semester 5'`); the filter holds an
integer (`5`). Comparing them directly matches nothing, silently. So:

```dart
int? _semesterNumber(String label) {
  final match = RegExp(r'(\d+)').firstMatch(label);
  return match == null ? null : int.parse(match.group(1)!);
}
```

### 5.3 Which semester is shown by default

`selectedSemesterProvider` starts as **null**, and `effectiveSemesterProvider`
falls back to the newest semester in the database.

> *"Holding a hardcoded default would show an empty screen whenever that
> particular label was not in the database."*

This is the same defect class that made the Academic Year dropdown assert on
every build.

---

## 6. Placements

### 6.1 Per department — `v_department_placement_summary`

| Column | Formula |
|---|---|
| `eligible` | `student_count` from the rollup |
| `placed` | `count(placement_records)` for that department |
| `highest_package_lpa` | `max(package_lpa)` |
| `average_package_lpa` | `avg(package_lpa)`, 2 dp |
| `placement_percent` | `least(placed ÷ eligible × 100, 100)` |

### 6.2 Salary bands — `v_package_bands`

Five fixed bands, **left-joined** so an empty band still returns a row with
count 0 rather than disappearing from the chart:

| Band | Range |
|---|---|
| Below 4 LPA | `0 ≤ p < 4` |
| 4 – 6 LPA | `4 ≤ p < 6` |
| 6 – 10 LPA | `6 ≤ p < 10` |
| 10 – 20 LPA | `10 ≤ p < 20` |
| Above 20 LPA | `20 ≤ p < 1000` |

Ranges are half-open (`>= min`, `< max`), so an offer of exactly 6.0 LPA falls
in "6 – 10" and is counted **once**.

### 6.3 Highest and lowest offer

Sorts the in-scope records by package and takes both ends, returning the
student and company with each. Returns `(null, null)` on an empty list rather
than throwing.

**Showing the lowest offer is deliberate.** A dashboard that reports only the
highest package tells the Principal the best story available, not the true one.

### 6.4 Batch, derived not stored

`placement_records` has **no batch column**. The batch comes from the register
number via `BatchParser` — full rules in
[13-FILTER-SYSTEM.md](13-FILTER-SYSTEM.md).

| Register number | Batch |
|---|---|
| `22CSE001` | 2022–2026 |
| `2022IOT001` | 2022–2026 |
| `731521101` | — (no year in it) |

Deriving means the batch can never disagree with the number it came from.

---

## 7. Dashboard headline figures — `v_dashboard_summary`

One view, one row, every headline number. All counted live.

| Figure | Formula |
|---|---|
| Total Students | `count(*) from student.students` |
| Total Faculty | `count(*) from faculty.faculties` |
| Total Departments | `count(*) from principal.departments where is_active` |
| Average Attendance | `avg(nullif(attendance_percentage, 0))` |
| Average CGPA | `avg(nullif(cgpa, 0))` |
| Top Performers | `count(*) where cgpa >= 8.5` |
| At Risk | `count(*) where (cgpa > 0 and cgpa < 6.5) or (attendance_percentage > 0 and attendance_percentage < 75)` |
| Pending Approvals | `count(*) from approval_requests where decision = 'pending'` |
| Total Placed | `count(*) from placement_records` |
| Average Package | `avg(package_lpa)` |
| Highest Package | `max(package_lpa)` |
| Latest Pass % | `overall_pass_percent` from the newest `semester_results` |

> **The at-risk and top-performer rules are written twice** — once in SQL here,
> once in Dart at `student_repository.dart`. They are identical today. **If one
> is changed, the other must be changed with it**, or the Dashboard and the
> Student Performance screen will disagree.
>
> This is the highest-value item on the maintenance list.

### Why a view, and not stored totals

This is the single most important design decision in the database.

**It was a real, visible bug.** Institution Overview showed **4,740 students**
while the Dashboard showed **10**. One read a figure written into
`kpi_snapshots` months ago; the other counted. Total Faculty showed **12** on
one screen and **0** on another.

A stored total is written once and goes stale in silence. Counting on read makes
that impossible.

---

## 8. Sorting

Every one of the **24** `.order()` calls in the codebase now names its direction
explicitly.

`postgrest`'s `.order()` defaults to **`ascending: false`** — descending. Every
call in the project had relied on the default, so every chart was drawn
backwards. Admissions genuinely rose from 2,650 to 3,410; the chart showed them
falling.

**If you add an `.order()`, write the direction.**

---

## 9. Ranking

`rank() over (order by avg_cgpa desc)` in `v_department_rollup`.

`rank()` — not `row_number()` — so two departments with the same average CGPA
receive the **same rank**, and the next rank skips. Ties are real; breaking them
arbitrarily invents a difference that is not there.

---

## Maintenance checklist

If you change any of these, change its twin:

| If you change… | …also change |
|---|---|
| At-risk / top-performer thresholds | `student_repository.dart:15-17` **and** `v_dashboard_summary` (migration 10) |
| Department spelling rules | `DepartmentNormalizer._keywordRules` **and** the `like '%' \|\| d.code \|\| '%'` joins in migrations 13/14/19 |
| Salary bands | `v_package_bands` (migration 10) |
| Programme length for batch ranges | `BatchParser._ugYears` |

---

**Next:** [07-DATABASE-RELATIONSHIPS.md](07-DATABASE-RELATIONSHIPS.md) — how the
tables connect to each other.
