import { config } from '../config';

class Summarizer {
  private cache = new Map<string, { display: string; tts: string }>();
  private requestCount = 0;
  private resetTimer: NodeJS.Timeout | null = null;

  constructor() {
    // Reset rate limit counter every minute
    this.resetTimer = setInterval(() => {
      this.requestCount = 0;
    }, 60000);
  }

  async displaySummary(text: string): Promise<string> {
    if (!config.enableSummarization) return text;
    if (this.requestCount >= 10) return text.substring(0, 200);

    this.requestCount++;

    // Intelligent truncation for watch display
    const sentences = text.split(/[.!?]+/).filter((s) => s.trim().length > 0);
    if (sentences.length <= 3) return text;
    return sentences.slice(0, 3).join('. ').trim() + '.';
  }

  async ttsSummary(text: string): Promise<string> {
    if (!config.enableSummarization) return text;

    // Short conversational summary for TTS
    const sentences = text.split(/[.!?]+/).filter((s) => s.trim().length > 0);
    if (sentences.length <= 2) return text;
    return sentences.slice(0, 2).join('. ').trim() + '.';
  }

  async diffSummary(diff: string, fileName: string): Promise<string> {
    if (!config.enableSummarization) return `Changes to ${fileName}`;

    const added = (diff.match(/^\+[^+]/gm) || []).length;
    const removed = (diff.match(/^-[^-]/gm) || []).length;

    let action = 'Modified';
    if (added > 0 && removed === 0) action = 'Added code to';
    else if (removed > 0 && added === 0) action = 'Removed code from';
    else if (added > removed) action = 'Extended';
    else if (removed > added) action = 'Simplified';

    return `${action} ${fileName} (+${added}, -${removed} lines)`;
  }

  getCached(messageId: string): { display: string; tts: string } | undefined {
    return this.cache.get(messageId);
  }

  setCached(messageId: string, summary: { display: string; tts: string }): void {
    this.cache.set(messageId, summary);
    // Limit cache size
    if (this.cache.size > 100) {
      const firstKey = this.cache.keys().next().value;
      if (firstKey) this.cache.delete(firstKey);
    }
  }

  isAvailable(): boolean {
    return config.enableSummarization;
  }

  dispose(): void {
    if (this.resetTimer) {
      clearInterval(this.resetTimer);
      this.resetTimer = null;
    }
    this.cache.clear();
  }
}

export const summarizer = new Summarizer();
