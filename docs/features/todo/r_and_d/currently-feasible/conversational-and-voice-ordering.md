# Conversational & Voice Ordering

**Status:** Draft Specification  
**Feasibility:** Currently Feasible  
**Target Window:** 2026+  
**Category:** Ordering UX, Accessibility, AI Interaction

## Feature Overview

Conversational and voice ordering enables guests to browse, search, refine, and submit orders using natural language rather than relying only on tap-based navigation.

The first implementation should prioritize assisted discovery and confirmation-based ordering, not fully autonomous spoken transactions.

## Problem Statement

Tap-based ordering can be slow or awkward in noisy, hands-busy, or accessibility-sensitive situations. Guests may know what they want conceptually but not how to navigate to it efficiently in the interface.

## Goals

- [ ] Improve accessibility for guests who prefer speech or natural language interaction
- [ ] Reduce friction for discovery, filtering, and simple ordering tasks
- [ ] Provide reliable confirmation flows before anything reaches the kitchen
- [ ] Establish a reusable conversational interface layer for future Smart Menu assistance

## Non-Goals

- [ ] Fully autonomous voice checkout in the first release
- [ ] Silent order submission without explicit confirmation
- [ ] Free-form handling of all modifiers without confidence thresholds
- [ ] Staff-free resolution of ambiguous or risky requests

## User Stories

- As a guest, I want to ask for items in plain language so I can find and order faster.
- As a guest, I want the system to repeat back what it understood before placing anything.
- As an operator, I want conversational ordering to improve usability without increasing kitchen mistakes.

## In Scope

- [ ] Voice search within the menu
- [ ] Natural language interpretation of item requests
- [ ] Spoken or typed modifications and preferences
- [ ] Confirmation-based add-to-order flow
- [ ] Graceful fallback to manual interaction when confidence is low

## Out of Scope

- [ ] Fully hands-free checkout and payment in the first release
- [ ] Long-form conversational support for every restaurant workflow
- [ ] Unbounded modifier parsing with no restaurant-specific rules

## Functional Requirements

### Input and Understanding

- [ ] The system must support speech-to-text and typed conversational input
- [ ] The system must map user utterances to menu search, item selection, or modification intents
- [ ] The system must detect ambiguity and request clarification before mutating the order
- [ ] The system must preserve restaurant-specific item naming and modifier semantics where possible

### Confirmation and Safety

- [ ] No item may be added to the order without an explicit confirmation step in the first release
- [ ] The UI must show the interpreted item, quantity, and modifiers before submission
- [ ] Low-confidence requests must fall back to search results or clarification prompts

### Experience and Accessibility

- [ ] Voice interaction should be optional and user-initiated
- [ ] The feature should support accessibility-friendly prompts and readable confirmations
- [ ] The experience must work acceptably in noisy environments by allowing typed continuation

## Technical Considerations

- [ ] Reuse existing voice transcription and intent infrastructure where available
- [ ] Support both LLM-based and rules-based interpretation paths
- [ ] Persist interpreted intents and confirmations in a debuggable format
- [ ] Ensure the feature can operate within existing Smart Menu ordering flows rather than creating a separate order pipeline

## Dependencies

- [ ] Speech-to-text pipeline
- [ ] Intent extraction or structured parsing layer
- [ ] Menu search and modifier resolution support
- [ ] Confirmation UI in the Smart Menu flow
- [ ] Logging and analytics for interpretation quality

## Risks

- [ ] Accent, noise, and menu ambiguity may reduce interpretation quality
- [ ] Shared-device or public-space voice use raises privacy concerns
- [ ] Incorrect modifier interpretation could create operational errors
- [ ] Over-reliance on LLMs may introduce cost or latency issues

## Delivery Plan

### Phase 1: Assisted Discovery

- [ ] Add conversational search input for menu discovery
- [ ] Return structured search results for common requests
- [ ] Instrument confidence and fallback behavior
- [ ] Validate usability across noisy and quiet environments

### Phase 2: Confirmed Ordering

- [ ] Map high-confidence intents to draft order actions
- [ ] Add explicit confirmation for item, quantity, and modifiers
- [ ] Support common modifier patterns such as allergies, no-onion, extra sauce, and drink preferences
- [ ] Add clear fallback paths to manual editing

### Phase 3: Expansion and Optimization

- [ ] Improve restaurant-specific vocabulary handling
- [ ] Add multi-turn clarification for ambiguous requests
- [ ] Tune prompt and parser strategies for latency and accuracy
- [ ] Explore deeper conversational assistance beyond ordering

## Acceptance Criteria

- [ ] Guests can use natural language to discover or draft common orders
- [ ] All order mutations require explicit confirmation in the initial release
- [ ] Low-confidence interpretations fail safely
- [ ] The feature improves access without materially increasing order error rates
- [ ] The implementation integrates with the existing Smart Menu order flow

## Success Metrics

- [ ] Voice or conversational session adoption rate
- [ ] Time-to-discovery for requested items
- [ ] Confirmation-to-order completion rate
- [ ] Interpretation error and fallback rate
- [ ] Accessibility and usability feedback scores

## Open Questions

- [ ] Should the first release support both voice and typed conversational input, or typed-first with optional voice?
- [ ] Which modifier families are safe enough for launch support?
- [ ] How should the system behave when a guest refers to an unavailable item or deprecated menu name?
- [ ] What confidence threshold should trigger clarification versus search results?
