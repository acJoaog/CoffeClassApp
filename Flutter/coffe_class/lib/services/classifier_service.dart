import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      print('Input shape: ${inputTensor.shape}');
      print('Input type: ${inputTensor.type}');
      print('Output shape: ${outputTensor.shape}');

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();

      print('Modelo carregado: ${_labels!.length} classes');
    } catch (e) {
      print('Erro ao carregar modelo: $e');
    }
  }

  // NCHW + float32 [0.0, 1.0]
  List<List<List<List<double>>>> _preprocessImage(XFile imageFile) {
    const inputSize = 256;

    final bytes = File(imageFile.path).readAsBytesSync();
    final image = img.decodeImage(bytes)!;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // [1, 3, 256, 256]
    final input = List.generate(1, (_) =>
        List.generate(3, (_) =>
            List.generate(inputSize, (_) =>
                List.filled(inputSize, 0.0)
            )
        )
    );

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][0][y][x] = pixel.r.toDouble() / 255.0; // R
        input[0][1][y][x] = pixel.g.toDouble() / 255.0; // G
        input[0][2][y][x] = pixel.b.toDouble() / 255.0; // B
      }
    }

    return input;
  }

  Future<List<Map<String, dynamic>>> classifyImage(XFile image) async {
    if (_interpreter == null || _labels == null) {
      await loadModel();
    }

    final input = _preprocessImage(image);

    // Output: [1, 5]
    final output = List.filled(1, List.filled(5, 0.0));

    _interpreter!.run(input, output);

    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < _labels!.length; i++) {
      final confidence = output[0][i];
      if (confidence > 0.01) {
        results.add({
          'label': _labels![i],
          'confidence': confidence,
        });
      }
    }

    results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    return results;
  }

  void dispose() {
    _interpreter?.close();
  }
}