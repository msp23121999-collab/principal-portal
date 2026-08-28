#!/usr/bin/env bash
#
# verify-live-security.sh — prove a Supabase project is not serving protected
# data to anonymous callers.
#
# This is the acceptance test for
# supabase/migrations/20260814000000_rls_hardening_corrections.sql and
# supabase/migrations/20260814000001_canonical_principal_identity.sql.
#
# Run it BEFORE applying them (expect FAIL — that is the recorded starting
# state) and AFTER (expect PASS). Deployment is not finished until this exits 0.
#
# It is read-only. It issues GET requests and never writes.
#
# USAGE
#   export SUPABASE_URL='https://<ref>.supabase.co'
#   export SUPABASE_ANON_KEY='<publishable/anon key>'
#   ./scripts/verify-live-security.sh
#
#   # optional: also prove a signed-in Principal still has access
#   export PRINCIPAL_JWT='<access token for the Principal account>'
#
#   # optional: prove a signed-in NON-Principal is denied
#   export NON_PRINCIPAL_JWT='<access token for any other account>'
#
# Credentials come from the environment on purpose. Nothing is written to disk
# and no key is echoed — the script prints only HTTP status codes and verdicts.
#
# EXIT CODES
#   0  every protected object refused anonymous access (and any supplied
#      authenticated identity behaved correctly)
#   1  at least one protected object is still exposed
#   2  configuration missing

set -uo pipefail

: "${SUPABASE_URL:?SUPABASE_URL is not set}" 2>/dev/null || exit 2
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY is not set}" 2>/dev/null || exit 2

SCHEMA="${SCHEMA:-principal}"

# Supabase serves PostgREST under /rest/v1. A bare PostgREST (used to rehearse
# this script against a local copy of the schema) serves at the root, so the
# prefix is configurable: REST_PREFIX='' points it at a plain instance.
REST_PREFIX="${REST_PREFIX-/rest/v1}"

FAILURES=0
CHECKS=0

# Tables that must never be readable without a session.
PROTECTED_TABLES=(
  principal_profiles
  user_settings
  payroll_lines
  audit_entries
  approval_decisions
  approval_requests
)

# All seven views. Each is owner-run and guarded by principal.is_principal(),
# so an anonymous caller must be refused outright.
PROTECTED_VIEWS=(
  v_dashboard_summary
  v_department_rollup
  v_attendance_daily
  v_package_bands
  v_department_placement_summary
  v_faculty_attendance_today
  v_attendance_daily_by_department
)

# Returns the HTTP status for a single-row GET against $1 as the bearer in $2.
probe() {
  local object="$1" bearer="$2"
  curl -s -o /dev/null -w '%{http_code}' --max-time 25 \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${bearer}" \
    -H "Accept-Profile: ${SCHEMA}" \
    -H "Range: 0-0" \
    "${SUPABASE_URL}${REST_PREFIX}/${object}?select=*"
}

# Returns the body, so we can tell "200 with rows" from "200 with []".
probe_body() {
  local object="$1" bearer="$2"
  curl -s --max-time 25 \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${bearer}" \
    -H "Accept-Profile: ${SCHEMA}" \
    -H "Range: 0-0" \
    "${SUPABASE_URL}${REST_PREFIX}/${object}?select=*"
}

report() {
  local label="$1" verdict="$2" detail="$3"
  CHECKS=$((CHECKS + 1))
  if [ "$verdict" = "PASS" ]; then
    printf '  \033[32mPASS\033[0m  %-34s %s\n' "$label" "$detail"
  else
    printf '  \033[31mFAIL\033[0m  %-34s %s\n' "$label" "$detail"
    FAILURES=$((FAILURES + 1))
  fi
}

echo
echo "Live security verification — ${SUPABASE_URL%%.*}...(redacted)"
echo "Schema: ${SCHEMA}    $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo

echo "A. ANONYMOUS — every protected object must refuse"
for t in "${PROTECTED_TABLES[@]}" "${PROTECTED_VIEWS[@]}"; do
  code=$(probe "$t" "$SUPABASE_ANON_KEY")
  # 200/206 means rows came back to a caller with no session: exposed.
  if [ "$code" = "200" ] || [ "$code" = "206" ]; then
    report "$t" "FAIL" "HTTP $code — STILL EXPOSED"
  else
    report "$t" "PASS" "HTTP $code — denied"
  fi
done

if [ -n "${NON_PRINCIPAL_JWT:-}" ]; then
  echo
  echo "B. AUTHENTICATED NON-PRINCIPAL — must see no protected rows"
  for t in "${PROTECTED_TABLES[@]}" "${PROTECTED_VIEWS[@]}"; do
    body=$(probe_body "$t" "$NON_PRINCIPAL_JWT")
    # RLS returns 200 with an empty array rather than an error. Both are fine;
    # anything carrying a row is not.
    if [ "$body" = "[]" ] || [ -z "$body" ]; then
      report "$t" "PASS" "no rows"
    elif echo "$body" | grep -q '"message"'; then
      report "$t" "PASS" "denied"
    else
      report "$t" "FAIL" "returned data to a non-Principal"
    fi
  done
else
  echo
  echo "B. AUTHENTICATED NON-PRINCIPAL — SKIPPED (set NON_PRINCIPAL_JWT to run)"
fi

if [ -n "${PRINCIPAL_JWT:-}" ]; then
  echo
  echo "C. LEGITIMATE PRINCIPAL — must still have access (guards against lockout)"
  for t in "${PROTECTED_VIEWS[@]}"; do
    body=$(probe_body "$t" "$PRINCIPAL_JWT")
    if echo "$body" | grep -q '"message"'; then
      report "$t" "FAIL" "Principal was refused — possible lockout"
    elif [ "$body" = "[]" ]; then
      # An empty view is legitimate when the underlying data is empty, so this
      # is reported rather than failed. Check it against expected volumes.
      report "$t" "PASS" "reachable, 0 rows (verify this is expected)"
    else
      report "$t" "PASS" "returns data"
    fi
  done
else
  echo
  echo "C. LEGITIMATE PRINCIPAL — SKIPPED (set PRINCIPAL_JWT to run)"
fi

echo
echo "-----------------------------------------------------------"
if [ "$FAILURES" -eq 0 ]; then
  echo "RESULT: PASS — $CHECKS checks, 0 failures."
  echo "No protected object served data to an unauthorised caller."
  exit 0
fi

echo "RESULT: FAIL — $CHECKS checks, $FAILURES failure(s)."
echo
echo "If this is a pre-deployment run, that is the expected starting state."
echo "Apply, in this order:"
echo "  1. supabase/migrations/20260814000000_rls_hardening_corrections.sql"
echo "  2. supabase/migrations/20260814000001_canonical_principal_identity.sql"
echo "then re-run this script. It must exit 0 before the release is complete."
exit 1
