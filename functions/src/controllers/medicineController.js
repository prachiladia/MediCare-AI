const medicineService = require("../services/medicineService");
const { validateCreateMedicine, validateUpdateMedicine } = require("../validators/medicineValidator");
const { success } = require("../utils/response");

async function createMedicine(req, res, next) {
  try {
    const payload = validateCreateMedicine(req.body);
    const medicine = await medicineService.createMedicine(req.user.uid, payload);
    return success(res, medicine, 201);
  } catch (err) {
    return next(err);
  }
}

async function listMedicines(req, res, next) {
  try {
    const activeOnly =
      req.query.activeOnly === "true" ? true : req.query.activeOnly === "false" ? false : undefined;
    const medicines = await medicineService.listMedicines(req.user.uid, { activeOnly });
    return success(res, medicines);
  } catch (err) {
    return next(err);
  }
}

async function getMedicine(req, res, next) {
  try {
    const medicine = await medicineService.getMedicine(req.user.uid, req.params.id);
    return success(res, medicine);
  } catch (err) {
    return next(err);
  }
}

async function updateMedicine(req, res, next) {
  try {
    const updates = validateUpdateMedicine(req.body);
    const medicine = await medicineService.updateMedicine(req.user.uid, req.params.id, updates);
    return success(res, medicine);
  } catch (err) {
    return next(err);
  }
}

async function deleteMedicine(req, res, next) {
  try {
    const result = await medicineService.deleteMedicine(req.user.uid, req.params.id);
    return success(res, result);
  } catch (err) {
    return next(err);
  }
}

module.exports = { createMedicine, listMedicines, getMedicine, updateMedicine, deleteMedicine };
