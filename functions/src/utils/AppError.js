/**
 * A predictable error type that controllers/services can throw.
 * The central error handler middleware knows how to turn these into
 * clean JSON responses without leaking internal stack traces.
 */
class AppError extends Error {
  constructor(statusCode, code, message) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true; // distinguishes "expected" errors from bugs
  }
}

module.exports = AppError;
