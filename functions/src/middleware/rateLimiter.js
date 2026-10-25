const rateLimit = require("express-rate-limit");

/**
 * General API rate limit - generous, just to stop abuse/bugs from
 * hammering Firestore.
 * Keyed by the authenticated user's uid when available, falling back
 * to IP for unauthenticated routes (e.g. register/login).
 */
const generalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => (req.user && req.user.uid) || req.ip,
  message: {
    success: false,
    error: { code: "RATE_LIMITED", message: "Too many requests. Please slow down." },
  },
});

/**
 * The AI assistant endpoint calls a paid, external AI API, so it
 * gets a much tighter limit to control cost and prevent abuse.
 */
const aiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 8,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => (req.user && req.user.uid) || req.ip,
  message: {
    success: false,
    error: {
      code: "AI_RATE_LIMITED",
      message: "You're sending questions too quickly. Please wait a moment and try again.",
    },
  },
});

/** Stricter limiter for unauthenticated auth endpoints (register/login) to slow brute force. */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.ip,
  message: {
    success: false,
    error: { code: "AUTH_RATE_LIMITED", message: "Too many attempts. Please try again later." },
  },
});

module.exports = { generalLimiter, aiLimiter, authLimiter };
