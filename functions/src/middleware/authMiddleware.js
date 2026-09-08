const { auth } = require("../config/firebase");
const AppError = require("../utils/AppError");
const logger = require("../utils/logger");

/**
 * Verifies the Firebase ID token sent by the mobile app in the
 * `Authorization: Bearer <idToken>` header.
 *
 * The mobile app gets this token from the Firebase Auth SDK after
 * sign-in (see README "Frontend Connection" section). This function
 * NEVER trusts a userId sent in the request body/params - the uid
 * always comes from the verified token. This is what prevents one
 * user from ever touching another user's data.
 */
async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    const [scheme, token] = header.split(" ");

    if (scheme !== "Bearer" || !token) {
      throw new AppError(401, "UNAUTHORIZED", "Missing or malformed Authorization header.");
    }

    const decoded = await auth.verifyIdToken(token, true /* checkRevoked */);

    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      emailVerified: decoded.email_verified,
    };

    next();
  } catch (err) {
    if (err instanceof AppError) return next(err);

    logger.warn("Token verification failed", { message: err.message });

    if (err.code === "auth/id-token-expired") {
      return next(new AppError(401, "TOKEN_EXPIRED", "Session expired. Please log in again."));
    }
    if (err.code === "auth/id-token-revoked") {
      return next(new AppError(401, "TOKEN_REVOKED", "Session revoked. Please log in again."));
    }
    return next(new AppError(401, "UNAUTHORIZED", "Invalid authentication token."));
  }
}

module.exports = requireAuth;
