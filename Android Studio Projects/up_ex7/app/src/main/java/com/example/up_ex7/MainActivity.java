package com.example.up_ex7;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.widget.Button;
import android.widget.ImageView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    ImageView img;
    Button bt1, bt2;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        bt1 = findViewById(R.id.button);
        bt2 = findViewById(R.id.button2);
        img = findViewById(R.id.imageView);

        bt1.setOnClickListener(v -> loadInThread(R.drawable.img1));
        bt2.setOnClickListener(v -> loadInThread(R.drawable.img2));
    }

    // The image is decoded on a separate (worker) thread,
    // then shown on the UI thread with img.post(...)
    private void loadInThread(final int resId) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                final Bitmap bmp = BitmapFactory.decodeResource(getResources(), resId);
                img.post(new Runnable() {
                    @Override
                    public void run() {
                        img.setImageBitmap(bmp);
                    }
                });
            }
        }).start();
    }
}
