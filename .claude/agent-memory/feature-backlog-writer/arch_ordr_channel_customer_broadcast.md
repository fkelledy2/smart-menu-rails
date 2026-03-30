---
name: Customer-facing realtime broadcasts use OrdrChannel (ordr_${id}_channel)
description: Customer-facing order updates broadcast to the existing OrdrChannel stream, not a new channel; KitchenBroadcastService already uses this stream name
type: feedback
---

The existing `OrdrChannel` streams from `ordr_#{identifier}_channel`. `KitchenBroadcastService#broadcast_status_change` already broadcasts to `ordr_#{order.id}_channel` for customer updates. Any new customer-facing realtime feature should extend this stream rather than creating a new channel.

**Why:** Creating a second customer-subscribed channel for the same order would require the customer client to manage two subscriptions and reconcile ordering between them. The existing stream is the correct single surface.

**How to apply:** When a feature spec involves broadcasting order-level updates to customers, use `ActionCable.server.broadcast("ordr_#{ordr_id}_channel", payload)` and extend `OrdrChannel`. Flag if a new channel is genuinely needed (e.g. a different entity scope like a `Dining Session` channel).

**Security note:** `OrdrChannel` currently accepts any `order_id` without verifying the subscriber holds the correct DiningSession token — this is a latent risk flagged in the #34 spec open questions. Confirm the auth guard approach before any customer-subscription feature ships.
