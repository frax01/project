/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const config = require('./config.js');

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { addDays, format } = require('date-fns');
const { it } = require('date-fns/locale'); 
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const { google } = require('googleapis');

admin.initializeApp();

const { GoogleAuth } = require('google-auth-library');


exports.closeDefaultMeals = functions.pubsub.schedule('every monday 12:00').timeZone('Europe/Rome').onRun(async (context) => {
    try {
      const snapshot = await admin.firestore().collection('pasti').where('default', '==', true).get();
      if (snapshot.empty) {
        console.log('No matching documents.');
        return null;
      }
      const batch = admin.firestore().batch();
      snapshot.forEach(doc => {
        const data = doc.data();
        if (data.status === 'aperto') {
            batch.update(doc.ref, { status: 'chiuso' });
        }
      });
      await batch.commit();
      console.log('Updated documents successfully');
    } catch (error) {
      console.error('Error updating documents: ', error);
    }
    return null;
});

exports.openDefaultMeals = functions.pubsub.schedule('every saturday 08:00').timeZone('Europe/Rome').onRun(async (context) => {
    try {
      const snapshot = await admin.firestore().collection('pasti').where('default', '==', true).get();
      if (snapshot.empty) {
        console.log('No matching documents');
        return null;
      }
      const batch = admin.firestore().batch();
      snapshot.forEach(doc => {
        const data = doc.data();
        if (data.status === 'chiuso') {
            batch.update(doc.ref, { status: 'aperto' });
        }
      });
      await batch.commit();
      console.log('Updated documents successfully');
    } catch (error) {
      console.error('Error updating documents: ', error);
    }
    return null;
});

exports.createMondayLunch = functions.pubsub.schedule('every tuesday 00:01').timeZone('Europe/Rome').onRun(async (context) => {
    try {
        const today = new Date();
        const nextMondayDate = addDays(today, (1 - today.getDay() + 7) % 7);
        const formattedDate = format(nextMondayDate, 'dd MMM yyyy', { locale: it }).toUpperCase();
        const formattedAppuntamento = format(nextMondayDate, 'dd-MM-yyyy');

        const existingDocs = await admin.firestore().collection('pasti').where('default', '==', true).get();
        if (!existingDocs.empty) {
            const batch = admin.firestore().batch();
            existingDocs.forEach(doc => {
                batch.delete(doc.ref);
            });
            await batch.commit();
            console.log('Documenti esistenti con default==true eliminati.');
        }

        await admin.firestore().collection('pasti').add({
            'data': formattedDate,
            'giorno': 'LUNEDÌ',
            'orario': '14:30',
            'prenotazioni': [],
            'appuntamento': formattedAppuntamento,
            'default': true,
            'status': 'chiuso',
            'modificato': false,
        });
        console.log('Documento creato correttamente con data:', formattedDate);
    } catch (error) {
        console.error('Errore durante la creazione del documento:', error);
    }
});

exports.generateAccessToken = functions.https.onRequest(async (req, res) => {
  try {
    const auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });
    const client = await auth.getClient();
    const accessTokenResponse = await client.getAccessToken();
    res.json({ accessToken: accessTokenResponse.token });
  } catch (error) {
    console.error('Failed to generate access token', error);
    res.status(500).send('Failed to generate access token');
  }
});


exports.scheduleNotification = functions.pubsub.schedule('every day 10:00').timeZone('Europe/Rome').onRun(async (context) => {

    for (const elem of ['Tiber Club', 'Delta Club']) {
        const usersBirthday = await fetchUsersBirthday(elem);
        if (usersBirthday[0].length > 0) {
            for (const name of usersBirthday[0]) {
                const tokensBirthday = await fetchTokensBirthday(elem);
                for (const token of tokensBirthday) {
                    if(usersBirthday[1].includes(token)) {
                      await sendNotification(token, 'birthday', name, 'personale', '', '');
                    } else {
                      await sendNotification(token, 'birthday', name, 'broadcast', '', '');
                    }
                }
            }
        }
    }

    let users = [];
    const today = new Date();
    const dayToday = String(today.getDate()).padStart(2, '0');
    const monthToday = String(today.getMonth() + 1).padStart(2, '0');

    try {
        for (const elem of ['Tiber Club', 'Delta Club']) {
            console.log(`elem: ${elem}`);
            const calendar = await admin.firestore()
                .collection('calendario')
                .where('club', '==', elem)
                .get();

            for (const event of calendar.docs) {
                users = [];
                const eventData = event.data().data;
                const eventDate = eventData.toDate();
                const day = String(eventDate.getDate()).padStart(2, '0');
                const monthNum = String(eventDate.getMonth() + 1).padStart(2, '0');
                if (day === dayToday && monthNum === monthToday) {
                    users.push(...event.data().utenti);
                }
                const tokensEvent = await fetchTokensEvent(users);
                if (tokensEvent.length > 0) {
                    for (const token of tokensEvent) {
                        console.log(`token: ${token}`);
                        await sendNotification(token, 'evento', event.data().titolo, '', event.id, eventDate);
                    }
                }
            }
        }
    } catch (error) {
        console.error('Error fetching user events:', error);
    }

    return null;
});

async function fetchTokensEvent(users) {
    const tokens = [];
    try {
        const userCollection = admin.firestore().collection('user');
        const userDocs = [];
        const batchSize = 10;
        for (let i = 0; i < users.length; i += batchSize) {
            const batch = users.slice(i, i + batchSize);
            const querySnapshot = await userCollection.where('email', 'in', batch).get();
            querySnapshot.forEach(doc => {
                userDocs.push(doc.data());
            });
        }

        userDocs.forEach(user => {
            tokens.push(...user.token);
        });        

    } catch (error) {
        console.error('Errore nel recupero dei token: ', error);
    }
    return tokens;
}

async function fetchUsersBirthday(elem) {
    const birthdays = [];
    const tokens = [];

    const today = new Date();
    const dayToday = String(today.getDate()).padStart(2, '0');
    const monthToday = String(today.getMonth() + 1).padStart(2, '0');
    try {
        const users = await admin.firestore()
        .collection('user')
        .where('club', '==', elem)
        .where('role', 'in', ['Tutor', 'Ragazzo'])
        .get();

        users.forEach(user => {
            const [day, month, year] = user.data().birthdate.split('-');
            if(day==dayToday && month==monthToday) {
                birthdays.push(`${user.data().name} ${user.data().surname}`);
                tokens.push(...user.data().token);
            }
        });
    } catch (error) {
        console.error('Errore nel recupero dei token: ', error);
    }
    return [birthdays, tokens];
}

async function fetchTokensBirthday(elem) {
    const tokens = [];
    try {
        const users = await admin.firestore()
        .collection('user')
        .where('club', '==', elem)
        .where('role', 'in', ['Tutor', 'Ragazzo'])
        .get();
        users.forEach(user => {
            if (user.data().token) {
                tokens.push(...user.data().token);
            }
        });
    } catch (error) {
        console.error('Errore nel recupero dei token: ', error);
    }
    return tokens
}

async function sendNotification(token, section, name, filter, id, focused) {

    let accessToken;
    try {
        const response = await axios.get('https://us-central1-club-60d94.cloudfunctions.net/generateAccessToken');
        accessToken = response.data.accessToken;
        console.log(`access: ${accessToken}`);
    } catch (error) {
        console.error('Errore nel recupero del token di accesso:', error);
        return;
    }

    let data = '';

    let docId = '';
    let selectedOption = '';
    let category = '';
    let notTitle = '';
    let message = '';

    if(section=='birthday' && filter=='broadcast') {
        docId = '';
        selectedOption = '';
        category = section;
        notTitle = `Oggi è il compleanno di ${name}`;
        message = 'Fagli gli auguri!';
    } else if(section=='birthday' && filter=='personale') {
        docId = '';
        selectedOption = '';
        category = section;
        notTitle = `Buon compleanno!`;
        message = 'Festeggia al Tiber!';
    } else {
        docId = id;
        selectedOption = '';
        category = section;
        notTitle = `Oggi: ${name}`;
        message = 'Ricordati di partecipare!';
    }

    if(section=='birthday') {
        data = {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            id: Date.now().toString(),
            docId: docId.toString(),
            selectedOption: selectedOption.toString(),
            status: 'done',
            category: category.toString(),
            notTitle: notTitle.toString(),
            notBody: message.toString()
        };
    } else if(section=='evento') {
        data = {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            id: Date.now().toString(),
            focusedDay: focused,
            docId: docId.toString(),
            selectedOption: selectedOption.toString(),
            status: 'done',
            category: category.toString(),
            notTitle: notTitle.toString(),
            notBody: message.toString()
        };
    }

    const notification = {
        title: notTitle,
        body: message
    };      

    const messagePayload = {
        'message': {
            'token': token,
            'notification': notification,
            'data': data,
        }
    };

    const url = 'https://fcm.googleapis.com/v1/projects/club-60d94/messages:send';

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(messagePayload)
        });
        console.log('Notifica inviata con successo:', response);
    } catch (error) {
        console.error('Errore nell\'invio della notifica: ', error);
    }
}

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
