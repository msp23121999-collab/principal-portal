# 16 — Requirements

What this system is required to do.

> **How this document was written.** Requirements are stated **from verified
> capability**, not from a wish list. Each one is marked with whether the system
> meets it today. Nothing here was invented to make the list look complete.

---

## Functional requirements

### FR-1 — Viewing institutional data

| # | Requirement | Met? |
|---|---|---|
| FR-1.1 | Show whole-college totals: students, faculty, departments, attendance, pass %, placement % | ✅ |
| FR-1.2 | Show the same figures per department | ✅ |
| FR-1.3 | Rank departments by a chosen metric | ✅ |
| FR-1.4 | Show results by semester, department and subject | ✅ |
| FR-1.5 | Show rank holders per semester | ✅ |
| FR-1.6 | Show attendance overall, per department, per staff member, per student | ✅ |
| FR-1.7 | Show staff present / absent / on leave | ✅ |
| FR-1.8 | Show placements including **both** the highest and lowest offer, with student and company | ✅ |
| FR-1.9 | Show exam schedule, internal assessment progress, hall tickets, result publication | ✅ |
| FR-1.10 | Show research output, patents, funded projects, consultancy | ✅ |
| FR-1.11 | Show accreditation standing and evidence progress | ✅ |
| FR-1.12 | Show finance: fees, scholarships, payroll, expenditure | ✅ |
| FR-1.13 | Show an audit trail of recorded actions | ⚠️ recorded actions only, not automatic capture |
| FR-1.14 | Show SGPA per student per semester | ❌ **cannot be calculated** — no end-semester results exist |

### FR-2 — Filtering

| # | Requirement | Met? |
|---|---|---|
| FR-2.1 | Narrow by academic year, department, programme, batch, year of study, semester, subject | ✅ |
| FR-2.2 | The chosen scope must persist across screens | ✅ |
| FR-2.3 | Options must come from real rows, never a hardcoded list | ✅ |
| FR-2.4 | Choosing a department must clear the programme and subject beneath it | ✅ |
| FR-2.5 | Choosing a semester must clear the subject beneath it | ✅ |
| FR-2.6 | Show only the filters a screen actually honours | ✅ |
| FR-2.7 | Show how many filters are active, and allow clearing them | ✅ |

### FR-3 — Acting

| # | Requirement | Met? |
|---|---|---|
| FR-3.1 | Approve or reject leave | ✅ |
| FR-3.2 | Approve or reject budget, purchase, event, academic requests | ✅ |
| FR-3.3 | Every decision must be recorded with who, why and when | ✅ `approval_decisions` |
| FR-3.4 | Create, publish and archive circulars | ✅ |
| FR-3.5 | Schedule meetings | ✅ |
| FR-3.6 | Change preferences | ✅ |
| FR-3.7 | Record a document | ⚠️ details only — **no file is stored** |
| FR-3.8 | Request a report | ⚠️ the request is recorded — **no file is produced** |

### FR-4 — Search and export

| # | Requirement | Met? |
|---|---|---|
| FR-4.1 | Search students, faculty and departments from the top bar | ✅ |
| FR-4.2 | Selecting a result must navigate and set the scope | ✅ |
| FR-4.3 | Export the filtered student roll | ✅ CSV |
| FR-4.4 | Export the filtered faculty roster | ✅ CSV |
| FR-4.5 | Export the filtered placement offers | ✅ CSV |
| FR-4.6 | Export from the other nine buttons | ❌ message only |
| FR-4.7 | Export as PDF | ❌ **NOT FOUND** |

### FR-5 — Data integrity

| # | Requirement | Met? |
|---|---|---|
| FR-5.1 | Never write to another portal's table structure | ✅ |
| FR-5.2 | Departments spelt several ways must count as one | ✅ `DepartmentNormalizer` |
| FR-5.3 | Degrees spelt several ways must count as one programme level | ✅ `ProgramLevels` |
| FR-5.4 | Totals must be calculated on read, never stored | ✅ 7 views |
| FR-5.5 | Unrecorded values must not be averaged as zero | ✅ `nullif` / `where(v > 0)` |
| FR-5.6 | A percentage must never exceed 100 | ✅ capped, migration 14 |
| FR-5.7 | Two screens must never disagree about the same figure | ✅ one source per figure |
| FR-5.8 | No screen may display an invented number | ✅ mock data deleted; failures show errors |

### FR-6 — Security ❌

| # | Requirement | Met? |
|---|---|---|
| FR-6.1 | A user must log in | ❌ **NOT FOUND** |
| FR-6.2 | Only the Principal may see the portal | ❌ |
| FR-6.3 | The database must reject unauthorised writes | ❌ **RLS off on 3 schemas — proven exploitable** |
| FR-6.4 | Secrets must not be committed | ✅ `--dart-define`, `.gitignore` |
| FR-6.5 | Actions must be attributable to a person | ❌ no identity to attribute to |

**FR-6 is the reason this portal is not production-ready.** See
[15-SECURITY.md](15-SECURITY.md).

---

## Non-functional requirements

### NFR-1 — Usability

| # | Requirement | Met? |
|---|---|---|
| NFR-1.1 | Readable at the Principal's preferred type size | ✅ one `AppFontSizes` scale, applied portal-wide |
| NFR-1.2 | Cards in a row must share a height and align | ✅ `minHeight` floors, `ResponsiveGrid` |
| NFR-1.3 | No content may overflow at any supported width | ✅ verified at 5 viewport widths |
| NFR-1.4 | Titles, tabs and content must share one left edge | ✅ `CrossAxisAlignment.stretch` in `TabbedPage` |
| NFR-1.5 | Rows must never leave a tile-shaped hole | ✅ column count chosen to leave fewest empty slots |
| NFR-1.6 | Screens must remember scroll position and selected tab | ✅ `StatefulShellRoute.indexedStack` |
| NFR-1.7 | A control that changes nothing must not be shown | ✅ 12 screens correctly have no filter bar |
| NFR-1.8 | Problem-first ordering — worst cases where they are looked for | ✅ attendance lowest first, overdue first, weakest last |

### NFR-2 — Reliability

| # | Requirement | Met? |
|---|---|---|
| NFR-2.1 | A failed read must show an error, never a substitute figure | ✅ |
| NFR-2.2 | A failed write must be reported, never swallowed | ✅ rethrown |
| NFR-2.3 | One unavailable source must not blank a multi-source screen | ✅ `gather()` |
| NFR-2.4 | An empty result must be distinguishable from a failure | ✅ `EmptyState` vs `ErrorState` |
| NFR-2.5 | No screen may crash on empty data | ✅ empty-list guards added |
| NFR-2.6 | Static analysis must be clean | ✅ **0 issues** |
| NFR-2.7 | Tests must pass | ✅ **79 tests** |

### NFR-3 — Responsiveness

| # | Requirement | Met? |
|---|---|---|
| NFR-3.1 | Usable from tablet to wide desktop | ✅ |
| NFR-3.2 | Grids must re-flow, not scroll horizontally | ✅ |
| NFR-3.3 | Wide tables may scroll within their own card | ✅ |

### NFR-4 — Maintainability

| # | Requirement | Met? |
|---|---|---|
| NFR-4.1 | One place per concern | ✅ one repository per feature, one filter object, one theme |
| NFR-4.2 | Every database change must be a migration with a rollback note | ✅ 20 migrations |
| NFR-4.3 | Re-running the seed must not double any table | ✅ natural keys, migration 12 |
| NFR-4.4 | Decisions with a non-obvious reason must be commented | ✅ |
| NFR-4.5 | A rule must not be written twice | ⚠️ **at-risk thresholds exist in Dart *and* SQL** |

### NFR-5 — Performance

| # | Requirement | Met? |
|---|---|---|
| NFR-5.1 | A screen must load in one round trip per source | ✅ |
| NFR-5.2 | Aggregation must happen in the database | ✅ views |
| NFR-5.3 | Filtering must scale to the full roll | ⚠️ **browser-side** — fine at 10 students, not at 10,000 |

### NFR-6 — Operability ❌

| # | Requirement | Met? |
|---|---|---|
| NFR-6.1 | Reproducible builds | ⚠️ `run-live.bat`, run by hand |
| NFR-6.2 | Automated deployment | ❌ **NOT FOUND** |
| NFR-6.3 | Monitoring / alerting | ❌ **NOT FOUND** |
| NFR-6.4 | Coordinated database migrations across teams | ❌ five foreign migrations in the shared history |

---

## Constraints — imposed, not chosen

These shaped the design and must not be "fixed" by a later team without
agreement.

| # | Constraint | Consequence |
|---|---|---|
| C-1 | **Do not touch, rename, alter or drop any student, HOD or faculty table.** Read-only. | cross-schema links are text, not foreign keys |
| C-2 | **Everything created must live in the `principal` schema.** | 62 tables, 7 views, all namespaced |
| C-3 | **No backend server, REST API or auth system.** Database + data layer + UI only. | business logic lives in views and providers |
| C-4 | **Delete all mock data once a screen is connected.** | `Repository.load` throws instead of falling back |
| C-5 | **Do not change existing UI design, branding, navigation or responsive behaviour unnecessarily.** | changes were surgical |
| C-6 | **Never expose passwords, keys, tokens or secrets.** | `--dart-define`, `.gitignore`, none in these documents |

**C-1 and C-3 together are why there is no login.** An authentication system was
explicitly out of scope, and the tables that would hold users belong to other
teams.

---

## Assumptions

Stated so they can be challenged:

1. **One user.** The portal assumes a single Principal. No multi-user or
   concurrent-edit handling exists.
2. **The other portals keep their column names.** `firstStr([...])` tolerates
   several spellings, but a wholly new name would need a code change.
3. **Departments are identifiable from their text.** `DepartmentNormalizer`
   covers the 11 known spellings; a genuinely new department needs a rule.
4. **Register numbers encode the admission year.** Two known formats are
   handled; a third would return no batch rather than a wrong one.
5. **The roll will grow.** Several guards (the placement cap) exist because it
   currently has not.

---

**Next:** [17-CURRENT-VS-EXPECTED.md](17-CURRENT-VS-EXPECTED.md) — the gap
between this list and reality.
