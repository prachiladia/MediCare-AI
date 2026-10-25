const fetch = require("node-fetch");
const { db } = require("../config/firebase");
const AppError = require("../utils/AppError");
const logger = require("../utils/logger");
const { getMedicine } = require("./medicineService");

const aiChatsCollection = db.collection("aiChats");

/**
 * System prompt that constrains the assistant. This is the main
 * safety control: it is set here, server-side, and is never sent
 * from or editable by the mobile app.
 */
const SYSTEM_PROMPT = `You are a helpful medication-reminder assistant inside the "AI Medicine Reminder" app.

Rules you must always follow:
- You are NOT a doctor, pharmacist, or medical professional, and you must never claim or imply that you are.
- You must never diagnose a condition, prescribe a medication, change a dosage, or tell a user to stop or start taking a medication.
- For any question involving specific medical advice, interactions, side effects, or dosing decisions, give general, widely known educational information only, and clearly recommend the user speak with their doctor or pharmacist for anything specific to their situation.
- If a user describes a medical emergency (e.g. severe allergic reaction, chest pain, difficulty breathing, overdose), tell them clearly to contact emergency services or a poison control center immediately.
- Keep answers short, clear, and easy to read on a phone screen.
- You may help with reminders, general medication information, adherence tips, and how to use this app.`;

/**
 * Very small keyword-based safety net for emergencies. This is not a
 * replacement for the system prompt, just an extra layer: it lets us
 * always show a consistent emergency banner even if the model's
 * wording varies.
 */
const EMERGENCY_KEYWORDS = [
  "overdose", "can't breathe", "cant breathe", "chest pain",
  "suicide", "unconscious", "severe allergic", "anaphylaxis",
];

function containsEmergencyKeyword(text) {
  const lower = text.toLowerCase();
  return EMERGENCY_KEYWORDS.some((k) => lower.includes(k));
}

/**
 * Calls the Anthropic API. The API key is read from an environment
 * variable / secret (see README "Environment Variables" section) and
 * is NEVER sent to or accessible from the mobile app - the app only
 * ever calls YOUR backend endpoint, which then calls Anthropic.
 */
async function callAiApi(question, contextNote) {
  const apiKey = process.env.AI_API_KEY;
  if (!apiKey) {
    throw new AppError(500, "CONFIG_ERROR", "AI assistant is not configured on the server.");
  }

  const userMessage = contextNote ? `${contextNote}\n\nUser question: ${question}` : question;

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-6",
      max_tokens: 500,
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: userMessage }],
    }),
  });

  if (!response.ok) {
    const errBody = await response.text();
    logger.error("AI API call failed", { status: response.status, errBody });
    throw new AppError(502, "AI_API_ERROR", "The AI assistant is temporarily unavailable. Please try again shortly.");
  }

  const data = await response.json();
  const textBlock = (data.content || []).find((b) => b.type === "text");
  return textBlock ? textBlock.text : "I'm sorry, I couldn't generate a response. Please try again.";
}

/**
 * Main entry point used by the controller.
 * 1. Validates the medicine belongs to the user, if medicineId given.
 * 2. Calls the AI API with a safety system prompt.
 * 3. Adds a safety disclaimer + emergency banner when relevant.
 * 4. Persists the Q&A to Firestore for the user's chat history.
 */
async function askAssistant(userId, { question, medicineId }) {
  let contextNote = "";
  if (medicineId) {
    const medicine = await getMedicine(userId, medicineId); // throws 404 if not owned
    contextNote = `The user is asking about their medicine "${medicine.name}" (dosage: ${medicine.dosage} ${medicine.dosageUnit}, frequency: ${medicine.frequency}). Do not assume any details not given here.`;
  }

  let answer;
  if (containsEmergencyKeyword(question)) {
    answer =
      "This sounds like it could be a medical emergency. Please contact your local emergency number or poison control immediately, or go to the nearest emergency room. I'm not able to help with emergencies - please seek immediate professional help.";
  } else {
    answer = await callAiApi(question, contextNote);
    answer += "\n\nThis is general information only, not medical advice. Please talk to your doctor or pharmacist about anything specific to your treatment.";
  }

  const record = {
    userId,
    medicineId: medicineId || null,
    question,
    answer,
    createdAt: new Date().toISOString(),
  };
  const docRef = await aiChatsCollection.add(record);
  logger.info("AI chat recorded", { userId, chatId: docRef.id });

  return { id: docRef.id, ...record };
}

async function getChatHistory(userId, { limit = 50 } = {}) {
  const snapshot = await aiChatsCollection
    .where("userId", "==", userId)
    .orderBy("createdAt", "desc")
    .limit(Math.min(limit, 100))
    .get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

module.exports = { askAssistant, getChatHistory };
