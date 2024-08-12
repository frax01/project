/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

const serverKey = 'AIzaSyAkmPm2DpVcfIg6uXMUuj7uLIxGd371qqM';  // Sostituisci con il tuo server key di Firebase

exports.scheduleNotification = functions.pubsub.schedule('every day 08:00').timeZone('Europe/Rome').onRun(async (context) => {
    const tokens = await fetchTokens(); // Funzione che recupera i token degli utenti

    const message = {
        notification: {
            title: 'Buongiorno!',
            body: 'Ecco la notifica programmata delle 8 del mattino.',
        },
        data: {
            category: 'daily_reminder',
        },
    };

    for (const token of tokens) {
        await sendNotification(token, message);
    }

    return null;
});

async function fetchTokens() {
    const tokens = [];
    try {
        const users = await admin.firestore().collection('user').get();
        users.forEach(user => {
            if (user.data().token) {
                tokens.push(...user.data().token);
            }
        });
    } catch (error) {
        console.error('Errore nel recupero dei token: ', error);
    }
    return tokens;
}

async function sendNotification(token, message) {
    try {
        await axios.post('https://fcm.googleapis.com/fcm/send', {
            to: token,
            notification: message.notification,
            data: message.data,
        }, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `key=${serverKey}`,
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
