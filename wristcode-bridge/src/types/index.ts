export interface SessionInfo {
  id: string;
  cwd: string;
  model: string;
  status: SessionStatus;
  lastActive: Date;
  projectName: string;
}

export type SessionStatus = 'running' | 'waiting' | 'idle' | 'error';

export interface SessionState {
  sessionId: string;
  cwd: string;
  model: string;
  status: SessionStatus;
  lastActive: Date;
  totalCost: number;
  inputTokens: number;
  outputTokens: number;
  messages: TerminalMessage[];
}

export interface TerminalMessage {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Date;
  type?: MessageType;
}

export type MessageType =
  | 'text'
  | 'tool_use'
  | 'tool_result'
  | 'approval_request'
  | 'status'
  | 'cost'
  | 'error'
  | 'summary'
  | 'ping';

export interface SSEEvent {
  type: MessageType;
  payload: Record<string, unknown>;
  timestamp: string;
  id?: number;
}

export interface ApprovalRequest {
  toolUseId: string;
  toolName: string;
  diff: string | null;
  summary: string;
}

export interface PairRequest {
  code: string;
}

export interface PairResponse {
  token: string;
  expiresIn: string;
  hostname: string;
}

export interface PromptRequest {
  text: string;
  type: 'voice' | 'text';
}

export interface ApprovalDecision {
  toolUseId: string;
  decision: 'approve' | 'reject';
}

export interface CommandRequest {
  command: string;
}

export interface ApiError {
  error: string;
  message: string;
  code: number;
}

export interface HealthResponse {
  status: 'ok';
  version: string;
  hostname: string;
  uptime: number;
  sessions: number;
}

export interface CostResponse {
  inputTokens: number;
  outputTokens: number;
  totalCost: number;
  sessionDuration: number;
}

export interface DiffFile {
  filePath: string;
  additions: number;
  deletions: number;
  lines: DiffLine[];
}

export interface DiffLine {
  number: number;
  type: 'added' | 'removed' | 'context';
  content: string;
}

export interface JWTPayload {
  device: string;
  pairedAt: number;
}
