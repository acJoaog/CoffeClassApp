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

class _ClassifierScreenState extends State<ClassifierScreen>
    with WidgetsBindingObserver {
  late CameraController _controller;
  final _classifier = ClassifierService();

  List<XFile> _capturedImages = [];
  List<List<Map<String, dynamic>>> _allResults = [];

  bool _isCapturing = false;
  bool _isProcessing = false;
  bool _isClassified = false;
  String _status = 'Inicializando...';

  bool _useAverageMode = true;

  static const int TOTAL_PHOTOS = 3;
  static const int DELAY_MS = 600;

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

      final results = await _classifier.classifyImage(_capturedImages.last);
      _allResults.add(results);
    }

    setState(() {
      _isCapturing = false;
      _isProcessing = false;
      _isClassified = true;
      _status = 'Classificação concluída!';
    });
  }

  Future<void> _capturePhoto() async {
    try {
      final xFile = await _controller.takePicture();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/photo_$timestamp.jpg');
      await File(xFile.path).copy(file.path);
      _capturedImages.add(XFile(file.path));
    } catch (e) {
      print('Erro ao capturar foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _useAverageMode
        ? _classifier.calculateAverageConfidence(_allResults)
        : _classifier.calculateHighestConfidence(_allResults);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classificador de Café'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A7C59),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // scroll
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // preview
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: _controller.value.isInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.previewSize!.height,
                            height: _controller.value.previewSize!.width,
                            child: CameraPreview(_controller),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),

              const SizedBox(height: 20),

              // botao classificar
              ElevatedButton.icon(
                onPressed:
                    _isCapturing || _isProcessing ? null : _startCaptureProcess,
                icon: _isCapturing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(_isClassified ? Icons.refresh : Icons.camera_alt),
                label: Text(
                  _isCapturing
                      ? 'Capturando...'
                      : _isClassified
                          ? 'Nova Captura'
                          : 'Classificar',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7C59),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              // botao modo
              if (_isClassified)
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _useAverageMode = !_useAverageMode),
                  icon: Icon(
                      _useAverageMode ? Icons.bar_chart : Icons.trending_up),
                  label: Text(_useAverageMode
                      ? 'Usar Maior Confiança'
                      : 'Usar Média das Confianças'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A7C59),
                    side:
                        const BorderSide(color: Color(0xFF4A7C59), width: 2),
                  ),
                ),

              const SizedBox(height: 12),

              Text(
                _status,
                style: const TextStyle(fontSize: 15, color: Colors.brown),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // resultado final
              if (_isClassified)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Resultado Final',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text(
                            result?['label'] ?? 'Indefinido',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A7C59)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${((result?['confidence'] as double? ?? 0.0) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 28,
                                color: Colors.brown[800],
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            result?['mode'] ?? '',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _classifier.dispose();
    WidgetsBinding.instance.removeObserver(this);

    for (var img in _capturedImages) {
      final file = File(img.path);
      if (file.existsSync()) file.deleteSync();
    }

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
