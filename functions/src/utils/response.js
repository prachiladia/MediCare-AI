/**
 * Every endpoint responds using these helpers so the mobile app can
 * rely on one consistent JSON shape:
 *   success: { success: true, data: ... }
 *   error:   { success: false, error: { code, message } }
 */

function success(res, data, statusCode = 200) {
  return res.status(statusCode).json({ success: true, data });
}

function error(res, statusCode, code, message) {
  return res.status(statusCode).json({
    success: false,
    error: { code, message },
  });
}

module.exports = { success, error };
