const Joi = require("joi");
const AppError = require("../utils/AppError");

const registerSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).max(128).required(),
  displayName: Joi.string().min(1).max(80).required(),
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

const updateProfileSchema = Joi.object({
  displayName: Joi.string().min(1).max(80),
  phoneNumber: Joi.string()
    .pattern(/^\+?[0-9]{7,15}$/)
    .messages({ "string.pattern.base": "phoneNumber must be a valid phone number." }),
  timezone: Joi.string().max(64), // e.g. "Asia/Kolkata" - used to schedule reminders correctly
  fcmToken: Joi.string().max(4096), // device push token, updated whenever it refreshes
  dateOfBirth: Joi.string().isoDate(),
}).min(1);

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
  validateRegister: (payload) => validate(registerSchema, payload),
  validateLogin: (payload) => validate(loginSchema, payload),
  validateUpdateProfile: (payload) => validate(updateProfileSchema, payload),
};
