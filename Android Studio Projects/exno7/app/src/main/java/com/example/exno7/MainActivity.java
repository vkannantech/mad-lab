package com.example.exno7;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;
import androidx.core.app.ActivityCompat;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    Button buttonSend;
    EditText textSMS;
    EditText textlon;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Referencing the Views
        buttonSend = findViewById(R.id.buttonSend);
        textSMS = findViewById(R.id.editTextSMS);
        textlon = findViewById(R.id.textlon);

        // Check for location permission
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            // Request permission if not already granted
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION}, 1);
            return;
        }

        startLocationUpdates();
    }

    // Uses GPS + network (Wi-Fi/cell) location, and shows the last known fix immediately.
    // GPS alone often gets no fix indoors (e.g. in a lab).
    private void startLocationUpdates() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        LocationManager mlocManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
        if (mlocManager == null) return;
        if (!mlocManager.isProviderEnabled(LocationManager.GPS_PROVIDER) && !mlocManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
            Toast.makeText(this, "Turn ON Location in phone settings", Toast.LENGTH_LONG).show();
        }
        LocationListener mlocListener = new MyLocationListener();
        for (String provider : new String[]{LocationManager.NETWORK_PROVIDER, LocationManager.GPS_PROVIDER}) {
            if (!mlocManager.getAllProviders().contains(provider)) continue;
            Location last = mlocManager.getLastKnownLocation(provider);
            if (last != null) mlocListener.onLocationChanged(last);
            mlocManager.requestLocationUpdates(provider, 0, 0, mlocListener);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == 1) {
            boolean anyGranted = false;
            for (int r : grantResults) if (r == PackageManager.PERMISSION_GRANTED) anyGranted = true;
            if (anyGranted) { // fine OR approximate location
                startLocationUpdates();
            } else {
                // Permission denied, show a message to the user
                Toast.makeText(this, "Location permission is required for this app", Toast.LENGTH_SHORT).show();
            }
        }
    }

    // Inner class for handling location updates
    public class MyLocationListener implements LocationListener {
        @Override
        public void onLocationChanged(Location loc) {
            // Getting the latitude and longitude
            Double lat = loc.getLatitude();
            Double lon = loc.getLongitude();

            // Updating the EditText fields with the new location
            textSMS.setText(lat.toString());
            textlon.setText(lon.toString());
        }

        @Override
        public void onProviderDisabled(String provider) {
            // Notify user if GPS is disabled
            Toast.makeText(getApplicationContext(), "GPS Disabled", Toast.LENGTH_SHORT).show();
        }

        @Override
        public void onProviderEnabled(String provider) {
            // Notify user if GPS is enabled
            Toast.makeText(getApplicationContext(), "GPS Enabled", Toast.LENGTH_SHORT).show();
        }

        @Override
        public void onStatusChanged(String provider, int status, Bundle extras) {
            // You can handle the provider status change here if needed
        }
    }
}
