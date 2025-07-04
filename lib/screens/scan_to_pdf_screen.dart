import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

class ScanToPdfScreen extends StatefulWidget {
  const ScanToPdfScreen({super.key});

  @override
  State<ScanToPdfScreen> createState() => _ScanToPdfScreenState();
}

class _ScanToPdfScreenState extends State<ScanToPdfScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _scannedImages = [];
  bool _isProcessing = false;

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _scannedImages.add(image);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to capture image: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isNotEmpty) {
        setState(() {
          _scannedImages.addAll(images);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick images: $e');
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _scannedImages.removeAt(index);
    });
  }

  Future<void> _reorderImages(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final XFile item = _scannedImages.removeAt(oldIndex);
      _scannedImages.insert(newIndex, item);
    });
  }

  Future<Uint8List> _imageToUint8List(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _generatePdf() async {
    if (_scannedImages.isEmpty) {
      _showErrorDialog('Please add at least one image to create a PDF');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final pdf = pw.Document();

      for (final imageFile in _scannedImages) {
        final imageBytes = await _imageToUint8List(imageFile);
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      final pdfBytes = await pdf.save();
      await _savePdf(pdfBytes);
    } catch (e) {
      _showErrorDialog('Failed to generate PDF: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _savePdf(Uint8List pdfBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'scanned_document_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(pdfBytes);

      // Show success dialog with options
      _showSuccessDialog(file.path, pdfBytes);
    } catch (e) {
      _showErrorDialog('Failed to save PDF: $e');
    }
  }

  void _showSuccessDialog(String filePath, Uint8List pdfBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('PDF Created Successfully!'),
            ],
          ),
          content: Text('Your PDF has been saved to:\n$filePath'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Printing.sharePdf(
                  bytes: pdfBytes,
                  filename: 'scanned_document.pdf',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
              ),
              child: const Text('Share', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Printing.layoutPdf(onLayout: (format) => pdfBytes);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
              ),
              child: const Text('Preview', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _captureImage(ImageSource.camera);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickMultipleImages();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E40AF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1E40AF).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF1E40AF),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E40AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan to PDF',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_scannedImages.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _scannedImages.clear();
                });
              },
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _scannedImages.isEmpty ? _buildEmptyState() : _buildImagesList(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.document_scanner,
              size: 60,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Images Added',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the camera button to start scanning\ndocuments or select from gallery',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E40AF).withOpacity(0.1),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF1E40AF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_scannedImages.length} image(s) ready. Drag to reorder.',
                  style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _scannedImages.length,
            onReorder: _reorderImages,
            itemBuilder: (context, index) {
              return Card(
                key: ValueKey(_scannedImages[index].path),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_scannedImages[index].path),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text('Page ${index + 1}'),
                  subtitle: Text(_scannedImages[index].name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle, color: Colors.grey),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeImage(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_scannedImages.isNotEmpty) ...[
          FloatingActionButton.extended(
            heroTag: "generate_pdf",
            onPressed: _isProcessing ? null : _generatePdf,
            backgroundColor: const Color(0xFF059669),
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text(
              _isProcessing ? 'Generating...' : 'Generate PDF',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          heroTag: "add_image",
          onPressed: _showImageSourceDialog,
          backgroundColor: const Color(0xFF1E40AF),
          child: const Icon(Icons.add_a_photo, color: Colors.white),
        ),
      ],
    );
  }
}
