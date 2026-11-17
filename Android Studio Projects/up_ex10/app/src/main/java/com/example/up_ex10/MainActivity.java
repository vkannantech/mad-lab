package com.example.up_ex10;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    EditText etEmail, etSubject, etMessage;
    Button btnSend;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        etEmail = findViewById(R.id.etEmail);
        etSubject = findViewById(R.id.etSubject);
        etMessage = findViewById(R.id.etMessage);
        btnSend = findViewById(R.id.btnSend);

        btnSend.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_SEND);
            intent.setType("message/rfc822");
            intent.putExtra(Intent.EXTRA_EMAIL, new String[]{etEmail.getText().toString()});
            intent.putExtra(Intent.EXTRA_SUBJECT, etSubject.getText().toString());
            intent.putExtra(Intent.EXTRA_TEXT, etMessage.getText().toString());
            try {
                startActivity(Intent.createChooser(intent, "Choose Email App"));
            } catch (ActivityNotFoundException e) {
                Toast.makeText(this, "No email app installed", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
