import { Response } from 'express';
import { SSEEvent, MessageType } from '../types';
import { config } from '../config';

interface SSEClient {
  res: Response;
  sessionId: string;
  lastEventId: number;
}

class SSEManager {
  private clients = new Map<string, SSEClient>();
  private eventCounters = new Map<string, number>();
  private keepAliveTimers = new Map<string, NodeJS.Timeout>();

  connect(sessionId: string, res: Response, lastEventId?: number): void {
    // Disconnect existing client for this session
    this.disconnect(sessionId);

    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'X-Accel-Buffering': 'no',
    });

    const client: SSEClient = {
      res,
      sessionId,
      lastEventId: lastEventId || 0,
    };

    this.clients.set(sessionId, client);

    if (!this.eventCounters.has(sessionId)) {
      this.eventCounters.set(sessionId, 0);
    }

    // Send initial connection event
    this.emit(sessionId, 'status', { state: 'connected' });

    // Keep-alive ping
    const timer = setInterval(() => {
      this.emit(sessionId, 'ping', {});
    }, config.sseKeepAliveInterval);
    this.keepAliveTimers.set(sessionId, timer);

    // Handle client disconnect
    res.on('close', () => {
      this.disconnect(sessionId);
    });

    console.log(`[SSE] Client connected for session ${sessionId}`);
  }

  emit(sessionId: string, type: MessageType | 'ping' | 'status' | 'connected', payload: Record<string, unknown>): void {
    const client = this.clients.get(sessionId);
    if (!client) return;

    const counter = (this.eventCounters.get(sessionId) || 0) + 1;
    this.eventCounters.set(sessionId, counter);

    const event: SSEEvent = {
      type: type as MessageType,
      payload,
      timestamp: new Date().toISOString(),
      id: counter,
    };

    try {
      client.res.write(`id: ${counter}\n`);
      client.res.write(`data: ${JSON.stringify(event)}\n\n`);
    } catch {
      this.disconnect(sessionId);
    }
  }

  disconnect(sessionId: string): void {
    const timer = this.keepAliveTimers.get(sessionId);
    if (timer) {
      clearInterval(timer);
      this.keepAliveTimers.delete(sessionId);
    }

    const client = this.clients.get(sessionId);
    if (client) {
      try {
        client.res.end();
      } catch {
        // Already closed
      }
      this.clients.delete(sessionId);
      console.log(`[SSE] Client disconnected for session ${sessionId}`);
    }
  }

  isConnected(sessionId: string): boolean {
    return this.clients.has(sessionId);
  }

  disconnectAll(): void {
    for (const sessionId of this.clients.keys()) {
      this.disconnect(sessionId);
    }
  }
}

export const sseManager = new SSEManager();
