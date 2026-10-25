/**
 * Central Firebase Admin SDK initialization.
 * Every other file imports `admin`, `db`, `auth`, and `messaging` from here
 * instead of calling admin.initializeApp() themselves, so we only ever
 * initialize the app once.
 */
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();
const messaging = admin.messaging();

// Reasonable Firestore settings for a Cloud Functions environment.
db.settings({ ignoreUndefinedProperties: true });

module.exports = { admin, db, auth, messaging };
