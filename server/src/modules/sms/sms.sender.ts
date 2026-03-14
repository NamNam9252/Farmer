import axios from "axios";
import { buildPacket, randomSID } from "./sms.parser";
import { PacketType, SMSConfig } from "./sms.types";

const HTTPSMS_SEND_URL = "https://api.httpsms.com/v1/messages/send";
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export class SMSSender {
  private readonly apiKey:    string;
  private readonly fromPhone: string;
  private readonly chunkSize: number;

  constructor(config: SMSConfig) {
    this.apiKey    = config.httpSmsApiKey;
    this.fromPhone = config.httpSmsFromPhone;
    this.chunkSize = config.chunkSize ?? 110;
  }

  async send(to: string, data: Buffer): Promise<void> {
    const sid    = randomSID();
    const chunks = this.chunkBuffer(data);

    console.log(`[SMS] Sending ${chunks.length} chunk(s) to ${to} [SID: ${sid}] totalBytes=${data.length}`);

    for (let i = 0; i < chunks.length; i++) {
      console.log(`[SMS] preparing outbound packet [SID: ${sid}] chunk=${i + 1}/${chunks.length} chunkBytes=${chunks[i].length}`);
      const encoded = buildPacket(
        sid,
        i,
        chunks.length,
        PacketType.RESPONSE,
        chunks[i]
      );

      await this.sendSingle(to, encoded);
      console.log(`[SMS] outbound packet delivered [SID: ${sid}] chunk=${i + 1}/${chunks.length}`);

      // small delay between chunks so carrier doesn't reorder/drop
      if (i < chunks.length - 1) await sleep(500);
    }

    console.log(`[SMS] completed outbound send to ${to} [SID: ${sid}]`);
  }

  async sendPlainText(to: string, content: string): Promise<void> {
    console.log(`[SMS] sending plain text SMS to ${to} | chars=${content.length}`);
    await this.sendSingle(to, content);
    console.log(`[SMS] completed plain text SMS send to ${to}`);
  }

  private async sendSingle(to: string, body: string): Promise<void> {
    try {
      const response = await axios.post(
        HTTPSMS_SEND_URL,
        {
          content: body,
          from:    this.fromPhone,
          to,
        },
        {
          headers: {
            "x-api-key":    this.apiKey,
            "Content-Type": "application/json",
          },
        }
      );
      console.log(`[SMS] httpSMS API accepted message to ${to} | status=${response.status}`);
    } catch (err: any) {
      const detail = err?.response?.data ?? err?.message ?? "Unknown error";
      console.error(`[SMS] httpSMS send failed to ${to}:`, detail);
      throw new Error(`SMS send failed: ${JSON.stringify(detail)}`);
    }
  }

  private chunkBuffer(data: Buffer): Buffer[] {
    const chunks: Buffer[] = [];
    for (let i = 0; i < data.length; i += this.chunkSize)
      chunks.push(data.slice(i, i + this.chunkSize));
    return chunks;
  }
}
