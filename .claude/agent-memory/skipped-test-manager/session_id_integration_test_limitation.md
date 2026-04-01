---
name: CookieStore session.id instability in ActionDispatch::IntegrationTest
description: session.id changes on every request in test env — cannot pre-seed Ordrparticipant.sessionid
type: feedback
---

## Problem
`OrdrPaymentsController#safe_session_id` returns `session.id.to_s`. In `ActionDispatch::IntegrationTest` with Rails' CookieStore, `session.id` is computed as a digest of the session data and changes on every request — even when no session data is mutated. This makes it impossible to pre-create an `Ordrparticipant` with a matching `sessionid` before the actual request under test.

Confirmed with: `test/controllers/ordr_payments_controller_test.rb:163` — the session ID changed between every request regardless of session mutations.

## Why
Rails CookieStore stores all session data in the cookie itself (no server-side store). The "session ID" is derived from the cookie value, which changes whenever the cookie is re-serialized (including fresh serializations of identical data).

## Implication
Any test that needs to verify session-based participant authentication (`Ordrparticipant.sessionid` matching `session.id`) cannot be written as a standard `ActionDispatch::IntegrationTest` against the CookieStore. Options:
1. Switch to a server-side session store (`Redis`, `database`)
2. Test at the unit level by stubbing `safe_session_id`
3. Test via a system test (Capybara maintains real browser sessions)

## How to apply
When asked to write tests for `authorize_split_access!` or any code that reads `session.id` and matches it to a DB record, flag this limitation immediately. The skip in `test/controllers/ordr_payments_controller_test.rb` is legitimate and should remain until the session store changes.
