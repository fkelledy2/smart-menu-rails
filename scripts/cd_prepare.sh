#!/usr/bin/env bash
# =============================================================================
# cd_prepare.sh — Continuous Delivery preparation gate
#
# Ensures the codebase is clean and ready to deploy to production:
#   1. Auto-fixes RuboCop, JS/CSS lint, i18n locale gaps (up to 3 passes)
#   2. Runs all unit tests   (Minitest + RSpec + Vitest)
#   3. Runs all system tests (Capybara / Selenium)
#   4. Runs the full ci_check.sh gate (security, quality, deployment readiness)
#
# Usage:
#   scripts/cd_prepare.sh                  # full run (unit + system + ci)
#   scripts/cd_prepare.sh --no-system      # skip slow Capybara system tests
#   scripts/cd_prepare.sh --quick          # --no-system + skip asset precompile
#   scripts/cd_prepare.sh --fix-only       # auto-fix then exit (no tests)
#   scripts/cd_prepare.sh --unit-only      # unit tests + fixes, skip system + ci
#
# Exit codes:
#   0  everything passed — safe to push
#   1  one or more checks failed — review output above
# =============================================================================

set -uo pipefail   # NOTE: no -e so we collect all failures before exiting

# ── Colours & helpers ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
FIX_COUNT=0
FAILURES=()

step_pass()  { PASS_COUNT=$((PASS_COUNT + 1)); echo -e "  ${GREEN}✔ $1${NC}"; }
step_fail()  { FAIL_COUNT=$((FAIL_COUNT + 1)); FAILURES+=("$1"); echo -e "  ${RED}✘ $1${NC}"; }
step_skip()  { SKIP_COUNT=$((SKIP_COUNT + 1)); echo -e "  ${YELLOW}⊘ $1 (skipped)${NC}"; }
step_fix()   { FIX_COUNT=$((FIX_COUNT + 1)); echo -e "  ${CYAN}↻ $1${NC}"; }
step_warn()  { echo -e "  ${YELLOW}⚠ $1${NC}"; }
step_info()  { echo -e "  ${BLUE}  $1${NC}"; }

section() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

run_cmd() {
  # run_cmd <label> <cmd...>
  # Returns 0 on success, 1 on failure; never raises.
  local label="$1"; shift
  local output
  output=$("$@" 2>&1)
  local rc=$?
  if [ $rc -eq 0 ]; then
    step_pass "$label"
  else
    step_fail "$label"
    # Show last 15 lines of output to aid diagnosis
    echo "$output" | tail -15 | sed 's/^/       /'
  fi
  return $rc
}

# ── Parse flags ───────────────────────────────────────────────────────────────
RUN_SYSTEM=true
RUN_CI=true
RUN_UNIT=true
FIX_ONLY=false
QUICK=false

for arg in "$@"; do
  case "$arg" in
    --no-system)  RUN_SYSTEM=false ;;
    --quick)      RUN_SYSTEM=false; QUICK=true ;;
    --fix-only)   FIX_ONLY=true; RUN_UNIT=false; RUN_SYSTEM=false; RUN_CI=false ;;
    --unit-only)  RUN_SYSTEM=false; RUN_CI=false ;;
  esac
done

# ── Project root ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

START_TIME=$(date +%s)

echo ""
echo -e "${BOLD}🚀 Smart Menu — Continuous Delivery Preparation${NC}"
echo -e "   $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "   System tests: $( $RUN_SYSTEM && echo 'yes' || echo 'no (--no-system)' )"
echo -e "   CI gate:      $( $RUN_CI     && echo 'yes' || echo 'no' )"
$QUICK && echo -e "   ${YELLOW}--quick: asset precompile skipped${NC}"

# =============================================================================
# PHASE 1 — AUTO-FIX  (up to 3 passes, stop when clean)
# =============================================================================
section "Phase 1/4  Auto-Fix Loop"

MAX_FIX_PASSES=3
for pass in $(seq 1 $MAX_FIX_PASSES); do
  echo -e "\n  ${BOLD}Pass $pass / $MAX_FIX_PASSES${NC}"

  # ── RuboCop ─────────────────────────────────────────────────────────────────
  echo -e "  ${CYAN}↻ RuboCop auto-correct (-A)…${NC}"
  RUBOCOP_OUT=$(bundle exec rubocop -A --format simple 2>&1 || true)
  RUBOCOP_FIXED=$(echo "$RUBOCOP_OUT" | grep -oE '[0-9]+ offenses? corrected' | grep -oE '^[0-9]+' || echo "0")
  [ "${RUBOCOP_FIXED:-0}" -gt 0 ] && step_fix "RuboCop: corrected $RUBOCOP_FIXED offense(s)"

  # ── JS lint + Prettier ───────────────────────────────────────────────────────
  echo -e "  ${CYAN}↻ ESLint + Prettier auto-fix…${NC}"
  yarn lint:js:fix > /dev/null 2>&1 || true
  yarn format > /dev/null 2>&1 || true

  # ── CSS/SCSS ─────────────────────────────────────────────────────────────────
  echo -e "  ${CYAN}↻ Stylelint auto-fix…${NC}"
  yarn lint:css:fix > /dev/null 2>&1 || true

  # ── i18n locale gaps ─────────────────────────────────────────────────────────
  echo -e "  ${CYAN}↻ i18n: syncing missing keys with placeholders…${NC}"
  I18N_OUT=$(bundle exec i18n-tasks missing 2>&1 || true)
  MISSING_COUNT=$(echo "$I18N_OUT" | grep -oE 'Missing translations \([0-9]+' | grep -oE '[0-9]+' || echo "0")
  if [ "${MISSING_COUNT:-0}" -gt 0 ]; then
    "$SCRIPT_DIR/i18n_sync_and_translate.sh" --sync-only > /dev/null 2>&1 || true
    step_fix "i18n: added placeholders for $MISSING_COUNT missing key(s)"
  fi

  # ── Check if everything is now clean ─────────────────────────────────────────
  RUBOCOP_CLEAN=true
  JS_CLEAN=true
  CSS_CLEAN=true
  I18N_CLEAN=true

  bundle exec rubocop --format simple > /dev/null 2>&1 || RUBOCOP_CLEAN=false
  yarn lint:js > /dev/null 2>&1 || JS_CLEAN=false
  yarn lint:css > /dev/null 2>&1 || CSS_CLEAN=false
  I18N_RECHECK=$(bundle exec i18n-tasks missing 2>&1 || true)
  echo "$I18N_RECHECK" | grep -q "Missing translations (0)" || I18N_CLEAN=false

  if $RUBOCOP_CLEAN && $JS_CLEAN && $CSS_CLEAN && $I18N_CLEAN; then
    step_pass "All auto-fixable issues resolved (pass $pass)"
    break
  elif [ "$pass" -eq "$MAX_FIX_PASSES" ]; then
    $RUBOCOP_CLEAN || step_fail "RuboCop — unfixable offenses remain after $MAX_FIX_PASSES passes"
    $JS_CLEAN      || step_fail "ESLint — unfixable offenses remain after $MAX_FIX_PASSES passes"
    $CSS_CLEAN     || step_fail "Stylelint — unfixable offenses remain after $MAX_FIX_PASSES passes"
    $I18N_CLEAN    || step_fail "i18n — missing keys still unresolved after $MAX_FIX_PASSES passes"
    echo -e "\n  ${YELLOW}Continuing to tests despite lint failures…${NC}"
  else
    step_info "Still dirty — running another pass…"
  fi
done

if $FIX_ONLY; then
  # ── Summary for --fix-only mode ───────────────────────────────────────────
  END_TIME=$(date +%s)
  ELAPSED=$((END_TIME - START_TIME))
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  Summary — fix-only mode${NC}  ($((ELAPSED / 60))m $((ELAPSED % 60))s)"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${CYAN}↻ Auto-fixes applied: $FIX_COUNT${NC}"
  if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "  ${RED}✘ Unfixable issues:   $FAIL_COUNT${NC}"
    for f in "${FAILURES[@]}"; do echo -e "    ${RED}• $f${NC}"; done
    exit 1
  else
    echo -e "  ${GREEN}✔ All fixable issues resolved.${NC}"
    echo -e "  ${YELLOW}  Commit the changes: git add -A && git commit -m 'fix: auto-correct lint and i18n'${NC}"
    exit 0
  fi
fi

# =============================================================================
# PHASE 2 — UNIT TESTS
# =============================================================================
if $RUN_UNIT; then
  section "Phase 2/4  Unit Tests"

  # Prepare test database once
  echo -e "  ${CYAN}Preparing test database…${NC}"
  if ! RAILS_ENV=test bundle exec rails db:test:prepare > /dev/null 2>&1; then
    step_fail "Test database preparation"
    echo -e "  ${YELLOW}Continuing without fresh db:test:prepare…${NC}"
  fi

  # Minitest (unit + integration — excludes test/system/)
  echo -e "  ${CYAN}Running Minitest (unit + integration)…${NC}"
  MINITEST_OUT=$(RAILS_ENV=test \
    DISABLE_SIMPLECOV=1 \
    DISABLE_BULLET_IN_TESTS=true \
    RAILS_LOG_LEVEL=error \
    bundle exec rails test 2>&1)
  MINITEST_RC=$?
  MINITEST_SUMMARY=$(echo "$MINITEST_OUT" | grep -E '^[0-9]+ runs|Finished in|failures|errors' | tail -5)
  if [ $MINITEST_RC -eq 0 ]; then
    step_pass "Minitest — $(echo "$MINITEST_SUMMARY" | head -1)"
  else
    step_fail "Minitest"
    echo "$MINITEST_OUT" | grep -E 'FAILED|Error:|Failure:' | head -20 | sed 's/^/       /'
    echo "$MINITEST_SUMMARY" | sed 's/^/       /'
  fi

  # RSpec (if installed)
  if bundle show rspec-rails > /dev/null 2>&1; then
    echo -e "  ${CYAN}Running RSpec…${NC}"
    RSPEC_OUT=$(RAILS_ENV=test \
      DISABLE_SIMPLECOV=1 \
      bundle exec rspec --format progress 2>&1)
    RSPEC_RC=$?
    RSPEC_SUMMARY=$(echo "$RSPEC_OUT" | grep -E '^[0-9]+ example|Finished in' | tail -3)
    if [ $RSPEC_RC -eq 0 ]; then
      step_pass "RSpec — $(echo "$RSPEC_SUMMARY" | head -1)"
    else
      step_fail "RSpec"
      echo "$RSPEC_OUT" | grep -E 'rspec \./|FAILED|Failure/Error:' | head -20 | sed 's/^/       /'
      echo "$RSPEC_SUMMARY" | sed 's/^/       /'
    fi
  else
    step_skip "RSpec (rspec-rails not in Gemfile)"
  fi

  # Vitest (JS unit tests)
  echo -e "  ${CYAN}Running Vitest (JS unit tests)…${NC}"
  if yarn test:run > /dev/null 2>&1; then
    step_pass "Vitest"
  else
    # Only fail if test files actually exist
    if find app/javascript test/javascript -name '*.test.*' -o -name '*.spec.*' 2>/dev/null | grep -q .; then
      step_fail "Vitest — JS unit tests failed (run: yarn test:run)"
    else
      step_skip "Vitest (no JS test files found)"
    fi
  fi
fi

# =============================================================================
# PHASE 3 — SYSTEM TESTS (Capybara / Selenium)
# =============================================================================
if $RUN_SYSTEM; then
  section "Phase 3/4  System Tests"

  SYSTEM_TEST_DIR="$PROJECT_DIR/test/system"
  SYSTEM_FILE_COUNT=$(find "$SYSTEM_TEST_DIR" -name '*_test.rb' 2>/dev/null | wc -l | tr -d ' ')

  if [ "$SYSTEM_FILE_COUNT" -eq 0 ]; then
    step_skip "System tests (no files in test/system/)"
  else
    step_info "Found $SYSTEM_FILE_COUNT system test file(s)"

    # System tests need a headless browser — check chromedriver is available
    if ! command -v chromedriver > /dev/null 2>&1 && ! command -v google-chrome > /dev/null 2>&1 && ! command -v chromium > /dev/null 2>&1; then
      step_warn "chromedriver / chromium not found — system tests may fail"
    fi

    echo -e "  ${CYAN}Running system tests (this may take several minutes)…${NC}"
    SYSTEM_OUT=$(RAILS_ENV=test \
      DISABLE_SIMPLECOV=1 \
      RAILS_LOG_LEVEL=error \
      bundle exec rails test:system 2>&1)
    SYSTEM_RC=$?
    SYSTEM_SUMMARY=$(echo "$SYSTEM_OUT" | grep -E '^[0-9]+ runs|Finished in|failures|errors' | tail -5)

    if [ $SYSTEM_RC -eq 0 ]; then
      step_pass "System tests — $(echo "$SYSTEM_SUMMARY" | head -1)"
    else
      step_fail "System tests"
      echo "$SYSTEM_OUT" | grep -E 'FAILED|Error:|Failure:|Screenshot:' | head -20 | sed 's/^/       /'
      echo "$SYSTEM_SUMMARY" | sed 's/^/       /'
      step_info "Screenshots saved in tmp/screenshots/ (if any)"
    fi
  fi
else
  section "Phase 3/4  System Tests"
  step_skip "System tests (--no-system / --quick)"
fi

# =============================================================================
# PHASE 4 — CI GATE  (security, quality re-verify, deployment readiness)
# =============================================================================
if $RUN_CI; then
  section "Phase 4/4  CI Gate (scripts/ci_check.sh)"

  echo -e "  ${CYAN}Running full CI gate…${NC}"
  CI_FLAGS="--fix"
  $QUICK && CI_FLAGS="$CI_FLAGS --quick"

  # Run ci_check.sh, capturing output but also streaming it
  CI_OUT=$("$SCRIPT_DIR/ci_check.sh" $CI_FLAGS 2>&1)
  CI_RC=$?

  # Stream a condensed view: only section headers and ✔/✘/⊘ lines
  echo "$CI_OUT" | grep -E '^  [✔✘⊘⚠↻]|━━━|Summary|Passed:|Failed:|Skipped:|Failures:' | sed 's/^/  /'

  if [ $CI_RC -eq 0 ]; then
    step_pass "CI gate"
  else
    step_fail "CI gate — one or more checks failed (see output above)"
  fi
fi

# =============================================================================
# SUMMARY
# =============================================================================
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS_REM=$((ELAPSED % 60))

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  CD Preparation Summary${NC}  (${MINUTES}m ${SECONDS_REM}s)"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}✔ Passed:  $PASS_COUNT${NC}"
echo -e "  ${RED}✘ Failed:  $FAIL_COUNT${NC}"
echo -e "  ${YELLOW}⊘ Skipped: $SKIP_COUNT${NC}"
echo -e "  ${CYAN}↻ Fixed:   $FIX_COUNT auto-corrections applied${NC}"

if [ $FIX_COUNT -gt 0 ]; then
  echo ""
  # Check if there are uncommitted changes from the auto-fixes
  if ! git diff --quiet 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ Auto-fix changes are unstaged. To commit them:${NC}"
    echo -e "     ${BOLD}git add -A && git commit -m 'fix: auto-correct lint, style, and i18n'${NC}"
  fi
fi

if [ $FAIL_COUNT -gt 0 ]; then
  echo ""
  echo -e "  ${RED}${BOLD}Failures:${NC}"
  for f in "${FAILURES[@]}"; do
    echo -e "    ${RED}• $f${NC}"
  done
  echo ""
  echo -e "  ${RED}${BOLD}✘ NOT ready to deploy — resolve the failures above.${NC}"
  exit 1
else
  echo ""
  echo -e "  ${GREEN}${BOLD}✔ Codebase is clean and ready to deploy to production.${NC}"
  if $RUN_SYSTEM; then
    echo -e "  ${GREEN}  Unit tests ✔ · System tests ✔ · CI gate ✔${NC}"
  else
    echo -e "  ${GREEN}  Unit tests ✔ · CI gate ✔  (system tests skipped)${NC}"
  fi
  exit 0
fi
