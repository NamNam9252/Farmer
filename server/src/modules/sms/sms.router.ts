import { Router, Request, Response } from "express";
import { SMS } from "./sms.service";

const router = Router();

// endpoint: POST /api/v1/sms/receive
// set this full URL in httpSMS dashboard:
//   https://<your-ngrok-or-domain>/api/v1/sms/receive
router.post("/receive", async (req: Request, res: Response): Promise<void> => {
  // always ACK immediately — httpSMS will retry if it doesn't get 200
  res.sendStatus(200);

  const raw =
    (req.body?.content as string | undefined) ??
    (req.body?.data?.content as string | undefined);

  const from =
    (req.body?.from as string | undefined) ??
    (req.body?.contact as string | undefined) ??
    (req.body?.data?.contact as string | undefined);

  if (!raw || !from) {
    console.warn(
      "[SMS] Webhook called with missing fields. Expected content/from or data.content/data.contact:",
      req.body
    );
    return;
  }

  console.log(
    `[SMS] webhook field extraction succeeded | from=${from} rawChars=${raw.length} eventType=${String(req.body?.type ?? "unknown")}`
  );

  // normalize — ensure +91 prefix
  const normalized = from.startsWith("+") ? from : `+${from}`;

  await SMS.handleIncoming(raw, normalized);
});

export default router;
