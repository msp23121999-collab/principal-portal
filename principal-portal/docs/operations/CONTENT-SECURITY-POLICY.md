# Content-Security-Policy — Principal Portal

**Written:** 2026-08-15
**Current state:** shipped as `Content-Security-Policy-**Report-Only**`
**Enforcing:** NOT YET — see §4. Promotion requires a browser check nobody has
run.

---

## 1. Why it is Report-Only and not enforced

A wrong CSP does not degrade a Flutter web app; it produces a blank page. The
policy below was derived from the origins the built bundle actually references,
but *derived* is not *verified* — the difference can only be closed by loading
the deployed page in a real browser and reading the console.

That check has not been performed, so the header ships in report-only mode.
Report-only is not a compromise here, it is the correct intermediate step: the
browser evaluates the policy, reports every violation to the console, and
**blocks nothing**. It cannot break the portal, and it produces exactly the
evidence needed to turn it on for real.

Guessing at an enforcing policy and deploying it would be the one change in this
pass capable of taking the whole portal down.

---

## 2. Where each origin came from

Every entry below is justified by something found in `build/web` after a real
`flutter build web --release` on 2026-08-15. Nothing is speculative.

```
$ grep -ohE 'https?://[a-zA-Z0-9.\-]+' main.dart.js flutter_bootstrap.js flutter.js index.html | sort -u
https://api.flutter.dev          <- doc link inside an error message
https://developer.mozilla.org    <- doc link inside an error message
https://docs.flutter.dev         <- doc link inside an error message
https://flutter.dev              <- doc link inside an error message
https://fonts.gstatic.com        <- Noto glyph fallback (engine)
https://github.com               <- doc link inside an error message
https://pub.dev                  <- doc link inside an error message
https://www.gstatic.com          <- CanvasKit fallback URL (engine)
```

| Directive | Value | Why |
|---|---|---|
| `default-src` | `'none'` | Deny by default; every capability is then granted explicitly. |
| `script-src` | `'self' 'wasm-unsafe-eval'` | The bundle is first-party. CanvasKit is WebAssembly, which needs `'wasm-unsafe-eval'` — without it the renderer never starts. |
| `style-src` | `'self' 'unsafe-inline'` | Flutter web injects inline `<style>` for its glass pane and text layout. `'unsafe-inline'` is unavoidable here; it is the known cost of the framework. |
| `font-src` | `'self' https://fonts.gstatic.com` | Inter is now bundled (`'self'`). The gstatic entry is *not* google_fonts — that dependency is gone. It is the engine's Noto fallback, fetched only when a glyph is missing from the bundled fonts. See §3. |
| `img-src` | `'self' data: blob:` | Bundled assets, plus the `data:`/`blob:` URLs Flutter generates internally. |
| `connect-src` | `'self'`, the Supabase project over https and wss, `fonts.gstatic.com`, `www.gstatic.com` | PostgREST and Auth are https; `wss:` is included because Supabase Realtime opens a socket — the portal does not use it today, but the client library can, and a blocked socket is a confusing failure. The two gstatic origins match `font-src`/CanvasKit. |
| `worker-src` / `child-src` | `'self' blob:` | Flutter spawns workers from blob URLs. |
| `frame-ancestors` | `'none'` | Clickjacking. Duplicates `X-Frame-Options: DENY` for browsers that prefer CSP. |
| `base-uri`, `form-action`, `object-src` | `'none'` | Nothing in the portal needs any of them; denying them costs nothing. |

The six documentation URLs above need no directive. They appear inside error
message strings and are never fetched.

---

## 3. The one origin that can probably be removed

`fonts.gstatic.com` is in the policy because the Flutter web engine downloads
Noto fallback fonts from it when asked to render a glyph the bundled fonts do
not contain — CJK, unusual scripts, some emoji. It appears exactly once in
`main.dart.js`, in the engine, not in application code.

This portal renders English and Tamil institutional data. If no screen ever
needs a glyph outside Inter's coverage, the origin can be dropped from both
`font-src` and `connect-src`, and the failure mode is a tofu box rather than a
broken page.

**Do not drop it speculatively.** Confirm during the §4 check: if no
`fonts.gstatic.com` request appears in the Network tab across a full pass of the
portal, remove it and re-verify.

---

## 4. Promoting to enforcing — the runbook

This is the part that has **NOT** been executed. All of it must be, in order.

### 4.1 Deploy with the report-only header

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<publishable key>
firebase deploy --only hosting
```

Confirm the header arrives:

```bash
curl -sI https://<your-site> | grep -i content-security-policy
```

### 4.2 Walk the portal with the console open

In **Chrome, Edge, Firefox and Safari** — the policy is evaluated per browser
and they do not agree on every directive:

- [ ] The page loads and paints. (A CanvasKit failure shows as a blank page.)
- [ ] The sign-in screen renders, and the Inter typeface is in use — not a
      fallback. Check in DevTools → Elements → Computed → `font-family`.
- [ ] Sign in succeeds. This exercises `connect-src` against Supabase Auth.
- [ ] The Dashboard loads its figures. This exercises PostgREST.
- [ ] Open every one of the 19 destinations. Charts must paint.
- [ ] Export a CSV. This exercises `blob:`.
- [ ] Publish a draft notice. This exercises a cross-schema write.
- [ ] **Console shows zero `Content-Security-Policy` violation reports.**

Record any violation verbatim rather than adjusting the policy from intuition —
each one names the directive and the blocked URL, which is the whole point of
this step.

### 4.3 Only then, enforce

Rename the header in `firebase.json`:

```
"key": "Content-Security-Policy-Report-Only"   ->   "key": "Content-Security-Policy"
```

Redeploy, and repeat 4.2 once more. A report-only pass and an enforcing pass are
not the same test: report-only evaluates the policy, enforcing also applies it,
and a directive the browser reports leniently can still block.

### 4.4 If it breaks

`firebase hosting:rollback` reverts to the previous release immediately. The
header is hosting configuration, so rolling back removes it without a rebuild.

---

## 5. Note on the Supabase origin

`connect-src` names the project reference explicitly, so the deployed policy is
coupled to the project the build points at. If the portal is ever built against
a different Supabase project, **this header must be updated in the same change**
— otherwise every query is blocked and the portal loads to a page of error
states.

The credentials themselves stay where they are: supplied at build time via
`--dart-define`, never committed. Only the origin appears here, and an origin is
not a secret — it is already visible in every network request the page makes.
