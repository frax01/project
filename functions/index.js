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
    //const usersBirthday = ['clZZVrDxSbaEz1lBJ3wClJ:APA91bEvMOBDI0P9_xjthTfCHy-O_XmvtyYhhKUhVzCWtS8TCcYwdTI6LLWpQdIV4sqJ6jOlxp7vBTuHBu5QJlBNM0SR-qTSl2QV2RYfAcW94hbm4V42r2j3EJC6TKAsbFktJgoFOW8b'];
    //await fetchUsersBirthday(); //per i compleanni
    //await fetchTokensEvent(); //per gli eventi

    const usersBirthday = [['Fra M'], ['a']];
    //await fetchUsersBirthday(); //per i compleanni
    //await fetchTokensEvent(); //per gli event
    if (usersBirthday[0].length > 0) {
        for (const name of usersBirthday[0]) {
            const tokensBirthday = await fetchTokensBirthday();
            for (const token of tokensBirthday) {
                if(usersBirthday[1].includes(token)) {
                  await sendNotification(token, 'birthday', name, 'personale');
                } else {
                  await sendNotification(token, 'birthday', name, 'broadcast');
                }
            }
        }
    }
    
    //if (tokensEvent.length > 0) {
    //    for (const token of tokensEvent) {
    //        await sendNotification(token, 'evento');
    //    }
    //}

    return null;
});

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
    return ['clZZVrDxSbaEz1lBJ3wClJ:APA91bEvMOBDI0P9_xjthTfCHy-O_XmvtyYhhKUhVzCWtS8TCcYwdTI6LLWpQdIV4sqJ6jOlxp7vBTuHBu5QJlBNM0SR-qTSl2QV2RYfAcW94hbm4V42r2j3EJC6TKAsbFktJgoFOW8b']; //tokens;
}

async function sendNotification(token, section, name, filter) {

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
        docId = '';
        selectedOption = '';
        category = section;
        notTitle = 'EVENTO IN PROGRAMMA';
        message = 'Ricordati di partecipare';
    }

    const data = {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        id: Date.now().toString(),
        docId: docId,
        selectedOption: selectedOption,
        status: 'done',
        category: category,
        notTitle: notTitle,
        notBody: message
    };

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
