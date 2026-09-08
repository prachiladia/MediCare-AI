const { db, auth } = require("../config/firebase");
const AppError = require("../utils/AppError");
const logger = require("../utils/logger");

const usersCollection = db.collection("users");

/**
 * Registers a new user.
 *
 * NOTE on architecture: Firebase Auth account creation (email+password)
 * is normally done directly from the mobile app using the Firebase
 * Auth SDK (createUserWithEmailAndPassword) - that's the standard,
 * recommended pattern and avoids ever handling raw passwords on your
 * server. This backend function exists for two reasons:
 *   1. It lets you create the account from a trusted server context
 *      (e.g. admin invite flows, or if you want one API call to do
 *      both auth + profile creation).
 *   2. It always creates the matching Firestore profile document,
 *      keeping Auth and Firestore in sync.
 *
 * See README "Frontend Connection" for the alternative (recommended)
 * client-side flow, which calls `createUserProfile` after signing up
 * directly with the Firebase client SDK.
 */
async function registerUser({ email, password, displayName }) {
  let userRecord;
  try {
    userRecord = await auth.createUser({ email, password, displayName });
  } catch (err) {
    if (err.code === "auth/email-already-exists") {
      throw new AppError(409, "EMAIL_IN_USE", "An account with this email already exists.");
    }
    logger.error("Failed to create auth user", { message: err.message });
    throw new AppError(500, "AUTH_CREATE_FAILED", "Could not create account. Please try again.");
  }

  const profile = await createUserProfile(userRecord.uid, { email, displayName });
  return { uid: userRecord.uid, ...profile };
}

/**
 * Creates the Firestore profile document for a user. Called either
 * right after registerUser() above, or by the client immediately
 * after it creates the Firebase Auth account itself.
 */
async function createUserProfile(uid, { email, displayName }) {
  const docRef = usersCollection.doc(uid);
  const existing = await docRef.get();
  if (existing.exists) {
    throw new AppError(409, "PROFILE_EXISTS", "A profile already exists for this account.");
  }

  const profile = {
    uid,
    email,
    displayName: displayName || "",
    phoneNumber: null,
    timezone: "UTC",
    fcmToken: null,
    dateOfBirth: null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  await docRef.set(profile);
  logger.info("User profile created", { uid });
  return profile;
}

async function getUserProfile(uid) {
  const doc = await usersCollection.doc(uid).get();
  if (!doc.exists) {
    throw new AppError(404, "PROFILE_NOT_FOUND", "User profile not found.");
  }
  return doc.data();
}

async function updateUserProfile(uid, updates) {
  const docRef = usersCollection.doc(uid);
  const doc = await docRef.get();
  if (!doc.exists) {
    throw new AppError(404, "PROFILE_NOT_FOUND", "User profile not found.");
  }

  const payload = { ...updates, updatedAt: new Date().toISOString() };
  await docRef.update(payload);
  const updated = await docRef.get();
  return updated.data();
}

/**
 * Deletes a user's Firebase Auth account AND all of their Firestore
 * data. This is a destructive, irreversible operation, so it deletes
 * medicines, history, notifications, and AI chats for the user too
 * (otherwise you'd leave orphaned data behind forever).
 */
async function deleteUserAccount(uid) {
  const batchDeleteCollection = async (collectionName) => {
    const snapshot = await db.collection(collectionName).where("userId", "==", uid).get();
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    if (!snapshot.empty) await batch.commit();
    return snapshot.size;
  };

  const deletedCounts = {
    medicines: await batchDeleteCollection("medicines"),
    medicineHistory: await batchDeleteCollection("medicineHistory"),
    notifications: await batchDeleteCollection("notifications"),
    aiChats: await batchDeleteCollection("aiChats"),
  };

  await usersCollection.doc(uid).delete();

  try {
    await auth.deleteUser(uid);
  } catch (err) {
    logger.error("Failed to delete auth user after deleting Firestore data", {
      uid,
      message: err.message,
    });
    throw new AppError(500, "ACCOUNT_DELETE_FAILED", "Account data was removed but the login could not be fully deleted. Please contact support.");
  }

  logger.info("User account deleted", { uid, deletedCounts });
  return deletedCounts;
}

/**
 * Logs a user in with email + password.
 *
 * IMPORTANT LIMITATION: The Firebase Admin SDK cannot verify a
 * password - only the Identity Platform REST API (or the client SDK)
 * can. This function calls that REST endpoint from the server using
 * your Firebase Web API key (safe to use server-side; it is NOT a
 * secret admin credential, just identifies your Firebase project).
 *
 * RECOMMENDED APPROACH: in almost all cases you should instead call
 * `signInWithEmailAndPassword()` directly from the mobile app using
 * the Firebase Auth SDK. That is faster (no extra network hop through
 * your backend) and is the standard Firebase pattern. This function
 * is provided so you have a working server-side option too (e.g. for
 * testing with curl/Postman, or a future admin panel).
 */
const fetch = require("node-fetch");

async function loginUser({ email, password }) {
  const apiKey = process.env.FIREBASE_WEB_API_KEY;
  if (!apiKey) {
    throw new AppError(500, "CONFIG_ERROR", "Server is not configured for server-side login.");
  }

  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const body = await res.json();

  if (!res.ok) {
    logger.warn("Login failed", { message: body.error && body.error.message });
    throw new AppError(401, "INVALID_CREDENTIALS", "Incorrect email or password.");
  }

  return {
    uid: body.localId,
    idToken: body.idToken,
    refreshToken: body.refreshToken,
    expiresIn: body.expiresIn,
  };
}

module.exports = {
  registerUser,
  createUserProfile,
  getUserProfile,
  updateUserProfile,
  deleteUserAccount,
  loginUser,
};
