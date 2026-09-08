const authService = require("../services/authService");
const { validateRegister, validateLogin, validateUpdateProfile } = require("../validators/userValidator");
const { success } = require("../utils/response");

async function register(req, res, next) {
  try {
    const payload = validateRegister(req.body);
    const user = await authService.registerUser(payload);
    return success(res, user, 201);
  } catch (err) {
    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const payload = validateLogin(req.body);
    const session = await authService.loginUser(payload);
    return success(res, session, 200);
  } catch (err) {
    return next(err);
  }
}

/**
 * "Logout" for Firebase ID-token auth is primarily a client-side
 * action (the app deletes/forgets the token and calls
 * firebase.auth().signOut()). This endpoint additionally revokes all
 * refresh tokens server-side so the user's existing sessions on
 * other devices are invalidated too - useful for a "log out
 * everywhere" / security feature.
 */
async function logout(req, res, next) {
  try {
    const { auth } = require("../config/firebase");
    await auth.revokeRefreshTokens(req.user.uid);
    return success(res, { message: "Logged out. All sessions revoked." });
  } catch (err) {
    return next(err);
  }
}

async function getProfile(req, res, next) {
  try {
    const profile = await authService.getUserProfile(req.user.uid);
    return success(res, profile);
  } catch (err) {
    return next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const updates = validateUpdateProfile(req.body);
    const profile = await authService.updateUserProfile(req.user.uid, updates);
    return success(res, profile);
  } catch (err) {
    return next(err);
  }
}

async function deleteAccount(req, res, next) {
  try {
    const result = await authService.deleteUserAccount(req.user.uid);
    return success(res, { message: "Account deleted.", ...result });
  } catch (err) {
    return next(err);
  }
}

module.exports = { register, login, logout, getProfile, updateProfile, deleteAccount };
