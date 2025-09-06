package com.example.coffeclass;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Button;
import android.content.Intent;
import android.graphics.Bitmap;
import android.provider.MediaStore;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MainActivity extends AppCompatActivity {

    private static final int REQUEST_IMAGE_CAPTURE = 1;
    private static final int REQUEST_CAMERA_PERMISSION = 100;
    private static final int TOTAL_PHOTOS = 3;

    private TFLiteHelper tfliteHelper;
    private TextView textView;
    private Button btnCapture;

    private final List<Bitmap> capturedImages = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        textView = findViewById(R.id.textViewResult);
        btnCapture = findViewById(R.id.buttonCapture);

        tfliteHelper = new TFLiteHelper(this, "model.tflite", "labels.txt");

        btnCapture.setOnClickListener(v -> takePhoto());
    }

    private void takePhoto() {
        // Verifica permissão da câmera
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA_PERMISSION);
        } else {
            openCamera();
        }
    }

    private void openCamera() {
        if (capturedImages.size() < TOTAL_PHOTOS) {
            Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            if (takePictureIntent.resolveActivity(getPackageManager()) != null) {
                startActivityForResult(takePictureIntent, REQUEST_IMAGE_CAPTURE);
            }
        } else {
            classifyAll();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                openCamera();
            } else {
                Toast.makeText(this, "Permissão da câmera negada", Toast.LENGTH_SHORT).show();
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == REQUEST_IMAGE_CAPTURE && resultCode == RESULT_OK) {
            Bitmap imageBitmap = (Bitmap) data.getExtras().get("data");
            if (imageBitmap != null) {
                capturedImages.add(imageBitmap);
                Toast.makeText(this, "Foto " + capturedImages.size() + " capturada", Toast.LENGTH_SHORT).show();

                if (capturedImages.size() < TOTAL_PHOTOS) {
                    // Abrir câmera para próxima foto automaticamente
                    openCamera();
                } else {
                    classifyAll();
                }
            } else {
                Toast.makeText(this, "Erro ao capturar imagem", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private void classifyAll() {
        Map<String, Integer> counts = new HashMap<>();

        for (Bitmap bmp : capturedImages) {
            String label = tfliteHelper.classify(bmp);
            counts.put(label, counts.getOrDefault(label, 0) + 1);
        }

        // Descobre a classificação mais frequente
        String mostFrequent = null;
        int maxCount = 0;
        for (Map.Entry<String, Integer> entry : counts.entrySet()) {
            if (entry.getValue() > maxCount) {
                maxCount = entry.getValue();
                mostFrequent = entry.getKey();
            }
        }

        textView.setText("Resultado: " + mostFrequent);

        // Limpa para próxima rodada de fotos
        capturedImages.clear();
    }
}

