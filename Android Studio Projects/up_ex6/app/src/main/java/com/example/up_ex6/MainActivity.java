package com.example.up_ex6;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    static final String CHANNEL_ID = "fxec_channel";
    Button notify;
    EditText e;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        notify = findViewById(R.id.button);
        e = findViewById(R.id.editText);

        // Android 8+: notifications need a channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel ch = new NotificationChannel(CHANNEL_ID, "Messages",
                    NotificationManager.IMPORTANCE_DEFAULT);
            getSystemService(NotificationManager.class).createNotificationChannel(ch);
        }
        // Android 13+: ask for notification permission
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 1);
        }

        notify.setOnClickListener(v -> {
            Intent intent = new Intent(MainActivity.this, Main2Activity.class);
            intent.putExtra("msg", e.getText().toString());
            PendingIntent pending = PendingIntent.getActivity(MainActivity.this, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

            Notification.Builder b = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                    ? new Notification.Builder(MainActivity.this, CHANNEL_ID)
                    : new Notification.Builder(MainActivity.this);
            Notification noti = b.setContentTitle("New Message")
                    .setContentText(e.getText().toString())
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setContentIntent(pending)
                    .build();

            NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            noti.flags |= Notification.FLAG_AUTO_CANCEL;
            manager.notify(0, noti);
        });
    }
}
