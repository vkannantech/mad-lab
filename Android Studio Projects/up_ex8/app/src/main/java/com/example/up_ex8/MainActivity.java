package com.example.up_ex8;

import android.app.WallpaperManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

import java.io.IOException;
import java.util.Random;

public class MainActivity extends AppCompatActivity {

    ImageView imageView;
    Button btnStart;

    int[] images = {
            R.drawable.img1,
            R.drawable.img2,
            R.drawable.img3,
            R.drawable.img4
    };

    Handler handler = new Handler(Looper.getMainLooper());
    Random random = new Random();

    Runnable runnable = new Runnable() {
        @Override
        public void run() {
            int index = random.nextInt(images.length);
            imageView.setImageResource(images[index]);

            WallpaperManager wallpaperManager = WallpaperManager.getInstance(getApplicationContext());
            Bitmap bitmap = BitmapFactory.decodeResource(getResources(), images[index]);
            try {
                wallpaperManager.setBitmap(bitmap);
                Toast.makeText(MainActivity.this, "Wallpaper Changed", Toast.LENGTH_SHORT).show();
            } catch (IOException e) {
                e.printStackTrace();
            }
            handler.postDelayed(this, 30000); // 30 seconds
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        imageView = findViewById(R.id.imageView);
        btnStart = findViewById(R.id.btnStart);

        btnStart.setOnClickListener(v -> {
            handler.removeCallbacks(runnable); // avoid starting two timers
            handler.post(runnable);
        });
    }

    @Override
    protected void onDestroy() {
        handler.removeCallbacks(runnable);
        super.onDestroy();
    }
}
