const { db } = require("../config/firebase");
const AppError = require("../utils/AppError");
const logger = require("../utils/logger");

const medicinesCollection = db.collection("medicines");

/**
 * Every function in this service takes `userId` explicitly and it is
 * always the uid from the verified auth token (never from the request
 * body). This is the second half of the "users can't touch each
 * other's data" guarantee - the first half is the Firestore security
 * rules, this is the same guarantee enforced in the API layer too
 * (defense in depth).
 */

async function createMedicine(userId, data) {
  const now = new Date().toISOString();
  const medicine = {
    ...data,
    userId,
    createdAt: now,
    updatedAt: now,
  };
  const docRef = await medicinesCollection.add(medicine);
  logger.info("Medicine created", { userId, medicineId: docRef.id });
  return { id: docRef.id, ...medicine };
}

async function getMedicine(userId, medicineId) {
  const doc = await medicinesCollection.doc(medicineId).get();
  if (!doc.exists) {
    throw new AppError(404, "MEDICINE_NOT_FOUND", "Medicine not found.");
  }
  if (doc.data().userId !== userId) {
    // Deliberately the same error as "not found" - never reveal that
    // a medicine exists but belongs to someone else.
    throw new AppError(404, "MEDICINE_NOT_FOUND", "Medicine not found.");
  }
  return { id: doc.id, ...doc.data() };
}

async function listMedicines(userId, { activeOnly } = {}) {
  let query = medicinesCollection.where("userId", "==", userId);
  if (activeOnly !== undefined) {
    query = query.where("isActive", "==", activeOnly);
  }
  query = query.orderBy("createdAt", "desc");
  const snapshot = await query.get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function updateMedicine(userId, medicineId, updates) {
  await getMedicine(userId, medicineId); // throws 404 if missing or not owned
  const payload = { ...updates, updatedAt: new Date().toISOString() };
  await medicinesCollection.doc(medicineId).update(payload);
  logger.info("Medicine updated", { userId, medicineId });
  return getMedicine(userId, medicineId);
}

async function deleteMedicine(userId, medicineId) {
  await getMedicine(userId, medicineId); // throws 404 if missing or not owned
  await medicinesCollection.doc(medicineId).delete();
  logger.info("Medicine deleted", { userId, medicineId });
  return { id: medicineId, deleted: true };
}

module.exports = {
  createMedicine,
  getMedicine,
  listMedicines,
  updateMedicine,
  deleteMedicine,
};
