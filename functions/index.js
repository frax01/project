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

exports.scheduleNotification = functions.pubsub.schedule('every day 22:04').timeZone('Europe/Rome').onRun(async (context) => {
    const usersBirthday = ['clZZVrDxSbaEz1lBJ3wClJ:APA91bEvMOBDI0P9_xjthTfCHy-O_XmvtyYhhKUhVzCWtS8TCcYwdTI6LLWpQdIV4sqJ6jOlxp7vBTuHBu5QJlBNM0SR-qTSl2QV2RYfAcW94hbm4V42r2j3EJC6TKAsbFktJgoFOW8b'];
    //await fetchUsersBirthday(); //per i compleanni
    //await fetchTokensEvent(); //per gli eventi

    if (usersBirthday.length > 0) {
        for (const name in usersBirthday) {
            const tokensBirthday = await fetchTokensBirthday();
            for (const token of tokensBirthday) {
                await sendNotification(token, 'compleanno', name);
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
            }
        });
    } catch (error) {
        console.error('Errore nel recupero dei token: ', error);
    }
    return birthdays;
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
    return ['c-tLWUaEQXeHHdo13a5zGM:APA91bH5lvCJvMPMMxLvSjKBYuvWuSuetUvgXB2E7Lptmm8RqpyGiaBb-dAXKdS45jfHLMDclSv5tvkctYAaXGRUwJEV_HDwdN_o5Dyzc6jAN-Z_FRTyShZTMIgMRqVu7SHhQjMrlnu7']; //tokens;
}

async function sendNotification(token, section, name) {

    const docId = '';
    const selectedOption = '';
    const category = '';
    const notTitle = '';
    const message = '';

    if(section=='compleanno') {
        docId = '';
        selectedOption = '';
        category = section;
        notTitle = `Oggi è il compleanno di ${name}`;
        message = 'Fagli gli auguri!';
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
