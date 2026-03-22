# MCP AI Agent Wrapper

## Status
- Priority Rank: #15
- Category: Post-Launch
- Effort: XL
- Dependencies: JWT Token Management (#8), Partner Integrations (#9), existing REST API surface, user consent infrastructure

## Problem Statement
As AI agents become mainstream tools for business automation, restaurant owners will expect mellow.menu to be accessible via AI assistants (Claude, ChatGPT, custom agents) for tasks like menu management, order monitoring, and analytics reporting. The Model Context Protocol (MCP) is an emerging standard for AI agent-to-service communication. Building an MCP server positions mellow.menu as AI-native and opens an ecosystem play where third-party agents can extend the platform's value.

## Success Criteria
- mellow.menu implements a compliant MCP server exposing restaurant resources (menus, orders, analytics) and tools (create menu item, update order status).
- AI agents authenticate via registered API keys and user consent grants.
- All agent actions are logged in full.
- User consent management allows restaurant owners to grant/revoke specific permissions to specific agents.
- The marketplace concept (agent discovery, verified agents) is explicitly post-launch scope.

## User Stories
- As a restaurant owner, I want AI tools to access my menu and order data so I can automate management tasks.
- As a restaurant owner, I want to explicitly consent to what each AI agent can do so I remain in control.
- As an AI developer, I want to build agents that integrate with mellow.menu using a standard protocol.

## Functional Requirements
1. MCP server exposed at a dedicated endpoint, implementing MCP protocol (initialize, resources/list, resources/read, tools/list, tools/call, logging).
2. Resources exposed: `mellow://restaurant/{id}/menu`, `mellow://restaurant/{id}/orders`, `mellow://restaurant/{id}/analytics`.
3. Tools exposed (v1): `create_menu_item`, `update_menu_item`, `get_recommendations`, `update_order_status`.
4. Agent registration: `ai_agents` table with `name`, `developer_id`, `agent_type`, `capabilities` (jsonb), `api_key_hash`, `verification_status`.
5. User consent: `user_agent_consents` table with `user_id`, `agent_id`, `consent_type`, `granted_at`, `expires_at`, `revoked_at`. All agent actions require valid, non-expired consent.
6. Session management: `agent_sessions` table with TTL and last-activity tracking.
7. Activity logging: `agent_activity_logs` table records every agent action with tool name, parameters, response status, execution time.
8. Multi-layer auth: (1) agent API key validation, (2) user session validation, (3) action scope check, (4) rate limiting per agent.
9. Restaurant owner UI: view connected agents, configure permissions, view activity log, revoke consent.

## Non-Functional Requirements
- Full MCP protocol version compliance (target: 2024-11-05 or later).
- WebSocket and HTTP transport support.
- All agent actions are logged — no silent mutations.
- Agent API keys stored as hashes only.
- Statement timeouts apply to all resource reads.

## Technical Notes

### New Components
- `app/services/mcp/server.rb`: MCP server implementation (or dedicated Rack app).
- `app/services/mcp/auth_manager.rb`: multi-layer authentication.
- `app/services/mcp/resource_manager.rb`: resource listing and reading.
- `app/services/mcp/tool_manager.rb`: tool execution with scope validation.

### Models / Migrations
- `create_ai_agents`, `create_user_agent_consents`, `create_agent_sessions`, `create_agent_activity_logs`.

### Policies
- `app/policies/ai_agent_policy.rb`: owners can manage their own consent grants.
- `app/policies/agent_activity_log_policy.rb`: owners can view their own restaurant's logs.

### Jobs
- `app/jobs/expire_agent_sessions_job.rb`: Sidekiq cron, expires stale sessions.

### Flipper
- `mcp_server` — disabled by default; enable per restaurant for early access programme.
- `mcp_marketplace` — separate flag for agent marketplace feature (post-launch).

## Acceptance Criteria
1. An MCP client sending an `initialize` request receives a valid `capabilities` response.
2. An authenticated agent can call `tools/call` with `create_menu_item` and the menu item appears in the restaurant's menu.
3. An agent without consent for `menu_management` receives a 403 error when attempting menu mutations.
4. All agent actions create records in `agent_activity_logs`.
5. A restaurant owner can revoke an agent's consent and subsequent calls from that agent are rejected.
6. Rate limit exceeded returns 429 to the agent.

## Out of Scope
- Agent marketplace and discovery (post-launch).
- Multi-modal support (voice, image processing) — post-launch.
- Agent-to-agent communication.
- Any agent capability not explicitly listed in the tools definition.

## Open Questions
1. Is there an existing MCP Ruby gem, or does this require a custom implementation? Research the Ruby MCP ecosystem before estimating effort.
2. Should the MCP server be a separate Rack app (better isolation) or integrated into the main Rails app (simpler deployment)?
3. What is the legal and GDPR position on AI agents acting on behalf of restaurant owners? Requires legal review before launch.
4. Is there a specific AI platform (e.g. Claude, ChatGPT plugins) that should be the primary integration target for v1?
