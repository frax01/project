package com.mycompany.dima;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import android.app.PendingIntent;
import android.content.Intent;

public class MyFirebaseMessagingService extends FirebaseMessagingService {

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
    //    Bitmap largeIcon = BitmapFactory.decodeResource(getResources(), R.drawable.logo);
    //    NotificationCompat.Builder builder = new NotificationCompat.Builder(this, "my_channel_id")
    //            .setSmallIcon(R.drawable.logo)
    //            .setLargeIcon(largeIcon)
    //            .setContentTitle(remoteMessage.getNotification().getTitle())
    //            .setContentText(remoteMessage.getNotification().getBody())
    //            .setPriority(NotificationCompat.PRIORITY_HIGH);
//
    //    //Intent intent = new Intent(this, Login.class);
    //    //intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP); // Cancella altre attività e apri questa
    //    //PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_ONE_SHOT);  
    //    //// Imposta l'intent sulla notifica
    //    //builder.setContentIntent(pendingIntent);
//
    //    NotificationManager notificationManager = getSystemService(NotificationManager.class);
//
    //    if (notificationManager != null) {
    //        notificationManager.notify(0, builder.build());
    //    }
    //}
}
