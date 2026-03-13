import { ChunkBuffer } from "./sms.types";

export class SMSSessionManager {
  private sessions = new Map<string, ChunkBuffer>();
  private readonly timeoutMs: number;

  constructor(timeoutMs = 60_000) {
    this.timeoutMs = timeoutMs;
    setInterval(() => this.cleanup(), 30_000).unref(); // unref so it doesn't block process exit
  }

  insert(
    sid:   string,
    seq:   number,
    total: number,
    from:  string,
    chunk: Buffer
  ): Buffer | null {
    if (!this.sessions.has(sid)) {
      this.sessions.set(sid, {
        chunks:     Array(total).fill(null),
        total,
        from,
        receivedAt: Date.now(),
      });
    }

    const session = this.sessions.get(sid)!;

    if (seq >= session.total) {
      console.warn(`[SMS] SEQ ${seq} out of range for session ${sid}, dropping`);
      return null;
    }

    if (session.chunks[seq] !== null) {
      console.warn(`[SMS] Duplicate chunk ${seq} for session ${sid}, ignoring`);
      return null;
    }

    session.chunks[seq] = chunk;

    const complete = session.chunks.every((c) => c !== null);
    if (!complete) return null;

    const full = Buffer.concat(session.chunks as Buffer[]);
    this.sessions.delete(sid);
    return full;
  }

  private cleanup() {
    const now = Date.now();
    for (const [sid, session] of this.sessions) {
      if (now - session.receivedAt > this.timeoutMs) {
        console.warn(`[SMS] Session ${sid} timed out, dropping`);
        this.sessions.delete(sid);
      }
    }
  }
}
