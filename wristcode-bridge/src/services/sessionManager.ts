import { v4 as uuidv4 } from 'uuid';
import { SessionInfo, SessionState, SessionStatus, TerminalMessage } from '../types';

class SessionManager {
  private activeSessions = new Map<string, SessionState>();
  private discoveredSessions: SessionInfo[] = [];

  constructor() {
    this.seedDiscoveredSessions();
  }

  private seedDiscoveredSessions(): void {
    // Simulated discovered sessions from ~/.claude/projects/
    this.discoveredSessions = [
      {
        id: 'a3f2c1',
        cwd: '/Users/adsol/Documents/techy-projects/watchvibe/sandbox',
        model: 'sonnet',
        status: 'idle',
        lastActive: new Date(Date.now() - 2 * 60 * 1000),
        projectName: 'watchvibe',
      },
    ];
  }

  getAllSessions(): SessionInfo[] {
    const activeList: SessionInfo[] = [];
    for (const [id, state] of this.activeSessions) {
      activeList.push({
        id,
        cwd: state.cwd,
        model: state.model,
        status: state.status,
        lastActive: state.lastActive,
        projectName: state.cwd.split('/').pop() || state.cwd,
      });
    }

    // Merge: active sessions override discovered ones
    const activeIds = new Set(activeList.map((s) => s.id));
    const discovered = this.discoveredSessions.filter((s) => !activeIds.has(s.id));
    return [...activeList, ...discovered];
  }

  getSession(id: string): SessionState | undefined {
    return this.activeSessions.get(id);
  }

  getSessionInfo(id: string): SessionInfo | undefined {
    const active = this.activeSessions.get(id);
    if (active) {
      return {
        id,
        cwd: active.cwd,
        model: active.model,
        status: active.status,
        lastActive: active.lastActive,
        projectName: active.cwd.split('/').pop() || active.cwd,
      };
    }
    return this.discoveredSessions.find((s) => s.id === id);
  }

  resumeSession(id: string): SessionState {
    const existing = this.activeSessions.get(id);
    if (existing) return existing;

    const discovered = this.discoveredSessions.find((s) => s.id === id);
    if (!discovered) {
      throw new Error('Session not found');
    }

    const state: SessionState = {
      sessionId: id,
      cwd: discovered.cwd,
      model: discovered.model,
      status: 'running',
      lastActive: new Date(),
      totalCost: 0,
      inputTokens: 0,
      outputTokens: 0,
      messages: [],
    };

    this.activeSessions.set(id, state);
    console.log(`[Session] Resumed session ${id} (${discovered.projectName})`);
    return state;
  }

  createSession(cwd: string, model: string = 'sonnet'): SessionState {
    const id = uuidv4().substring(0, 6);
    const state: SessionState = {
      sessionId: id,
      cwd,
      model,
      status: 'running',
      lastActive: new Date(),
      totalCost: 0,
      inputTokens: 0,
      outputTokens: 0,
      messages: [],
    };

    this.activeSessions.set(id, state);
    console.log(`[Session] Created session ${id} at ${cwd}`);
    return state;
  }

  endSession(id: string): boolean {
    const session = this.activeSessions.get(id);
    if (!session) return false;

    this.activeSessions.delete(id);
    console.log(`[Session] Ended session ${id}`);
    return true;
  }

  getHistory(id: string, limit: number = 50, offset: number = 0): TerminalMessage[] {
    const session = this.activeSessions.get(id);
    if (!session) return [];
    return session.messages.slice(offset, offset + limit);
  }

  addMessage(id: string, message: TerminalMessage): void {
    const session = this.activeSessions.get(id);
    if (session) {
      session.messages.push(message);
      session.lastActive = new Date();
      if (session.messages.length > 500) {
        session.messages = session.messages.slice(-200);
      }
    }
  }

  updateStatus(id: string, status: SessionStatus): void {
    const session = this.activeSessions.get(id);
    if (session) {
      session.status = status;
      session.lastActive = new Date();
    }
  }

  updateCost(id: string, inputTokens: number, outputTokens: number): void {
    const session = this.activeSessions.get(id);
    if (session) {
      session.inputTokens += inputTokens;
      session.outputTokens += outputTokens;
      // Approximate cost calculation
      session.totalCost += (inputTokens * 0.003 + outputTokens * 0.015) / 1000;
    }
  }

  getActiveCount(): number {
    return this.activeSessions.size;
  }
}

export const sessionManager = new SessionManager();
