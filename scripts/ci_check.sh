#!/usr/bin/env bash
# =============================================================================
# ci_check.sh — Run all GitHub Actions CI checks locally
#
# Mirrors the jobs in .github/workflows/ci.yml so you can catch failures
# before pushing. Also catches i18n translation gaps before they cause
# test-suite failures in CI.
#
# Usage:
#   scripts/ci_check.sh            # run everything
#   scripts/ci_check.sh --quick    # skip slow checks (Lighthouse, assets)
#   scripts/ci_check.sh --fix      # auto-fix RuboCop + JS/CSS lint + i18n sync
#   scripts/ci_check.sh --i18n     # only run the i18n check (fast pre-commit)
# =============================================================================

set -euo pipefail

# ── Colours & helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
FAILURES=()

step_pass()  { PASS_COUNT=$((PASS_COUNT + 1)); echo -e "  ${GREEN}✔ $1${NC}"; }
step_fail()  { FAIL_COUNT=$((FAIL_COUNT + 1)); FAILURES+=("$1"); echo -e "  ${RED}✘ $1${NC}"; }
step_skip()  { SKIP_COUNT=$((SKIP_COUNT + 1)); echo -e "  ${YELLOW}⊘ $1 (skipped)${NC}"; }
step_warn()  { echo -e "  ${YELLOW}⚠ $1${NC}"; }

section() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ── Parse flags ──────────────────────────────────────────────────────────────
QUICK=false
FIX=false
I18N_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --quick)  QUICK=true ;;
    --fix)    FIX=true ;;
    --i18n)   I18N_ONLY=true ;;
  esac
done

# ── Project root ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

START_TIME=$(date +%s)

echo ""
echo -e "${BOLD}🚀 Smart Menu CI Check${NC}"
if $I18N_ONLY; then
  echo -e "   ${YELLOW}--i18n mode: running i18n check only${NC}"
else
  echo -e "   Running the same checks as GitHub Actions…"
fi
if $QUICK; then
  echo -e "   ${YELLOW}--quick mode: skipping Lighthouse & asset precompile${NC}"
fi
if $FIX; then
  echo -e "   ${YELLOW}--fix mode: auto-correct RuboCop, JS/CSS lint, and i18n sync${NC}"
fi

# ── i18n-only shortcut ───────────────────────────────────────────────────────
# When --i18n is passed, run the i18n section alone and exit.
if $I18N_ONLY; then
  section "i18n — Translation Coverage"

  MISSING_OUTPUT=$(bundle exec i18n-tasks missing 2>&1 || true)
  if echo "$MISSING_OUTPUT" | grep -q "Missing translations (0)"; then
    step_pass "i18n — no missing translations"
  elif echo "$MISSING_OUTPUT" | grep -q "Missing translations"; then
    MISSING_COUNT=$(echo "$MISSING_OUTPUT" | grep -oE 'Missing translations \([0-9]+' | grep -oE '[0-9]+' || echo "?")
    if $FIX; then
      echo -e "  ${CYAN}↻ Auto-syncing $MISSING_COUNT missing key(s) with placeholder values…${NC}"
      "$SCRIPT_DIR/i18n_sync_and_translate.sh" --sync-only
      # Re-check after sync
      RECHECK=$(bundle exec i18n-tasks missing 2>&1 || true)
      if echo "$RECHECK" | grep -q "Missing translations (0)"; then
        step_pass "i18n — all keys synced (placeholder values added)"
        echo -e "  ${YELLOW}⚠ Run scripts/i18n_sync_and_translate.sh to translate via DeepL${NC}"
        echo -e "  ${YELLOW}  then commit: git add config/locales/ && git commit -m 'i18n: sync missing keys'${NC}"
      else
        REMAIN=$(echo "$RECHECK" | grep -oE 'Missing translations \([0-9]+' | grep -oE '[0-9]+' || echo "?")
        step_fail "i18n — $REMAIN key(s) still missing after sync"
      fi
    else
      step_fail "i18n — $MISSING_COUNT missing translation(s)"
      echo -e "       Run ${BOLD}scripts/ci_check.sh --i18n --fix${NC} to add placeholder keys"
      echo -e "       Run ${BOLD}scripts/i18n_sync_and_translate.sh${NC} to also translate via DeepL"
    fi
  else
    step_pass "i18n — no missing translations"
  fi

  UNUSED_COUNT=$(bundle exec i18n-tasks unused 2>&1 | grep -oE 'Unused keys \([0-9]+' | grep -oE '[0-9]+' || echo "0")
  if [ "$UNUSED_COUNT" != "0" ] && [ "$UNUSED_COUNT" != "" ]; then
    step_warn "i18n — $UNUSED_COUNT unused translation key(s) (run: bundle exec i18n-tasks remove-unused)"
  fi

  echo ""
  if [ ${FAIL_COUNT} -gt 0 ]; then
    echo -e "  ${RED}${BOLD}✘ i18n check failed.${NC}"
    exit 1
  else
    echo -e "  ${GREEN}${BOLD}✔ i18n check passed.${NC}"
    exit 0
  fi
fi

# =============================================================================
# 1. SECURITY ANALYSIS  (mirrors: jobs.security)
# =============================================================================
section "1/7  Security Analysis"

# Bundler Audit
if bundle exec bundler-audit --update > /dev/null 2>&1 && \
   bundle exec bundler-audit check > /dev/null 2>&1; then
  step_pass "Bundler Audit — no vulnerable gems"
else
  step_fail "Bundler Audit — vulnerable gems found"
  echo -e "       Run ${BOLD}bundle exec bundler-audit check${NC} for details"
fi

# Brakeman
if bundle exec brakeman --config-file config/brakeman.yml --no-pager -q > /dev/null 2>&1; then
  step_pass "Brakeman — no security warnings"
else
  step_fail "Brakeman — security warnings found"
  echo -e "       Run ${BOLD}bundle exec brakeman --config-file config/brakeman.yml${NC} for details"
fi

# =============================================================================
# 2. CODE QUALITY  (mirrors: jobs.quality)
# =============================================================================
section "2/7  Code Quality"

# RuboCop — auto-correct then verify
echo -e "  ${CYAN}↻ Running RuboCop with auto-correct…${NC}"
bundle exec rubocop -A --format simple 2>&1 | tail -5 || true
# Re-check: are there any remaining offenses after auto-correct?
if bundle exec rubocop --format simple > /dev/null 2>&1; then
  step_pass "RuboCop — all offenses auto-corrected"
else
  step_fail "RuboCop — unfixable offenses remain after auto-correct"
  echo -e "       Run ${BOLD}bundle exec rubocop${NC} for details"
fi

# UI/UX lint guardrails
if bundle exec rake uiux:lint > /dev/null 2>&1; then
  step_pass "UI/UX lint guardrails"
else
  step_fail "UI/UX lint guardrails"
  echo -e "       Run ${BOLD}bundle exec rake uiux:lint${NC} for details"
fi

# JavaScript lint (ESLint) — always auto-fix first, then verify
echo -e "  ${CYAN}↻ Auto-fixing JS (ESLint + Prettier)…${NC}"
yarn lint:js:fix > /dev/null 2>&1 || true
yarn format > /dev/null 2>&1 || true
if yarn lint:js > /dev/null 2>&1; then
  step_pass "ESLint — no JS offenses"
else
  step_fail "ESLint — unfixable JS offenses remain"
  echo -e "       Run ${BOLD}yarn lint:js${NC} for details"
fi

# CSS/SCSS lint (Stylelint) — always auto-fix first, then verify
echo -e "  ${CYAN}↻ Auto-fixing CSS (Stylelint)…${NC}"
yarn lint:css:fix > /dev/null 2>&1 || true
if yarn lint:css > /dev/null 2>&1; then
  step_pass "Stylelint — no CSS/SCSS offenses"
else
  step_fail "Stylelint — unfixable CSS/SCSS offenses remain"
  echo -e "       Run ${BOLD}yarn lint:css${NC} for details"
fi

# =============================================================================
# 3. i18n — TRANSLATION COVERAGE
# =============================================================================
section "3/7  i18n — Translation Coverage"

MISSING_OUTPUT=$(bundle exec i18n-tasks missing 2>&1 || true)
if echo "$MISSING_OUTPUT" | grep -q "Missing translations (0)"; then
  step_pass "i18n — no missing translations"
elif echo "$MISSING_OUTPUT" | grep -q "Missing translations"; then
  MISSING_COUNT=$(echo "$MISSING_OUTPUT" | grep -oE 'Missing translations \([0-9]+' | grep -oE '[0-9]+' || echo "?")
  if $FIX; then
    echo -e "  ${CYAN}↻ Syncing $MISSING_COUNT missing key(s) with placeholder values…${NC}"
    "$SCRIPT_DIR/i18n_sync_and_translate.sh" --sync-only
    # Re-check after sync
    RECHECK=$(bundle exec i18n-tasks missing 2>&1 || true)
    if echo "$RECHECK" | grep -q "Missing translations (0)"; then
      step_pass "i18n — all keys synced (placeholder values added)"
      echo -e "  ${YELLOW}⚠ Keys have 'replace_me' values — run scripts/i18n_sync_and_translate.sh to translate via DeepL${NC}"
      echo -e "  ${YELLOW}  then: git add config/locales/ && git commit -m 'i18n: sync missing keys'${NC}"
    else
      REMAIN=$(echo "$RECHECK" | grep -oE 'Missing translations \([0-9]+' | grep -oE '[0-9]+' || echo "?")
      step_fail "i18n — $REMAIN key(s) still missing after sync"
    fi
  else
    step_fail "i18n — $MISSING_COUNT missing translation(s) across locale files"
    echo -e "       Run ${BOLD}scripts/ci_check.sh --i18n --fix${NC} to add placeholder keys"
    echo -e "       Run ${BOLD}scripts/i18n_sync_and_translate.sh${NC} to sync + translate via DeepL"
  fi
else
  step_pass "i18n — no missing translations"
fi

# Unused key count (informational, not a failure)
UNUSED_COUNT=$(bundle exec i18n-tasks unused 2>&1 | grep -oE 'Unused keys \([0-9]+' | grep -oE '[0-9]+' || echo "0")
if [ "${UNUSED_COUNT:-0}" != "0" ] && [ "${UNUSED_COUNT:-0}" != "" ]; then
  step_warn "i18n — ${UNUSED_COUNT} unused key(s) (informational; run: bundle exec i18n-tasks remove-unused)"
fi

# =============================================================================
# 4. TEST SUITE  (mirrors: jobs.test)
# =============================================================================
section "4/7  Test Suite"

# Minitest
echo -e "  ${CYAN}Running Minitest…${NC}"
if RAILS_ENV=test bundle exec rails test 2>&1 | tail -3; then
  step_pass "Minitest"
else
  step_fail "Minitest"
fi

# RSpec
echo -e "  ${CYAN}Running RSpec…${NC}"
if bundle show rspec-rails > /dev/null 2>&1; then
  if RAILS_ENV=test bundle exec rspec 2>&1 | tail -3; then
    step_pass "RSpec"
  else
    step_fail "RSpec"
  fi
else
  step_skip "RSpec (not installed)"
fi

# Vitest (JS unit tests)
echo -e "  ${CYAN}Running Vitest (JS unit tests)…${NC}"
if yarn test:run > /dev/null 2>&1; then
  step_pass "Vitest — JS unit tests"
else
  # Only fail if there are actual test files; vitest exits non-zero when no files found
  if ls app/javascript/**/*.test.* app/javascript/**/*.spec.* 2>/dev/null | head -1 | grep -q .; then
    step_fail "Vitest — JS unit tests failed"
    echo -e "       Run ${BOLD}yarn test:run${NC} for details"
  else
    step_skip "Vitest (no test files found)"
  fi
fi

# =============================================================================
# 5. PERFORMANCE ANALYSIS  (mirrors: jobs.performance)
# =============================================================================
section "5/7  Performance Analysis"

if [ -f test/performance/bullet_test.rb ]; then
  if RAILS_ENV=test bundle exec rails test test/performance/bullet_test.rb 2>&1 | tail -3; then
    step_pass "Bullet N+1 detection"
  else
    step_fail "Bullet N+1 detection"
  fi
else
  step_skip "Bullet N+1 detection (no test file)"
fi

# =============================================================================
# 6. DEPLOYMENT READINESS  (mirrors: jobs.deploy-check)
# =============================================================================
section "6/7  Deployment Readiness"

# Pending migrations
if RAILS_ENV=test bundle exec rails db:migrate:status 2>&1 | grep -q "down"; then
  step_fail "Pending migrations — run db:migrate"
else
  step_pass "No pending migrations"
fi

# Credentials
if bundle exec rails credentials:show > /dev/null 2>&1; then
  step_pass "Credentials decryptable"
else
  step_fail "Credentials — cannot decrypt (missing RAILS_MASTER_KEY?)"
fi

# Asset precompilation (production)
if $QUICK; then
  step_skip "Asset precompilation (--quick)"
else
  echo -e "  ${CYAN}Precompiling assets (production)…${NC}"
  if SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails assets:precompile > /dev/null 2>&1; then
    step_pass "Asset precompilation (production)"
    # Clean up precompiled assets
    RAILS_ENV=production bundle exec rails assets:clobber > /dev/null 2>&1 || true
  else
    step_fail "Asset precompilation (production)"
    echo -e "       Run ${BOLD}SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails assets:precompile${NC}"
  fi
fi

# =============================================================================
# 7. LIGHTHOUSE  (mirrors: jobs.lighthouse — local smoke test only)
# =============================================================================
section "7/7  Lighthouse (local smoke test)"

if $QUICK; then
  step_skip "Lighthouse (--quick)"
else
  if command -v lhci > /dev/null 2>&1 || npx --yes @lhci/cli --version > /dev/null 2>&1; then
    # Check if server is already running on port 3000
    if lsof -i :3000 -sTCP:LISTEN > /dev/null 2>&1; then
      step_skip "Lighthouse — server already running on :3000, run lhci manually"
    else
      step_skip "Lighthouse — start server first, then run lhci"
    fi
  else
    step_skip "Lighthouse CLI not installed (npm i -g @lhci/cli)"
  fi
fi

# =============================================================================
# SUMMARY
# =============================================================================
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Summary${NC}  (${MINUTES}m ${SECONDS}s)"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}✔ Passed:  ${PASS_COUNT}${NC}"
echo -e "  ${RED}✘ Failed:  ${FAIL_COUNT}${NC}"
echo -e "  ${YELLOW}⊘ Skipped: ${SKIP_COUNT}${NC}"

if [ ${FAIL_COUNT} -gt 0 ]; then
  echo ""
  echo -e "  ${RED}${BOLD}Failures:${NC}"
  for f in "${FAILURES[@]}"; do
    echo -e "    ${RED}• $f${NC}"
  done
  echo ""
  echo -e "  ${RED}${BOLD}✘ CI would fail — fix the above before pushing.${NC}"
  exit 1
else
  echo ""
  echo -e "  ${GREEN}${BOLD}✔ All checks passed — safe to push!${NC}"
  exit 0
fi
