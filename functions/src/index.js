const express = require("express");
const cors = require("cors");
const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");

require("./config/firebase"); // initializes admin SDK exactly once

const requireAuth = require("./middleware/authMiddleware");
const { errorHandler, notFoundHandler } = require("./middleware/errorHandler");
const { generalLimiter, aiLimiter, authLimiter } = require("./middleware/rateLimiter");

const authController = require("./controllers/authController");
const medicineController = require("./controllers/medicineController");
const historyController = require("./controllers/historyController");
const aiController = require("./controllers/aiController");

setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: "1mb" }));

// ---------------------------------------------------------------
// Health check (useful for uptime checks / quick manual testing)
// ---------------------------------------------------------------
app.get("/health", (req, res) => res.json({ success: true, data: { status: "ok" } }));

// ---------------------------------------------------------------
// Auth routes
// register/login are public (no token yet); everything else requires it.
// ---------------------------------------------------------------
app.post("/auth/register", authLimiter, authController.register);
app.post("/auth/login", authLimiter, authController.login);
app.post("/auth/logout", requireAuth, generalLimiter, authController.logout);
app.get("/auth/profile", requireAuth, generalLimiter, authController.getProfile);
app.put("/auth/profile", requireAuth, generalLimiter, authController.updateProfile);
app.delete("/auth/account", requireAuth, generalLimiter, authController.deleteAccount);

// ---------------------------------------------------------------
// Medicine CRUD routes - all require auth
// ---------------------------------------------------------------
app.post("/medicines", requireAuth, generalLimiter, medicineController.createMedicine);
app.get("/medicines", requireAuth, generalLimiter, medicineController.listMedicines);
app.get("/medicines/:id", requireAuth, generalLimiter, medicineController.getMedicine);
app.put("/medicines/:id", requireAuth, generalLimiter, medicineController.updateMedicine);
app.delete("/medicines/:id", requireAuth, generalLimiter, medicineController.deleteMedicine);

// ---------------------------------------------------------------
// Taken / missed / skipped + history routes
// ---------------------------------------------------------------
app.post("/medicines/:id/taken", requireAuth, generalLimiter, historyController.markTaken);
app.post("/medicines/:id/missed", requireAuth, generalLimiter, historyController.markMissed);
app.post("/medicines/:id/skipped", requireAuth, generalLimiter, historyController.markSkipped);
app.get("/history/today", requireAuth, generalLimiter, historyController.getTodayStatus);
app.get("/history", requireAuth, generalLimiter, historyController.getHistory);

// ---------------------------------------------------------------
// AI assistant routes - tighter rate limit, external API cost
// ---------------------------------------------------------------
app.post("/ai/chat", requireAuth, aiLimiter, aiController.chat);
app.get("/ai/chat/history", requireAuth, generalLimiter, aiController.getChatHistory);

// 404 + centralized error handler must be registered last, in this order.
app.use(notFoundHandler);
app.use(errorHandler);

/**
 * Exposes the whole Express app as ONE Cloud Function ("api").
 * The mobile app calls, e.g.:
 *   https://us-central1-<project-id>.cloudfunctions.net/api/medicines
 *
 * WHY ONE FUNCTION INSTEAD OF MANY: bundling all REST routes into a
 * single Express app means one cold start serves any route, is
 * simpler to reason about and deploy, and is the recommended pattern
 * for REST-style Firebase backends. If you later want per-endpoint
 * scaling/config you can always split hot routes into their own
 * onRequest functions.
 */
exports.api = onRequest(app);

// Scheduled Cloud Function for reminders (separate export, not part
// of the Express app since it's not an HTTP route).
exports.checkReminders = require("./scheduled/reminderScheduler").checkReminders;
