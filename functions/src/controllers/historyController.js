const historyService = require("../services/historyService");
const { validateHistoryStatus } = require("../validators/medicineValidator");
const { success } = require("../utils/response");
const AppError = require("../utils/AppError");

async function markTaken(req, res, next) {
  try {
    const payload = validateHistoryStatus(req.body);
    const entry = await historyService.recordStatus(req.user.uid, req.params.id, "taken", payload);
    return success(res, entry, 201);
  } catch (err) {
    return next(err);
  }
}

async function markMissed(req, res, next) {
  try {
    const payload = validateHistoryStatus(req.body);
    const entry = await historyService.recordStatus(req.user.uid, req.params.id, "missed", payload);
    return success(res, entry, 201);
  } catch (err) {
    return next(err);
  }
}

async function markSkipped(req, res, next) {
  try {
    const payload = validateHistoryStatus(req.body);
    const entry = await historyService.recordStatus(req.user.uid, req.params.id, "skipped", payload);
    return success(res, entry, 201);
  } catch (err) {
    return next(err);
  }
}

async function getTodayStatus(req, res, next) {
  try {
    const { date } = req.query; // "YYYY-MM-DD", app computes this in the user's local timezone
    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      throw new AppError(400, "VALIDATION_ERROR", "Query param 'date' is required in YYYY-MM-DD format.");
    }
    const entries = await historyService.getTodayStatus(req.user.uid, date);
    return success(res, entries);
  } catch (err) {
    return next(err);
  }
}

async function getHistory(req, res, next) {
  try {
    const { medicineId, status, startDate, endDate, limit } = req.query;
    const entries = await historyService.getHistory(req.user.uid, {
      medicineId,
      status,
      startDate,
      endDate,
      limit: limit ? Number(limit) : undefined,
    });
    return success(res, entries);
  } catch (err) {
    return next(err);
  }
}

module.exports = { markTaken, markMissed, markSkipped, getTodayStatus, getHistory };
