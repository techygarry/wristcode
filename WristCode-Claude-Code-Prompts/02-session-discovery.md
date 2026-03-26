# WristCode — Session 2: Session Discovery + Management

## Context
Building on Session 1's bridge server. Now add Claude Agent SDK integration for discovering, listing, creating, resuming, and ending Claude Code sessions.

## Prerequisites
- Session 1 complete (bridge server with auth running)
- Claude Code installed and authenticated on this Mac
- Install: npm install @anthropic-ai/claude-agent-sdk

## Task
Add these files to wristcode-bridge/src/:

### services/sessionDiscovery.ts
- Use `listSessions()` from the Agent SDK to scan ~/.claude/projects/
- Return session metadata: id, cwd (project directory), model, status, lastActive timestamp
- Poll every 30 seconds to keep list fresh (configurable interval)
- Map status from SDK states to: "running" | "waiting" | "idle" | "error"

### services/sessionManager.ts
Active session management with a Map<sessionId, SessionState>:
- `resumeSession(id)`: Use SDK V2 `unstable_v2_resumeSession(sessionId)` to resume with full context
- `createSession(cwd, model)`: Use `unstable_v2_createSession({ model, cwd })` to spawn new session
- `endSession(id)`: Call session.close() and remove from active map
- `getHistory(id)`: Use `getSessionMessages(sessionId)` for transcript
- `getSessionCost(id)`: Track cumulative input/output tokens and cost
- Store session state: { session, sessionId, cwd, model, status, lastActive, totalCost, inputTokens, outputTokens }

### routes/sessions.ts (all behind JWT auth)
```
GET    /api/sessions          -> [{ id, cwd, model, status, lastActive }]
POST   /api/sessions          -> { id, cwd, model } (body: { cwd: string, model?: string })
GET    /api/sessions/:id      -> { full session detail + cost }
DELETE /api/sessions/:id      -> { success: true }
GET    /api/sessions/:id/history -> [{ role, content, timestamp }] (paginated: ?limit=50&offset=0)
```

## Important
- Default model: "sonnet" (maps to claude-sonnet-4-5 internally)
- Session discovery runs on startup + periodic interval
- Discovered sessions (from disk) show as "idle" until resumed
- Active sessions (in Map) show real-time status
- Merge discovered + active lists in GET /sessions (no duplicates)
- Use the SDK's `settingSources: ["user", "project"]` to load project-specific settings

## Error Handling
- Session not found: 404 { error: "SESSION_NOT_FOUND" }
- Session already active: 409 { error: "SESSION_ALREADY_ACTIVE" }
- Claude Code not installed: 503 { error: "CLAUDE_NOT_AVAILABLE" }
