package com.example.up_ex9;

import android.app.Activity;
import android.os.Bundle;
import android.os.Environment;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;

public class MainActivity extends Activity {
    EditText inputText;
    TextView response;
    Button saveButton, readButton;

    private final String filename = "SampleFile.txt";
    private final String filepath = "MyFileStorage";
    File myExternalFile;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        inputText = findViewById(R.id.myInputText);
        response = findViewById(R.id.response);
        saveButton = findViewById(R.id.saveExternalStorage);
        readButton = findViewById(R.id.getExternalStorage);

        saveButton.setOnClickListener(v -> {
            try (FileOutputStream fos = new FileOutputStream(myExternalFile)) {
                fos.write(inputText.getText().toString().getBytes());
                inputText.setText("");
                response.setText("SampleFile.txt saved to External Storage...\n" + myExternalFile.getAbsolutePath());
            } catch (IOException e) {
                response.setText("Save failed: " + e.getMessage());
            }
        });

        readButton.setOnClickListener(v -> {
            StringBuilder myData = new StringBuilder();
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(new FileInputStream(myExternalFile)))) {
                String strLine;
                while ((strLine = br.readLine()) != null) {
                    if (myData.length() > 0) myData.append("\n");
                    myData.append(strLine);
                }
                inputText.setText(myData.toString());
                response.setText("SampleFile.txt data retrieved from External Storage...");
            } catch (IOException e) {
                response.setText("Nothing saved yet. Type text and press SAVE first.");
            }
        });

        if (!isExternalStorageAvailable() || isExternalStorageReadOnly()) {
            saveButton.setEnabled(false);
        } else {
            // App-specific external storage: no permission needed on Android 4.4+
            myExternalFile = new File(getExternalFilesDir(filepath), filename);
        }
    }

    private static boolean isExternalStorageReadOnly() {
        return Environment.MEDIA_MOUNTED_READ_ONLY.equals(Environment.getExternalStorageState());
    }

    private static boolean isExternalStorageAvailable() {
        return Environment.MEDIA_MOUNTED.equals(Environment.getExternalStorageState());
    }
}
