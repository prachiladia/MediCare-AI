/**
 * Thin wrapper around firebase-functions logger.
 * Centralizing logging here means:
 *  1. We never accidentally log secrets (API keys, passwords) because
 *     every log call goes through `sanitize()`.
 *  2. Logs show up correctly in Firebase / Google Cloud Logging with
 *     the right severity level.
 */
const functionsLogger = require("firebase-functions/logger");

const SENSITIVE_KEYS = [
  "password",
  "apiKey",
  "api_key",
  "token",
  "secret",
  "authorization",
  "idToken",
  "refreshToken",
];

function sanitize(payload) {
  if (!payload || typeof payload !== "object") return payload;
  const clone = Array.isArray(payload) ? [...payload] : { ...payload };
  for (const key of Object.keys(clone)) {
    if (SENSITIVE_KEYS.some((s) => key.toLowerCase().includes(s.toLowerCase()))) {
      clone[key] = "[REDACTED]";
    } else if (typeof clone[key] === "object" && clone[key] !== null) {
      clone[key] = sanitize(clone[key]);
    }
  }
  return clone;
}

module.exports = {
  info: (message, data) => functionsLogger.info(message, sanitize(data)),
  warn: (message, data) => functionsLogger.warn(message, sanitize(data)),
  error: (message, data) => functionsLogger.error(message, sanitize(data)),
  debug: (message, data) => functionsLogger.debug(message, sanitize(data)),
};
