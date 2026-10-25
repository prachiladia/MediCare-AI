const AppError = require("../utils/AppError");
const logger = require("../utils/logger");

/**
 * Express error-handling middleware (must have 4 args so Express
 * recognizes it as an error handler). Every controller either throws
 * an AppError or calls next(err), and it all funnels through here.
 *
 * This is what stops raw Firebase/Node stack traces or internal
 * details from ever reaching the mobile app.
 */
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  if (err instanceof AppError) {
    logger.warn(`Handled error: ${err.code}`, {
      path: req.path,
      method: req.method,
      message: err.message,
    });
    return res.status(err.statusCode).json({
      success: false,
      error: { code: err.code, message: err.message },
    });
  }

  // Unexpected/unhandled error - log full detail server-side only.
  logger.error("Unhandled server error", {
    path: req.path,
    method: req.method,
    message: err.message,
    stack: err.stack,
  });

  return res.status(500).json({
    success: false,
    error: {
      code: "INTERNAL_ERROR",
      message: "Something went wrong. Please try again later.",
    },
  });
}

function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    error: { code: "NOT_FOUND", message: `Route ${req.method} ${req.path} not found.` },
  });
}

module.exports = { errorHandler, notFoundHandler };
