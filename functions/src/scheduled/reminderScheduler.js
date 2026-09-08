const { onSchedule } = require("firebase-functions/v2/scheduler");
const { db } = require("../config/firebase");
const { sendReminderNotification } = require("../services/notificationService");
const { recordStatus } = require("../services/historyService");
const logger = require("../utils/logger");

const DAY_KEYS = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];

/**
 * Runs every 5 minutes.
 *
 * WHY POLLING INSTEAD OF "TRUE" SCHEDULING:
 * Firebase/FCM has no built-in way to say "deliver this notification
 * at exactly 08:30 in the user's timezone, every day, forever."
 * The standard, correct Firebase pattern is a Cloud Scheduler job
 * (via `onSchedule`) that runs frequently and checks: "which active
 * medicines have a reminderTime that falls in the last 5 minutes,
 * for a user whose LOCAL time is currently in that window?" This
 * keeps things simple and reliable at the cost of ~5 min precision,
 * which is normally fine for medicine reminders.
 *
 * For higher precision (exact-minute delivery) you'd instead create
 * one Cloud Task per reminder occurrence via Cloud Tasks, but that
 * adds real complexity - start with this polling approach.
 */
const checkReminders = onSchedule(
  { schedule: "every 5 minutes", timeZone: "UTC", region: "us-central1" },
  async () => {
    const now = new Date();
    const nowMinusWindow = new Date(now.getTime() - 5 * 60 * 1000);

    const snapshot = await db.collection("medicines").where("isActive", "==", true).get();
    logger.info("Reminder check started", { activeMedicineCount: snapshot.size });

    let sent = 0;

    for (const doc of snapshot.docs) {
      const medicine = doc.data();
      const medicineId = doc.id;

      // Respect start/end date window.
      if (medicine.startDate && new Date(medicine.startDate) > now) continue;
      if (medicine.endDate && new Date(medicine.endDate) < now) continue;

      // Load the owner to get their timezone (default UTC).
      const userDoc = await db.collection("users").doc(medicine.userId).get();
      if (!userDoc.exists) continue;
      const timezone = userDoc.data().timezone || "UTC";

      const localNow = new Date(now.toLocaleString("en-US", { timeZone: timezone }));
      const localWindowStart = new Date(nowMinusWindow.toLocaleString("en-US", { timeZone: timezone }));
      const currentDayKey = DAY_KEYS[localNow.getDay()];

      if (medicine.frequency === "weekly" || medicine.frequency === "specific_days") {
        if (!medicine.daysOfWeek || !medicine.daysOfWeek.includes(currentDayKey)) continue;
      }
      if (medicine.frequency === "as_needed") continue; // no fixed reminder

      for (const time of medicine.reminderTimes || []) {
        const [hh, mm] = time.split(":").map(Number);
        const scheduled = new Date(localNow);
        scheduled.setHours(hh, mm, 0, 0);

        const isDue = scheduled > localWindowStart && scheduled <= localNow;
        if (!isDue) continue;

        await sendReminderNotification({
          userId: medicine.userId,
          medicineId,
          medicineName: medicine.name,
          dosage: medicine.dosage,
          dosageUnit: medicine.dosageUnit,
          scheduledTime: scheduled.toISOString(),
        });

        // Pre-create a "pending" history entry so the app can show
        // this dose as awaiting action; the user (or a later missed
        // sweep) updates it to taken/missed/skipped.
        await recordStatus(medicine.userId, medicineId, "pending", {
          scheduledTime: scheduled.toISOString(),
          actualTime: null,
          note: null,
        }).catch((err) => logger.error("Failed to pre-create history entry", { message: err.message }));

        sent += 1;
      }
    }

    logger.info("Reminder check finished", { notificationsSent: sent });
  }
);

module.exports = { checkReminders };
