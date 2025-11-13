import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
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
      _isNCHW = _inputShape[1] == 3 && _inputShape[2] == _inputSize;

      print('Input shape: $_inputShape (${_isNCHW ? "NCHW" : "NHWC"})');
      print('Output size: $_outputSize');

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      print('Modelo carregado: ${_labels!.length} classes');
    } catch (e) {
      print('Erro ao carregar modelo: $e');
      rethrow;
    }
  }

  Float32List _preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);
    final input = Float32List(1 * _inputSize * _inputSize * 3);
    int idx = 0;

    if (_isNCHW) {
      for (int c = 0; c < 3; c++) {
        for (int y = 0; y < _inputSize; y++) {
          for (int x = 0; x < _inputSize; x++) {
            final p = resized.getPixel(x, y);
            final v = c == 0 ? p.r / 255.0 : c == 1 ? p.g / 255.0 : p.b / 255.0;
            input[idx++] = v;
          }
        }
      }
    } else {
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final p = resized.getPixel(x, y);
          input[idx++] = p.r / 255.0;
          input[idx++] = p.g / 255.0;
          input[idx++] = p.b / 255.0;
        }
      }
    }
    return input;
  }

  img.Image _rotateImage(img.Image src, int angle) => img.copyRotate(src, angle: angle);

  img.Image _shearImage(img.Image src, double shearDeg) {
    final shear = math.tan(shearDeg * math.pi / 180.0);
    final w = src.width;
    final h = src.height;
    final maxShift = (h * shear).abs().ceil();
    final newW = w + maxShift;

    final out = img.Image(width: newW, height: h, numChannels: src.numChannels);
    final bg = src.numChannels == 4 ? img.ColorRgba8(0, 0, 0, 255) : img.ColorRgb8(0, 0, 0);
    img.fill(out, color: bg);

    final cx = h / 2.0;
    final offset = maxShift ~/ 2;

    for (int y = 0; y < h; y++) {
      final shift = ((y - cx) * shear).round();
      for (int x = 0; x < w; x++) {
        final dstX = x + shift + offset;
        if (dstX >= 0 && dstX < newW) {
          out.setPixel(dstX, y, src.getPixel(x, y));
        }
      }
    }

    final cropX = (out.width - w) ~/ 2;
    return img.copyCrop(out, x: cropX, y: 0, width: w, height: h);
  }

  List<img.Image> _generateAugmentedImages(img.Image original) {
    final rand = math.Random();
    final rot = rand.nextInt(31) - 15;
    final shear = (rand.nextInt(31) - 15).toDouble();

    final a = img.flipHorizontal(original);
    final aRot = _rotateImage(a, rot);

    final b = img.flipVertical(original);
    final bShear = _shearImage(b, shear);

    return [original, aRot, bShear];
  }

  Future<List<Map<String, dynamic>>> classifyImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Falha ao decodificar imagem');

    final raw = _preprocessImage(decoded);
    final input = raw.reshape(_inputShape);

    final outputBuffer = List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]);
    final outputMap = {0: outputBuffer};

    _interpreter!.runForMultipleInputs([input], outputMap);

    return _postprocess(outputBuffer[0]);
  }

  Future<List<List<Map<String, dynamic>>>> classifyWithAugmentations(XFile file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Falha ao decodificar imagem');

    final variants = _generateAugmentedImages(decoded);
    final all = <List<Map<String, dynamic>>>[];

    for (final v in variants) {
      final raw = _preprocessImage(v);
      final input = raw.reshape(_inputShape);

      final outputBuffer = List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]);
      final outputMap = {0: outputBuffer};

      _interpreter!.runForMultipleInputs([input], outputMap);
      all.add(_postprocess(outputBuffer[0]));
    }
    return all;
  }

  List<Map<String, dynamic>> _postprocess(List<dynamic> output) {
    final res = <Map<String, dynamic>>[];
    for (int i = 0; i < _outputSize; i++) {
      final conf = (output[i] as num).toDouble();
      if (conf > 0.01) {
        res.add({'label': _labels![i], 'confidence': conf});
      }
    }
    res.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    return res;
  }

  Map<String, dynamic>? findMostFrequentResult(List<List<Map<String, dynamic>>> all) {
    final map = <String, List<double>>{};

    for (final list in all) {
      if (list.isNotEmpty) {
        final label = list[0]['label'] as String;
        final conf = list[0]['confidence'] as double;
        map.putIfAbsent(label, () => []).add(conf);
      }
    }

    if (map.isEmpty) return null;

    String? bestLabel;
    double bestScore = -1.0;

    map.forEach((label, confs) {
      final count = confs.length;
      final avg = confs.reduce((a, b) => a + b) / count;
      final score = count * avg;
      if (score > bestScore) {
        bestScore = score;
        bestLabel = label;
      }
    });

    final avgConf = map[bestLabel!]!.reduce((a, b) => a + b) / map[bestLabel!]!.length;
    return {'label': bestLabel!, 'confidence': avgConf};
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}