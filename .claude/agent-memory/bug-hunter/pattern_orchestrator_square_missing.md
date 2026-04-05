---
name: Payments::Orchestrator Missing Square Provider
description: Orchestrator#provider_adapter only handled :stripe, raised ArgumentError for :square — now includes SquareAdapter (FIXED)
type: project
---

`Payments::Orchestrator#provider_adapter` only had a case for `:stripe`, raising `ArgumentError` for any other provider including `:square`. `Payments::Providers::SquareAdapter` already existed. Fixed by adding the `:square` case to the provider_adapter method. The immediate blast radius was limited (Auto Pay hardcodes `:stripe`, ordr_payments routes Square separately) but any new code using `Orchestrator.new(provider: :square)` would have crashed.

**Why:** The Orchestrator was built with Stripe first; Square was added to adapters but not wired into the provider_adapter switch.

**How to apply:** When adding new payment adapters, always update Orchestrator#provider_adapter in the same commit.
