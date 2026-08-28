# Production backup and recovery — Principal Portal

**Written:** 2026-08-15
**Owner of this document:** Principal Portal team
**Owner of the decisions in it:** whoever owns the Supabase project

---

## Read this first

Most of this document is marked **UNKNOWN**. That is the finding, not an
omission.

Nothing in this repository, in `DEPLOY.md`, or in `docs/principal-integration/`
states how the database is backed up, how far back a restore could reach, who
would perform one, or how long it would take. Supabase may well be taking
automatic backups on whatever plan the project is on — but nobody has written
down which plan, what it covers, or whether a restore has ever been attempted.

An untested backup is indistinguishable from no backup until the day it matters.
That risk is not hypothetical here: `BLOCKERS.md` records that a second team is
applying migrations to the same database with no shared history, so an
accidental destructive change is a realistic scenario.

The fields below are the ones the project owner has to fill in. Each is marked
with what must be confirmed and where to confirm it. **Nothing here has been
invented** — no frequency, no retention window, no RTO, no RPO.

---

## 1. What is being protected

| Asset | Where it lives | Owner |
|---|---|---|
| `principal` schema — profiles, approvals, decisions, circulars, audit trail, KPI snapshots | Supabase Postgres, project `jnpvzmbisqzbmhkexhwr` | Principal Portal team |
| `student`, `faculty`, `hod`, `timetable` schemas | Same Postgres instance | Student / Faculty / HOD portal teams |
| Supabase Auth users | Same project, `auth` schema | Shared |
| Deployed web bundle | Firebase Hosting | Principal Portal team |

Two things follow from the second row. A restore of this database is **not a
Principal Portal decision** — it would roll back three other teams' data at the
same time. And a Principal Portal incident cannot be resolved by restoring
unilaterally.

---

## 2. Backup mechanism actually available

**UNKNOWN — must be confirmed by the project owner.**

Confirm in the Supabase dashboard under **Project Settings → Database →
Backups**, and record here:

- [ ] Which plan the project is on (Free / Pro / Team / Enterprise).
- [ ] Whether daily backups are enabled, and at what time (UTC).
- [ ] Whether Point-in-Time Recovery is enabled.
- [ ] Whether backups cover the `auth` schema as well as the application schemas.

> Free-tier Supabase projects historically have **no** automatic backups. If the
> project is on the free tier, treat the current backup position as *none* until
> proven otherwise, and raise that before any real user data is entered.

**Do not fill these in from memory or from Supabase's public documentation.**
Read them off this project's own settings page.

## 3. Retention actually available

**UNKNOWN — must be confirmed by the project owner.**

- [ ] Number of days of daily backups retained: ______
- [ ] Point-in-time recovery window, if enabled: ______
- [ ] Where backup artefacts are stored, and who can download them: ______

## 4. Recovery objectives

**UNKNOWN — these are a decision, not a lookup.**

They cannot be read off a dashboard; the institution has to state them.

- [ ] **RPO** — how much data the institution accepts losing in an incident.
      (If the answer is "a day", daily backups are sufficient. If the answer is
      "an hour", point-in-time recovery is required.)
- [ ] **RTO** — how long the portal may be unavailable during a restore.

Until these are stated, there is no way to say whether the backup arrangement in
section 2 is adequate, because "adequate" is defined by these two numbers.

---

## 5. Restore procedure

**Not yet executed. The steps below are the intended procedure and must be
rehearsed before they are relied on** — see section 6.

### Who performs it

**UNKNOWN.** Restoring affects four portals, so this needs a named person with
project-owner access and an agreed way to reach the other three teams. Record:

- [ ] Primary: ______
- [ ] Backup: ______
- [ ] How the Student, Faculty and HOD teams are notified: ______

### Prerequisites

1. Project-owner access to the Supabase project.
2. Agreement from the other three portal teams — a restore rolls their data back
   too.
3. A maintenance window. All four portals should be off the database.
4. A fresh backup taken *immediately before* the restore, so the pre-restore
   state is itself recoverable.

### Steps

1. Announce the window; confirm all four portals are quiesced.
2. Take a manual backup of the current state.
3. In the Supabase dashboard, **Database → Backups**, select the target backup
   or point in time.
4. Restore.
5. Re-run the security verifier before letting anyone back in:

   ```bash
   export SUPABASE_URL='https://<ref>.supabase.co'
   export SUPABASE_ANON_KEY='<publishable key>'
   ./scripts/verify-live-security.sh
   ```

   **This step is not optional.** A restore returns the database to a previous
   state, which may predate
   `20260814000000_rls_hardening_corrections.sql` — in which case the restore
   silently reopens the schema to anonymous readers. The verifier must exit 0.

6. If the verifier fails, re-apply the migrations in
   `supabase/migrations/` in filename order, then re-run it.
7. Confirm each portal signs in and reads its own data before reopening.

---

## 6. Staging / scratch restore rehearsal

**Not yet performed.** This is the single most valuable item on this page: a
procedure nobody has executed is not a procedure.

1. Create a scratch Supabase project.
2. Restore the most recent production backup into it.
3. Record:
   - [ ] How long the restore took, wall clock: ______
   - [ ] Whether `auth` users came back: ______
   - [ ] Whether all five schemas came back: ______
   - [ ] Whether `./scripts/verify-live-security.sh` passes against it: ______
4. Point a local build at the scratch project and confirm the portal loads:

   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://<scratch-ref>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<scratch publishable key>
   ```

5. Delete the scratch project.

The wall-clock number from step 3 is the *only* honest input to the RTO in
section 4.

---

## 7. What `seed.sql` does and does not do

`supabase/seed.sql` is often mistaken for a backup. It is not one.

**What it is.** 1,024 lines, 71 `insert` statements, every one carrying an
`on conflict` clause. No `truncate`, no `delete`. It is safe to re-run against a
populated database: it will not destroy anything.

**What it restores.** Reference and demonstration data for the `principal`
schema — departments, academic years, KPI snapshot rows, facility counts,
seeded circulars and approval requests.

**What it does NOT restore, and never will:**

- Any student record, mark, or attendance entry — those live in the `student`
  and `faculty` schemas and are owned by other teams.
- The Principal's own profile, or the `auth` user behind it.
- Any approval decision or audit-trail entry made through the portal. The audit
  trail is append-only by policy and exists precisely so decisions survive; a
  seed file cannot reconstruct it.
- Any circular or notice published since the seed was written.

So: `seed.sql` gets a *fresh* environment to a usable state. It does not recover
an institution's records. Do not treat re-seeding as an incident response.

---

## 8. Deployment rollback (separate from database recovery)

Rolling back the web bundle is unrelated to the database and much cheaper.

```bash
firebase hosting:releases:list
firebase hosting:rollback
```

The bundle carries no data. A rollback is safe at any time and does not need the
other teams. Note that the bundle also carries the Supabase URL and publishable
key compiled in via `--dart-define`, so rolling back to a build made against a
different project will point the portal somewhere else — check which project a
release was built for before rolling back to it.

---

## 9. Summary of what must be confirmed

| # | Item | Section | Status |
|---|---|---|---|
| 1 | Supabase plan and backup settings | 2 | **UNKNOWN** |
| 2 | Retention / PITR window | 3 | **UNKNOWN** |
| 3 | RPO and RTO | 4 | **UNKNOWN — institution's decision** |
| 4 | Named restore operator and deputy | 5 | **UNKNOWN** |
| 5 | Cross-team notification path | 5 | **UNKNOWN** |
| 6 | Rehearsed restore, with timings | 6 | **NOT PERFORMED** |

Items 1–5 are lookups or decisions and can be closed in an afternoon. Item 6 is
the one that turns this document from a plan into a procedure.
