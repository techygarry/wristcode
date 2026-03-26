# WristCode — Session 4: Response Summarization (Max Subscription Only)

## Context
Sessions 1-3 complete. Bridge server fully functional. Now add response summarization optimized for the tiny watch screen. This uses Claude Code's own session (Max subscription) — NO separate API key needed.

## Important: Max-Only Architecture
Instead of calling the Anthropic API directly (which needs a separate API key + billing), we use the Claude Agent SDK to spawn a lightweight summarizer session. This piggybacks on your existing Claude Max subscription — zero extra cost.

## Task

### services/summarizer.ts
Create a summarizer service that uses a dedicated Claude Agent SDK session:

```typescript
// Uses a persistent "summarizer" session via Agent SDK
// Model: haiku (cheapest, fastest — included in Max)
// NOT the Anthropic API — uses your Max subscription through Agent SDK

class Summarizer {
  private session: Session | null = null;

  async init() {
    // Create a lightweight session dedicated to summarization
    this.session = unstable_v2_createSession({
      model: "haiku",
      maxTurns: 1,  // Single-turn only
    });
  }

  async displaySummary(text: string): Promise<string>
  // Prompt: "Summarize this Claude Code output in 2-4 short sentences
  // for display on an Apple Watch screen. Be concise and technical.
  // Focus on: what was done, what changed, any issues.
  // Output ONLY the summary, no preamble."

  async ttsSummary(text: string): Promise<string>
  // Prompt: "Summarize in 1-2 spoken sentences for text-to-speech
  // on Apple Watch. Conversational, brief, like telling a colleague.
  // Output ONLY the summary."

  async diffSummary(diff: string, fileName: string): Promise<string>
  // Prompt: "Describe this code diff in plain English, 1-2 sentences.
  // File: {fileName}. Focus on what changed and why it matters.
  // Output ONLY the description."

  async isAvailable(): Promise<boolean>
  // Check if summarizer session can be created
  // Returns false if Claude Code not authenticated
}
```

### Integration with SSE
- After each Claude response completes (result message), auto-generate summaries
- Emit SSE event: `{ type: "summary", payload: { display: string, tts: string } }`
- For approval_request events, generate diffSummary and include in the event
- Cache summaries in memory (Map<messageId, SummaryResult>) to avoid re-generating on reconnect
- Configurable: ENABLE_SUMMARIZATION env var (default: true)
- If summarization fails (rate limit, etc.), gracefully degrade — send full text without summary

### Performance
- Summarization runs async — don't block the main response stream
- Haiku responses are fast (~500ms) so summaries arrive shortly after the main response
- Rate limit: max 10 summarization requests per minute (queue excess)
- Dispose summarizer session on server shutdown

## Fallback Behavior
If summarization is disabled or fails:
- Watch receives full text (no summary event)
- Watch-side truncation: show first 200 chars with "..." and scroll for full text
- Diff viewer shows raw diff without AI summary

## Why This Approach
- Zero additional cost (uses Max subscription)
- No API key management
- Same auth flow as main sessions
- Haiku is fast enough for real-time summarization
- Degrades gracefully if unavailable
