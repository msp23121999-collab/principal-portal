# 02 — User Roles

Who can use this portal, and what they can do.

---

## The short version

**There is one role. It is not enforced by anything.**

> **Explain Like I'm 5**
>
> Imagine the Principal's office. There is one chair.
>
> The door has **no lock and no nameplate**. Whoever walks in sits in the chair
> and can do everything the Principal can do.
>
> That is the whole role system.

---

## What was searched for, and not found

To be certain rather than assuming, the codebase was searched for every
mechanism a role system normally uses:

| Searched for | Result |
|---|---|
| A login route in `AppRoutes` | **NOT FOUND** — 20 routes, none of them a login |
| `signIn`, `signUp`, `signOut` | **NOT FOUND** |
| Session or token handling | **NOT FOUND** |
| A `role` or `permission` field anywhere | **NOT FOUND** |
| A route guard or redirect on the shell | **NOT FOUND** |
| Conditional rendering by role | **NOT FOUND** |
| Supabase Auth initialisation | **NOT FOUND** — `Supabase.initialize` receives a URL and the anon key only |

`principal_profiles` and `user_settings` are keyed to the literal text
`'placeholder-principal'`, because there is no real user to attach them to.

---

## The one implicit role

| | |
|---|---|
| **Name** | Principal |
| **How you become it** | open the web address |
| **How it is checked** | it isn't |
| **Can be revoked** | no |
| **Number of accounts** | none — there are no accounts |

### What that role can do

**Read** — everything on all 20 screens, across all five schemas.

**Write** — four things:

| Action | Writes to |
|---|---|
| Approve / reject leave | `faculty.leave_applications.status` **and** `principal.approval_decisions` |
| Approve / reject budget, purchase, event, academic requests | `principal.approval_requests`, `principal.approval_decisions` |
| Create / publish / archive a circular | `principal.circulars` |
| Schedule a meeting | `principal.meetings` |

Plus one that writes a *record* but produces nothing: requesting a report
(`report_runs`).

**Cannot do** — anything else. There is no user management, no role assignment,
no delegation, no read-only observer.

---

## Other roles in the wider KSRCE ERP

These exist as **data**, not as users of this portal:

| Role | Their portal | This portal's relationship |
|---|---|---|
| **Student** | Student Portal | reads `student.*`, never writes |
| **Faculty** | Faculty Portal | reads `faculty.*`; writes only `leave_applications.status` |
| **HOD** | HOD Portal | reads `hod.department_notices` |

A student cannot log into the Principal Portal — but only because they would not
know the address, not because anything stops them.

---

## The permission matrix

Honest rather than aspirational:

| Screen | Principal | Anyone with the URL |
|---|:-:|:-:|
| All 20 screens | full | **full** |
| Approve / reject | ✅ | **✅** |
| Publish a circular | ✅ | **✅** |
| Schedule a meeting | ✅ | **✅** |

**The two columns are identical.** That is the finding, not a formatting error.

---

## And beyond the portal

Worse than the table above: an attacker does not even need the portal.

With the anon key — which ships inside the JavaScript and can be read by anyone
who opens developer tools — a direct `PATCH` to `student.students` **succeeds**.
This was tested: a real student's CGPA was changed from 8.62 to 9.99 and then
restored.

So the honest permission statement is:

> **Anyone who can read the web page can change any student's marks, whether or
> not they ever open the portal.**

Full evidence in [15-SECURITY.md](15-SECURITY.md).

---

## What a real role model would need

Recorded for the team that builds it. **Not implemented — this is a
recommendation, not a description.**

| Role | Should see | Should be able to do |
|---|---|---|
| Principal | everything | approve, publish, schedule |
| Vice Principal / Dean | everything | approve within a limit |
| HOD | their own department | raise requests, not approve their own |
| Office / Admin | finance, reports | generate reports |
| Auditor | audit and compliance | read only |

Three things must happen together, in this order:

1. **Authentication** — a real login, so there is a user to check.
2. **A role column**, on a table the portal can read.
3. **RLS policies keyed to that role**, so the rules hold even when someone
   bypasses the app entirely.

Step 3 is the important one. Rules enforced only in the app are decoration: the
database is reachable directly, and a check written in Dart cannot stop a
request that never runs the Dart.

The `principal` schema is already prepared for this — every table has RLS on
with named policies applied by one helper,
`principal.apply_standard_setup()`. Tightening them is an edit to one function.

---

**Next:** [03-PAGE-INVENTORY.md](03-PAGE-INVENTORY.md) — every screen.
