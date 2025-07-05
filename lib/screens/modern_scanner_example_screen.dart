// Example screen demonstrating the modern document scanner
// This shows how to use camera + google_ml_kit for document scanning

import 'package:flutter/material.dart';
import '../services/modern_document_detection_service.dart';

class ModernScannerExampleScreen extends StatefulWidget {
  const ModernScannerExampleScreen({super.key});

  @override
  State<ModernScannerExampleScreen> createState() =>
      _ModernScannerExampleScreenState();
}

class _ModernScannerExampleScreenState
    extends State<ModernScannerExampleScreen> {
  final ModernDocumentDetectionService _scannerService =
      ModernDocumentDetectionService();
  String? _lastScannedImage;
  String _extractedText = '';
  DocumentType _documentType = DocumentType.other;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Document Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scanner buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Document Scanner Options',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _scanDocument,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Scan Document'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('From Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Processing indicator
            if (_isProcessing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Processing document...'),
                    ],
                  ),
                ),
              ),

            // Results section
            if (_lastScannedImage != null && !_isProcessing) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Results',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Document Type: ${_documentType.name.toUpperCase()}',
                      ),
                      const SizedBox(height: 8),
                      Text('Image Path: $_lastScannedImage'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Extracted text
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extracted Text (OCR)',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _extractedText.isEmpty
                                  ? 'No text found'
                                  : _extractedText,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Instructions
            if (_lastScannedImage == null && !_isProcessing)
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.document_scanner,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Modern Document Scanner',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Scan Document" to use the camera or "From Gallery" to select an existing image. The app will automatically detect document edges and extract text using AI.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanDocument() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final scannedPath = await _scannerService.scanSingleDocument(context);

      if (scannedPath != null) {
        await _processDocument(scannedPath);
      }
    } catch (e) {
      _showErrorSnackBar('Error scanning document: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final imagePath = await _scannerService.pickFromGallery();

      if (imagePath != null) {
        await _processDocument(imagePath);
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processDocument(String imagePath) async {
    try {
      // Analyze the document
      final analysis = await _scannerService.analyzeDocument(imagePath);

      setState(() {
        _lastScannedImage = imagePath;
        _extractedText = analysis.textResult.fullText;
        _documentType = analysis.documentType;
      });

      _showSuccessSnackBar('Document processed successfully!');
    } catch (e) {
      _showErrorSnackBar('Error processing document: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _scannerService.dispose();
    super.dispose();
  }
}
