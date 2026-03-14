import { SMSSender } from "./sms.sender";
import {
  SMSConfig,
  SMSMessageHandler,
  SMSRequestEnvelope,
} from "./sms.types";

class SMSService {
  private sender!:        SMSSender;
  private handler:        SMSMessageHandler | null = null;
  private initialized =   false;

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
    this.initialized = true;

    console.log("[SMS] Service initialized ✓");
  }

  onMessage(handler: SMSMessageHandler): void {
    this.handler = handler;
    console.log("[SMS] Message handler registered ✓");
  }

  async send(to: string, data: unknown): Promise<void> {
    if (!this.initialized) {
      this.assertInitialized();
      return;
    }

    const payload = JSON.stringify(data);
    console.log(`[SMS] → ${to} | text: ${payload}`);
    await this.sender.sendPlainText(to, payload);
  }

  async sendText(to: string, text: string): Promise<void> {
    this.assertInitialized();
    console.log(`[SMS] → ${to} | text: ${text}`);
    await this.sender.sendPlainText(to, text);
  }

  async handleIncoming(raw: string, from: string): Promise<void> {
    this.assertInitialized();
    console.log(`[SMS] webhook received from ${from} | rawChars=${raw.length}`);

    if (!this.handler) {
      console.warn("[SMS] No handler registered!");
      return;
    }

    let action: string = "sms";
    let payload: any = raw;

    // Try to parse as JSON envelope if it looks like one
    if (raw.trim().startsWith("{") && raw.trim().endsWith("}")) {
      try {
        const envelope: SMSRequestEnvelope = JSON.parse(raw);
        action = envelope.action;
        payload = envelope.payload;
        console.log(`[SMS] JSON envelope detected | action=${action}`);
      } catch (_) {
        // Stay as direct string
      }
    }

    await this.dispatchToHandler(action, payload, from, "direct");
  }

  private assertInitialized(): void {
    if (!this.initialized)
      console.warn("[SMS] Call SMS.init() before using the service.");
  }

  private async dispatchToHandler(
    action: string,
    payload: unknown,
    from: string,
    sid: string
  ): Promise<void> {
    if (!this.handler) return;

    const result = await this.handler(action, payload, from);
    console.log(`[SMS] handler completed | sid=${sid} from=${from}`);

    // If result is null or undefined, or explicitly handled, don't send default response
    if (result === undefined || result === null) return;
    
    if (typeof result === "object" && (result as any).skipDefaultResponse) {
      return;
    }

    let data = result;
    if (typeof result === "object" && "data" in (result as any)) {
      data = (result as any).data;
    }

    await this.send(from, { ok: true, data });
  }
}

export const SMS = new SMSService();