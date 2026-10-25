const { db, messaging } = require("../config/firebase");
const logger = require("../utils/logger");

const notificationsCollection = db.collection("notifications");
const usersCollection = db.collection("users");

/**
 * Sends a push notification to a user's device via FCM, and also
 * writes a record to notifications/{id} so the app can show an
 * in-app notification history/inbox.
 *
 * FCM LIMITATION: FCM does not schedule notifications for the
 * future by itself - it only sends immediately. To get a
 * notification to fire "at 8:00 AM daily", we run a Cloud Scheduler
 * job (see scheduled/reminderScheduler.js) every few minutes that
 * checks which reminders are due *right now* and calls this function.
 * This is the standard, correct pattern for Firebase; there is no
 * built-in "send later" feature.
 */
async function sendReminderNotification({ userId, medicineId, medicineName, dosage, dosageUnit, scheduledTime }) {
  const userDoc = await usersCollection.doc(userId).get();
  if (!userDoc.exists) {
    logger.warn("Skipping notification: user not found", { userId });
    return null;
  }

  const { fcmToken } = userDoc.data();

  const notification = {
    userId,
    medicineId,
    title: "Medicine reminder",
    body: `Time to take ${medicineName} (${dosage} ${dosageUnit})`,
    scheduledFor: scheduledTime,
    read: false,
    readAt: null,
    delivered: false,
    createdAt: new Date().toISOString(),
  };

  const docRef = await notificationsCollection.add(notification);

  if (!fcmToken) {
    logger.warn("User has no FCM token registered; notification saved but not pushed", { userId });
    return { id: docRef.id, ...notification };
  }

  try {
    await messaging.send({
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        type: "MEDICINE_REMINDER",
        medicineId,
        notificationId: docRef.id,
      },
      android: { priority: "high" },
      apns: { headers: { "apns-priority": "10" } },
    });
    await docRef.update({ delivered: true });
    logger.info("Reminder notification sent", { userId, medicineId });
  } catch (err) {
    logger.error("FCM send failed", { userId, medicineId, message: err.message, code: err.code });
    // Common cause: the fcmToken is stale/unregistered. Clear it so
    // we stop trying to push to a dead token.
    if (err.code === "messaging/registration-token-not-registered") {
      await usersCollection.doc(userId).update({ fcmToken: null });
    }
  }

  return { id: docRef.id, ...notification };
}

module.exports = { sendReminderNotification };
