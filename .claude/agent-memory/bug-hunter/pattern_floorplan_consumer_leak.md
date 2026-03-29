---
name: FloorplanController creates a new ActionCable consumer on every connect — consumer is never disconnected
description: floorplan_controller.js calls createConsumer() in _subscribeToChannel but only unsubscribes the subscription object, not the underlying consumer — WebSocket connection leaks on Turbo navigation
type: project
---

In app/javascript/controllers/floorplan_controller.js line 50:
```js
const consumer = createConsumer();
this._subscription = consumer.subscriptions.create(...);
```

disconnect() calls this._subscription.unsubscribe() but the consumer itself is a local variable — it is never stored and never disconnected. Each navigation cycle that mounts/unmounts this controller creates a new WebSocket consumer that persists.

Fix: store the consumer on the instance (this._consumer = createConsumer()) and call this._consumer.disconnect() in disconnect().

**Why:** createConsumer() creates a new WebSocket connection each time; the shared consumer from @rails/actioncable should be used instead, or the consumer must be explicitly disconnected.
**How to apply:** Prefer the module-level consumer singleton or store and disconnect any created consumer.
