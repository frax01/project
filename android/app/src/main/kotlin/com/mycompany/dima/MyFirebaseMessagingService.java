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

    //@Override
    //public void onMessageReceived(RemoteMessage remoteMessage) {
    //    // Gestisci la ricezione della notifica push qui
    //}
    
    //@Override
    //public void onMessageReceived(RemoteMessage remoteMessage) {
    //    System.out.println("From: " + remoteMessage.getFrom());
    //    System.out.println("Notification Message Body: " + remoteMessage.getNotification().getBody());
//
    //    createNotificationChannel();
    //    showNotification(remoteMessage);
    //}
    //  
    //private void createNotificationChannel() {
    //    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
    //        String channelId = "my_channel_id";
    //        String channelName = "My Channel Name";
    //        
    //        NotificationChannel channel = new NotificationChannel(
    //                channelId,
    //                channelName,
    //                NotificationManager.IMPORTANCE_HIGH
    //        );
//
    //        NotificationManager notificationManager = getSystemService(NotificationManager.class);
//
    //        if (notificationManager != null) {
    //            notificationManager.createNotificationChannel(channel);
    //        }
    //    }
    //}
//
    //private void showNotification(RemoteMessage remoteMessage) {
    //    NotificationCompat.Builder builder = new NotificationCompat.Builder(this, "my_channel_id")
    //            .setSmallIcon(R.drawable.photo)
    //            .setContentTitle(remoteMessage.getNotification().getTitle())
    //            .setContentText(remoteMessage.getNotification().getBody())
    //            .setPriority(NotificationCompat.PRIORITY_HIGH);
//
    //    NotificationManager notificationManager = getSystemService(NotificationManager.class);
//
    //    if (notificationManager != null) {
    //        notificationManager.notify(0, builder.build());
    //    }
    //}
    //
    //public void onMessageOpenedApp(RemoteMessage remoteMessage) {
    //    // Gestisci l'apertura dell'app tramite una notifica push quando l'app è in background o chiusa.
    //    System.out.println("Message data payload");
    //    // Gestisci il payload della notifica e avvia l'azione desiderata.
    //}
}
