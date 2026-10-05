// Run with: cd functions && node --test test/
const test = require('node:test');
const assert = require('node:assert');
const crypto = require('node:crypto');

const {
  tokensFromField,
  handleSendClubNotification,
  handleVerifyCcPassword,
  sendToTokens,
} = require('../notifications');

// ---- tiny in-memory fakes -------------------------------------------------

function fakeDb({ users = [], ccPassword = null } = {}) {
  const cc = ccPassword === null ? {} : { password: ccPassword };
  const docs = users.map((u, i) => ({ id: `u${i}`, data: { ...u } }));
  function makeQuery(filters, max) {
    return {
      where(field, op, value) {
        return makeQuery([...filters, { field, op, value }], max);
      },
      limit(n) {
        return makeQuery(filters, n);
      },
      async get() {
        let result = docs.filter((d) =>
          filters.every((f) => {
            const v = d.data[f.field];
            if (f.op === '==') return v === f.value;
            if (f.op === 'array-contains') return Array.isArray(v) && v.includes(f.value);
            throw new Error(`operator ${f.op} is not faked`);
          })
        );
        if (max) result = result.slice(0, max);
        return {
          empty: result.length === 0,
          docs: result.map((d) => ({
            id: d.id,
            ref: { update: async (patch) => Object.assign(d.data, patch) },
            data: () => d.data,
          })),
        };
      },
    };
  }
  return {
    docs,
    cc,
    collection(name) {
      if (name === 'user') return makeQuery([], null);
      if (name === 'ccPassword') {
        return {
          doc: (id) => ({
            get: async () => ({
              exists: Object.prototype.hasOwnProperty.call(cc, id),
              data: () => cc[id],
            }),
            set: async (value) => {
              cc[id] = value;
            },
          }),
        };
      }
      throw new Error(`unexpected collection ${name}`);
    },
  };
}

function fakeMessaging() {
  const sent = [];
  return {
    sent,
    async sendEach(messages) {
      sent.push(...messages);
      return { successCount: messages.length, failureCount: 0 };
    },
  };
}

const safeEqual = (a, b) => {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && crypto.timingSafeEqual(x, y);
};

const admin = (extra = {}) => ({
  email: 'admin@club.it',
  club: 'Tiber Club',
  status: 'Admin',
  role: 'Tutor',
  club_class: [],
  token: [{ iPhone: 'tok-admin' }],
  ...extra,
});
const student = (email, club, classes, token, extra = {}) => ({
  email,
  club,
  status: 'User',
  role: 'Ragazzo',
  club_class: classes,
  token,
  ...extra,
});
const authOf = (email) => ({ token: { email } });

const rejectsWith = (code) => (err) => {
  assert.strictEqual(err.code, code);
  return true;
};

// ---- tokensFromField --------------------------------------------------------

test('tokensFromField skips null/empty tokens and keeps the others', () => {
  assert.deepStrictEqual(
    tokensFromField(['legacy', { iPhone: 'a' }, { iPad: null }, null, {}, '', { x: 'a' }]),
    ['legacy', 'a']
  );
  assert.deepStrictEqual(tokensFromField(undefined), []);
});

// ---- sendClubNotification -----------------------------------------------------

const eventData = (extra = {}) => ({
  category: 'new_event',
  classes: ['1° liceo', '2° liceo'],
  title: 'Nuovo programma!',
  body: 'Gita',
  docId: 'abc',
  selectedOption: 'trip',
  ...extra,
});

test('rejects calls without a logged-in user', async () => {
  await assert.rejects(
    handleSendClubNotification({ db: fakeDb(), messaging: fakeMessaging(), auth: null, data: eventData() }),
    rejectsWith('unauthenticated')
  );
});

test('rejects a caller that has no profile', async () => {
  await assert.rejects(
    handleSendClubNotification({
      db: fakeDb({ users: [admin()] }),
      messaging: fakeMessaging(),
      auth: authOf('stranger@x.it'),
      data: eventData(),
    }),
    rejectsWith('permission-denied')
  );
});

test('a non-admin cannot send program notifications', async () => {
  const messaging = fakeMessaging();
  await assert.rejects(
    handleSendClubNotification({
      db: fakeDb({ users: [student('kid@club.it', 'Tiber Club', ['1° liceo'], ['t'])] }),
      messaging,
      auth: authOf('kid@club.it'),
      data: eventData(),
    }),
    rejectsWith('permission-denied')
  );
  assert.strictEqual(messaging.sent.length, 0);
});

test('an admin notifies only the users of their club and the chosen classes', async () => {
  const messaging = fakeMessaging();
  const db = fakeDb({
    users: [
      admin(),
      student('a@club.it', 'Tiber Club', ['1° liceo'], [{ iPhone: 'tok-a' }, { iPad: null }]),
      student('b@club.it', 'Tiber Club', ['2° liceo', '1° liceo'], ['tok-b', { Pixel: 'tok-a' }]),
      student('c@club.it', 'Tiber Club', ['5° liceo'], [{ iPhone: 'tok-c' }]),
      student('d@other.it', 'Delta Club', ['1° liceo'], [{ iPhone: 'tok-d' }]),
    ],
  });

  const result = await handleSendClubNotification({
    db,
    messaging,
    auth: authOf('admin@club.it'),
    // the club sent by the app must be ignored
    data: eventData({ club: 'Delta Club' }),
  });

  assert.deepStrictEqual(result, { sent: 2, failed: 0 });
  assert.deepStrictEqual(messaging.sent.map((m) => m.token).sort(), ['tok-a', 'tok-b']);
  const message = messaging.sent[0];
  assert.strictEqual(message.notification.title, 'Nuovo programma!');
  assert.strictEqual(message.data.docId, 'abc');
  assert.strictEqual(message.data.selectedOption, 'trip');
  assert.strictEqual(message.data.category, 'new_event');
  assert.strictEqual(message.data.role, '');
  for (const value of Object.values(message.data)) {
    assert.strictEqual(typeof value, 'string'); // FCM data values must be strings
  }
});

test('a null token of one user does not stop the others (regression)', async () => {
  const messaging = fakeMessaging();
  await handleSendClubNotification({
    db: fakeDb({
      users: [
        admin(),
        student('a@club.it', 'Tiber Club', ['1° liceo'], [{ iPhone: null }]),
        student('b@club.it', 'Tiber Club', ['1° liceo'], [{ iPhone: 'tok-b' }]),
      ],
    }),
    messaging,
    auth: authOf('admin@club.it'),
    data: eventData(),
  });
  assert.deepStrictEqual(messaging.sent.map((m) => m.token), ['tok-b']);
});

test('program notifications need a title, a document and a valid type', async () => {
  const run = (data) =>
    handleSendClubNotification({
      db: fakeDb({ users: [admin()] }),
      messaging: fakeMessaging(),
      auth: authOf('admin@club.it'),
      data,
    });
  await assert.rejects(run(eventData({ selectedOption: 'hack' })), rejectsWith('invalid-argument'));
  await assert.rejects(run(eventData({ docId: '' })), rejectsWith('invalid-argument'));
  await assert.rejects(run(eventData({ title: '  ' })), rejectsWith('invalid-argument'));
  await assert.rejects(run({ category: 'whatever' }), rejectsWith('invalid-argument'));
});

test('new_user notifies the admins of the caller club, once', async () => {
  const messaging = fakeMessaging();
  const db = fakeDb({
    users: [
      student('new@club.it', 'Tiber Club', [], [{ iPhone: 'tok-new' }], { status: '' }),
      admin({ email: 'admin1@club.it', token: [{ iPhone: 'tok-admin1' }] }),
      admin({ email: 'admin2@other.it', club: 'Delta Club', token: [{ iPhone: 'tok-admin2' }] }),
    ],
  });
  const params = { db, messaging, auth: authOf('new@club.it'), data: { category: 'new_user' } };

  const first = await handleSendClubNotification(params);
  const second = await handleSendClubNotification(params);

  assert.deepStrictEqual(first, { sent: 1, failed: 0 });
  assert.deepStrictEqual(second, { sent: 0, skipped: true });
  assert.deepStrictEqual(messaging.sent.map((m) => m.token), ['tok-admin1']);
  assert.strictEqual(messaging.sent[0].notification.title, 'Nuova registrazione!');
});

test('accepted: an admin notifies a user of their own club only', async () => {
  const messaging = fakeMessaging();
  const db = fakeDb({
    users: [
      admin(),
      student('kid@club.it', 'Tiber Club', [], [{ iPhone: 'tok-kid' }]),
      student('far@other.it', 'Delta Club', [], [{ iPhone: 'tok-far' }]),
    ],
  });
  const call = (userEmail, email = 'admin@club.it') =>
    handleSendClubNotification({
      db,
      messaging,
      auth: authOf(email),
      data: { category: 'accepted', userEmail },
    });

  assert.deepStrictEqual(await call('kid@club.it'), { sent: 1, failed: 0 });
  assert.strictEqual(messaging.sent[0].token, 'tok-kid');
  await assert.rejects(call('far@other.it'), rejectsWith('not-found'));
  await assert.rejects(call('kid@club.it', 'kid@club.it'), rejectsWith('permission-denied'));
});

// ---- verifyCcPassword -----------------------------------------------------------

const ccDb = () => fakeDb({ ccPassword: { staffPw: 'staff-secret', tutorPw: 'tutor-secret' } });
const verify = (db, data, now) =>
  handleVerifyCcPassword({ db, data, timingSafeEqual: safeEqual, now });

test('verifyCcPassword compares on the server and never returns the password', async () => {
  const db = ccDb();
  assert.deepStrictEqual(await verify(db, { type: 'staff', password: 'staff-secret' }), { ok: true });
  assert.deepStrictEqual(await verify(db, { type: 'staff', password: 'tutor-secret' }), { ok: false });
  assert.deepStrictEqual(await verify(db, { type: 'tutor', password: 'tutor-secret' }), { ok: true });
  assert.deepStrictEqual(await verify(db, { type: 'tutor', password: '' }), { ok: false });
  await assert.rejects(verify(db, { type: 'admin', password: 'x' }), rejectsWith('invalid-argument'));
});

test('verifyCcPassword is false when no password is configured', async () => {
  const result = await verify(fakeDb({ ccPassword: null }), { type: 'staff', password: '' });
  assert.deepStrictEqual(result, { ok: false });
});

test('verifyCcPassword locks after too many wrong passwords, then unlocks', async () => {
  const db = ccDb();
  let clock = new Date('2027-01-15T10:00:00Z');
  const now = () => clock;

  for (let i = 0; i < 10; i++) {
    assert.deepStrictEqual(await verify(db, { type: 'staff', password: `wrong${i}` }, now), { ok: false });
  }
  // locked: even the right password is refused
  await assert.rejects(
    verify(db, { type: 'staff', password: 'staff-secret' }, now),
    rejectsWith('resource-exhausted')
  );

  // the window ends, the right password works again
  clock = new Date('2027-01-15T10:16:00Z');
  assert.deepStrictEqual(await verify(db, { type: 'staff', password: 'staff-secret' }, now), { ok: true });
});

test('a successful password does not count as a failure', async () => {
  const db = ccDb();
  for (let i = 0; i < 25; i++) {
    assert.deepStrictEqual(await verify(db, { type: 'tutor', password: 'tutor-secret' }), { ok: true });
  }
});

// ---- sendToTokens (used by the scheduled functions) -----------------------------

test('sendToTokens sends string-only data, with the extra fields', async () => {
  const messaging = fakeMessaging();
  const result = await sendToTokens(messaging, ['tok-1'], {
    category: 'evento',
    title: 'Riunione',
    body: 'Oggi',
    docId: 'ev1',
    extra: { focusedDay: new Date('2027-01-15T00:00:00.000Z').toISOString() },
  });

  assert.deepStrictEqual(result, { sent: 1, failed: 0 });
  const message = messaging.sent[0];
  assert.strictEqual(message.data.category, 'evento');
  assert.strictEqual(message.data.focusedDay, '2027-01-15T00:00:00.000Z');
  assert.strictEqual(message.data.selectedOption, '');
  for (const value of Object.values(message.data)) {
    assert.strictEqual(typeof value, 'string');
  }
});

test('sendToTokens with no tokens sends nothing', async () => {
  const messaging = fakeMessaging();
  assert.deepStrictEqual(await sendToTokens(messaging, [], { category: 'x', title: 'y' }), { sent: 0, failed: 0 });
  assert.strictEqual(messaging.sent.length, 0);
});

// ---- profile lookup with mixed-case emails -----------------------------------------

test('a profile saved with capital letters is found through the claimed email', async () => {
  const messaging = fakeMessaging();
  const db = fakeDb({
    users: [
      admin({ email: 'Admin@Club.it' }),
      student('a@club.it', 'Tiber Club', ['1° liceo'], [{ iPhone: 'tok-a' }]),
    ],
  });
  const call = (data) =>
    handleSendClubNotification({
      db,
      messaging,
      auth: authOf('admin@club.it'), // the Auth token is always lowercase
      data: { ...eventData(), ...data },
    });

  // without the email saved by the app the profile is not found
  await assert.rejects(call({}), rejectsWith('permission-denied'));
  // with it (same address, other case) it is
  assert.deepStrictEqual(await call({ email: 'Admin@Club.it' }), { sent: 1, failed: 0 });
});

test('a caller cannot claim the profile of a different address', async () => {
  const db = fakeDb({ users: [admin({ email: 'boss@club.it' })] });
  await assert.rejects(
    handleSendClubNotification({
      db,
      messaging: fakeMessaging(),
      auth: authOf('kid@club.it'),
      data: { ...eventData(), email: 'boss@club.it' },
    }),
    rejectsWith('permission-denied')
  );
});
