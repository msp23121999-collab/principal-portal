# 15 — Security

> ## ⚠️ Read this before putting the portal on a public address
>
> Two problems block real use. Neither can be fixed inside this repository
> alone.

---

## Terms first

> **Explain Like I'm 5**
>
> **Authentication** — checking *who you are*. Like showing your ID card at the
> gate.
>
> **Authorization** — checking *what you are allowed to do* once inside. The ID
> gets you in the building; it does not open the safe.
>
> **RLS (row-level security)** — a lock on the cupboard itself, not on the door
> of the room. Even if someone gets into the room, the cupboard stays shut
> unless the lock says they may open it.
>
> **Anon key** — a public password that ships inside the web page. It is
> *meant* to be public. It is only safe when the cupboard has its own lock.

---

## Finding 1 — CRITICAL: the public key can change student marks

**Status: PROVEN, not suspected.** We ran the test.

Using only the anon key that ships inside the JavaScript bundle — the key
anybody can read by opening developer tools:

```
GET  student.students        → {"register_no":"2022IOT001","cgpa":8.62}
PATCH student.students       → HTTP 204  (accepted)
GET  student.students        → {"register_no":"2022IOT001","cgpa":9.99}
PATCH (restore)              → HTTP 204
GET  student.students        → {"register_no":"2022IOT001","cgpa":8.62}
```

A real student's CGPA was changed from 8.62 to 9.99 and then put back.

The same `PATCH` succeeds against `faculty.faculties`.

**What this means in plain English**

Anyone who opens the portal, presses F12, and copies one line of text can then
change any student's marks, attendance or fee record from their own computer.
They never need to log in, because there is nothing to log in to.

**Cause**

RLS is **off** on the `student`, `faculty` and `hod` schemas. With RLS off,
PostgREST grants the anon role whatever the database grants it — and that
currently includes `UPDATE`.

**Why this was not fixed here**

Turning RLS on for those tables without first writing the policies the Student,
Faculty and HOD portals need would **immediately break all three of those
applications** — they would stop being able to read their own data. That is a
production outage for three teams to close one finding in ours.

This is a coordinated change. It needs the database team and the other portal
owners, together.

**Recommended fix**

1. The owning team writes RLS policies for each of their tables.
2. RLS is enabled per table, in a maintenance window, with all four portals
   tested.
3. Verify afterwards: the `PATCH` above must return **401 or 403**, not 204.

**Severity: CRITICAL — stop-ship.**

---

## Finding 2 — CRITICAL: there is no login

**Status: NOT FOUND — no authentication exists anywhere in the codebase.**

Confirmed absent:

- No login route (`AppRoutes` has 22 entries, none of them a login)
- No `signIn`, `signUp`, or session handling
- No roles, no permission checks
- `Supabase.initialize` is called with a URL and the anon key only

The Principal's profile and settings are stored against the literal text
`'placeholder-principal'`, because there is no real user to attach them to.

**What this means**

Anyone with the web address is the Principal. There is no second step.

**Recommended fix**

Decide which identity system the college will use — Supabase Auth, or the
existing KSRCE ERP login shared with the other portals. That is a decision for
the college, not a code change we can guess at. Once decided:

1. Add a login route and guard the shell.
2. Replace `'placeholder-principal'` with the signed-in user's id.
3. Tighten the `principal` RLS policies from "allow everything" to "allow this
   user" — the policies are already named and in place for exactly this, see
   `apply_standard_setup()` in migration 03.

**Severity: CRITICAL — stop-ship.**

---

## Finding 3 — MEDIUM: two teams migrating one database

`supabase db push` refuses to run. The remote migration history contains **five
migrations that do not exist in this repository**, dated during this work.

Another team is changing the same database. Migrations 19 and 20 were therefore
applied with direct SQL statements rather than by repairing a migration history
this portal does not own.

**Risk:** two teams changing one database with no shared record will eventually
produce a change that undoes another, and neither will know why.

**Recommended fix:** one shared migration repository, or clearly separated
schema ownership with an agreed process.

---

## What is handled correctly

Worth stating, so it is not accidentally "fixed" later:

**Secrets are not committed.** `SUPABASE_URL` and `SUPABASE_ANON_KEY` are
supplied at build time with `--dart-define`. `run-live.bat` holds the key
locally and is listed in `.gitignore`. There are no credentials in any source
file, and none in these documents.

**The `principal` schema has RLS switched on** for every table, with named
policies (`<table>_read`, `<table>_write`) applied by one helper,
`principal.apply_standard_setup()`. The policies currently permit everything —
deliberately, because there is no user to check against yet. Tightening them
later is an edit to one function, not a redesign.

**Other portals' tables are respected.** The portal reads `student`, `faculty`,
`hod` and `public` and never alters their structure. The single write —
approving leave — changes one column's value and records the full decision in
`principal.approval_decisions`.

**Failures are visible, not hidden.** When the database is unreachable the
screens show an error, never plausible-looking substitute figures. A Principal
can always tell the difference between a real number and a missing one.

---

## Summary

| # | Finding | Severity | Fixable here? |
|---|---|---|---|
| 1 | Public key can write to student and faculty records | **CRITICAL** | ❌ needs the DB team + other portals |
| 2 | No authentication or authorization | **CRITICAL** | ❌ needs a college decision |
| 3 | Two teams migrating one database | MEDIUM | ❌ needs a cross-team agreement |
| — | Secrets kept out of the repo | ✅ correct | — |
| — | RLS on and policies named in `principal` | ✅ correct | — |
| — | Other schemas read-only | ✅ correct | — |
| — | Errors shown honestly | ✅ correct | — |

**Bottom line:** the application is in good shape. The deployment is not, and
the two blockers both live outside this codebase.
