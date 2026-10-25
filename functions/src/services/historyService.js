const { db } = require("../config/firebase");
const AppError = require("../utils/AppError");
const logger = require("../utils/logger");
const { getMedicine } = require("./medicineService");

const historyCollection = db.collection("medicineHistory");

function dateOnly(isoString) {
  return isoString.slice(0, 10); // "YYYY-MM-DD"
}

/**
 * Records a taken/missed/skipped event for a medicine dose.
 * Verifies the medicine belongs to this user first (getMedicine
 * throws 404 otherwise), so a history entry can never be created
 * against someone else's medicine.
 */
async function recordStatus(userId, medicineId, status, { scheduledTime, actualTime, note }) {
  await getMedicine(userId, medicineId);

  const entry = {
    userId,
    medicineId,
    status, // "taken" | "missed" | "skipped"
    scheduledTime,
    actualTime: status === "taken" ? actualTime : null,
    note: note || null,
    date: dateOnly(scheduledTime),
    createdAt: new Date().toISOString(),
  };

  const docRef = await historyCollection.add(entry);
  logger.info("History recorded", { userId, medicineId, status });
  return { id: docRef.id, ...entry };
}

async function getTodayStatus(userId, timezoneDateString) {
  // timezoneDateString: "YYYY-MM-DD" computed on the client/server for
  // the user's local day, since Firestore has no notion of timezone.
  const snapshot = await historyCollection
    .where("userId", "==", userId)
    .where("date", "==", timezoneDateString)
    .get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

/**
 * Flexible history query with optional filters, used by GET /history.
 */
async function getHistory(userId, { medicineId, status, startDate, endDate, limit = 50 } = {}) {
  let query = historyCollection.where("userId", "==", userId);

  if (medicineId) query = query.where("medicineId", "==", medicineId);
  if (status) query = query.where("status", "==", status);
  if (startDate) query = query.where("date", ">=", startDate);
  if (endDate) query = query.where("date", "<=", endDate);

  query = query.orderBy("date", "desc").limit(Math.min(limit, 200));

  const snapshot = await query.get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function getHistoryEntry(userId, historyId) {
  const doc = await historyCollection.doc(historyId).get();
  if (!doc.exists || doc.data().userId !== userId) {
    throw new AppError(404, "HISTORY_NOT_FOUND", "History entry not found.");
  }
  return { id: doc.id, ...doc.data() };
}

module.exports = {
  recordStatus,
  getTodayStatus,
  getHistory,
  getHistoryEntry,
};
