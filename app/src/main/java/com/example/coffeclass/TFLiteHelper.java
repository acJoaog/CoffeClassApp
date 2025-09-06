package com.example.coffeclass;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.DataType;
import org.tensorflow.lite.support.common.FileUtil;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.List;

public class TFLiteHelper {

    private Interpreter interpreter;
    private List<String> labels;
    private int inputWidth, inputHeight, inputChannels;
    private boolean isChannelFirst; // true = NCHW, false = NHWC

    public TFLiteHelper(Context context, String modelPath, String labelsPath) {
        try {
            interpreter = new Interpreter(FileUtil.loadMappedFile(context, modelPath));
            labels = FileUtil.loadLabels(context, labelsPath);

            int[] shape = interpreter.getInputTensor(0).shape();
            DataType type = interpreter.getInputTensor(0).dataType();

            if (shape.length != 4) {
                throw new IllegalArgumentException("Input tensor must be 4D");
            }

            // Detect layout
            if (shape[1] == 3 || shape[1] == 1) {
                isChannelFirst = true; // NCHW
                inputChannels = shape[1];
                inputHeight = shape[2];
                inputWidth = shape[3];
            } else {
                isChannelFirst = false; // NHWC
                inputHeight = shape[1];
                inputWidth = shape[2];
                inputChannels = shape[3];
            }

            Log.d("TFLiteHelper", "Input shape: " + shape[0] + "," + shape[1] + "," + shape[2] + "," + shape[3]);
            Log.d("TFLiteHelper", "Input type: " + type + " ChannelFirst: " + isChannelFirst);

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public String classify(Bitmap bitmap) {
        try {
            // Redimensiona
            Bitmap resized = Bitmap.createScaledBitmap(bitmap, inputWidth, inputHeight, true);
            if (resized.getConfig() != Bitmap.Config.ARGB_8888) {
                resized = resized.copy(Bitmap.Config.ARGB_8888, false);
            }

            // Prepara o buffer
            float[][] output = new float[1][labels.size()];

            if (isChannelFirst) {
                float[][][][] input = bitmapToNCHW(resized);
                interpreter.run(input, output);
            } else {
                float[][][][] input = bitmapToNHWC(resized);
                interpreter.run(input, output);
            }

            // Retorna label com maior valor
            int maxIdx = 0;
            for (int i = 1; i < labels.size(); i++) {
                if (output[0][i] > output[0][maxIdx]) maxIdx = i;
            }

            return labels.get(maxIdx);

        } catch (Exception e) {
            e.printStackTrace();
            return "Erro na classificação";
        }
    }

    private float[][][][] bitmapToNHWC(Bitmap bmp) {
        float[][][][] input = new float[1][inputHeight][inputWidth][inputChannels];
        for (int y = 0; y < inputHeight; y++) {
            for (int x = 0; x < inputWidth; x++) {
                int pixel = bmp.getPixel(x, y);
                input[0][y][x][0] = ((pixel >> 16) & 0xFF) / 255f; // R
                input[0][y][x][1] = ((pixel >> 8) & 0xFF) / 255f;  // G
                input[0][y][x][2] = (pixel & 0xFF) / 255f;         // B
            }
        }
        return input;
    }

    private float[][][][] bitmapToNCHW(Bitmap bmp) {
        float[][][][] input = new float[1][inputChannels][inputHeight][inputWidth];
        for (int y = 0; y < inputHeight; y++) {
            for (int x = 0; x < inputWidth; x++) {
                int pixel = bmp.getPixel(x, y);
                input[0][0][y][x] = ((pixel >> 16) & 0xFF) / 255f; // R
                input[0][1][y][x] = ((pixel >> 8) & 0xFF) / 255f;  // G
                input[0][2][y][x] = (pixel & 0xFF) / 255f;         // B
            }
        }
        return input;
    }

}
