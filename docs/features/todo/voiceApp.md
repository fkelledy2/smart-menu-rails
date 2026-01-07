# Voice Ordering Applet (Backend-Intelligent)

## Summary
This document proposes a **voice-first ordering “applet”** experience launched from a QR code / menu link, with **all intelligence in the Rails backend**.

Primary distribution targets:
- [ ] **iOS App Clip** (recommended first-class “applet” experience)
- [ ] **Android Instant App** (parity target)
- [ ] **PWA voice mode** (fast fallback channel)

Scope includes the full ordering lifecycle:
- [ ] Start an order
- [ ] Add/remove items
- [ ] Update quantities/modifiers
- [ ] Request a bill
- [ ] Pay the bill

Customers are **anonymous** (no login) and enter via **QR scan**.

---

## Non-goals (initially)
- [ ] Staff management or staff voice workflows
- [ ] Full native app store installs (App Clip/Instant are sufficient)
- [ ] Offline ordering

---

## Product experience

### Entry points
- [ ] QR code on the table / menu card:
  - [ ] `https://mellow.menu/s/:smartmenu_slug?table=7` (existing smart menu entry)
  - [ ] Includes a CTA: **“Order by Voice”**

### Voice “applet” behavior
- [ ] Tap **Order by Voice**:
  - [ ] iOS: launches App Clip
  - [ ] Android: launches Instant App
  - [ ] Fallback: launches PWA voice mode
- [ ] Applet shows:
  - [ ] restaurant + table context
  - [ ] a large mic button (“Hold to talk” or “Tap to talk”)
  - [ ] a running transcript
  - [ ] “What I understood” confirmation cards (items added/removed, totals)
  - [ ] “Request bill” and “Pay now” actions

### Conversational interaction model
We recommend a **command-driven** conversation with confirmations:
- [ ] “Add two margaritas” -> backend proposes changes -> UI confirms “Add?” -> commit
- [ ] “Remove the fries” -> propose removal -> confirm -> commit
- [ ] “What’s in the seafood linguine?” -> read item details
- [ ] “Split the bill” (future)

---

## Architecture overview

### Principle: Backend intelligence
The applet does not decide business logic. It:
- [ ] Captures speech audio and converts to text (native STT)
- [ ] Sends transcript + context token to Rails
- [ ] Rails interprets intent, validates, updates state, returns UI directives

### Components
- [ ] **Client (Applet)**
  - [ ] iOS App Clip / Android Instant / PWA
  - [ ] speech-to-text
  - [ ] minimal UI state

- [ ] **Rails Backend**
  - [ ] session/token issuance
  - [ ] order state machine
  - [ ] intent parsing and fulfillment
  - [ ] payment orchestration (Stripe)
  - [ ] audit, rate limiting, abuse controls

- [ ] **Optional LLM/NLU layer**
  - [ ] can be a Rails service calling an LLM
  - [ ] can be replaced/augmented with rules + embeddings + menu search

---

## Security model

### Token types
We need an anonymous but secure way to bind a user to:
- restaurant
- menu
- table
- current order

Recommended token strategy:

- [ ] **Menu Context Token** (short-lived, issued from QR landing)
   - Encodes: `restaurant_id`, `menu_id`, `table_id` (or table code), `smartmenu_slug`
   - TTL: 10–30 minutes

- [ ] **Voice Session Token** (very short-lived, refreshable)
   - Created when user taps “Order by Voice”
   - TTL: 5–10 minutes rolling
   - Used for voice commands and payment steps

- [ ] **Payment Intent/Checkout Token**
   - Stripe-managed (preferred)
   - Rails returns a client secret or a hosted checkout session URL

### Threat controls
- [ ] **Rate limit** voice commands per session + per IP
- [ ] **Replay protection**: nonce / monotonic sequence numbers on commands
- [ ] **Table hijacking protection**:
  - [ ] table token rotates periodically
  - [ ] optional staff PIN to enable payment
  - [ ] optional “confirm table” spoken/typed phrase displayed on table card

### Privacy
- [ ] Do not store raw audio by default
- [ ] Store:
  - [ ] transcript
  - [ ] inferred intent
  - [ ] applied actions
  - [ ] order changes

---

## Backend API (proposed)
These are suggested endpoints; naming can match existing Rails conventions.

### 1) Create voice session
`POST /api/v1/voice_sessions`

Request:
- [ ] `menu_context_token`
- [ ] client metadata (platform, locale)

Response:
- [ ] `voice_session_id`
- [ ] `voice_session_token`
- [ ] `menu_snapshot` (optional, minimal)

### 2) Send a transcript chunk
`POST /api/v1/voice_sessions/:id/commands`

Request:
- [ ] `token`
- [ ] `transcript`
- [ ] optional: `confidence`, `locale`, `sequence`

Response:
- [ ] `status`: success/error
- [ ] `proposed_actions`: list
- [ ] `requires_confirmation`: boolean
- [ ] `ui_state`: updated cart totals, last understood command

### 3) Confirm / commit proposed actions
Two patterns:

A) Single endpoint with `confirm=true`
- [ ] `POST /api/v1/voice_sessions/:id/commands`

B) Explicit confirmation endpoint
- [ ] `POST /api/v1/voice_sessions/:id/confirm`

### 4) Order lifecycle endpoints
If not already present, define stable APIs for:
- [ ] `POST /api/v1/orders` (start)
- [ ] `PATCH /api/v1/orders/:id` (update)
- [ ] `POST /api/v1/orders/:id/items` (add)
- [ ] `PATCH /api/v1/orders/:id/items/:item_id` (qty/modifiers)
- [ ] `DELETE /api/v1/orders/:id/items/:item_id` (remove)

### 5) Bill + payment
- `POST /api/v1/orders/:id/request_bill`
- `POST /api/v1/orders/:id/payments/intent` (Stripe PaymentIntent)
- `POST /api/v1/orders/:id/payments/confirm` (server-side confirmation hooks)

### Webhooks
- [ ] Stripe webhook endpoint already likely exists; ensure voice sessions/orders observe payment updates.

---

## Intent parsing / fulfillment

### Recommended approach (hybrid)
- [ ] **Step 1: classify intent**
  - [ ] add/remove/qty
  - [ ] ask question
  - [ ] request bill
  - [ ] pay
- [ ] **Step 2: menu item resolution**
  - [ ] fuzzy search (existing matcher services)
  - [ ] embeddings/vector search (pgvector) when available
- [ ] **Step 3: propose actions**
  - [ ] return “I heard…” + a structured change list
- [ ] **Step 4: confirmation**
  - [ ] for destructive actions and payment

### Example intents
- [ ] Add:
  - [ ] “Add 2 cheeseburgers”
- [ ] Remove:
  - [ ] “Remove the fries”
- [ ] Modify:
  - [ ] “No onions” (modifier model permitting)
- [ ] Bill:
  - [ ] “Can I get the bill?”
- [ ] Pay:
  - [ ] “Pay now”

---

## iOS App Clip details

### Launching
From the menu web UI:
- [ ] a link that resolves to an App Clip invocation URL
- [ ] recommended also support **QR** / **App Clip Code**

### App Clip payload
The App Clip needs:
- [ ] `menu_context_token`
- [ ] optionally: `table_code`

### Speech
- [ ] Use Apple Speech framework for local transcription
- [ ] Send transcript to Rails (do not send raw audio initially)

### Payment
- [ ] Use Stripe’s native SDK or redirect to Stripe-hosted checkout in a webview.
- [ ] Prefer Apple Pay for conversion.

---

## Android Instant App

### Similar to App Clip
- [ ] deep link with context token
- [ ] native STT
- [ ] call same Rails APIs

---

## PWA voice mode (fallback)

### Use cases
- [ ] devices that cannot launch applets
- [ ] desktop voice ordering

### Implementation
- [ ] existing browser voice approach
- [ ] same backend voice session endpoints

---

## Rollout plan

### Phase 0: Backend foundation (MVP)
- [ ] Define `VoiceSession` model (or equivalent)
- [ ] Token issuance + rate limiting
- [ ] Minimal intent pipeline: add/remove/qty + confirmations
- [ ] Integrate with existing ordering APIs

### Phase 1: PWA voice ordering
- [ ] Ship quickly to validate:
  - [ ] command patterns
  - [ ] menu matching accuracy
  - [ ] conversion

### Phase 2: iOS App Clip
- [ ] Build App Clip shell UI + STT
- [ ] Integrate payment (Apple Pay + Stripe)

### Phase 3: Android Instant App
- [ ] Mirror the iOS experience

### Phase 4: Enhancements
- [ ] multi-turn clarifications ("Did you mean X or Y?")
- [ ] allergies and dietary constraints
- [ ] upsells (“Would you like fries with that?”)
- [ ] split bills / pay-per-item

---

## Open questions
- [ ] **Table identity**: do we already have stable table tokens/QR codes per table?
- [ ] **Order ownership**: can multiple phones join the same table order (shared cart)?
- [ ] **Payments**: do we allow partial payment / tips via voice?
- [ ] **Staff confirmation**: do we require staff validation before enabling payment?

---

## Suggested next implementation step
Start with a Rails-only spike:
- [ ] `POST /api/v1/voice_sessions`
- [ ] `POST /api/v1/voice_sessions/:id/commands`
- [ ] Log transcripts + proposed actions
- [ ] Use existing menu item matcher for resolution

Once that’s stable, the App Clip becomes primarily UI + speech capture.
