package com.mycompany.dima;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class MyFirebaseMessagingService extends FirebaseMessagingService {
    
    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        createNotificationChannel();
        // Handle FCM messages here.
        // If the application is in the foreground handle both data and notification messages here.
        // Also, if you intend on generating your own notifications as a result of a received FCM
        // message, here is where that should be initiated.
        System.out.println("From: " + remoteMessage.getFrom());
        System.out.println("Notification Message Body: " + remoteMessage.getNotification().getBody());

        // Creare il canale di notifica qui

        // Mostrare la notifica
        showNotification(remoteMessage);
    }

    private void createNotificationChannel() {
        System.out.println("ciaoooooooooooooooooooo");
        // Verificare la versione di Android per assicurarsi che il canale sia supportato
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Impostare l'ID e il nome del canale
            String channelId = "my_channel_id";
            String channelName = "My Channel Name";
            
            // Creare il canale di notifica
            NotificationChannel channel = new NotificationChannel(
                    channelId,
                    channelName,
                    NotificationManager.IMPORTANCE_HIGH
            );

            // Ottenere il NotificationManager
            NotificationManager notificationManager = getSystemService(NotificationManager.class);

            // Aggiungere il canale al NotificationManager
            if (notificationManager != null) {
                notificationManager.createNotificationChannel(channel);
            }
        }
    }

    private void showNotification(RemoteMessage remoteMessage) {
        System.out.println("hellooooooooooooo");
        // Costruire la notifica utilizzando i dati di FCM ricevuti
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, "my_channel_id")
                .setSmallIcon(R.drawable.photo)
                .setContentTitle(remoteMessage.getNotification().getTitle())
                .setContentText(remoteMessage.getNotification().getBody())
                .setPriority(NotificationCompat.PRIORITY_HIGH);

        // Ottenere il NotificationManager
        NotificationManager notificationManager = getSystemService(NotificationManager.class);

        // Mostrare la notifica
        if (notificationManager != null) {
            notificationManager.notify(0, builder.build());
        }
    }
}
