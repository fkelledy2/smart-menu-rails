---
name: coverage_baseline
description: Coverage baseline (March 2026), gap analysis, and milestone targets for the Smart Menu remediation effort
type: project
---

## Current state (as of 2026-03-22)

- SimpleCov HTML (single run): ~11–12% (one test runner only)
- RSpec suite alone: ~41.9% of app lines covered
- Minitest Unit Tests alone: ~2.6%
- Merged (all result sets, CI): ~29–40% depending on how total is computed
- CI COVERAGE_MIN: 60% (set in `.github/workflows/ci.yml`)
- Three SimpleCov result sets merged: "Unit Tests", "RSpec", "Integration Tests"

**Why:** SimpleCov `use_merging true` with 1-hour timeout. CI runs Minitest then RSpec. The HTML report from a single `bundle exec rails test` run will only show Minitest coverage, not the merged number. To see the real merged figure, run both suites in sequence.

**How to apply:** Always interpret coverage numbers relative to the merged result. Single-run numbers are misleadingly low for Minitest but misleadingly high for overall state.

## Gap calculation (approximate)

- Merged app-only coverage: ~29–40%
- Target: 60%
- Gap: ~20–30 percentage points
- Estimated lines needed: 8,000–13,000 additional covered lines
- Total app lines (approximate): ~35,000–40,000

## Milestone targets

| Milestone | Target | Key deliverables |
|-----------|--------|-----------------|
| Phase 1   | 48%    | All 48 Pundit policies + payment paths + core models |
| Phase 2   | 54%    | Top 30 service objects + critical jobs + channels |
| Phase 3   | 60%+   | Controllers + ViewComponents + remaining models |

## Coverage ratchet

Once a milestone % is reached, raise SimpleCov minimum in `.simplecov` and `.github/workflows/ci.yml`:
```
minimum_coverage ENV['COVERAGE_MIN'].to_i
```
Current COVERAGE_MIN=60 in CI.
