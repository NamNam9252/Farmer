import { Router, Request, Response } from "express";
import { SMS } from "./sms.service";

const router = Router();

// endpoint: POST /api/v1/sms/receive
// set this full URL in httpSMS dashboard:
//   https://<your-ngrok-or-domain>/api/v1/sms/receive
router.post("/receive", async (req: Request, res: Response): Promise<void> => {
  // always ACK immediately — httpSMS will retry if it doesn't get 200
  res.sendStatus(200);

  const raw  = req.body?.content as string | undefined;
  const from = req.body?.from    as string | undefined;

  if (!raw || !from) {
    console.warn("[SMS] Webhook called with missing fields:", req.body);
    return;
  }

  // normalize — ensure +91 prefix
  const normalized = from.startsWith("+") ? from : `+${from}`;

  await SMS.handleIncoming(raw, normalized);
});

export default router;
