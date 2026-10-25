const Joi = require("joi");
const AppError = require("../utils/AppError");

const chatSchema = Joi.object({
  question: Joi.string().min(1).max(1000).required(),
  medicineId: Joi.string().max(128).allow(null, ""), // optional context: "ask about this specific medicine"
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
  validateChat: (payload) => validate(chatSchema, payload),
};
