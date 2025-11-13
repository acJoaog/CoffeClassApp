import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'services/classifier_service.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Class',
      theme: ThemeData(primarySwatch: Colors.brown, useMaterial3: true),
      home: const ClassifierScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ClassifierScreen extends StatefulWidget {
  const ClassifierScreen({super.key});
  @override
  State<ClassifierScreen> createState() => _ClassifierScreenState();
}

class _ClassifierScreenState extends State<ClassifierScreen> with WidgetsBindingObserver {
  late CameraController _controller;
  final _classifier = ClassifierService();
  List<XFile> _capturedImages = [];
  List<List<Map<String, dynamic>>> _allResults = [];
  bool _isCapturing = false;
  bool _isProcessing = false;
  bool _isClassified = false;
  String _status = 'Inicializando...';

  static const int TOTAL_PHOTOS = 3;
  static const int DELAY_MS = 500;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _classifier.loadModel();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      setState(() => _status = 'Câmera não disponível');
      return;
    }

    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller.initialize();
    if (mounted) {
      setState(() => _status = 'Pronto para capturar');
    }
  }

  Future<void> _startCaptureProcess() async {
    if (_isCapturing || _isProcessing) return;

    setState(() {
      _capturedImages.clear();
      _allResults.clear();
      _isClassified = false;
      _isCapturing = true;
      _isProcessing = true;
      _status = 'Capturando foto 1 de $TOTAL_PHOTOS...';
    });

    for (int i = 0; i < TOTAL_PHOTOS; i++) {
      await Future.delayed(const Duration(milliseconds: DELAY_MS));
      if (!mounted) return;

      setState(() => _status = 'Capturando foto ${i + 1} de $TOTAL_PHOTOS...');
      await _capturePhoto();
    }

    setState(() {
      _isCapturing = false;
      _status = 'Classificando ${_capturedImages.length * 3} imagens...';
    });

    await _classifyAll();

    if (mounted) {
      setState(() {
        _isClassified = true;
        _isProcessing = false;
        _status = 'Classificação concluída!';
      });
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final xFile = await _controller.takePicture();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(xFile.path).copy(file.path);
      _capturedImages.add(XFile(file.path));
    } catch (e) {
      print('Erro ao capturar foto: $e');
    }
  }

  Future<void> _classifyAll() async {
    _allResults.clear();
    for (var image in _capturedImages) {
      final augmentedResults = await _classifier.classifyWithAugmentations(image);
      for (var res in augmentedResults) {
        _allResults.add(res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _classifier.findMostFrequentResult(_allResults);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classificador de Café'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A7C59),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Column(
        children: [
          // PREVIEW DA CÂMERA
          Container(
            width: 300,
            height: 300,
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.brown, width: 3),
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
            ),
            child: _controller.value.isInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: _controller.value.previewSize?.width ?? 300,
                        height: _controller.value.previewSize?.height ?? 300,
                        child: CameraPreview(_controller),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          const SizedBox(height: 16),

          // BOTÃO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                key: ValueKey<bool>(_isClassified),
                onPressed: _isCapturing || _isProcessing ? null : _startCaptureProcess,
                icon: _isCapturing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_isClassified ? Icons.refresh : Icons.camera_alt),
                label: Text(
                  _isCapturing
                      ? 'Capturando...'
                      : _isClassified
                          ? 'Nova Captura'
                          : 'Classificar',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7C59),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // STATUS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _status,
              style: const TextStyle(fontSize: 14, color: Colors.brown),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // RESULTADO
          Expanded(
            child: _allResults.isEmpty
                ? const Center(
                    child: Text(
                      'Capture fotos para ver o resultado',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Resultado:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Text(
                                result?['label'] ?? 'Não identificado',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A7C59)),
                              ),
                              if (result != null) ...[
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _classifier.dispose();
    WidgetsBinding.instance.removeObserver(this);

    // DELETAR IMAGENS TEMPORÁRIAS
    for (var xfile in _capturedImages) {
      final file = File(xfile.path);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (e) {
          print('Erro ao deletar imagem temporária: $e');
        }
      }
    }
    _capturedImages.clear();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }
}