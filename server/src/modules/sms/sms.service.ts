import zlib from "zlib";
import { promisify } from "util";
import { SMSSessionManager } from "./sms.session";
import { SMSSender } from "./sms.sender";
import { parsePacket } from "./sms.parser";
import {
  PacketType,
  SMSConfig,
  SMSHandlerResult,
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

  async sendText(to: string, text: string): Promise<void> {
    this.assertInitialized();

    const payload = Buffer.from(text, "utf-8");
    console.log(`[SMS] → ${to} | text payload: ${payload.length}B`);
    await this.sender.sendPlainText(to, text);
  }

  // ─── Called by router on every incoming webhook hit ───────────────────────

  async handleIncoming(raw: string, from: string): Promise<void> {
    this.assertInitialized();
    console.log(`[SMS] webhook payload received from ${from} | rawChars=${raw.length}`);

    let packet;
    try {
      packet = parsePacket(raw);
      console.log(
        `[SMS] packet parsed from ${from} | sid=${packet.sid} seq=${packet.seq + 1}/${packet.total} type=${packet.type} payloadBytes=${packet.payload.length}`
      );
    } catch (e) {
      console.warn(`[SMS] parsePacket failed for ${from}; treating as direct payload`);
      await this.handleDirectPayload(raw, from);
      return;
    }

    const packetTypeKnown = Object.values(PacketType).includes(packet.type);
    const sidLooksValid = /^[A-Za-z0-9]{2}$/.test(packet.sid);
    const packetLooksPlausible =
      packetTypeKnown &&
      sidLooksValid &&
      packet.total > 0 &&
      packet.seq < packet.total;

    if (!packetLooksPlausible) {
      console.warn(
        `[SMS] packet appears invalid/incompatible from ${from}; falling back to direct payload handling`
      );
      await this.handleDirectPayload(raw, from);
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

    if (!full) {
      console.log(`[SMS] waiting for more chunks | sid=${packet.sid} from=${from}`);
      return; // still waiting for remaining chunks
    }

    console.log(`[SMS] ✓ Session ${packet.sid} complete — processing fullBytes=${full.length}`);

    try {
      const decompressed             = await gunzip(full);
      const envelope: SMSRequestEnvelope = JSON.parse(decompressed.toString("utf-8"));
      console.log(
        `[SMS] envelope parsed | sid=${packet.sid} from=${from} action=${String(envelope.action)} payloadType=${typeof envelope.payload}`
      );

      if (!this.handler) {
        console.warn("[SMS] No handler registered! Call SMS.onMessage() in app.ts");
        await this.send(from, { ok: false, err: "Server handler not configured" });
        return;
      }

      await this.dispatchToHandler(envelope.action, envelope.payload, from, packet.sid);
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

  private shouldSkipDefaultResponse(result: unknown): result is SMSHandlerResult {
    return (
      typeof result === "object" &&
      result !== null &&
      "skipDefaultResponse" in result &&
      Boolean((result as SMSHandlerResult).skipDefaultResponse)
    );
  }

  private unwrapHandlerData(result: unknown): unknown {
    if (
      typeof result === "object" &&
      result !== null &&
      "data" in result &&
      Object.prototype.hasOwnProperty.call(result, "skipDefaultResponse")
    ) {
      return (result as SMSHandlerResult).data;
    }

    return result;
  }

  private async handleDirectPayload(raw: string, from: string): Promise<void> {
    if (!this.handler) {
      console.warn("[SMS] No handler registered for direct payload mode");
      await this.send(from, { ok: false, err: "Server handler not configured" });
      return;
    }

    console.log(`[SMS] processing direct payload mode from ${from}`);
    await this.dispatchToHandler("sms", raw, from, "direct");
  }

  private async dispatchToHandler(
    action: string,
    payload: unknown,
    from: string,
    sid: string
  ): Promise<void> {
    if (!this.handler) {
      console.warn("[SMS] No handler registered! Call SMS.onMessage() in app.ts");
      await this.send(from, { ok: false, err: "Server handler not configured" });
      return;
    }

    const result = await this.handler(action, payload, from);
    console.log(`[SMS] handler completed | sid=${sid} from=${from}`);

    if (this.shouldSkipDefaultResponse(result)) {
      console.log(`[SMS] Handler opted out of default response for ${from}`);
      return;
    }

    await this.send(from, { ok: true, data: this.unwrapHandlerData(result) });
  }
}

export const SMS = new SMSService();