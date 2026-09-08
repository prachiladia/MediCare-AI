/**
 * Verifies that protected routes reject requests with no/invalid
 * auth token, WITHOUT needing a real Firebase project. We mock
 * firebase-admin so this runs anywhere, instantly.
 */
jest.mock("firebase-admin", () => {
  const verifyIdToken = jest.fn().mockRejectedValue({ code: "auth/argument-error" });
  return {
    apps: [],
    initializeApp: jest.fn(),
    firestore: () => ({ settings: jest.fn(), collection: jest.fn() }),
    auth: () => ({ verifyIdToken }),
    messaging: () => ({}),
  };
});

const request = require("supertest");
const express = require("express");
const requireAuth = require("../src/middleware/authMiddleware");
const { errorHandler } = require("../src/middleware/errorHandler");

function buildTestApp() {
  const app = express();
  app.use(express.json());
  app.get("/medicines", requireAuth, (req, res) => res.json({ success: true, data: [] }));
  app.use(errorHandler);
  return app;
}

describe("requireAuth middleware", () => {
  const app = buildTestApp();

  test("rejects requests with no Authorization header", async () => {
    const res = await request(app).get("/medicines");
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("UNAUTHORIZED");
  });

  test("rejects requests with malformed Authorization header", async () => {
    const res = await request(app).get("/medicines").set("Authorization", "Token abc123");
    expect(res.status).toBe(401);
  });

  test("rejects requests with an invalid token", async () => {
    const res = await request(app).get("/medicines").set("Authorization", "Bearer not-a-real-token");
    expect(res.status).toBe(401);
  });
});
