import { Router, Request, Response } from "express";
import { SMS } from "./sms.service";

const router = Router();

// endpoint: POST /api/v1/sms/receive
// set this full URL in httpSMS dashboard:
//   https://<your-ngrok-or-domain>/api/v1/sms/receive
router.post("/receive", async (req: Request, res: Response): Promise<void> => {
  // always ACK immediately — httpSMS will retry if it doesn't get 200
  res.sendStatus(200);

  // httpSMS can send either flat payload or CloudEvents-style payload in `data`.
  const eventData = req.body?.data ?? req.body;
  const raw = (eventData?.content ?? req.body?.content) as string | undefined;
  const from = (
    eventData?.contact ??
    eventData?.from ??
    req.body?.from ??
    req.body?.contact
  ) as string | undefined;

  console.log(
    `[SMS] Webhook received | eventType=${req.body?.type ?? "unknown"} | hasData=${Boolean(req.body?.data)} | contentChars=${raw?.length ?? 0} | from=${from ?? "missing"}`
  );

  if (!raw || !from) {
    console.warn("[SMS] Webhook called with missing fields:", req.body);
    return;
  }

  // normalize — ensure +91 prefix
  const normalized = from.startsWith("+") ? from : `+${from}`;

  console.log(`[SMS] Webhook parsed | from=${normalized} | rawChars=${raw.length}`);

  // Process asynchronously after immediate ACK to keep webhook snappy.
  void SMS.handleIncoming(raw, normalized).catch((err) => {
    console.error(`[SMS] Async handleIncoming failed for ${normalized}:`, err);
  });
});

export default router;
