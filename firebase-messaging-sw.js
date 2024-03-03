importScripts('https://www.gstatic.com/firebasejs/7.6.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/7.6.0/firebase-messaging.js');

firebase.initializeApp({
    apiKey: 'apikey', // sostituisci con la tua chiave API
    authDomain: 'club-60d94.firebaseapp.com', // sostituisci con il tuo dominio di autenticazione
    projectId: 'club-60d94', // sostituisci con il tuo ID progetto
    storageBucket: 'club-60d94.appspot.com', // sostituisci con il tuo bucket di storage
    messagingSenderId: '53952636966', // sostituisci con il tuo ID mittente di messaggistica
    appId: '1:53952636966:android:4913f93f8c6e0fc8959ee7', // sostituisci con il tuo ID app
});

const messaging = firebase.messaging();