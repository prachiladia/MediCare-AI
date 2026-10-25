const aiService = require("../services/aiService");
const { validateChat } = require("../validators/aiValidator");
const { success } = require("../utils/response");

async function chat(req, res, next) {
  try {
    const payload = validateChat(req.body);
    const result = await aiService.askAssistant(req.user.uid, payload);
    return success(res, result, 201);
  } catch (err) {
    return next(err);
  }
}

async function getChatHistory(req, res, next) {
  try {
    const { limit } = req.query;
    const history = await aiService.getChatHistory(req.user.uid, { limit: limit ? Number(limit) : undefined });
    return success(res, history);
  } catch (err) {
    return next(err);
  }
}

module.exports = { chat, getChatHistory };
