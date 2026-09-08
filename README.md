# AI Medicine Reminder — Backend

A complete, production-ready Firebase backend for a medicine reminder mobile app,
with an AI assistant for medication questions.

---

## 1. Architecture

```
Mobile App (iOS/Android)
   │  Firebase Auth SDK (sign up / log in directly)
   │  HTTPS + Bearer <idToken>
   ▼
Cloud Function "api"  (Express app, one HTTPS function for all REST routes)
   │
   ├── authMiddleware   → verifies Firebase ID token on every protected route
   ├── controllers      → thin HTTP layer (parse request, call service, format response)
   ├── validators (Joi) → reject bad input before it touches the database
   ├── services         → all business logic + Firestore reads/writes
   └── middleware        → rate limiting, centralized error handling

Cloud Function "checkReminders" (Cloud Scheduler, every 5 minutes)
   └── scans active medicines → sends FCM push notifications when a dose is due

Firestore  (users, medicines, medicineHistory, notifications, aiChats)
   └── protected by firestore.rules — a user can only ever read/write their own data
```

**Why this shape?**
- One Express app behind one Cloud Function (`api`) is simpler to deploy, debug, and
  reason about than dozens of tiny functions, and is the standard pattern for REST-style
  Firebase backends.
- Every protected route re-derives the user's identity from their verified ID token
  (never from anything the client sends in the body) — this, plus Firestore security
  rules, is what makes cross-user data access impossible even if the app has a bug.
- Firestore rules give you a **second, independent** layer of protection, enforced by
  Google's servers even if your Cloud Function code has a mistake.

### JavaScript vs. TypeScript
This project uses **plain JavaScript**. TypeScript is a great tool, but as a beginner
you'd be learning two things at once (backend concepts *and* a type system). JavaScript
lets you focus on Firebase/Express/Firestore first. Every file uses JSDoc-style comments
to explain intent. You can migrate to TypeScript later — the file structure won't need to
change.

---

## 2. Database Design

| Collection            | Document ID | Key fields | Purpose |
|------------------------|-------------|------------|---------|
| `users/{uid}`          | Firebase Auth `uid` | email, displayName, timezone, fcmToken | One profile per user. Using the Auth uid as the doc ID means "is this my profile?" is a simple, fast rule check. |
| `medicines/{id}`       | auto ID | userId, name, dosage, dosageUnit, frequency, daysOfWeek, reminderTimes[], startDate, endDate, isActive | One document per medicine a user takes. |
| `medicineHistory/{id}` | auto ID | userId, medicineId, status (taken/missed/skipped/pending), scheduledTime, actualTime, date | Append-only audit log of every dose event. Never updated/deleted by the client, so history is trustworthy. |
| `notifications/{id}`   | auto ID | userId, medicineId, title, body, scheduledFor, read | In-app notification inbox, written by the scheduled function. |
| `aiChats/{id}`         | auto ID | userId, medicineId?, question, answer | AI assistant conversation history. |

**Why flat top-level collections instead of nesting everything under `users/{uid}/...`?**
Both are valid in Firestore. Flat collections were chosen here because:
- `collectionGroup` queries like "all of a user's history across dates" are simple
  `where("userId","==",uid)` queries and are easy for a beginner to read.
- It keeps security rules simple and uniform (every rule follows the same
  `resource.data.userId == request.auth.uid` pattern).

Every document carries a `userId` field, and the security rules (below) enforce that a
user can only read/write documents where `userId` matches their own uid.

---

## 3. Firestore Security Rules

See [`firestore.rules`](./firestore.rules). Highlights:

- **Nothing is readable/writable without being signed in** (`request.auth != null`).
- **Ownership check on every collection**: a document can only be read/written by the
  user whose uid matches its `userId` field (or, for `users/{uid}`, whose uid matches
  the document ID itself).
- **`userId` is immutable**: you can update a medicine's name, but you can never move it
  to belong to a different user.
- **History is append-only**: `medicineHistory` documents can be created but never
  updated or deleted from the client — this keeps the adherence history honest.
- **AI answers can't be forged**: the client may create the `question` half of an
  `aiChats` document, but only your Cloud Function (using the Admin SDK, which bypasses
  rules) can attach the `answer`.
- **Default deny**: the final rule block denies anything not explicitly allowed above.

---

## 4. API Reference

All routes are served from one base URL:
`https://<region>-<project-id>.cloudfunctions.net/api`

Every route except `/auth/register` and `/auth/login` requires:
`Authorization: Bearer <Firebase ID token>`

| Method | Path | Description |
|--------|------|-------------|
| GET  | `/health` | Health check |
| POST | `/auth/register` | Create Auth user + profile |
| POST | `/auth/login` | Server-side login (see note below) |
| POST | `/auth/logout` | Revoke all refresh tokens |
| GET  | `/auth/profile` | Get own profile |
| PUT  | `/auth/profile` | Update own profile |
| DELETE | `/auth/account` | Delete account + all data |
| POST | `/medicines` | Create medicine |
| GET  | `/medicines` | List own medicines (`?activeOnly=true`) |
| GET  | `/medicines/:id` | Get one medicine |
| PUT  | `/medicines/:id` | Update medicine |
| DELETE | `/medicines/:id` | Delete medicine |
| POST | `/medicines/:id/taken` | Record a dose as taken |
| POST | `/medicines/:id/missed` | Record a dose as missed |
| POST | `/medicines/:id/skipped` | Record a dose as skipped |
| GET  | `/history/today?date=YYYY-MM-DD` | Today's dose statuses |
| GET  | `/history?medicineId=&status=&startDate=&endDate=&limit=` | Filtered history |
| POST | `/ai/chat` | Ask the AI assistant |
| GET  | `/ai/chat/history` | Past AI conversations |

**Note on `/auth/login`:** the Firebase Admin SDK can't check a password (only the
client SDK or the Identity Toolkit REST API can). The **recommended** approach is to
call `signInWithEmailAndPassword()` directly from the mobile app using the Firebase Auth
SDK — it's faster and is the standard Firebase pattern. `/auth/login` is provided as a
working alternative (e.g. for testing with curl) — see `functions/src/services/authService.js`.

### Example: create a medicine
```
POST /medicines
Authorization: Bearer <idToken>
Content-Type: application/json

{
  "name": "Metformin",
  "dosage": 500,
  "dosageUnit": "mg",
  "frequency": "daily",
  "reminderTimes": ["08:00", "20:00"],
  "startDate": "2026-09-01",
  "instructions": "Take with food"
}
```
Response:
```json
{
  "success": true,
  "data": {
    "id": "abc123",
    "userId": "uid_...",
    "name": "Metformin",
    "dosage": 500,
    "dosageUnit": "mg",
    "frequency": "daily",
    "reminderTimes": ["08:00", "20:00"],
    "startDate": "2026-09-01",
    "isActive": true,
    "createdAt": "2026-09-01T10:00:00.000Z",
    "updatedAt": "2026-09-01T10:00:00.000Z"
  }
}
```
All error responses share this shape:
```json
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "..." } }
```

---

## 5. Reminders & Notifications — how scheduling actually works

**Important Firebase limitation:** FCM only sends push notifications *immediately* —
there is no "deliver this at 8:00 AM daily" API. The correct, standard Firebase pattern
(used here) is:

1. A Cloud Scheduler job (`checkReminders`, defined with `onSchedule`) runs every 5
   minutes.
2. It loads all active medicines, converts "now" into each user's own timezone, and
   checks whether any `reminderTimes` fell within the last 5 minutes.
3. For each due reminder, it sends an FCM push notification and writes a
   `notifications/{id}` + a `pending` `medicineHistory` entry.

This gives ~5-minute precision, which is normal and acceptable for medicine reminders.
If you need exact-minute delivery later, look into **Cloud Tasks** (schedule one task per
reminder occurrence) — more precise, but more moving parts, so start with the scheduler
approach above.

The mobile app must register its FCM device token by calling
`PUT /auth/profile { "fcmToken": "..." }` whenever Firebase Messaging issues a new token.

---

## 6. AI Assistant — safety design

`POST /ai/chat` calls the Anthropic API from the **server only** — the API key never
reaches the mobile app. Safety measures in `functions/src/services/aiService.js`:

- A fixed **system prompt** (set server-side, not editable by the client) instructs the
  model that it is not a doctor, must never diagnose, prescribe, or tell a user to
  start/stop/change a medication, and must always recommend consulting a doctor or
  pharmacist for anything specific.
- Every answer gets a **disclaimer appended** automatically.
- A simple keyword check intercepts likely **emergencies** (e.g. "overdose", "chest
  pain") and returns a fixed message telling the user to contact emergency services,
  without calling the AI model at all.
- `aiLimiter` rate-limits `/ai/chat` to 8 requests/minute per user to control cost and
  abuse.
- Every question + answer is stored in `aiChats` for the user's own history.

---

## 7. Project Structure

```
ai-medicine-reminder-backend/
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── .firebaserc                 ← put your real Firebase project ID here
├── .gitignore
├── README.md
└── functions/
    ├── package.json
    ├── .env.example             ← copy to .env for LOCAL EMULATOR use only
    ├── test/
    │   ├── validators.test.js
    │   └── auth-protection.test.js
    └── src/
        ├── index.js              ← Express app + Cloud Functions exports
        ├── config/firebase.js    ← Admin SDK init (once)
        ├── controllers/          ← HTTP handlers (thin)
        ├── services/             ← business logic + Firestore access
        ├── middleware/           ← auth check, rate limiting, error handling
        ├── validators/           ← Joi input validation schemas
        ├── utils/                ← logger, response helpers, AppError
        └── scheduled/reminderScheduler.js
```

---

## 8. Setup & Installation

### Prerequisites
1. Install Node.js 20: https://nodejs.org
2. Install the Firebase CLI:
   ```
   npm install -g firebase-tools
   ```
3. Create a Firebase project at https://console.firebase.google.com, and in it enable:
   - **Authentication** → Email/Password sign-in method
   - **Firestore Database** (production mode)
   - **Cloud Messaging**
   - Upgrade to the **Blaze (pay-as-you-go)** plan — required for Cloud Functions and
     outbound network calls (needed to call the Anthropic API). Blaze has a generous free
     tier; a small app like this typically costs $0/month.

### Get the code running locally
```bash
firebase login
cd ai-medicine-reminder-backend
firebase use --add            # pick your Firebase project, alias it "default"
cd functions
npm install
cp .env.example .env          # then edit .env with your real keys (LOCAL ONLY)
```

### Run locally with the emulator
```bash
firebase emulators:start --only functions,firestore,auth
```
The API will be available at something like:
`http://127.0.0.1:5001/<project-id>/us-central1/api`

---

## 9. Environment Variables & Secrets

**Never put real API keys in code or commit a real `.env` file** (`.gitignore` already
excludes `.env`).

- **Local emulator**: values come from `functions/.env` (copied from `.env.example`).
- **Deployed functions**: use Firebase's secret manager, not `.env`:
  ```bash
  firebase functions:secrets:set AI_API_KEY
  firebase functions:secrets:set FIREBASE_WEB_API_KEY
  ```
  Then declare the secrets in `functions/src/index.js`'s function definitions (for v2
  functions, pass `{ secrets: ["AI_API_KEY", "FIREBASE_WEB_API_KEY"] }` in `onRequest`'s
  options) so they're injected as `process.env.AI_API_KEY` at runtime. This keeps the key
  encrypted at rest and out of your source control entirely.

---

## 10. Testing

### Automated unit tests (no Firebase project needed)
```bash
cd functions
npm test
```
This runs Jest tests for input validation (`validators.test.js`) and route protection
(`auth-protection.test.js`, with Firebase Admin mocked).

### Manual/integration testing against the emulator
Start the emulator (`firebase emulators:start --only functions,firestore,auth`), then:

1. **Create a user with the Auth emulator REST API** (simulates the mobile app sign-up):
   ```bash
   curl -X POST "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key" \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123","returnSecureToken":true}'
   ```
   Copy the `idToken` from the response.

2. **Create the matching Firestore profile:**
   ```bash
   curl -X POST "http://127.0.0.1:5001/<project-id>/us-central1/api/auth/register" \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123","displayName":"Test User"}'
   ```

3. **Add a medicine (needs the Bearer token from step 1):**
   ```bash
   curl -X POST "http://127.0.0.1:5001/<project-id>/us-central1/api/medicines" \
     -H "Authorization: Bearer <idToken>" -H "Content-Type: application/json" \
     -d '{"name":"Metformin","dosage":500,"dosageUnit":"mg","frequency":"daily","reminderTimes":["08:00"],"startDate":"2026-09-01"}'
   ```

4. **Confirm cross-user isolation:** repeat step 1–3 for a second user, then try fetching
   the first user's medicine with the second user's token — you should get `404
   MEDICINE_NOT_FOUND`.

5. **Test the Firestore rules directly:**
   ```bash
   cd functions && npx firebase-tools emulators:exec --only firestore "npm run test:rules"
   ```
   (Add a rules-testing script with `@firebase/rules-unit-testing` if you want automated
   rule tests — the manual checks above cover the same ground for now.)

---

## 11. Deployment

```bash
# 1. From the project root:
firebase use --add                       # if not done already
firebase deploy --only firestore:rules,firestore:indexes
firebase functions:secrets:set AI_API_KEY
firebase functions:secrets:set FIREBASE_WEB_API_KEY
firebase deploy --only functions

# 2. Check logs after deploying:
firebase functions:log

# 3. Test the deployed API:
curl https://us-central1-<project-id>.cloudfunctions.net/api/health
```

---

## 12. Frontend Integration Examples

The mobile app should use the **Firebase client SDK** for sign-up/login (to get an
ID token), then call this backend for everything else.

```js
import { initializeApp } from "firebase/app";
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword } from "firebase/auth";

const app = initializeApp({ /* your firebaseConfig */ });
const auth = getAuth(app);
const API_BASE = "https://us-central1-<project-id>.cloudfunctions.net/api";

// Sign up
const cred = await createUserWithEmailAndPassword(auth, email, password);
await fetch(`${API_BASE}/auth/register`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ email, password, displayName }),
});

// Log in
await signInWithEmailAndPassword(auth, email, password);
const idToken = await auth.currentUser.getIdToken();

// Helper for authenticated calls
async function apiCall(path, options = {}) {
  const token = await auth.currentUser.getIdToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...options.headers,
    },
  });
  return res.json();
}

// Add medicine
await apiCall("/medicines", { method: "POST", body: JSON.stringify(medicineData) });

// Get medicines
const { data: medicines } = await apiCall("/medicines");

// Update medicine
await apiCall(`/medicines/${id}`, { method: "PUT", body: JSON.stringify(updates) });

// Delete medicine
await apiCall(`/medicines/${id}`, { method: "DELETE" });

// Mark taken
await apiCall(`/medicines/${id}/taken`, {
  method: "POST",
  body: JSON.stringify({ scheduledTime: new Date().toISOString() }),
});

// Get history
const { data: history } = await apiCall("/history?status=taken&limit=20");

// Ask the AI assistant
const { data: chat } = await apiCall("/ai/chat", {
  method: "POST",
  body: JSON.stringify({ question: "What should I do if I miss a dose?" }),
});
```

---

## 13. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `401 UNAUTHORIZED` on every request | Missing/expired `Authorization: Bearer <idToken>` header — call `getIdToken()` again. |
| `403`/permission-denied from Firestore directly (not via API) | Check `firestore.rules` — client SDK writes must include a `userId` matching the caller. |
| AI chat returns `AI_API_ERROR` | `AI_API_KEY` secret not set, or Anthropic API is down/rate-limiting — check `firebase functions:log`. |
| Notifications never arrive | User's `fcmToken` is null/stale — app must call `PUT /auth/profile` with a fresh token; check the `checkReminders` function logs. |
| `functions:secrets:set` command fails | You must be on the Blaze plan and have Cloud Functions API enabled for the project. |
| Emulator can't reach Firestore | Make sure you started it with `--only functions,firestore,auth` so all three run together. |

---

## 14. Final Checklist

- ✅ Authentication (register, login, logout, profile CRUD, delete account)
- ✅ Database (Firestore, 5 collections, documented schema)
- ✅ Medicine CRUD (create/read/update/delete, validated)
- ✅ Reminders (recurring daily/weekly/specific-days, start/end dates)
- ✅ Notifications (FCM via scheduled Cloud Function)
- ✅ Medicine history (taken/missed/skipped, filterable queries)
- ✅ AI assistant (safety system prompt, disclaimers, emergency handling, no key exposure)
- ✅ Security (Firestore rules + server-side ownership checks, defense in depth)
- ✅ Validation (Joi schemas on every write endpoint)
- ✅ Error handling (centralized, no leaked internals)
- ✅ Testing (automated Jest tests + manual emulator test plan)
- ✅ Deployment (step-by-step CLI instructions)
