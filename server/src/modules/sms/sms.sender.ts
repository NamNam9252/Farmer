import axios from "axios";
import { SMSConfig } from "./sms.types";

const HTTPSMS_SEND_URL = "https://api.httpsms.com/v1/messages/send";

export class SMSSender {
  private readonly apiKey:    string;
  private readonly fromPhone: string;

  constructor(config: SMSConfig) {
    this.apiKey    = config.httpSmsApiKey;
    this.fromPhone = config.httpSmsFromPhone;
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
}
