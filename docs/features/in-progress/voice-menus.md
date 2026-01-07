# Voice Menus (Smartmenu Customer Voice Commands)

## Goals
Enable customers on Smartmenu customer pages (e.g. `/smartmenus/:slug`) to interact via **push-to-talk** voice commands:

- [x] Add an item to an order (by name/description).
- [x] Remove an item from an order (by name/description).
- [x] Submit/confirm the order.
- [x] Request the bill.

Constraints:

- [x] **Browser agnostic** as much as feasible. (Hybrid: Web Speech API when available, audio upload fallback)
- [x] Works in existing Smartmenu context (Rails + browser UI).
- [x] Avoid “always listening”; use press-and-hold push-to-talk.
- [x] Prefer device/OS voice isolation features where possible. (uses `echoCancellation`, `noiseSuppression`, `autoGainControl` constraints)
- [x] Visual responses are acceptable initially.
- [x] Consider bandwidth constraints (3G/4G/5G/WiFi). (audio mime-type negotiation + short-utterance model; implemented client-side)
- [x] Consider capturing interactions for future model training. (VoiceCommand persistence exists)

---

## High-level approach
Voice control has three separable components:

1. [x] **Capture UI + audio capture** (push-to-talk, mic permissions, UX cues).
2. [x] **Speech-to-text (STT)** (in-browser, OS-provided, or server-side).
3. [x] **Intent parsing + action execution** (map transcript -> Smartmenu actions -> existing endpoints).

We should implement this with a feature flag and a progressive enhancement strategy:

- [x] If advanced STT isn’t available, fall back to manual UI. (voice UI is gated; standard UI remains)
- [x] If the device/browser supports high-quality on-device STT, use it. (Web Speech API)
- [x] Otherwise fall back to server-side STT. (audio upload + Whisper)

---

## Option A: Client-side STT (Web Speech API) + client-side intent parsing
### Summary
Use `SpeechRecognition` (Web Speech API) to get transcripts directly in the browser.

### Pros
- Lowest latency.
- No audio bandwidth cost (only text).
- No server cost for transcription.
- Audio never leaves the device (privacy-friendly).

### Cons
- Not truly browser-agnostic (support varies; often best on Chromium).
- Some mobile browsers have inconsistent behavior.

### When to use
- As the **fastest path to a POC**.
- As an optimization path even if we implement server-side STT.

---

## Option B: Server-side STT (upload audio) + server-side intent parsing (recommended for “browser agnostic”)
### Summary
Capture audio via Web Audio / MediaRecorder, upload it to Rails, run STT server-side, then parse intent.

### Pros
- Much more browser-agnostic (MediaRecorder availability is still uneven, but better than Web Speech API for consistent behavior).
- Deterministic server-side behavior.
- Enables storing voice interactions for analytics/training.

### Cons
- Higher latency.
- Uses bandwidth (audio upload).
- Requires STT vendor or self-hosting.
- Must address privacy/compliance.

### STT vendor choices
- **Deepgram**: strong streaming + pricing; good docs.
- **OpenAI Whisper** (hosted or self-hosted): good accuracy; self-hosting requires GPU to be performant.
- **Google Speech-to-Text**: excellent quality; more complex setup/cost.
- **AWS Transcribe**: solid; integrates with AWS.
- **Azure Speech**: solid.

---

## Option C: Hybrid (best long-term)
### Summary
Try client-side STT first; if unavailable, fall back to server-side STT.

### Pros
- Best UX where supported.
- Still works across browsers via fallback.

### Cons
- More complexity.

### Decision
We will implement **Option C** up-front.

- [x] **Primary path**: Client-side STT where supported (text-only to server).
- [x] **Fallback path**: Push-to-talk audio capture -> upload to Rails -> server-side STT -> intent parsing.

This meets the “browser agnostic” requirement by always having a server-side path.

---

## Heroku deployment considerations (production)
The solution must run on existing Heroku infrastructure. This favors:

- [x] External STT vendors (no GPU required). (OpenAI Whisper API)
- [x] Short-lived request/response workflows (avoid long-running dyno requests). (controller responds `202 Accepted`, work is async)
- [x] Background jobs (Sidekiq) for any heavier processing. (`VoiceCommandTranscriptionJob`)

### Recommended Heroku add-ons
- **Heroku Postgres**
  - Store transcripts, intent resolution outcomes, and linkage to `restaurant/menu/smartmenu/ordr`.
- **Heroku Redis**
  - Rate limiting counters, ephemeral session state, and Sidekiq.
- **Cloud storage for audio (if stored)**
  - ActiveStorage to S3-compatible storage (AWS S3 is typical on Heroku).

### STT vendor integration choices (Heroku-friendly)
All of these work well from Heroku dynos via HTTPS APIs:

- **Deepgram**
  - Very good for real-time/near-real-time, has streaming and pre-recorded endpoints.
- **Google Speech-to-Text / AWS Transcribe / Azure Speech**
  - Enterprise-grade; cost/ops depends on existing cloud alignment.
- **Whisper (hosted)**
  - Good accuracy, simplest “send audio -> receive transcript” model.

Self-hosting STT on Heroku (GPU) is generally not practical.

### Rate limiting / abuse
Voice endpoints are sensitive to abuse (cost + DoS). Add:

- Per-session + per-IP throttling (e.g. `rack-attack`).
- Hard caps on request size and duration.
- Server-side validation of `smartmenu_slug` and customer context.

---

## Proposed Hybrid architecture (Option C)
### Client flow
1. User presses and holds push-to-talk.
2. Browser attempts client-side STT:
   - If supported: transcript is produced on-device.
   - If not supported: record audio using `MediaRecorder`.
3. Client sends either:
   - **Transcript** (preferred)
   - **Audio blob** (fallback)
4. Rails returns:
   - normalized transcript
   - parsed intent
   - action result (success/error + message)
5. UI shows a visual response (toast/overlay).

### Server flow
1. Receive transcript or audio.
2. If audio: call STT vendor -> transcript.
3. Parse transcript -> intent.
4. Resolve menu item(s) (name/description matching).
5. Execute existing order operations (reuse existing controllers/JS endpoints).
6. Return response.

---

## Rails endpoints (proposed)
### `POST /smartmenus/:slug/voice_commands`
Accepts either JSON transcript or multipart audio.

- Input (JSON example):
  - `transcript`: string
  - `locale`: optional (e.g. `it`)
  - `mode`: `customer`

- Input (multipart example):
  - `audio`: blob
  - `content_type`: inferred
  - `locale`: optional

- Output:
  - `transcript`: string
  - `intent`: `{ type: 'add_item'|'remove_item'|'submit_order'|'request_bill', ... }`
  - `result`: `{ ok: boolean, message: string, matched_items: [...] }`

- [x] `POST /smartmenus/:slug/voice_commands` exists and returns `{ id, status }` (`202 Accepted`).
- [x] `GET /smartmenus/:slug/voice_commands/:id` exists for polling results.
- [x] Accepts JSON transcript.
- [x] Accepts multipart audio upload.
- [x] Async processing via Sidekiq (returns quickly to avoid Heroku timeouts).
- [ ] Optional: enqueue + return job id for polling (instead of VoiceCommand id). (current polling is by VoiceCommand id)

Implementation notes:

- Keep request handling under Heroku router timeouts (short utterances).
- For slower vendor calls, optionally enqueue Sidekiq and return a job id for polling.

---

## Data capture for training / back propagation
### What we can capture
- [x] transcript
- [x] resolved intent
- [x] whether it succeeded (stored in `result` + status)
- [x] matched menuitem ids (intent enrichment can attach `menuitem_id`; client also resolves)
- [ ] latency metrics
- [ ] device/browser metadata (coarse)

### Audio storage
Storing raw audio is possible but should be **opt-in**.

- [ ] Default: store transcript only. (audio can be attached when provided)
- [ ] Opt-in: store audio via ActiveStorage + strict retention window.

### Consent
- [ ] Provide an explicit customer-facing consent toggle.
- [ ] If disabled, do not store audio and consider hashing/anonymizing transcripts.

---

## Push-to-talk UX design
### Interaction model
- [x] A floating microphone button on customer pages.
- [x] **Press and hold** to record.
- [x] Release to stop recording and submit.

### Visual cues
- Button state:
  - Idle
  - Recording (animated)
  - Processing
  - Success / Error
- Transcript preview:
  - “Heard: …”
- Action confirmation:
  - “Added 1× Margherita Pizza”
  - “Removed 1× Coke”
  - “Order submitted”
  - “Bill requested”

- [x] Visual feedback for success/error is implemented (toast-style overlay messages).
- [ ] Explicit “Processing” state is shown.

### Accessibility
- [ ] Ensure button has `aria-label` and supports keyboard activation.

---

## Audio quality / “voice isolation” considerations
Browsers can request audio processing constraints from the OS:

- [x] `echoCancellation: true`
- [x] `noiseSuppression: true`
- [x] `autoGainControl: true`

These leverage platform audio processing where available.

For more advanced isolation:

- Use WebRTC audio processing constraints (above) + encourage AirPods/BT headsets.
- Optionally integrate a client-side noise suppression model (heavier; likely not needed initially).

---

## Bandwidth considerations (3G/4G/5G/WiFi)
### If using client-side STT
- [x] Only text transmitted (tiny).

### If using server-side STT
- [x] Audio upload size depends on codec and duration.

Recommendations:

- [x] Use **Opus** in WebM where supported (high quality/low bitrate). (prefers `audio/webm;codecs=opus`)
- [ ] Cap recording duration (e.g. 6–10 seconds per utterance).
- [ ] Prefer mono, 16kHz–48kHz.

Rule of thumb:

- Opus @ ~16–24 kbps for 8 seconds ≈ 16–24 KB (plus container overhead)
- Very feasible on mobile.

Fallback:

- If Opus not available, fallback to AAC (m4a) or WAV (WAV is large; avoid if possible).

---

## Intent model (commands we support)
We should start with a small, well-defined grammar.

### Add item
Examples:

- “Add the margherita pizza.”
- “Add one cappuccino.”
- “Add two sparkling waters.”

### Remove item
Examples:

- “Remove the coke.”
- “Remove one cappuccino.”

### Submit order
Examples:

- “Submit my order.”
- “Place the order.”

### Request bill
Examples:

- “Can I get the bill?”
- “Request the check.”

### Disambiguation
If multiple items match:

- “I found 3 matches: … Tap to choose.”

- [x] Intent parsing supports: add/remove/submit/request bill.
- [x] Intent parsing also supports: start order / close order.
- [ ] Disambiguation UI when multiple items match.

---

## Item matching strategy (name + description)
Given transcript text, we need to map to a `menuitem_id`.

### Data available client-side
Smartmenu already has a JSON state endpoint (`/smartmenus/:slug.json`) and DOM contains item cards.

We can build a client-side index:

- `menuitem_id -> { name, description, tags }`

### Matching algorithm (v1)
- Normalize strings:
  - lowercase
  - remove punctuation
  - collapse whitespace
- Candidate generation:
  - exact substring match on name
  - fuzzy match (Levenshtein / token set ratio)
  - consider description keywords
- Rank:
  - name match score weighted higher than description
  - prefer items currently visible/active

### Matching algorithm (v2)
Use an embeddings-based match server-side (e.g. pgvector) for high-quality matching.

- [x] Client-side matching (v1) is implemented (DOM dataset matching + fuzzy scoring).
- [x] Server-side match enrichment is implemented when vector search is enabled (`MenuItemMatcherService`).
- [ ] Pure server-side embeddings-based match (pgvector) as the primary matcher.

---

## Action execution (integrate with existing Rails endpoints)
We should not create “voice-only” order mutation logic; instead reuse existing flows.

Likely existing calls:

- Add item: POST `/restaurants/:restaurant_id/ordritems` (or similar) with `ordr_id`, `menuitem_id`.
- Remove item: PATCH `/restaurants/:restaurant_id/ordritems/:id` status = removed.
- Submit order: PATCH `/restaurants/:restaurant_id/ordrs/:id` status = ordered.
- Request bill: PATCH `/restaurants/:restaurant_id/ordrs/:id` status = billrequested.

Voice layer should only:

- [x] Resolve the intended action.
- [x] Call the same JS helpers already used by buttons (through `ordr_commons`).
- [ ] Execute actions server-side (so voice_commands response includes action result without requiring client to apply it).

---

## Proposed implementation plan (incremental)
### Phase 0: UX + feature flag
- [x] Add `Voice` button UI to Smartmenu customer view.
- [x] Gate behind feature flag (env var + per-menu enable).

### Phase 1: Client-side STT POC (Option A)
- [x] Push-to-talk button starts/stops speech recognition.
- [ ] Display transcript.
- [x] Implement minimal intent parsing (add/remove/submit/bill).
- [x] Hook into existing JS order actions.

### Phase 2: Hybrid fallback (Option C)
- [x] If Web Speech API unavailable, capture audio and POST to Rails.
- [ ] Rails returns `{ transcript, intent, action_result }`. (currently returns `{ id, status }`; details via polling)

### Phase 3: Server-side STT (Option B)
- [x] Implement `/smartmenus/:slug/voice_commands` endpoint.
  - [x] Accept audio blob
  - [x] Run STT (Whisper)
  - [x] Parse intent
  - [ ] Return action + result in the immediate response (async polling used instead)
- [ ] Add rate limiting and abuse prevention.

### Phase 4: Analytics + training data capture
- [x] Store transcript.
- [x] Store resolved intent.
- [x] Store status/success + error.
- [x] Store anonymized-ish context (`menu_id`, `restaurant_id`, `order_id` in `context`).
- [ ] Optionally store audio (with explicit consent).

---

## Data capture, privacy, compliance
Capturing voice for training is possible, but needs explicit design.

### Recommended default
- [ ] Store **transcripts + intent outcomes only**.
- [ ] Do not store raw audio by default.

### Optional (opt-in)
- [ ] Provide “Help improve voice ordering” toggle.
- [ ] If enabled: store audio + transcript.
- [x] Store language/locale.
- [ ] Store device/browser info.

### Security
- [ ] Encrypt audio at rest.
- [ ] Strict retention policy (e.g. 30–90 days) unless explicitly extended.
- [ ] Redact PII if detected.

---

## Rails gems / libraries to consider
### Audio/STT
- No single “Rails gem” will fully solve STT; typically use vendor SDKs/HTTP.
- For HTTP calls:
  - `faraday`
  - `httparty`

### Rate limiting / abuse prevention
- `rack-attack`

- [ ] Implement per-session + per-IP throttling (e.g. `rack-attack`).
- [ ] Hard caps on request size and duration.

### Storage
- ActiveStorage for audio blobs.

### Background jobs
- Sidekiq for async transcription if needed.

---

## Open questions
- Do we require voice ordering to work without starting an order first?
  - If not started, voice “add item” could trigger “start order” flow automatically.
- Which STT vendor is preferred (cost, latency, privacy)?
- Do we need multilingual recognition tied to restaurant locales?

---

## Acceptance criteria
- On a Smartmenu customer page, user can hold a button and say:
  - “Add the margherita pizza” -> item added.
  - “Remove the coke” -> item removed.
  - “Submit my order” -> order submitted.
  - “Request the bill” -> bill requested.
- UI shows what was heard and what action was taken.
- Works with poor connectivity (short utterances, retry UX).
- Logging/analytics respects privacy and consent.

- [x] Add/remove/submit/request bill are supported end-to-end.
- [x] UI shows what action was taken (via messages).
- [ ] UI shows what was heard (explicit transcript preview).
- [ ] Poor connectivity UX (retry/backoff UI) beyond polling loop.
- [ ] Privacy/consent controls for logging/analytics.
