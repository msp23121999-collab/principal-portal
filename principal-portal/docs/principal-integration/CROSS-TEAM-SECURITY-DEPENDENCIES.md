# Cross-Team Security Dependencies

**Date:** 2026-08-14 · **Owner of this document:** Principal Portal team
**Audience:** Student Portal, Faculty Portal and HOD Portal teams

This records security findings and coupling that the Principal Portal
**cannot fix from its own repository**. Nothing described here has been changed
by us — deliberately. Each item belongs to the team that owns the schema.

| Tag | Meaning |
| --- | --- |
| **[ACTIVE DATABASE VERIFIED]** | Observed against the live hosted project |
| **[LOCAL DATABASE VERIFIED]** | Executed on PostgreSQL 17 with the full migration chain |
| **[NOT EXECUTABLE]** | Could not be tested, with the reason |

---

## 1. FINDING — student PII is readable by anonymous callers

**Severity: HIGH.** **[ACTIVE DATABASE VERIFIED]**

An unauthenticated request carrying only the project's publishable (anon) key —
the key that ships inside every portal's web bundle and is visible in page
source — returns student records:

```
GET /rest/v1/students          Accept-Profile: student     HTTP 200
  → id, student_id, roll_no, register_no, application_no, full_name, …

GET /rest/v1/attendance_table  Accept-Profile: student     HTTP 200
  → date, reg_no, name, dept, …
```

Confirmed state of `student.students`:

| Property | Value |
| --- | --- |
| `anon` SELECT | **GRANTED** |
| Row Level Security | **DISABLED** |
| Policies | **0** |

With RLS disabled and a grant to `anon`, there is nothing between the public
internet and the student roll. Names and register numbers are personal data.

### This is not caused by the Principal Portal

The Principal Portal repository contains **zero** statements creating or
altering the `student` schema — no `create table student.*`, no
`create schema student`, no `alter table student.*`, across all 28 migrations.
**[REPOSITORY VERIFIED]** We have never granted anything to `anon` there.

### Suggested remediation — for the Student Portal team

```sql
-- 1. Take the tables back from anonymous callers.
revoke select on student.students, student.attendance_table from anon;

-- 2. Turn on row security.
alter table student.students        enable row level security;
alter table student.attendance_table enable row level security;

-- 3. Add policies that match YOUR authentication model.
create policy students_self_read on student.students
  for select to authenticated
  using ( <the column that links a row to auth.uid()> );
```

> ⚠️ **Step 3's predicate can only be written by your team.** We do not know
> which column links a student row to an authenticated user. Enabling RLS
> without a correct policy turns the table into deny-all and locks every student
> out of your portal. Please do not copy step 2 without step 3.

### You can do this safely — the Principal Portal no longer depends on it

**[LOCAL DATABASE VERIFIED]** We rebuilt your schema locally, applied
`revoke all … from anon, authenticated` plus `enable row level security` with
**zero policies** — the strictest possible state — and re-ran the Principal
Portal's full data verification:

```
Objects refused/errored: 0
RESULT: PASS — every object the portal reads is reachable by the Principal.
EXIT: 0
```

The Principal Portal reads the roll through `principal.v_students`, an
owner-run view gated on `principal.is_principal()`. It needs no privilege in
your schema at all.

---

## 1b. RE-VERIFIED 2026-08-14 — the exposure is wider than first recorded

**Severity: HIGH.** **[ACTIVE DATABASE VERIFIED]**

Re-probed during the final enterprise QA pass with only the publishable key and
no session. The original finding covered `student.students` and
`student.attendance_table`; it extends to the faculty and HOD schemas as well.

No values are reproduced here — only object, outcome and row count.

| Object | Anonymous result | Rows exposed |
| --- | --- | --- |
| `student.students` | **200 — data returned** | **15** |
| `student.student_notifications` | **200 — data returned** | **27** |
| `student.notice_board_posts` | **200 — data returned** | ≥1 |
| `faculty.faculties` | **200 — data returned** | **16** |
| `faculty.leave_applications` | **200 — data returned** | **7** |
| `faculty.marks` | **200 — data returned** | **8** |
| `faculty.research_publications` | **200 — data returned** | ≥1 |
| `hod.department_notices` | **200 — data returned** | ≥1 |
| `faculty.notifications` | 200 — empty | 0 |
| `faculty.patents` | 200 — empty | 0 |

`faculty.marks` is student assessment data and `faculty.leave_applications`
contains staff leave reasons. Both are readable by anyone who opens the page
source of any portal in this project and copies the publishable key.

For contrast, on the same day and with the same key, all 13 protected
`principal` objects returned HTTP 401 with PostgreSQL error `42501 permission
denied`. That the same key produces `404 PGRST205` for a nonexistent object
confirms the key is valid and the difference is privilege, not authentication.

Nothing above was changed by the Principal Portal team.

---

## 2. COUPLING — nine objects the Principal Portal still reads directly

**Severity: MEDIUM — a coordination risk, not a live vulnerability.**

`principal.v_students` removed the dependency on `student.students`. Nine
cross-schema reads remain direct. **[LOCAL DATABASE VERIFIED]** — with those
tables revoked, these Principal Portal features fail with
`permission denied`:

| Object | Principal Portal feature that breaks |
| --- | --- |
| `faculty.faculties` | Faculty page, Institution overview, Leave |
| `faculty.leave_applications` | Approvals, Leave |
| `faculty.marks` | Results |
| `faculty.notifications` | Notifications |
| `faculty.patents` | Research |
| `faculty.research_publications` | Research |
| `student.notice_board_posts` | Circulars |
| `student.student_notifications` | Notifications |
| `hod.department_notices` | Circulars |

**If you plan to tighten any of these, please tell us first.** The fix on our
side is the same guarded-view pattern used for `v_students` — roughly one view
and one repository line per object — but it has to be in place *before* the
grant is withdrawn, or the corresponding page shows an error state.

This is recorded as planned work in the Principal Portal backlog. It is not
urgent while the current grants stand.

---

## 3. For reference — how the Principal schema was secured

Offered only as a worked example; adapt it, don't copy it.

| Control | What it does |
| --- | --- |
| `revoke all … from anon` + `alter default privileges … revoke` | anon holds nothing, now or on future tables |
| RLS on every table, policies scoped `TO authenticated` | no policy applies to `anon` |
| `is_principal()` — `SECURITY DEFINER`, pinned `search_path`, execute revoked from `public`/`anon` | one authorisation predicate, in one place |
| Views: `security_invoker = off` + `security_barrier = true` + `is_principal()` guard | reads across schemas with no grant to the caller, and the guard cannot be bypassed by predicate pushdown |
| Append-only tables have no `DELETE` policy | the audit trail cannot be erased |

Result **[ACTIVE DATABASE VERIFIED]** on the live project: 13 of 13 protected
objects return **HTTP 401** to an anonymous caller. Before the work, all 13
returned **HTTP 200 with rows**.

Worth noting: `FORCE ROW LEVEL SECURITY` was assessed and deliberately **not**
used. It subjects the table owner to the policies, which would make every
owner-run view return zero rows — including for legitimate users.

---

## 4. What we are asking for

1. **Close the anon exposure on `student.students` and `student.attendance_table`** — §1. Highest priority; it is live student PII.
2. **Tell us before tightening any of the nine objects in §2**, so we can put a guarded view in place first.
3. **Nothing else.** The Principal Portal now takes no privilege from the `student` schema, and we have made no change to any table we do not own.

Questions to the Principal Portal team. The verification tooling referenced here
is in `scripts/verify-live-security.sh` and `scripts/verify-principal-portal.sh`;
both are read-only and safe to run against production.
