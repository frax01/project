// Push notifications sent on behalf of the app.
//
// The app used to ask a public, unauthenticated HTTPS function
// (generateAccessToken) for an OAuth token and then called FCM itself, so
// anybody who knew the URL could send any notification to any device. The app
// now calls the callable function below: it checks who is calling, decides who
// receives the notification and sends it with the Admin SDK. Dependencies
// (db, messaging) are injected so the logic can be tested without Firebase.

const { HttpsError } = require('firebase-functions/v2/https');

const EVENT_CATEGORIES = ['new_event', 'modified_event'];
const PROGRAM_OPTIONS = ['weekend', 'trip', 'evento'];
const MAX_CLASSES = 20;

/** Tokens of a user document: legacy strings or {device: token} maps. Null and empty ones are skipped. */
function tokensFromField(field) {
  const tokens = [];
  if (!Array.isArray(field)) return tokens;
  for (const entry of field) {
    const candidates =
      typeof entry === 'string'
        ? [entry]
        : entry && typeof entry === 'object'
          ? Object.values(entry)
          : [];
    for (const token of candidates) {
      if (typeof token === 'string' && token && !tokens.includes(token)) {
        tokens.push(token);
      }
    }
  }
  return tokens;
}

function clean(value, max) {
  return typeof value === 'string' ? value.trim().slice(0, max) : '';
}

/**
 * The caller's profile. The Auth token carries the email in lowercase while a
 * profile keeps it as it was typed at sign-up, so the email the app has saved
 * is also tried, but only if it is the same address ignoring case: a caller
 * can never claim someone else's profile.
 */
async function findCaller(db, auth, data) {
  const authEmail = auth.token.email;
  const claimed = clean(data && data.email, 200);
  const emails = [authEmail];
  if (claimed && claimed !== authEmail && claimed.toLowerCase() === authEmail.toLowerCase()) {
    emails.push(claimed);
  }
  for (const email of emails) {
    const user = await findUserByEmail(db, email);
    if (user) return user;
  }
  return null;
}

async function findUserByEmail(db, email) {
  const snapshot = await db.collection('user').where('email', '==', email).limit(1).get();
  if (snapshot.empty) return null;
  const doc = snapshot.docs[0];
  return { id: doc.id, ref: doc.ref, data: doc.data() };
}

function collectTokens(docs, seenIds = new Set()) {
  const tokens = [];
  for (const doc of docs) {
    if (seenIds.has(doc.id)) continue;
    seenIds.add(doc.id);
    for (const token of tokensFromField(doc.data().token)) {
      if (!tokens.includes(token)) tokens.push(token);
    }
  }
  return tokens;
}

async function tokensForClasses(db, club, classes) {
  const seen = new Set();
  const tokens = [];
  for (const className of classes) {
    const snapshot = await db
      .collection('user')
      .where('club', '==', club)
      .where('club_class', 'array-contains', className)
      .get();
    for (const token of collectTokens(snapshot.docs, seen)) {
      if (!tokens.includes(token)) tokens.push(token);
    }
  }
  return tokens;
}

async function tokensForAdmins(db, club) {
  const snapshot = await db
    .collection('user')
    .where('club', '==', club)
    .where('status', '==', 'Admin')
    .get();
  return collectTokens(snapshot.docs);
}

/**
 * Handles one call of sendClubNotification.
 *   auth: request.auth of the callable, data: request.data.
 * Returns {sent, failed} (or {sent: 0, skipped: true}).
 */
async function handleSendClubNotification({ db, messaging, auth, data, now = () => new Date() }) {
  if (!auth || !auth.token || !auth.token.email) {
    throw new HttpsError('unauthenticated', 'Accesso richiesto');
  }
  const caller = await findCaller(db, auth, data);
  if (!caller) {
    throw new HttpsError('permission-denied', 'Profilo utente non trovato');
  }
  const club = caller.data.club;
  const isAdmin = caller.data.status === 'Admin';
  const category = clean(data && data.category, 30);

  let tokens;
  let title;
  let body;
  let docId = '';
  let selectedOption = '';

  if (EVENT_CATEGORIES.includes(category)) {
    if (!isAdmin) {
      throw new HttpsError('permission-denied', 'Solo gli admin possono inviare questa notifica');
    }
    const classes = (Array.isArray(data.classes) ? data.classes : [])
      .filter((c) => typeof c === 'string' && c)
      .slice(0, MAX_CLASSES);
    title = clean(data.title, 100);
    body = clean(data.body, 200);
    docId = clean(data.docId, 100);
    selectedOption = clean(data.selectedOption, 20);
    if (!title || !docId || !PROGRAM_OPTIONS.includes(selectedOption)) {
      throw new HttpsError('invalid-argument', 'Dati della notifica non validi');
    }
    // Only the caller's own club: a club sent by the app is ignored.
    tokens = await tokensForClasses(db, club, classes);
  } else if (category === 'new_user') {
    // A new user tells the admins of their own club, once.
    if (caller.data.adminNotifiedAt) {
      return { sent: 0, skipped: true };
    }
    title = 'Nuova registrazione!';
    body = 'Accetta il nuovo utente';
    tokens = await tokensForAdmins(db, club);
    await caller.ref.update({ adminNotifiedAt: now() });
  } else if (category === 'accepted') {
    if (!isAdmin) {
      throw new HttpsError('permission-denied', 'Solo gli admin possono accettare un utente');
    }
    const target = await findUserByEmail(db, clean(data.userEmail, 200));
    if (!target || target.data.club !== club) {
      throw new HttpsError('not-found', 'Utente non trovato');
    }
    title = 'Sei stato accettato!';
    body = 'Fai di nuovo Login';
    tokens = tokensFromField(target.data.token);
  } else {
    throw new HttpsError('invalid-argument', 'Categoria non valida');
  }

  return sendToTokens(messaging, tokens, { category, title, body, docId, selectedOption });
}

/** FCM data values must all be strings. */
function buildData({ category, title, body, docId, selectedOption, extra = {} }) {
  return {
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    id: Date.now().toString(),
    docId: String(docId || ''),
    selectedOption: String(selectedOption || ''),
    status: 'done',
    category: String(category),
    notTitle: String(title),
    notBody: String(body || ''),
    // The recipient screen loads its own role when this is empty (it used to
    // receive the sender's role).
    role: '',
    ...extra,
  };
}

async function sendToTokens(messaging, tokens, info) {
  if (tokens.length === 0) return { sent: 0, failed: 0 };
  const messages = tokens.map((token) => ({
    token,
    notification: { title: info.title, body: info.body || '' },
    data: buildData(info),
  }));
  let sent = 0;
  let failed = 0;
  for (let i = 0; i < messages.length; i += 500) {
    const result = await messaging.sendEach(messages.slice(i, i + 500));
    sent += result.successCount;
    failed += result.failureCount;
  }
  return { sent, failed };
}

const CC_WINDOW_MS = 15 * 60 * 1000;
const CC_MAX_FAILURES = 10;

/**
 * Handles one call of verifyCcPassword: the Champions Club staff/tutor
 * passwords stay on the server (they used to be downloaded to every phone and
 * compared there). It must also work for people without an account (the
 * Champions Club screen is open to them), so it does not require a login;
 * instead, after CC_MAX_FAILURES wrong passwords within CC_WINDOW_MS every
 * attempt is refused until the window ends.
 */
async function handleVerifyCcPassword({ db, data, timingSafeEqual, now = () => new Date() }) {
  const type = clean(data && data.type, 10);
  if (type !== 'staff' && type !== 'tutor') {
    throw new HttpsError('invalid-argument', 'Tipo non valido');
  }
  const password = typeof (data && data.password) === 'string' ? data.password : '';

  const attemptsRef = db.collection('ccPassword').doc('attempts');
  const attempts = await attemptsRef.get();
  const state = attempts.exists ? attempts.data() : {};
  const time = now().getTime();
  const windowOpen = typeof state.windowStart === 'number' && time - state.windowStart < CC_WINDOW_MS;
  const failures = windowOpen ? state.failures || 0 : 0;
  const windowStart = windowOpen ? state.windowStart : time;
  if (failures >= CC_MAX_FAILURES) {
    throw new HttpsError('resource-exhausted', 'Troppi tentativi, riprova tra qualche minuto');
  }

  const doc = await db.collection('ccPassword').doc('password').get();
  const expected = doc.exists ? doc.data()[type === 'staff' ? 'staffPw' : 'tutorPw'] : null;
  const ok = typeof expected === 'string' && !!expected && timingSafeEqual(password, expected);
  if (!ok) {
    await attemptsRef.set({ failures: failures + 1, windowStart });
  }
  return { ok };
}

module.exports = {
  tokensFromField,
  handleSendClubNotification,
  handleVerifyCcPassword,
  sendToTokens,
  buildData,
};
