# Menu Experiments (A/B + Time-boxed) (v1)

## Purpose
Enable safe experimentation on menus:

- A/B testing between menu versions
- Time-boxed experiments
- Explicit audit trail

This builds directly on **Menu as Versioned Artifact**.

## Current State (today)

- There is no `MenuVersion` system yet.
- Menu time restrictions exist, but that is not a version experiment system.

Cross references:

- `docs/features/todo/2026/02-menu-as-versioned-artifact-v1.md`
- `docs/features/done/MENU_TIME_RESTRICTIONS.md`

## Scope (v1)

- Experiments are defined as:
  - one control version
  - one variant version
  - allocation (e.g., 50/50)
  - eligibility rules (time window, optionally table-based)
  - start/end timestamps
- The system selects a menu version at request time based on experiment assignment.
- The system records exposure events for analysis.

## Non-goals (v1)

- AI suggestions.
- Auto-optimization.
- Multi-variant experiments.

## Acceptance Criteria (GIVEN / WHEN / THEN)

### Experiment creation

- GIVEN a menu has at least two immutable versions
  WHEN an owner creates an experiment with control=V1 and variant=V2
  THEN the system persists an experiment record with allocation rules and a time window.

### Version assignment

- GIVEN an experiment is active and a customer opens the smart menu
  WHEN version assignment is computed
  THEN the customer is deterministically assigned to either control or variant based on a stable key (e.g., session id).

- GIVEN a customer refreshes the page
  WHEN version assignment is recomputed
  THEN the same customer receives the same version during the experiment window.

### Exposure logging

- GIVEN a customer receives the variant version
  WHEN the menu is rendered
  THEN an exposure event is recorded with: menu_id, version_id, experiment_id, session_id, timestamp.

### Safety

- GIVEN the experiment window ends
  WHEN a customer opens the smart menu
  THEN the system serves the default active version and no longer assigns variants.

## Progress Checklist

- [ ] Implement MenuVersion system (dependency)
- [ ] Add `menu_experiments` table/model
- [ ] Define deterministic assignment strategy (session-based)
- [ ] Add exposure logging (table or event stream)
- [ ] Update smart menu rendering to select version
- [ ] Add reporting for experiment results (basic)
- [ ] Add tests:
  - [ ] deterministic assignment
  - [ ] window enforcement
  - [ ] exposure logging
