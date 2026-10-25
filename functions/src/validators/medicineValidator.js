const Joi = require("joi");
const AppError = require("../utils/AppError");

const timeSchema = Joi.string()
  .pattern(/^([01]\d|2[0-3]):([0-5]\d)$/)
  .messages({ "string.pattern.base": "Reminder time must be in HH:mm 24-hour format, e.g. 08:30." });

const createMedicineSchema = Joi.object({
  name: Joi.string().min(1).max(120).required(),
  dosage: Joi.number().positive().required(),
  dosageUnit: Joi.string()
    .valid("mg", "g", "ml", "mcg", "IU", "tablet", "capsule", "drop", "puff", "other")
    .required(),
  frequency: Joi.string()
    .valid("daily", "weekly", "specific_days", "as_needed")
    .required(),
  daysOfWeek: Joi.array()
    .items(Joi.string().valid("mon", "tue", "wed", "thu", "fri", "sat", "sun"))
    .when("frequency", {
      is: Joi.valid("weekly", "specific_days"),
      then: Joi.array().min(1).required(),
      otherwise: Joi.array().optional(),
    }),
  reminderTimes: Joi.array().items(timeSchema).min(1).required(),
  startDate: Joi.string().isoDate().required(),
  endDate: Joi.string().isoDate().allow(null),
  instructions: Joi.string().max(500).allow("", null),
  notes: Joi.string().max(1000).allow("", null),
  isActive: Joi.boolean().default(true),
})
  .custom((value, helpers) => {
    if (value.endDate && new Date(value.endDate) < new Date(value.startDate)) {
      return helpers.error("any.invalid", { message: "endDate cannot be before startDate." });
    }
    return value;
  }, "date range validation")
  .messages({ "any.invalid": "endDate cannot be before startDate." });

const updateMedicineSchema = Joi.object({
  name: Joi.string().min(1).max(120),
  dosage: Joi.number().positive(),
  dosageUnit: Joi.string().valid("mg", "g", "ml", "mcg", "IU", "tablet", "capsule", "drop", "puff", "other"),
  frequency: Joi.string().valid("daily", "weekly", "specific_days", "as_needed"),
  daysOfWeek: Joi.array().items(Joi.string().valid("mon", "tue", "wed", "thu", "fri", "sat", "sun")),
  reminderTimes: Joi.array().items(timeSchema).min(1),
  startDate: Joi.string().isoDate(),
  endDate: Joi.string().isoDate().allow(null),
  instructions: Joi.string().max(500).allow("", null),
  notes: Joi.string().max(1000).allow("", null),
  isActive: Joi.boolean(),
}).min(1);

const historyStatusSchema = Joi.object({
  scheduledTime: Joi.string().isoDate().required(),
  actualTime: Joi.string().isoDate().default(() => new Date().toISOString()),
  note: Joi.string().max(300).allow("", null),
});

function validate(schema, payload) {
  const { error, value } = schema.validate(payload, {
    abortEarly: false,
    stripUnknown: true,
  });
  if (error) {
    const message = error.details.map((d) => d.message).join(" ");
    throw new AppError(400, "VALIDATION_ERROR", message);
  }
  return value;
}

module.exports = {
  validateCreateMedicine: (payload) => validate(createMedicineSchema, payload),
  validateUpdateMedicine: (payload) => validate(updateMedicineSchema, payload),
  validateHistoryStatus: (payload) => validate(historyStatusSchema, payload),
};
