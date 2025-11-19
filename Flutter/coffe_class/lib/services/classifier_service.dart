import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  Interpreter? _interpreter;
  List<String>? _labels;

  late int _inputSize;
  late List<int> _inputShape;
  late int _outputSize;
  late bool _isNCHW;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      _inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;

      _inputSize = _inputShape[1] == _inputShape[2] ? _inputShape[1] : 256;
      _outputSize = outputShape[1];
      _isNCHW = _inputShape[1] == 1 && _inputShape[1] == 3; // NCHW: [1,3,224,224]

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

      print('Modelo carregado com sucesso: ${_labels!.length} classes');
      print('Input shape: $_inputShape | Tamanho: $_inputSize | Formato: ${_isNCHW ? "NCHW" : "NHWC"}');
    } catch (e) {
      print('Erro ao carregar modelo: $e');
      rethrow;
    }
  }

  Float32List _preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);
    final buffer = Float32List(1 * 3 * _inputSize * _inputSize);
    int offset = 0;

    if (_isNCHW) {
      // Formato NCHW [1, 3, H, W]
      for (int c = 0; c < 3; c++) {
        for (int h = 0; h < _inputSize; h++) {
          for (int w = 0; w < _inputSize; w++) {
            final pixel = resized.getPixel(w, h);
            final value = c == 0
                ? pixel.r / 255.0
                : c == 1
                    ? pixel.g / 255.0
                    : pixel.b / 255.0;
            buffer[offset++] = value;
          }
        }
      }
    } else {
      // Formato NHWC [1, H, W, 3]
      for (int h = 0; h < _inputSize; h++) {
        for (int w = 0; w < _inputSize; w++) {
          final pixel = resized.getPixel(w, h);
          buffer[offset++] = pixel.r / 255.0;
          buffer[offset++] = pixel.g / 255.0;
          buffer[offset++] = pixel.b / 255.0;
        }
      }
    }
    return buffer;
  }

  Future<List<Map<String, dynamic>>> classifyImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Não foi possível decodificar a imagem');

    final inputData = _preprocessImage(image);
    final input = inputData.reshape(_inputShape);

    final output = List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]);
    final outputMap = {0: output};

    _interpreter!.runForMultipleInputs([input], outputMap);

    return _postprocess(output[0]);
  }

  List<Map<String, dynamic>> _postprocess(List<dynamic> rawOutput) {
    final List<Map<String, dynamic>> results = [];
    for (int i = 0; i < _outputSize; i++) {
      final confidence = (rawOutput[i] as num).toDouble();
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

  /// MODO 1: Classe mais frequente -> média das suas confidências
  Map<String, dynamic>? calculateAverageConfidence(List<List<Map<String, dynamic>>> allResults) {
    if (allResults.isEmpty) return null;

    final Map<String, List<double>> labelConfidences = {};

    for (final resultList in allResults) {
      if (resultList.isNotEmpty) {
        final label = resultList[0]['label'] as String;
        final conf = resultList[0]['confidence'] as double;
        labelConfidences.putIfAbsent(label, () => []).add(conf);
      }
    }

    if (labelConfidences.isEmpty) return null;

    String bestLabel = '';
    double bestAvg = -1;

    labelConfidences.forEach((label, confs) {
      final avg = confs.reduce((a, b) => a + b) / confs.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestLabel = label;
      }
    });

    return {
      'label': bestLabel,
      'confidence': bestAvg,
      'mode': 'Média das Confianças',
    };
  }

  /// MODO 2: Maior confiança absoluta (independente da classe)
  Map<String, dynamic>? calculateHighestConfidence(List<List<Map<String, dynamic>>> allResults) {
    Map<String, dynamic>? best;

    for (final resultList in allResults) {
      if (resultList.isNotEmpty) {
        final candidate = resultList[0];
        final conf = candidate['confidence'] as double;

        if (best == null || conf > (best['confidence'] as double)) {
          best = {
            'label': candidate['label'],
            'confidence': conf,
            'mode': 'Maior Confiança',
          };
        }
      }
    }
    return best;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}