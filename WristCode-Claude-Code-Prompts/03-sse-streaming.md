# WristCode — Session 3: SSE Streaming + Prompt Handling

## Context
Sessions 1-2 complete. Bridge server has auth + session management. Now add real-time streaming and user interaction (prompts, approvals, slash commands).

## Task
Add/update these files:

### services/sseManager.ts
SSE (Server-Sent Events) connection manager:
- Each session supports one SSE connection from the watch
- Event format: `data: {"type":"text","payload":{...},"timestamp":"ISO"}\n\n`
- Event types:
  - `text`: { content: string, isStreaming: boolean } — Claude's response
  - `tool_use`: { toolName: string, toolInput: object, toolUseId: string }
  - `tool_result`: { toolUseId: string, output: string, isError: boolean }
  - `approval_request`: { toolUseId: string, toolName: string, diff: string|null, summary: string }
  - `status`: { state: "running"|"waiting"|"idle"|"error" }
  - `cost`: { inputTokens: number, outputTokens: number, totalCost: number }
  - `error`: { message: string, code: string }
- Keep-alive ping every 15 seconds: `data: {"type":"ping"}\n\n`
- Handle client disconnect gracefully (cleanup SSE connection)
- Reconnection support: client sends `Last-Event-ID` header

### Update routes/sessions.ts — add endpoints:

```
POST /api/sessions/:id/prompt
Body: { text: string, type: "voice"|"text" }
Response: { promptId: string }
```
- Forward prompt to active session via session.send(text)
- Stream response events to SSE connection
- Track prompt type for analytics

```
GET /api/sessions/:id/stream
```
- SSE endpoint. Set headers: Content-Type: text/event-stream, Cache-Control: no-cache, Connection: keep-alive
- Each event has incrementing ID for reconnection

```
POST /api/sessions/:id/approve
Body: { toolUseId: string, decision: "approve"|"reject" }
Response: { success: true }
```
- When Claude calls a tool needing approval (Write, Edit, Bash), pause the agent loop
- Emit approval_request SSE event with tool details + diff
- Wait for this endpoint to be called before continuing
- Use SDK's permission handling (PreToolUse hook callback)
- On reject, tell Claude the user rejected the change

```
POST /api/sessions/:id/command
Body: { command: string }  (e.g., "/compact", "/clear", "/status")
Response: { result: string }
```

```
GET /api/sessions/:id/cost
Response: { inputTokens, outputTokens, totalCost, sessionDuration }
```

## Approval Flow (Critical)
1. Claude wants to Edit a file
2. Bridge intercepts via PreToolUse hook
3. Emits approval_request with { toolUseId, toolName, diff, summary }
4. SSE pushes to watch, watch shows diff screen
5. User taps Approve or Reject
6. Watch sends POST /approve
7. Bridge resolves the hook callback (approve → allow, reject → deny with message)
8. Claude continues or adjusts based on decision

## Notes
- Use PreToolUse hook for tools: Write, Edit, MultiEdit, Bash (configurable list)
- Read, Glob, Grep auto-approved (no watch notification)
- If watch disconnects during approval wait, timeout after 5 minutes → auto-reject with message
