#!/usr/bin/env bash
#
# verify-principal-portal.sh — sign in as the Principal against the live project
# and exercise every table and view the portal reads.
#
# This answers the question static analysis cannot: does the real Principal,
# through real RLS, actually receive the data each screen needs?
#
# It complements verify-live-security.sh, which proves the opposite direction —
# that nobody *else* can read it.
#
# WHAT IT DOES
#   1. Signs in with the Principal's email + password (password auth, same call
#      the Flutter app makes) and holds the returned access token in memory.
#   2. Requests every object in scripts/portal-objects.txt as that Principal.
#   3. Reports, per module: HTTP status, row count, and a verdict.
#
# It performs GET requests only. It writes nothing.
#
# CREDENTIALS
#   Supplied through the environment, never as arguments (arguments show up in
#   shell history and process lists). The token is never printed.
#
#   export SUPABASE_URL='https://<ref>.supabase.co'
#   export SUPABASE_ANON_KEY='<publishable/anon key>'
#   export PRINCIPAL_EMAIL='principal@ksrce.ac.in'
#   export PRINCIPAL_PASSWORD='<the temporary password you set>'
#   ./scripts/verify-principal-portal.sh
#
# EXIT CODES
#   0  every object the portal reads returned data or a legitimate empty set
#   1  at least one object the Principal needs was refused or errored
#   2  configuration missing, or sign-in failed

set -uo pipefail

# Explicit checks rather than ${VAR:?...}: that construct aborts the shell with
# status 1 before any `|| exit 2` can run, so the documented exit code was wrong.
missing=""
[ -z "${SUPABASE_URL:-}" ]        && missing="$missing SUPABASE_URL"
[ -z "${SUPABASE_ANON_KEY:-}" ]   && missing="$missing SUPABASE_ANON_KEY"
[ -z "${PRINCIPAL_EMAIL:-}" ]     && missing="$missing PRINCIPAL_EMAIL"
[ -z "${PRINCIPAL_PASSWORD:-}" ]  && missing="$missing PRINCIPAL_PASSWORD"

if [ -n "$missing" ]; then
  echo "Not configured. Set these environment variables first:$missing" >&2
  exit 2
fi

# Strip carriage returns and surrounding whitespace from every input.
#
# A value copied out of a Windows file — run-live.bat, a .env, Notepad — carries
# a trailing \r. It is invisible in the terminal, survives export, and makes
# curl fail to build the request at all: the result is HTTP 000 with an empty
# body, which reads exactly like a rejected password and is not one.
# A trailing slash on the URL is harmless but tidied for the same reason.
trim() { printf '%s' "$1" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# The URL, key and email get *all* whitespace removed, not just the ends.
#
# Trimming the ends was not enough. A URL pasted across a line wrap can carry a
# space in the middle, and curl refuses it outright:
#
#   curl: (3) URL rejected: Malformed input to a URL function   -> HTTP 000
#
# which is indistinguishable from a network failure and nothing like a rejected
# password. None of these three values can legitimately contain a space.
strip_ws() { printf '%s' "$1" | tr -d '[:space:]'; }

SUPABASE_URL=$(strip_ws "$SUPABASE_URL"); SUPABASE_URL="${SUPABASE_URL%/}"
SUPABASE_ANON_KEY=$(strip_ws "$SUPABASE_ANON_KEY")
PRINCIPAL_EMAIL=$(strip_ws "$PRINCIPAL_EMAIL")
# The password is NOT trimmed of internal characters — only \r and \n, which
# cannot legitimately be part of a password typed into a login form.
PRINCIPAL_PASSWORD=$(printf '%s' "$PRINCIPAL_PASSWORD" | tr -d '\r\n')

case "$SUPABASE_URL" in
  http://*|https://*) ;;
  *) echo "SUPABASE_URL must start with http:// or https:// (got: '${SUPABASE_URL}')" >&2; exit 2 ;;
esac

REST_PREFIX="${REST_PREFIX-/rest/v1}"
MANIFEST="${MANIFEST:-scripts/portal-objects.txt}"

# On Supabase, auth and REST share a host. Split out so the script can be
# rehearsed against a local PostgREST + auth stub before it is pointed at
# production. Defaults to Supabase's layout, so normal use needs neither.
AUTH_BASE="${AUTH_BASE-$SUPABASE_URL}"
AUTH_PATH="${AUTH_PATH-/auth/v1/token?grant_type=password}"

[ -f "$MANIFEST" ] || { echo "Manifest not found: $MANIFEST"; exit 2; }

echo
echo "Principal Portal — live data verification"
echo "Project: ${SUPABASE_URL%%.*}...(redacted)    $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo

# -----------------------------------------------------------------------------
# 1. Sign in — the same grant the Flutter client uses
# -----------------------------------------------------------------------------
# JSON is built and parsed with Python, not with printf/sed.
#
# The previous version did both by hand and broke twice: printf could not be
# trusted with a password containing `%`, and the sed patterns that read the
# error message were malformed, producing
# `sed: Unmatched ) or \)` on every failed sign-in. Worse, a parsing failure was
# reported as "SIGN-IN FAILED", which is a different thing entirely and sent us
# looking at the account instead of the script.
#
# Python is present wherever Flutter is, handles every character a password can
# contain — @ # % " \ spaces parentheses — and cannot be confused by whitespace
# in the response.
PY_BIN="${PY_BIN:-python}"
command -v "$PY_BIN" >/dev/null 2>&1 || PY_BIN=python3
command -v "$PY_BIN" >/dev/null 2>&1 || {
  echo "Neither python nor python3 found; this script needs one to parse JSON." >&2
  exit 2
}

# Build the request body safely from the environment.
LOGIN_BODY=$("$PY_BIN" -c 'import json,os,sys; sys.stdout.write(json.dumps({"email":os.environ["PRINCIPAL_EMAIL"],"password":os.environ["PRINCIPAL_PASSWORD"]}))')

# HTTP status and body are captured separately, so a transport problem, a
# rejected password and an unparsable response are three distinguishable things.
LOGIN_BODY_FILE=$(mktemp)
trap 'rm -f "$LOGIN_BODY_FILE"' EXIT

# -sS keeps the progress meter quiet but lets curl's own error through, and its
# exit code is kept separately from the HTTP status. Discarding both is what
# made a malformed URL look like a rejected password.
CURL_ERR_FILE=$(mktemp)
LOGIN_HTTP=$(curl -sS -o "$LOGIN_BODY_FILE" -w '%{http_code}' --max-time 30 \
  -X POST "${AUTH_BASE}${AUTH_PATH}" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  --data-binary "$LOGIN_BODY" 2>"$CURL_ERR_FILE")
CURL_EXIT=$?
CURL_ERR=$(tr -d '\r' < "$CURL_ERR_FILE"); rm -f "$CURL_ERR_FILE"

# Prints the token on stdout if present, otherwise an error line on stderr.
# Never echoes the password, and the token is captured into a variable rather
# than displayed.
TOKEN=$("$PY_BIN" - "$LOGIN_BODY_FILE" <<'PYEOF' 2>/tmp/.signin_err
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        raw = fh.read()
except OSError as exc:
    print(f"could not read response: {exc}", file=sys.stderr); raise SystemExit(1)
if not raw.strip():
    print("empty response from the auth endpoint", file=sys.stderr); raise SystemExit(1)
try:
    data = json.loads(raw)
except ValueError:
    print("response was not JSON: " + " ".join(raw[:120].split()), file=sys.stderr)
    raise SystemExit(1)
token = data.get("access_token")
if token:
    sys.stdout.write(token); raise SystemExit(0)
for key in ("error_description", "msg", "message", "error_code", "error"):
    if data.get(key):
        print(str(data[key]), file=sys.stderr); raise SystemExit(1)
print("no access_token in the response", file=sys.stderr)
raise SystemExit(1)
PYEOF
)
SIGNIN_REASON=$(cat /tmp/.signin_err 2>/dev/null); rm -f /tmp/.signin_err

echo "Sign-in HTTP status : ${LOGIN_HTTP}"
if [ -n "$TOKEN" ]; then
  echo "Token present       : TRUE (value not displayed)"
else
  echo "Token present       : FALSE"
fi

if [ -z "$TOKEN" ]; then
  echo
  if [ "$LOGIN_HTTP" = "000" ]; then
    # curl never completed the request. This is NOT an authentication failure —
    # the server was never reached, so the credentials were never judged.
    echo "RESULT: COULD NOT REACH THE AUTH ENDPOINT."
    echo "  The request was never completed, so this says nothing about the password."
    echo
    echo "  curl exit code : ${CURL_EXIT}"
    echo "  curl error     : ${CURL_ERR:-none reported}"
    echo
    # Character-class report on the URL. Shows the shape of the value without
    # printing it, so a stray space or control character is visible.
    echo "  SUPABASE_URL length      : ${#SUPABASE_URL}"
    echo "  starts with https://     : $(case "$SUPABASE_URL" in https://*) echo yes;; *) echo NO;; esac)"
    echo "  contains whitespace      : $(printf '%s' "$SUPABASE_URL" | grep -q '[[:space:]]' && echo YES || echo no)"
    echo "  contains control chars   : $(printf '%s' "$SUPABASE_URL" | grep -q '[[:cntrl:]]' && echo YES || echo no)"
    echo "  ANON_KEY present         : $([ -n "$SUPABASE_ANON_KEY" ] && echo yes || echo NO) (length ${#SUPABASE_ANON_KEY})"
    echo "  EMAIL present            : $([ -n "$PRINCIPAL_EMAIL" ] && echo yes || echo NO) (length ${#PRINCIPAL_EMAIL})"
    echo "  PASSWORD present         : $([ -n "$PRINCIPAL_PASSWORD" ] && echo yes || echo NO) (length ${#PRINCIPAL_PASSWORD})"
    echo
    case "$CURL_EXIT" in
      3)  echo "  Exit 3 = malformed URL. A space or control character reached curl." ;;
      6)  echo "  Exit 6 = DNS lookup failed. The host name did not resolve." ;;
      7)  echo "  Exit 7 = connection refused or no route. Firewall or proxy?" ;;
      28) echo "  Exit 28 = timed out. The host accepted nothing within 30s." ;;
      35|60) echo "  Exit ${CURL_EXIT} = TLS problem. Corporate proxy intercepting HTTPS?" ;;
      *)  echo "  See https://curl.se/libcurl/c/libcurl-errors.html for exit ${CURL_EXIT}." ;;
    esac
    echo
    echo "  Reachability check that exposes nothing:"
    echo "    curl -sS -o /dev/null -w 'HTTP %{http_code}\\n' \"\$SUPABASE_URL/auth/v1/health\""
  elif [ "$LOGIN_HTTP" = "200" ]; then
    # Requirement: a parsing failure is not an authentication failure.
    echo "RESULT: SIGN-IN OK, BUT THE RESPONSE COULD NOT BE PARSED."
    echo "  The server accepted the credentials (HTTP 200) but no token was read."
    echo "  detail: ${SIGNIN_REASON:-unknown}"
  else
    echo "RESULT: SIGN-IN FAILED (HTTP ${LOGIN_HTTP})."
    echo "  reason: ${SIGNIN_REASON:-no detail returned}"
    echo
    echo "  If the password is right, check how it was exported. In bash a '#'"
    echo "  starts a comment unless the value is single-quoted:"
    echo "      export PRINCIPAL_PASSWORD='<your-password>#with-hash'   <- correct"
    echo "      export PRINCIPAL_PASSWORD=<your-password>#with-hash     <- truncated at #"
  fi
  exit 2
fi

echo "Sign-in             : OK"

# The role claim the Flutter client gates the UI on — decoded with Python so a
# padding quirk in the JWT cannot break it.
ROLE=$(printf '%s' "$TOKEN" | "$PY_BIN" -c '
import sys, json, base64
tok = sys.stdin.read().strip()
try:
    part = tok.split(".")[1]
    part += "=" * (-len(part) % 4)
    print(json.loads(base64.urlsafe_b64decode(part)).get("role", "unknown"))
except Exception:
    print("unknown")
')
echo "JWT role claim      : ${ROLE}"
echo

# -----------------------------------------------------------------------------
# 2. Exercise every object the portal reads
# -----------------------------------------------------------------------------
PASS=0; FAIL=0; EMPTY=0
FAILED_LIST=""

printf "  %-9s %-34s %-6s %-8s %s\n" "SCHEMA" "OBJECT" "HTTP" "ROWS" "MODULES"
printf "  %-9s %-34s %-6s %-8s %s\n" "---------" "----------------------------------" "------" "--------" "-------"

while IFS='|' read -r schema object modules; do
  [ -z "${schema:-}" ] && continue

  body=$(curl -s --max-time 25 \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept-Profile: ${schema}" \
    "${SUPABASE_URL}${REST_PREFIX}/${object}?select=*&limit=5")

  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept-Profile: ${schema}" \
    "${SUPABASE_URL}${REST_PREFIX}/${object}?select=*&limit=5")

  # A successful select returns a JSON *array*; a PostgREST error returns a
  # JSON *object* carrying "message". Detecting on `"code":"..."` alone was
  # wrong — `principal.v_department_rollup` has a department `code` column, so
  # every successful read of it was reported as a failure.
  if [ "${body#\{}" != "$body" ] && printf '%s' "$body" | grep -q '"message"'; then
    err=$(printf '%s' "$body" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p' | cut -c1-46)
    printf "  %-9s %-34s %-6s %-8s FAIL: %s\n" "$schema" "$object" "$code" "-" "$err"
    FAIL=$((FAIL+1)); FAILED_LIST="${FAILED_LIST}\n    ${schema}.${object} -> ${err}"
    continue
  fi

  rows=$(printf '%s' "$body" | grep -o '"id"' | wc -l | tr -d ' ')
  [ "$body" = "[]" ] && rows=0
  if [ "$rows" = "0" ] && [ "$body" != "[]" ]; then
    # Rows without an "id" column (views, aggregates): count opening braces.
    rows=$(printf '%s' "$body" | grep -o '{' | wc -l | tr -d ' ')
  fi

  if [ "$body" = "[]" ]; then
    printf "  %-9s %-34s %-6s %-8s %s  (empty — verify expected)\n" "$schema" "$object" "$code" "0" "$modules"
    EMPTY=$((EMPTY+1))
  else
    printf "  %-9s %-34s %-6s %-8s %s\n" "$schema" "$object" "$code" "$rows" "$modules"
    PASS=$((PASS+1))
  fi
done < "$MANIFEST"

echo
echo "-----------------------------------------------------------"
echo "Objects returning data : $PASS"
echo "Objects empty          : $EMPTY   (legitimate if the table really has no rows)"
echo "Objects refused/errored: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo
  echo "The Principal was refused, or the request failed, on:"
  printf "%b\n" "$FAILED_LIST"
  echo
  echo "Each of these is a screen that will show an error state in the portal."
  exit 1
fi

echo
echo "RESULT: PASS — every object the portal reads is reachable by the Principal."
exit 0
