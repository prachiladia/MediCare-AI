/**
 * These tests cover pure validation logic (no Firebase needed), so
 * they run fast and don't require the emulator. Run with `npm test`.
 *
 * For full integration tests (real Firestore reads/writes, auth
 * tokens, etc.) run the Firebase emulator first:
 *   firebase emulators:start --only functions,firestore,auth
 * and see README "Testing" section for example curl requests against
 * the emulator, which cover the end-to-end flows these unit tests
 * intentionally don't.
 */
const { validateCreateMedicine, validateUpdateMedicine } = require("../src/validators/medicineValidator");
const { validateRegister, validateLogin } = require("../src/validators/userValidator");
const { validateChat } = require("../src/validators/aiValidator");

describe("medicineValidator", () => {
  test("accepts a valid daily medicine", () => {
    const value = validateCreateMedicine({
      name: "Metformin",
      dosage: 500,
      dosageUnit: "mg",
      frequency: "daily",
      reminderTimes: ["08:00", "20:00"],
      startDate: "2026-01-01",
    });
    expect(value.name).toBe("Metformin");
    expect(value.reminderTimes).toHaveLength(2);
  });

  test("rejects missing required fields", () => {
    expect(() => validateCreateMedicine({ name: "Metformin" })).toThrow(/VALIDATION_ERROR|required/i);
  });

  test("rejects invalid reminder time format", () => {
    expect(() =>
      validateCreateMedicine({
        name: "Metformin",
        dosage: 500,
        dosageUnit: "mg",
        frequency: "daily",
        reminderTimes: ["8am"],
        startDate: "2026-01-01",
      })
    ).toThrow();
  });

  test("rejects endDate before startDate", () => {
    expect(() =>
      validateCreateMedicine({
        name: "Metformin",
        dosage: 500,
        dosageUnit: "mg",
        frequency: "daily",
        reminderTimes: ["08:00"],
        startDate: "2026-05-01",
        endDate: "2026-01-01",
      })
    ).toThrow();
  });

  test("requires daysOfWeek for weekly frequency", () => {
    expect(() =>
      validateCreateMedicine({
        name: "Vitamin D",
        dosage: 1,
        dosageUnit: "tablet",
        frequency: "weekly",
        reminderTimes: ["09:00"],
        startDate: "2026-01-01",
      })
    ).toThrow();
  });

  test("update schema requires at least one field", () => {
    expect(() => validateUpdateMedicine({})).toThrow();
  });
});

describe("userValidator", () => {
  test("accepts valid registration", () => {
    const value = validateRegister({
      email: "user@example.com",
      password: "supersecret123",
      displayName: "Jamie",
    });
    expect(value.email).toBe("user@example.com");
  });

  test("rejects short password", () => {
    expect(() =>
      validateRegister({ email: "user@example.com", password: "short", displayName: "Jamie" })
    ).toThrow();
  });

  test("rejects invalid email on login", () => {
    expect(() => validateLogin({ email: "not-an-email", password: "whatever" })).toThrow();
  });
});

describe("aiValidator", () => {
  test("accepts a valid question", () => {
    const value = validateChat({ question: "What does missing a dose mean?" });
    expect(value.question).toBeDefined();
  });

  test("rejects empty question", () => {
    expect(() => validateChat({ question: "" })).toThrow();
  });

  test("rejects overly long question", () => {
    expect(() => validateChat({ question: "a".repeat(2000) })).toThrow();
  });
});
