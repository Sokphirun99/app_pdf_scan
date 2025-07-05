// Modern Document Detection Service using camera and google_ml_kit
// This service provides advanced document scanning with ML processing

import 'package:flutter/material.dart';
import 'package:document_scanner_flutter/document_scanner_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';

/// Modern document detection service using latest packages
class ModernDocumentDetectionService {
  static final ModernDocumentDetectionService _instance =
      ModernDocumentDetectionService._internal();
  factory ModernDocumentDetectionService() => _instance;
  ModernDocumentDetectionService._internal();

  // Text recognizer for OCR
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Image labeler for document type detection
  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );

  /// Scan single document with context
  Future<String?> scanSingleDocument(BuildContext context) async {
    try {
      final scannedDocument = await DocumentScannerFlutter.launch(
        context,
        labelsConfig: const {
          "android_next_button_label": "Next",
          "android_ok_label": "OK",
          "android_scanning_message": "Scanning document...",
        },
      );

      if (scannedDocument != null) {
        return scannedDocument.path;
      }

      return null;
    } catch (e) {
      debugPrint('Error scanning document: $e');
      return null;
    }
  }

  /// Pick image from gallery and apply document processing
  Future<String?> pickFromGallery({bool enhanceDocument = true}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) return null;

      if (enhanceDocument) {
        return await _enhanceDocument(image.path);
      }

      return image.path;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Extract text from document using OCR
  Future<DocumentTextResult> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return DocumentTextResult(
        fullText: recognizedText.text,
        textBlocks:
            recognizedText.blocks
                .map(
                  (block) => TextBlock(
                    text: block.text,
                    boundingBox: block.boundingBox,
                    confidence:
                        1.0, // ML Kit doesn't provide block-level confidence in newer versions
                    lines:
                        block.lines
                            .map(
                              (line) => TextLine(
                                text: line.text,
                                boundingBox: line.boundingBox,
                                confidence: 1.0, // Default confidence
                              ),
                            )
                            .toList(),
                  ),
                )
                .toList(),
      );
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return DocumentTextResult(fullText: '', textBlocks: []);
    }
  }

  /// Detect document type using image labeling
  Future<DocumentType> detectDocumentType(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final imageLabels = await _imageLabeler.processImage(inputImage);

      // Analyze labels to determine document type
      for (final label in imageLabels) {
        final labelText = label.label.toLowerCase();

        if (labelText.contains('passport') || labelText.contains('document')) {
          return DocumentType.passport;
        } else if (labelText.contains('card') || labelText.contains('credit')) {
          return DocumentType.idCard;
        } else if (labelText.contains('receipt') ||
            labelText.contains('invoice')) {
          return DocumentType.receipt;
        } else if (labelText.contains('text') || labelText.contains('paper')) {
          return DocumentType.document;
        }
      }

      return DocumentType.other;
    } catch (e) {
      debugPrint('Error detecting document type: $e');
      return DocumentType.other;
    }
  }

  /// Get document analysis including text and type
  Future<DocumentAnalysisResult> analyzeDocument(String imagePath) async {
    try {
      final textResult = await extractText(imagePath);
      final documentType = await detectDocumentType(imagePath);

      return DocumentAnalysisResult(
        imagePath: imagePath,
        textResult: textResult,
        documentType: documentType,
        analysisTimestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error analyzing document: $e');
      return DocumentAnalysisResult(
        imagePath: imagePath,
        textResult: DocumentTextResult(fullText: '', textBlocks: []),
        documentType: DocumentType.other,
        analysisTimestamp: DateTime.now(),
      );
    }
  }

  /// Enhance document image (placeholder for additional processing)
  Future<String> _enhanceDocument(String originalPath) async {
    // For now, return the original path
    // In the future, you can add image enhancement logic here
    // such as brightness adjustment, contrast enhancement, etc.
    return originalPath;
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
  }
}

/// Document analysis result
class DocumentAnalysisResult {
  final String imagePath;
  final DocumentTextResult textResult;
  final DocumentType documentType;
  final DateTime analysisTimestamp;

  DocumentAnalysisResult({
    required this.imagePath,
    required this.textResult,
    required this.documentType,
    required this.analysisTimestamp,
  });
}

/// Text extraction result
class DocumentTextResult {
  final String fullText;
  final List<TextBlock> textBlocks;

  DocumentTextResult({required this.fullText, required this.textBlocks});
}

/// Text block with position and confidence
class TextBlock {
  final String text;
  final Rect? boundingBox;
  final double confidence;
  final List<TextLine> lines;

  TextBlock({
    required this.text,
    this.boundingBox,
    required this.confidence,
    required this.lines,
  });
}

/// Text line with position and confidence
class TextLine {
  final String text;
  final Rect? boundingBox;
  final double confidence;

  TextLine({required this.text, this.boundingBox, required this.confidence});
}

/// Document type enumeration
enum DocumentType { passport, idCard, receipt, document, businessCard, other }
