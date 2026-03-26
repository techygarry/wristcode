import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { exec } from 'child_process';
import { promisify } from 'util';
import { sessionManager } from '../services/sessionManager';
import { sseManager } from '../services/sseManager';
import { summarizer } from '../services/summarizer';
import { AppError } from '../middleware/errorHandler';
import {
  TerminalMessage,
  PromptRequest,
  ApprovalDecision,
  CommandRequest,
} from '../types';

const execAsync = promisify(exec);

// Strip markdown code blocks and keep only conversational text
function stripCodeBlocks(text: string): string {
  // Remove ```lang ... ``` blocks
  let result = text.replace(/```[\s\S]*?```/g, '[code written]');
  // Remove inline code that's very long (>80 chars)
  result = result.replace(/`[^`]{80,}`/g, '[code]');
  // Collapse multiple newlines
  result = result.replace(/\n{3,}/g, '\n\n');
  return result.trim();
}

function sanitizeForJSON(text: string): string {
  return text
    .replace(/\x1B\[[0-9;]*[a-zA-Z]/g, '')  // ANSI escape codes
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')  // Control chars except \n \r \t
    .replace(/\\/g, '\\\\')  // Escape backslashes
    .replace(/\t/g, '  ');  // Tabs to spaces
}

const router = Router();

// GET /sessions — list all sessions
router.get('/sessions', (_req: Request, res: Response) => {
  const sessions = sessionManager.getAllSessions();
  res.json({ sessions });
});

// POST /sessions — create a new session
router.post('/sessions', (req: Request, res: Response) => {
  const { cwd, model } = req.body as { cwd?: string; model?: string };

  if (!cwd) {
    throw new AppError('MISSING_CWD', 'Working directory (cwd) is required', 400);
  }

  const session = sessionManager.createSession(cwd, model || 'sonnet');

  res.status(201).json({
    id: session.sessionId,
    cwd: session.cwd,
    model: session.model,
    status: session.status,
  });
});

// GET /sessions/:id — session detail + cost
router.get('/sessions/:id', (req: Request, res: Response) => {
  const { id } = req.params;

  // Try to get active session first
  let session = sessionManager.getSession(id);

  // If not active, try to resume from discovered sessions
  if (!session) {
    const info = sessionManager.getSessionInfo(id);
    if (!info) {
      throw new AppError('SESSION_NOT_FOUND', `Session ${id} not found`, 404);
    }
    session = sessionManager.resumeSession(id);
  }

  res.json({
    id: session.sessionId,
    cwd: session.cwd,
    model: session.model,
    status: session.status,
    lastActive: session.lastActive,
    totalCost: session.totalCost,
    inputTokens: session.inputTokens,
    outputTokens: session.outputTokens,
    messageCount: session.messages.length,
  });
});

// DELETE /sessions/:id — end session
router.delete('/sessions/:id', (req: Request, res: Response) => {
  const { id } = req.params;

  sseManager.disconnect(id);
  const ended = sessionManager.endSession(id);

  if (!ended) {
    throw new AppError('SESSION_NOT_FOUND', `Session ${id} not found`, 404);
  }

  res.json({ message: 'Session ended', id });
});

// GET /sessions/:id/history — paginated messages
router.get('/sessions/:id/history', (req: Request, res: Response) => {
  const { id } = req.params;

  const session = sessionManager.getSession(id);
  if (!session) {
    throw new AppError('SESSION_NOT_FOUND', `Session ${id} not found`, 404);
  }

  const limit = Math.min(parseInt(req.query.limit as string, 10) || 50, 200);
  const offset = Math.max(parseInt(req.query.offset as string, 10) || 0, 0);

  const messages = sessionManager.getHistory(id, limit, offset);

  res.json({
    messages,
    total: session.messages.length,
    limit,
    offset,
    hasMore: offset + limit < session.messages.length,
  });
});

// GET /sessions/:id/stream — SSE endpoint
router.get('/sessions/:id/stream', (req: Request, res: Response) => {
  const { id } = req.params;

  const session = sessionManager.getSession(id);
  if (!session) {
    // Try to resume discovered session
    const info = sessionManager.getSessionInfo(id);
    if (!info) {
      throw new AppError('SESSION_NOT_FOUND', `Session ${id} not found`, 404);
    }
    sessionManager.resumeSession(id);
  }

  const lastEventId = req.headers['last-event-id']
    ? parseInt(req.headers['last-event-id'] as string, 10)
    : undefined;

  sseManager.connect(id, res, lastEventId);
});

// POST /sessions/:id/prompt — send a prompt
router.post('/sessions/:id/prompt', async (req: Request, res: Response) => {
  try {
  const { id } = req.params;
  const { text, type } = req.body as PromptRequest;

  let session = sessionManager.getSession(id);
  if (!session) {
    // Auto-resume discovered sessions
    const info = sessionManager.getSessionInfo(id);
    if (info) {
      session = sessionManager.resumeSession(id);
    } else {
      res.status(404).json({ error: 'SESSION_NOT_FOUND', message: `Session ${id} not found` });
      return;
    }
  }

  if (!text) {
    res.status(400).json({ error: 'MISSING_TEXT', message: 'Prompt text is required' });
    return;
  }

  // Store the user message
  const userMessage: TerminalMessage = {
    id: uuidv4(),
    role: 'user',
    content: text,
    timestamp: new Date(),
    type: type === 'voice' ? 'text' : 'text',
  };
  sessionManager.addMessage(id, userMessage);
  sessionManager.updateStatus(id, 'running');

  // Emit user message via SSE
  sseManager.emit(id, 'text', {
    role: 'user',
    content: text,
    messageId: userMessage.id,
  });

  // Run real Claude Code CLI
  const cwd = session.cwd || process.cwd();
  console.log(`[Claude] Running prompt in ${cwd}: "${text.substring(0, 80)}..."`);

  try {
    const fs = await import('fs');
    const safeCwd = fs.existsSync(cwd) ? cwd : process.env.HOME || '/tmp';
    const escaped = text.replace(/"/g, '\\"');
    const modelFlag = session.model && session.model !== 'sonnet' ? ` --model ${session.model}` : '';

    // Use callback exec to always capture stdout even on non-zero exit
    const { stdout, stderr } = await new Promise<{ stdout: string; stderr: string }>((resolve) => {
      exec(
        `claude -p${modelFlag} "${escaped}" < /dev/null`,
        {
          cwd: safeCwd,
          timeout: 180000,
          maxBuffer: 1024 * 1024 * 10,
          env: { ...process.env, FORCE_COLOR: '0' },
        },
        (_err, stdout, stderr) => {
          // Always resolve — never reject. We handle errors via stdout/stderr content.
          resolve({ stdout: stdout || '', stderr: stderr || '' });
        }
      );
    });

    // Strip ANSI codes and control chars from Claude output
    const raw = stdout.trim() || stderr.trim() || 'No output';
    const responseText = sanitizeForJSON(raw);
    const inputTokens = Math.ceil(text.length / 4);
    const outputTokens = Math.ceil(responseText.length / 4);
    sessionManager.updateCost(id, inputTokens, outputTokens);

    const assistantMessage: TerminalMessage = {
      id: uuidv4(),
      role: 'assistant',
      content: responseText,
      timestamp: new Date(),
      type: 'text',
    };
    sessionManager.addMessage(id, assistantMessage);

    sseManager.emit(id, 'text', { content: responseText });

    // Check if an index.html was created
    const fsCheck = await import('fs');
    const hasPreview = fsCheck.existsSync(require('path').join(safeCwd, 'index.html'));

    // Strip code blocks and truncate for watch display
    const stripped = stripCodeBlocks(responseText);
    const watchResponse = stripped.length > 600
      ? stripped.substring(0, 600) + '\n\n...'
      : stripped;

    res.json({
      messageId: userMessage.id,
      status: 'completed',
      response: watchResponse,
      hasPreview,
      cost: {
        inputTokens,
        outputTokens,
        totalCost: sessionManager.getSession(id)?.totalCost ?? 0,
      },
    });
  } catch (err: any) {
    // exec throws on non-zero exit OR when stderr has content
    // But claude -p often writes to stdout even when it "errors"
    const rawOutput = err.stdout?.trim();
    const output = rawOutput ? sanitizeForJSON(rawOutput) : undefined;
    if (output) {
      // Claude produced output despite the "error" (usually just stderr warnings)
      console.log(`[Claude] Completed with warnings`);
      const inputTokens = Math.ceil(text.length / 4);
      const outputTokens = Math.ceil(output.length / 4);
      sessionManager.updateCost(id, inputTokens, outputTokens);

      const assistantMessage: TerminalMessage = {
        id: uuidv4(),
        role: 'assistant',
        content: output,
        timestamp: new Date(),
        type: 'text',
      };
      sessionManager.addMessage(id, assistantMessage);

      const fs2 = require('fs');
      const hasPreview2 = fs2.existsSync(require('path').join(session.cwd, 'index.html'));
      const watchOutput = stripCodeBlocks(output);
      const truncated = watchOutput.length > 600 ? watchOutput.substring(0, 600) + '\n\n...' : watchOutput;

      res.json({
        messageId: userMessage.id,
        status: 'completed',
        response: truncated,
        hasPreview: hasPreview2,
        cost: {
          inputTokens,
          outputTokens,
          totalCost: sessionManager.getSession(id)?.totalCost ?? 0,
        },
      });
      return;
    }

    const errorMsg = err.stderr?.trim() || err.message || 'Claude execution failed';
    console.error(`[Claude] Error:`, errorMsg.substring(0, 200));

    const errorMessage: TerminalMessage = {
      id: uuidv4(),
      role: 'assistant',
      content: errorMsg,
      timestamp: new Date(),
      type: 'error',
    };
    sessionManager.addMessage(id, errorMessage);

    res.json({
      messageId: userMessage.id,
      status: 'error',
      response: errorMsg,
      cost: { inputTokens: 0, outputTokens: 0, totalCost: 0 },
    });
  }
  } catch (outerErr: any) {
    console.error('[Claude] Unhandled error:', outerErr.message?.substring(0, 100));
    res.status(500).json({ status: 'error', response: outerErr.message || 'Internal error' });
  }
});

// POST /sessions/:id/approve — approval decision
router.post('/sessions/:id/approve', (req: Request, res: Response) => {
  const { id } = req.params;
  const { toolUseId, decision } = req.body as ApprovalDecision;

  const session = sessionManager.getSession(id);
  if (!session) {
    throw new AppError('SESSION_NOT_FOUND', `Session ${id} not found`, 404);
  }

  if (!toolUseId || !decision) {
    throw new AppError('MISSING_FIELDS', 'toolUseId and decision are required', 400);
  }

  if (decision !== 'approve' && decision !== 'reject') {
    throw new AppError('INVALID_DECISION', 'Decision must be "approve" or "reject"', 400);
  }

  // Store the approval as a system message
  const approvalMessage: TerminalMessage = {
    id: uuidv4(),
    role: 'system',
    content: `Tool use ${toolUseId}: ${decision}ed`,
    timestamp: new Date(),
    type: 'tool_result',
  };
  sessionManager.addMessage(id, approvalMessage);

  // Emit confirmation via SSE
  sseManager.emit(id, 'tool_result', {
    toolUseId,
    decision,
    message: `Tool use ${decision === 'approve' ? 'approved' : 'rejected'}`,
  });

  if (decision === 'approve') {
    sessionManager.updateStatus(id, 'running');
  } else {
    sessionManager.updateStatus(id, 'idle');
  }

  res.json({
    toolUseId,
    decision,
    status: decision === 'approve' ? 'resumed' : 'rejected',
  });
});

// POST /sessions/:id/command — slash command
router.post('/sessions/:id/command', (req: Request, res: Response) => {
  const { id } = req.params;
  const { command } = req.body as CommandRequest;

  const session = sessionManager.getSession(id);
  if (!session) {
    throw new AppError('SESSION_NOT_FOUND', `Session ${id} not found`, 404);
  }

  if (!command) {
    throw new AppError('MISSING_COMMAND', 'Command is required', 400);
  }

  const cmd = command.startsWith('/') ? command.slice(1).toLowerCase() : command.toLowerCase();
  let responseText: string;

  switch (cmd) {
    case 'status':
      responseText = [
        `Session: ${session.sessionId}`,
        `Model: ${session.model}`,
        `Status: ${session.status}`,
        `CWD: ${session.cwd}`,
        `Messages: ${session.messages.length}`,
        `Cost: $${session.totalCost.toFixed(4)}`,
      ].join('\n');
      break;

    case 'clear':
      session.messages = [];
      responseText = 'Conversation history cleared.';
      break;

    case 'compact':
      if (session.messages.length > 10) {
        const kept = session.messages.slice(-10);
        const removed = session.messages.length - 10;
        session.messages = kept;
        responseText = `Compacted conversation: removed ${removed} older messages, kept last 10.`;
      } else {
        responseText = 'Conversation is already compact.';
      }
      break;

    case 'cost':
      responseText = [
        `Input tokens: ${session.inputTokens.toLocaleString()}`,
        `Output tokens: ${session.outputTokens.toLocaleString()}`,
        `Total cost: $${session.totalCost.toFixed(4)}`,
      ].join('\n');
      break;

    case 'help':
      responseText = [
        'Available commands:',
        '  /status  — Show session status',
        '  /clear   — Clear conversation history',
        '  /compact — Compact conversation to last 10 messages',
        '  /cost    — Show token usage and cost',
        '  /help    — Show this help message',
      ].join('\n');
      break;

    default:
      throw new AppError('UNKNOWN_COMMAND', `Unknown command: /${cmd}`, 400);
  }

  // Store command response as system message
  const cmdMessage: TerminalMessage = {
    id: uuidv4(),
    role: 'system',
    content: responseText,
    timestamp: new Date(),
    type: 'status',
  };
  sessionManager.addMessage(id, cmdMessage);

  // Emit via SSE
  sseManager.emit(id, 'status', {
    command: cmd,
    content: responseText,
    messageId: cmdMessage.id,
  });

  res.json({
    command: cmd,
    result: responseText,
  });
});

// GET /sessions/:id/cost — token usage + cost
router.get('/sessions/:id/cost', (req: Request, res: Response) => {
  const { id } = req.params;

  const session = sessionManager.getSession(id);
  if (!session) {
    throw new AppError('SESSION_NOT_FOUND', `Session ${id} not found`, 404);
  }

  const createdAt = session.messages.length > 0
    ? session.messages[0].timestamp
    : session.lastActive;
  const durationMs = Date.now() - new Date(createdAt).getTime();

  res.json({
    inputTokens: session.inputTokens,
    outputTokens: session.outputTokens,
    totalCost: session.totalCost,
    sessionDuration: Math.floor(durationMs / 1000),
  });
});

// --- Simulated Claude response ---

function simulateClaudeResponse(sessionId: string, promptText: string): void {
  const responseText = generateSimulatedResponse(promptText);
  const words = responseText.split(' ');
  let charIndex = 0;

  // Stream text response word by word
  const streamText = (wordIndex: number): void => {
    if (wordIndex >= words.length) {
      // Text streaming complete — finalize the text message
      const assistantMessage: TerminalMessage = {
        id: uuidv4(),
        role: 'assistant',
        content: responseText,
        timestamp: new Date(),
        type: 'text',
      };
      sessionManager.addMessage(sessionId, assistantMessage);

      // Simulate token usage
      const inputTokens = Math.ceil(promptText.length / 4);
      const outputTokens = Math.ceil(responseText.length / 4);
      sessionManager.updateCost(sessionId, inputTokens, outputTokens);

      sseManager.emit(sessionId, 'cost', {
        inputTokens,
        outputTokens,
        totalCost: sessionManager.getSession(sessionId)?.totalCost ?? 0,
      });

      // Simulate tool use after text response
      setTimeout(() => simulateToolUse(sessionId), 500);
      return;
    }

    const word = words[wordIndex];
    charIndex += word.length + 1;

    sseManager.emit(sessionId, 'text', {
      role: 'assistant',
      content: word + ' ',
      streaming: true,
      progress: charIndex / responseText.length,
    });

    setTimeout(() => streamText(wordIndex + 1), 30 + Math.random() * 50);
  };

  // Begin streaming after a brief "thinking" delay
  setTimeout(() => {
    sseManager.emit(sessionId, 'status', { state: 'thinking' });
    setTimeout(() => streamText(0), 300);
  }, 200);
}

function simulateToolUse(sessionId: string): void {
  const toolUseId = uuidv4();
  const readToolId = uuidv4();

  // Simulate "Read file" tool use
  sseManager.emit(sessionId, 'tool_use', {
    toolUseId: readToolId,
    toolName: 'Read',
    input: { file_path: 'src/index.ts', limit: 50 },
  });

  const readMessage: TerminalMessage = {
    id: readToolId,
    role: 'assistant',
    content: 'Reading src/index.ts',
    timestamp: new Date(),
    type: 'tool_use',
  };
  sessionManager.addMessage(sessionId, readMessage);

  // Simulate tool result after a delay
  setTimeout(() => {
    sseManager.emit(sessionId, 'tool_result', {
      toolUseId: readToolId,
      toolName: 'Read',
      output: '// File contents read successfully (42 lines)',
    });

    // Simulate "Edit file" tool use that requires approval
    setTimeout(() => {
      sseManager.emit(sessionId, 'tool_use', {
        toolUseId,
        toolName: 'Edit',
        input: { file_path: 'src/index.ts', old_string: '// old code', new_string: '// new code' },
      });

      const editMessage: TerminalMessage = {
        id: toolUseId,
        role: 'assistant',
        content: 'Editing src/index.ts',
        timestamp: new Date(),
        type: 'tool_use',
      };
      sessionManager.addMessage(sessionId, editMessage);

      // Send approval request
      const diffText = '-// old code\n+// new code';
      summarizer.diffSummary(diffText, 'src/index.ts').then((summary) => {
        sseManager.emit(sessionId, 'approval_request', {
          toolUseId,
          toolName: 'Edit',
          diff: diffText,
          summary,
        });

        sessionManager.updateStatus(sessionId, 'waiting');
      });
    }, 400);
  }, 600);
}

function generateSimulatedResponse(prompt: string): string {
  const lower = prompt.toLowerCase();

  if (lower.includes('fix') || lower.includes('bug')) {
    return "I found the issue. The problem is in the error handling logic where the catch block doesn't properly propagate the error type. I'll read the file first and then apply the fix.";
  }

  if (lower.includes('test')) {
    return "I'll create a comprehensive test suite for this module. Let me first review the existing code to understand the interface, then write the tests.";
  }

  if (lower.includes('refactor')) {
    return "Good idea. I'll refactor this to use a cleaner pattern. Let me examine the current implementation and propose the changes.";
  }

  if (lower.includes('explain') || lower.includes('what')) {
    return "This code implements a request handler that validates input, processes the data through the service layer, and returns a formatted response. The key components are the validation middleware, the service logic, and the response serializer.";
  }

  if (lower.includes('add') || lower.includes('create') || lower.includes('implement')) {
    return "I'll implement that for you. Let me review the existing codebase structure first to make sure the new code follows the established patterns.";
  }

  return "I understand. Let me analyze the codebase and work on that. I'll start by reading the relevant files to understand the current state.";
}

export default router;
