# Heroku Voice Menu Rollout (Production)

## Goals

- Deploy safely without breaking production.
- Allow staged enablement of voice features.
- Avoid Sidekiq retry storms when external services are missing/misconfigured.

## Required Heroku Add-ons

- Postgres: `heroku-postgresql` (plan must support extensions)
- Redis: `heroku-redis` (required for Sidekiq)

## Required Processes

From `Procfile`:

- `web`: Rails server
- `worker`: Sidekiq
- `release`: migrations

Voice features rely on Sidekiq jobs. If you enable voice in production, ensure the `worker` dyno is running.

## Configuration (Config Vars)

### Feature flags (recommended defaults)

- `SMART_MENU_VOICE_ENABLED`
  - **Default**: `false` in production until ready
  - When `false`, voice endpoints return 404.

- `SMART_MENU_VOICE_WHISPER_ENABLED`
  - **Default**: enabled when unset
  - Set to `false` to disable audio transcription (audio uploads will fail fast).

- `SMART_MENU_DEEPL_ENABLED`
  - **Default**: enabled when unset
  - Set to `false` to disable translation fallback.

- `SMART_MENU_VECTOR_SEARCH_ENABLED`
  - **Default**: enabled when unset
  - Set to `false` to disable semantic enrichment of add/remove item intents.

- `SMART_MENU_ML_RERANK_ENABLED`
  - **Default**: enabled when unset
  - Set to `false` to use embeddings + vector nearest-neighbor, but skip rerank.

### External service configuration

- OpenAI Whisper (only needed if using audio transcription)
  - `OPENAI_API_KEY`
  - `OPENAI_WHISPER_MODEL` (optional, defaults to `whisper-1`)

- DeepL (only needed if using translation fallback)
  - `DEEPL_API_KEY`

- SmartMenu ML service (only needed for embeddings/vector search and/or rerank)
  - `SMART_MENU_ML_URL` (example: `https://<your-ml-service>.herokuapp.com`)
  - `SMART_MENU_ML_TIMEOUT_SECONDS` (optional; defaults to `0.25`)

## Database requirements (pgvector)

- Ensure the Postgres extension `vector` is enabled.
- Ensure the `menu_item_search_documents` table is present and indexed.

Notes:

- The app includes a migration that runs `enable_extension 'vector'`.
- If your Postgres plan does not allow installing extensions, vector search must remain disabled.

## Suggested staged rollout

### Stage 0: Ship code with voice OFF

Set:

- `SMART_MENU_VOICE_ENABLED=false`

Optional safety defaults:

- `SMART_MENU_VECTOR_SEARCH_ENABLED=false`
- `SMART_MENU_DEEPL_ENABLED=false`

Deploy.

### Stage 1: Enable voice for transcript-only testing

If you will send `transcript` directly (no audio):

- `SMART_MENU_VOICE_ENABLED=true`
- Keep `SMART_MENU_VOICE_WHISPER_ENABLED=false` if you want to ensure no audio transcription is attempted

### Stage 2: Enable Whisper audio transcription

- `SMART_MENU_VOICE_WHISPER_ENABLED=true`
- `OPENAI_API_KEY=...`

### Stage 3: Enable translation fallback

- `SMART_MENU_DEEPL_ENABLED=true`
- `DEEPL_API_KEY=...`

### Stage 4: Enable embeddings + vector match (without rerank)

- Confirm pgvector migration applied successfully.
- `SMART_MENU_VECTOR_SEARCH_ENABLED=true`
- `SMART_MENU_ML_URL=...`
- `SMART_MENU_ML_RERANK_ENABLED=false`

### Stage 5: Enable rerank

- `SMART_MENU_ML_RERANK_ENABLED=true`

## Operational checks

- Verify Sidekiq is running and queues are processing.
- Validate `VoiceCommand` records transition from `queued` -> `processing` -> `completed`.
- If a service is misconfigured, jobs should mark the `VoiceCommand` as `failed` with a clear error.
