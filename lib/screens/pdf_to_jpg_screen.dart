import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../services/pdf_converter_service.dart';

class PdfToJpgScreen extends StatefulWidget {
  const PdfToJpgScreen({super.key});

  @override
  State<PdfToJpgScreen> createState() => _PdfToJpgScreenState();
}

class _PdfToJpgScreenState extends State<PdfToJpgScreen> {
  final _converterService = PdfConverterService();

  File? _selectedPdf;
  bool _isConverting = false;
  List<String> _convertedImagePaths = [];
  double _conversionProgress = 0.0;
  int _quality = 90;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to JPG'),
        backgroundColor: const Color(0xFFDB2777),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileSelector(),
            const SizedBox(height: 20),
            _buildQualitySlider(),
            const SizedBox(height: 20),
            _buildConvertButton(),
            if (_isConverting) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _conversionProgress / 100),
              const SizedBox(height: 8),
              Text(
                'Converting... ${_conversionProgress.toInt()}%',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            _buildResultsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select PDF File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPdf != null
                        ? path.basename(_selectedPdf!.path)
                        : 'No file selected',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _selectPdfFile,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Browse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB2777),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Image Quality',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('$_quality%', style: const TextStyle(fontSize: 16)),
              ],
            ),
            Slider(
              value: _quality.toDouble(),
              min: 10,
              max: 100,
              divisions: 9,
              label: '$_quality%',
              onChanged: (value) {
                setState(() {
                  _quality = value.round();
                });
              },
              activeColor: const Color(0xFFDB2777),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertButton() {
    return ElevatedButton.icon(
      onPressed:
          _selectedPdf == null || _isConverting ? null : _convertPdfToJpg,
      icon: const Icon(Icons.transform),
      label: const Text('Convert to JPG'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFDB2777),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_convertedImagePaths.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Converted images will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_convertedImagePaths.length} Images',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _shareImages,
                icon: const Icon(Icons.share),
                label: const Text('Share All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _convertedImagePaths.length,
              itemBuilder: (context, index) {
                final imagePath = _convertedImagePaths[index];
                return GestureDetector(
                  onTap: () => _previewImage(imagePath),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(imagePath), fit: BoxFit.cover),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Page ${index + 1}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedPdf = File(result.files.first.path!);
        _convertedImagePaths = [];
      });
    }
  }

  Future<void> _convertPdfToJpg() async {
    if (_selectedPdf == null) return;

    setState(() {
      _isConverting = true;
      _conversionProgress = 0;
      _convertedImagePaths = [];
    });

    try {
      final imagePaths = await _converterService.pdfToJpg(
        _selectedPdf!.path,
        quality: _quality,
        onProgress: (progress) {
          setState(() {
            _conversionProgress = progress;
          });
        },
      );

      setState(() {
        _convertedImagePaths = imagePaths;
        _isConverting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully converted to ${imagePaths.length} JPG images',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConverting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _previewImage(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(path.basename(imagePath)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => Share.shareXFiles([XFile(imagePath)]),
                  ),
                ],
              ),
              body: Center(
                child: InteractiveViewer(child: Image.file(File(imagePath))),
              ),
            ),
      ),
    );
  }

  void _shareImages() {
    if (_convertedImagePaths.isNotEmpty) {
      Share.shareXFiles(
        _convertedImagePaths.map((path) => XFile(path)).toList(),
      );
    }
  }
}
