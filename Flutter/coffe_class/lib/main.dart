import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/classifier_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Class',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
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

class _ClassifierScreenState extends State<ClassifierScreen> {
  final _picker = ImagePicker();
  final _classifier = ClassifierService();
  XFile? _image;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    setState(() {
      _image = image;
      _isLoading = true;
      _results = [];
    });

    final results = await _classifier.classifyImage(image);

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classificador de Café'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(Icons.camera_alt, 'Câmera', () => _pickImage(ImageSource.camera)),
                _buildButton(Icons.photo_library, 'Galeria', () => _pickImage(ImageSource.gallery)),
              ],
            ),
            const SizedBox(height: 24),

            // Imagem
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.brown.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_image!.path), fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 64, color: Colors.brown),
                          SizedBox(height: 8),
                          Text('Selecione uma imagem'),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Resultados
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_results.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resultado:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      ..._results.take(3).map((result) {
                        final label = result['label'] as String;
                        final confidence = (result['confidence'] as double) * 100;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
                              Text('${confidence.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              )
            else if (_image != null)
              const Text('Nenhum resultado detectado.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}