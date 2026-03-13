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
const RAW_PROMPT_ACTION = "__raw_prompt__";
const VALID_PACKET_TYPES = new Set<number>([
  PacketType.REQUEST,
  PacketType.RESPONSE,
  PacketType.ACK,
  PacketType.ERROR,
]);

const isLikelyLegacyPacket = (packet: {
  sid: string;
  seq: number;
  total: number;
  type: number;
}): boolean => {
  const sidOk = /^[A-Za-z0-9]{2}$/.test(packet.sid);
  const typeOk = VALID_PACKET_TYPES.has(packet.type);
  const totalOk = Number.isInteger(packet.total) && packet.total > 0 && packet.total <= 64;
  const seqOk = Number.isInteger(packet.seq) && packet.seq >= 0 && packet.seq < packet.total;

  return sidOk && typeOk && totalOk && seqOk;
};

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
      httpSmsApiKey:    (process.env.HTTPSMS_API_KEY ?? "").trim(),
      httpSmsFromPhone: (process.env.HTTPSMS_FROM_PHONE ?? "").trim(),
      chunkSize:        110,
      timeoutMs:        60_000,
    };

    const missing: string[] = [];
    if (!config.httpSmsApiKey)    missing.push("HTTPSMS_API_KEY");
    if (!config.httpSmsFromPhone) missing.push("HTTPSMS_FROM_PHONE");
    if (missing.length)
      throw new Error(`[SMS] Missing env vars: ${missing.join(", ")}`);

    this.sender      = new SMSSender(config);
    this.sessions    = new SMSSessionManager(config.timeoutMs);
    this.initialized = true;

    const maskedKey = `${config.httpSmsApiKey.slice(0, 4)}***${config.httpSmsApiKey.slice(-3)}`;
    console.log(`[SMS] Service initialized ✓ | from=${config.httpSmsFromPhone} | apiKey=${maskedKey} | keyLen=${config.httpSmsApiKey.length}`);
  }

  // ─── Register a handler for incoming decoded messages ─────────────────────

  onMessage(handler: SMSMessageHandler): void {
    this.handler = handler;
    console.log("[SMS] Message handler registered ✓");
  }

  // ─── Send anything to any phone number — usable from anywhere ────────────

  async send(to: string, data: unknown): Promise<void> {
    this.assertInitialized();

    const json       = JSON.stringify(data);
    const compressed = await gzip(Buffer.from(json, "utf-8"));

    console.log(
      `[SMS] → ${to} | raw: ${json.length}B | compressed: ${compressed.length}B`
    );

    await this.sender.send(to, compressed);
  }

  async sendRaw(to: string, rawMessage: string): Promise<void> {
    this.assertInitialized();
    await this.sender.sendPlain(to, rawMessage);
  }

  // ─── Called by router on every incoming webhook hit ───────────────────────

  async handleIncoming(raw: string, from: string): Promise<void> {
    this.assertInitialized();

    let packet;
    try {
      packet = parsePacket(raw);
    } catch (e) {
      await this.dispatchRawPrompt(raw, from, "packet parse failed");
      return;
    }

    if (!isLikelyLegacyPacket(packet)) {
      console.warn(
        `[SMS] Parsed bytes but header is not a valid legacy packet (sid=${packet.sid}, seq=${packet.seq}, total=${packet.total}, type=${packet.type}); treating as raw prompt`
      );
      await this.dispatchRawPrompt(raw, from, "invalid legacy packet header");
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
      throw new Error("[SMS] Call SMS.init() before using the service");
  }

  private async dispatchRawPrompt(raw: string, from: string, reason: string): Promise<void> {
    if (!this.handler) {
      console.warn(`[SMS] No handler registered for raw message mode (${reason})`);
      return;
    }

    console.log(`[SMS] Falling back to raw prompt mode for ${from} (${reason})`);
    try {
      await this.handler(RAW_PROMPT_ACTION, raw, from);
    } catch (rawErr) {
      console.error(`[SMS] Raw message processing error for ${from}:`, rawErr);
    }
  }
}

export const SMS = new SMSService();