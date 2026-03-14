import zlib from "zlib";
import { promisify } from "util";
import { SMSSessionManager } from "./sms.session";
import { SMSSender } from "./sms.sender";
import { parsePacket } from "./sms.parser";
import {
  PacketType,
  SMSConfig,
  SMSMessageHandler,
  SMSRequestEnvelope,
} from "./sms.types";

const gunzip = promisify(zlib.gunzip);
const gzip   = promisify(zlib.gzip);

class SMSService {
  private sender!:        SMSSender;
  private sessions!:      SMSSessionManager;
  private handler:        SMSMessageHandler | null = null;
  private initialized =   false;

  // ─── Call once in app.ts ──────────────────────────────────────────────────

  init(): void {
    if (this.initialized) {
      console.warn("[SMS] Already initialized, skipping");
      return;
    }

    const config: SMSConfig = {
      httpSmsApiKey:    process.env.HTTPSMS_API_KEY!,
      httpSmsFromPhone: process.env.HTTPSMS_FROM_PHONE!,
      chunkSize:        110,
      timeoutMs:        60_000,
    };

    const missing: string[] = [];
    if (!config.httpSmsApiKey)    missing.push("HTTPSMS_API_KEY");
    if (!config.httpSmsFromPhone) missing.push("HTTPSMS_FROM_PHONE");
    if (missing.length) {
      console.warn(`[SMS] Missing env vars: ${missing.join(", ")}. SMS service disabled.`);
      return;
    }

    this.sender      = new SMSSender(config);
    this.sessions    = new SMSSessionManager(config.timeoutMs);
    this.initialized = true;

    console.log("[SMS] Service initialized ✓");
  }

  // ─── Register a handler for incoming decoded messages ─────────────────────

  onMessage(handler: SMSMessageHandler): void {
    this.handler = handler;
    console.log("[SMS] Message handler registered ✓");
  }

  // ─── Send anything to any phone number — usable from anywhere ────────────

  async send(to: string, data: unknown): Promise<void> {
    if (!this.initialized) {
      this.assertInitialized();
      return;
    }

    const json       = JSON.stringify(data);
    const compressed = await gzip(Buffer.from(json, "utf-8"));

    console.log(
      `[SMS] → ${to} | raw: ${json.length}B | compressed: ${compressed.length}B`
    );

    await this.sender.send(to, compressed);
  }

  // ─── Called by router on every incoming webhook hit ───────────────────────

  async handleIncoming(raw: string, from: string): Promise<void> {
    this.assertInitialized();

    let packet;
    try {
      packet = parsePacket(raw);
    } catch (e) {
      console.error(`[SMS] Malformed packet from ${from}:`, e);
      return;
    }

    if (packet.type !== PacketType.REQUEST) {
      console.log(`[SMS] Ignoring non-request packet (type=${packet.type}) from ${from}`);
      return;
    }

    const full = this.sessions.insert(
      packet.sid,
      packet.seq,
      packet.total,
      from,
      packet.payload
    );

    if (!full) return; // still waiting for remaining chunks

    console.log(`[SMS] ✓ Session ${packet.sid} complete — processing`);

    try {
      const decompressed             = await gunzip(full);
      const envelope: SMSRequestEnvelope = JSON.parse(decompressed.toString("utf-8"));

      if (!this.handler) {
        console.warn("[SMS] No handler registered! Call SMS.onMessage() in app.ts");
        await this.send(from, { ok: false, err: "Server handler not configured" });
        return;
      }

      const result = await this.handler(envelope.action, envelope.payload, from);
      await this.send(from, { ok: true, data: result });
    } catch (e: any) {
      console.error(`[SMS] Processing error for ${from}:`, e);
      await this.send(from, { ok: false, err: e?.message ?? "Internal server error" });
    }
  }

  // ─── Guard ────────────────────────────────────────────────────────────────

  private assertInitialized(): void {
    if (!this.initialized)
      console.warn("[SMS] Call SMS.init() before using the service. Handlers disabled.");
  }
}

export const SMS = new SMSService();