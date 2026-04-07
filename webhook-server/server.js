const express = require("express");
const crypto = require("crypto");
const { execSync } = require("child_process");

const app = express();
const PORT = process.env.PORT || 3000;
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;
const SITE_DIR = process.env.SITE_DIR || "/site";

if (!WEBHOOK_SECRET) {
  console.error("WEBHOOK_SECRET is required. Set it in your .env file.");
  process.exit(1);
}

app.use(express.json());

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "naibor-webhook" });
});

// Webhook endpoint — n8n sends POST here with the secret
app.post("/webhook/deploy", (req, res) => {
  const providedSecret = req.headers["x-webhook-secret"] || req.body.secret;

  if (!providedSecret) {
    return res.status(401).json({ error: "Missing secret" });
  }

  const valid = crypto.timingSafeEqual(
    Buffer.from(providedSecret),
    Buffer.from(WEBHOOK_SECRET)
  );

  if (!valid) {
    return res.status(403).json({ error: "Invalid secret" });
  }

  console.log(`[${new Date().toISOString()}] Webhook received — pulling latest`);

  try {
    const output = execSync(`cd ${SITE_DIR} && git pull origin main`, {
      encoding: "utf-8",
      timeout: 30000,
    });
    console.log("Git pull output:", output);
    res.json({ status: "deployed", output: output.trim() });
  } catch (err) {
    console.error("Deploy failed:", err.message);
    res.status(500).json({ error: "Deploy failed", details: err.message });
  }
});

// Webhook endpoint for n8n to call with custom actions
app.post("/webhook/notify", (req, res) => {
  const providedSecret = req.headers["x-webhook-secret"] || req.body.secret;

  if (
    !providedSecret ||
    !crypto.timingSafeEqual(
      Buffer.from(providedSecret),
      Buffer.from(WEBHOOK_SECRET)
    )
  ) {
    return res.status(403).json({ error: "Unauthorized" });
  }

  const { action, payload } = req.body;
  console.log(`[${new Date().toISOString()}] Action: ${action}`, payload || "");
  res.json({ status: "received", action });
});

app.listen(PORT, () => {
  console.log(`Webhook server listening on port ${PORT}`);
  console.log(`Deploy endpoint: POST http://localhost:${PORT}/webhook/deploy`);
  console.log(`Notify endpoint: POST http://localhost:${PORT}/webhook/notify`);
});
