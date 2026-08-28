# 18 — Glossary

Every term, three ways: the technical meaning, the simple meaning, and where it
turns up in this project.

Terms marked **NOT USED IN THIS PROJECT** are defined so that nobody spends a
morning looking for them.

---

## Architecture

**Frontend**
*Technical:* the client application running in the browser.
*Simple:* what you see and click.
*Here:* a Flutter Web app, `lib/`.

**Backend**
*Technical:* server-side code between the client and the database.
*Simple:* the waiter between you and the kitchen.
*Here:* **NOT FOUND.** The browser talks to the database directly. Its usual
jobs are done by Postgres views and Riverpod providers.

**API**
*Technical:* an agreed way for two programs to talk.
*Simple:* the menu — what you may ask for, and how to ask.
*Here:* PostgREST's automatic API. **No endpoint in this project was written by
hand.**

**PostgREST**
*Technical:* a server that turns a PostgreSQL database into a REST API
automatically.
*Simple:* it puts a web address in front of every table, so the browser can ask
for data without anyone writing code for it.
*Here:* this is what replaces the backend.

**Supabase**
*Technical:* a hosted platform bundling PostgreSQL, PostgREST, auth and storage.
*Simple:* the company that hosts the database and puts the web address in front
of it.
*Here:* the database host. Its **auth** and **storage** features are available
but **not used**.

**SPA (single-page application)**
*Technical:* one page whose content is replaced without a full reload.
*Simple:* the page never blinks white when you click a menu item.
*Here:* yes — go_router swaps the middle of the screen only.

---

## Database

**Database**
*Simple:* a big cupboard where information is kept.

**Schema**
*Technical:* a named namespace inside a database.
*Simple:* one shelf in the cupboard, owned by one team.
*Here:* five — `principal` (ours), `student`, `faculty`, `hod`, `public`.

**Table**
*Simple:* one box on a shelf, holding one kind of thing.
*Here:* 62 in `principal`.

**Row** — one card in the box (one student, one meeting).
**Column** — one label on the box ("name", "marks").

**Primary key**
*Technical:* the column uniquely identifying a row.
*Simple:* the unique number on each card, so two students with the same name are
never confused.
*Here:* every table uses `id uuid`.

**Foreign key**
*Technical:* a column referencing another table's primary key.
*Simple:* a card that says "see card 12 in the other box".
*Here:* used inside `principal`. **Never across schemas** — see
[07-DATABASE-RELATIONSHIPS.md](07-DATABASE-RELATIONSHIPS.md).

**View**
*Technical:* a stored query that behaves like a table.
*Simple:* a note on the wall — "count box 1 and box 2 and add them up". Read it
and you get today's answer.
*Here:* 7 views. They hold all the totals, so a total can never go stale.

**Migration**
*Technical:* a versioned, repeatable change to the database's structure.
*Simple:* a written, dated instruction for changing the cupboard, so anyone can
rebuild it identically.
*Here:* 20 files in `supabase/migrations/`, each with a `-- ROLLBACK:` note.

**Seed**
*Simple:* sample data to fill the boxes so screens have something to show.
*Here:* `supabase/seed.sql`. Safe to re-run — see *natural key*.

**Natural key**
*Technical:* a unique constraint on a row's real-world identity.
*Simple:* "one student, one offer per company" — so running the seed twice does
not give everyone two jobs.

**Trigger**
*Technical:* a function the database runs automatically on a change.
*Simple:* a rule that fires by itself.
*Here:* one — `set_updated_at()`, keeping `updated_at` current on all 62 tables.

**RLS (row-level security)**
*Technical:* per-row access rules enforced by the database itself.
*Simple:* a lock on the cupboard, not just the room door.
*Here:* **on** for `principal` with permissive policies; **off** for `student`,
`faculty` and `hod` — which is finding 1 in
[15-SECURITY.md](15-SECURITY.md).

**Cascade / Restrict / Set null**
*Simple:*
- **cascade** — delete the meeting, its agenda goes too.
- **restrict** — you may not delete a department that still has students.
- **set null** — delete the year; the figures stay, unstamped.

---

## The application

**Flutter** — Google's toolkit for building an app from one codebase.
*Here:* the whole frontend. Flutter Web draws to a **canvas**, which is why
inspecting the page with browser dev tools shows almost no HTML.

**Dart** — the language Flutter is written in.

**Widget**
*Technical:* the unit of UI in Flutter; everything is one.
*Simple:* a Lego brick. A button is a widget, a page is a widget made of widgets.

**Riverpod**
*Technical:* a reactive state-management and dependency-injection library.
*Simple:* the wiring. When the filter changes, everything watching it redraws by
itself — nobody has to remember to refresh each screen.

**Provider**
*Technical:* a Riverpod unit that supplies a value and rebuilds its watchers.
*Simple:* a labelled tap. Widgets connect to it; when what's behind it changes,
they all know.

**FutureProvider** — a provider whose value arrives later (a database read). It
gives you three states: loading, error, data.

**StateNotifier** — a provider that holds something changeable.
*Here:* `PortalFilterNotifier` holds the current filter.

**go_router** — the library deciding which screen a web address shows.

**StatefulShellRoute**
*Simple:* the sidebar and top bar are drawn once and stay put; only the middle
changes. Each screen remembers its scroll position and selected tab.

**Repository**
*Technical:* the layer isolating data access from the rest of the app.
*Simple:* the only part of the app allowed to talk to the database. Everything
else asks it.
*Here:* `lib/features/*/data/*_repository.dart`, all extending one base class.

**Model** — a Dart class describing the shape of one thing (a `Student`, a
`Meeting`).

**fl_chart** — the charting library.
**data_table_2** — the table library.
**Material 3** — Google's design system; where the spacing and colours come from.

---

## Security

**Authentication** — checking *who you are*. **NOT FOUND** here.
**Authorization** — checking *what you may do*. **NOT FOUND** here.

**Anon key**
*Technical:* a public API key identifying the project, shipped in the client.
*Simple:* a public password that is *meant* to be public — safe only when the
database enforces RLS.
*Here:* supplied at build time with `--dart-define`, never committed.

**`--dart-define`**
*Simple:* passing a value into the app at build time, so it lives in the build
command rather than in a file somebody might commit.

**`.gitignore`** — a list of files git must never record.
*Here:* `run-live.bat` is on it, because it holds the key.

---

## Concepts specific to this project

**KSRCE ERP** — the college's set of systems. Four portals: Student, Faculty,
HOD, and this one.

**Normalisation (of text, not databases)**
*Simple:* collapsing many spellings of one thing into one code — "CSE",
"Computer Science and Engineering" and "Computer Science & Engineering" all
become `CSE`.
*Here:* `DepartmentNormalizer`, `ProgramLevels`, `BatchParser`. Without them,
the portal reports four Computer Science departments.

**Programme level** — UG, PG, Diploma or PhD, worked out from free-text degree
values.

**Batch** — the admission year, read out of the register number (`22CSE001` →
2022 → "2022–2026"). Derived, never stored twice.

**CGPA / SGPA**
*Simple:* **SGPA** is the average for one semester. **CGPA** is the average of
everything so far.
*Here:* CGPA is stored on `student.students`. **SGPA cannot currently be
calculated** — there are no end-semester results. See
[17-CURRENT-VS-EXPECTED.md](17-CURRENT-VS-EXPECTED.md).

**CIA (Continuous Internal Assessment)** — the tests during the term, as opposed
to the end-semester exam.

**CO / PO (Course Outcome / Programme Outcome)**
*Simple:* "we said this course would teach X — did it?" Measured 0 to 3.

**NAAC / NBA / NIRF**
*Simple:* **NAAC** grades the whole college. **NBA** approves individual
courses. **NIRF** is a national league table where a *lower* rank is better.

**At risk** — CGPA below 6.5 **or** attendance below 75%, ignoring unrecorded
zeros.
**Top performer** — CGPA of 8.5 or above.
Both are this portal's own definitions, stated once in
`student_repository.dart`.

**LPA (lakhs per annum)** — the Indian convention for salary. 1 lakh =
100,000 rupees; "6 LPA" = ₹600,000 a year.

---

## Terms that do NOT apply here

Defined so nobody hunts for them.

| Term | What it means | Status |
|---|---|---|
| **JWT** | a signed token proving who a user is | **NOT USED** — no authentication |
| **ORM** | a library mapping database rows to objects | **NOT USED** — PostgREST is called directly |
| **Controller** | the server class handling a request | **NOT USED** — no server |
| **Middleware** | code running between request and handler | **NOT USED** — no server |
| **Service layer** | server-side business logic | **NOT USED** — that logic is in views and providers |
| **Docker** | packaging an app with its environment | **NOT USED** — no Dockerfile |
| **Container** | one running instance of such a package | **NOT USED** |
| **Kubernetes** | orchestrating many containers | **NOT USED** |
| **Redis / cache layer** | a fast store for repeated answers | **NOT USED** — Riverpod holds results for the session only |
| **WebSocket** | a two-way live connection | **NOT USED** — no real-time updates |
| **GraphQL** | an alternative query API | **NOT USED** |
| **CI/CD** | automatic building, testing and deploying | **NOT USED** — builds are run by hand |
| **Session** | the server's memory of a logged-in user | **NOT USED** — nobody logs in |
| **Refresh token** | a token used to get a new access token | **NOT USED** |
| **Rate limiting** | capping how often a client may call | **NOT USED** |
| **CORS** | rules for which sites may call an API | handled by Supabase, not configured here |

---

**Next:** [02-USER-ROLES.md](02-USER-ROLES.md) — who can do what.
