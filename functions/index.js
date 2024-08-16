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

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.scheduleNotification = functions.pubsub.schedule('every day 08:00').timeZone('Europe/Rome').onRun(async (context) => {
    
    //'clZZVrDxSbaEz1lBJ3wClJ:APA91bEvMOBDI0P9_xjthTfCHy-O_XmvtyYhhKUhVzCWtS8TCcYwdTI6LLWpQdIV4sqJ6jOlxp7vBTuHBu5QJlBNM0SR-qTSl2QV2RYfAcW94hbm4V42r2j3EJC6TKAsbFktJgoFOW8b'
    
    const usersBirthday = await fetchUsersBirthday();
    if (usersBirthday[0].length > 0) {
        for (const name of usersBirthday[0]) {
            const tokensBirthday = await fetchTokensBirthday();
            for (const token of tokensBirthday) {
                if(usersBirthday[1].includes(token)) {
                  await sendNotification(token, 'birthday', name, 'personale', '', '');
                } else {
                  await sendNotification(token, 'birthday', name, 'broadcast', '', '');
                }
            }
        }
    }

    let users = [];
    const today = new Date();
    const dayToday = String(today.getDate()).padStart(2, '0');
    const monthToday = String(today.getMonth() + 1).padStart(2, '0');
    try {
        const calendar = await admin.firestore()
            .collection('calendario')
            .where('club', '==', 'Tiber Club')
            .get();

        calendar.forEach(async (event) => {
            users = [];
            const eventData = event.data().data;
            const eventDate = eventData.toDate();
            const day = String(eventDate.getDate()).padStart(2, '0');
            const monthNum = String(eventDate.getMonth() + 1).padStart(2, '0');
            if (day == dayToday && monthNum == monthToday) {
                users.push(...event.data().utenti);
            }
            const tokensEvent = await fetchTokensEvent(users);
            if (tokensEvent.length > 0) {
                for (const token of tokensEvent) {
                    await sendNotification(token, 'evento', event.data().titolo, '', event.id, eventDate);
                }
            }
        });
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

async function fetchUsersBirthday() {
    const birthdays = [];
    const tokens = [];

    const today = new Date();
    const dayToday = String(today.getDate()).padStart(2, '0');
    const monthToday = String(today.getMonth() + 1).padStart(2, '0');
    try {
        const users = await admin.firestore()
        .collection('user')
        .where('club', '==', 'Tiber Club')
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

async function fetchTokensBirthday() {
    const tokens = [];
    try {
        const users = await admin.firestore()
        .collection('user')
        .where('club', '==', 'Tiber Club')
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
            docId: docId,
            selectedOption: selectedOption,
            status: 'done',
            category: category,
            notTitle: notTitle,
            notBody: message
        };
    } else if(section=='evento') {
        data = {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            id: Date.now().toString(),
            focusedDay: focused,
            docId: docId,
            selectedOption: selectedOption,
            status: 'done',
            category: category,
            notTitle: notTitle,
            notBody: message
        };
    }

    const notification = {
        title: notTitle,
        body: message
    };      

    try {
        await axios.post('https://fcm.googleapis.com/fcm/send', {
            to: token,
            notification: notification,
            data: data,
        }, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `key=${config.serverKey}`,
            },
        });
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
