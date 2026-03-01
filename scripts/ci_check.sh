#!/usr/bin/env bash
# =============================================================================
# ci_check.sh — Run all GitHub Actions CI checks locally
#
# Mirrors the jobs in .github/workflows/ci.yml so you can catch failures
# before pushing.
#
# Usage:
#   scripts/ci_check.sh            # run everything
#   scripts/ci_check.sh --quick    # skip slow checks (Lighthouse, assets)
#   scripts/ci_check.sh --fix      # auto-fix RuboCop offenses then continue
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

section() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ── Parse flags ──────────────────────────────────────────────────────────────
QUICK=false
FIX=false
for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=true ;;
    --fix)   FIX=true ;;
  esac
done

# ── Project root ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

START_TIME=$(date +%s)

echo ""
echo -e "${BOLD}🚀 Smart Menu CI Check${NC}"
echo -e "   Running the same checks as GitHub Actions…"
if $QUICK; then
  echo -e "   ${YELLOW}--quick mode: skipping Lighthouse & asset precompile${NC}"
fi
if $FIX; then
  echo -e "   ${YELLOW}--fix mode: will auto-correct RuboCop offenses${NC}"
fi

# =============================================================================
# 1. SECURITY ANALYSIS  (mirrors: jobs.security)
# =============================================================================
section "1/6  Security Analysis"

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
section "2/6  Code Quality"

# RuboCop — always auto-correct
echo -e "  ${YELLOW}↻ Running RuboCop with auto-correct…${NC}"
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

# =============================================================================
# 3. TEST SUITE  (mirrors: jobs.test)
# =============================================================================
section "3/6  Test Suite"

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

# =============================================================================
# 4. PERFORMANCE ANALYSIS  (mirrors: jobs.performance)
# =============================================================================
section "4/6  Performance Analysis"

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
# 5. DEPLOYMENT READINESS  (mirrors: jobs.deploy-check)
# =============================================================================
section "5/6  Deployment Readiness"

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
# 6. LIGHTHOUSE  (mirrors: jobs.lighthouse — local smoke test only)
# =============================================================================
section "6/6  Lighthouse (local smoke test)"

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
