import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/scan_to_pdf_models.dart' as models;
import '../services/scan_service.dart';
import 'package:pdf_image_renderer/pdf_image_renderer.dart';

/// PDF Generation Service
/// Handles all PDF creation, image processing, and file management operations
class PdfGenerationService {
  final ScanService _scanService = ScanService();
  final ImagePicker _picker = ImagePicker();

  /// Capture image from camera or gallery
  Future<models.ScanToImageData?> captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return models.ScanToImageData(
          path: image.path,
          name: path.basename(image.path),
          scannedAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<List<models.ScanToImageData>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      return images
          .map(
            (image) => models.ScanToImageData(
              path: image.path,
              name: path.basename(image.path),
              scannedAt: DateTime.now(),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  /// Generate PDF from images
  Future<Uint8List> generatePdf(
    List<models.ScanToImageData> images,
    models.PdfGenerationSettings settings,
  ) async {
    if (images.isEmpty) {
      throw Exception('No images to generate PDF');
    }

    try {
      final pdf = pw.Document();

      for (final imageData in images) {
        final file = File(imageData.path);
        if (!await file.exists()) {
          throw Exception('Image file not found: ${imageData.path}');
        }

        final imageBytes = await file.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: _getPdfPageFormat(settings.pageSize),
            orientation: _getPdfOrientation(settings.orientation),
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      // Add metadata if enabled
      if (settings.includeMetadata) {
        // PDF metadata will be set automatically by the pdf package
      }

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  /// Save PDF to specific location
  Future<String> savePdf(
    Uint8List pdfBytes,
    models.PdfGenerationSettings settings,
    models.PdfSaveLocation location,
  ) async {
    try {
      String fileName = settings.fileName;
      if (!fileName.endsWith('.pdf')) {
        fileName += '.pdf';
      }

      String savePath;

      switch (location.type) {
        case models.PdfSaveType.downloads:
          savePath = await _saveToDownloads(pdfBytes, fileName);
          break;
        case models.PdfSaveType.documents:
          savePath = await _saveToDocuments(pdfBytes, fileName);
          break;
        case models.PdfSaveType.customPath:
          savePath = await _saveToCustomPath(pdfBytes, fileName, location.path);
          break;
        default:
          throw Exception('Unsupported save location type');
      }

      return savePath;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  /// Share PDF file
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf',
      );
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  /// Preview PDF before saving
  Future<void> previewPdf(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: fileName,
      );
    } catch (e) {
      throw Exception('Failed to preview PDF: $e');
    }
  }

  /// Remove image at index
  Future<void> removeImage(
    List<models.ScanToImageData> images,
    int index,
  ) async {
    if (index >= 0 && index < images.length) {
      final imageData = images[index];
      try {
        final file = File(imageData.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore file deletion errors
      }
    }
  }

  /// Cleanup temporary files
  Future<void> cleanupTempFiles() async {
    try {
      await _scanService.cleanupTempFiles();
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Request necessary permissions
  Future<bool> requestPermissions() async {
    try {
      return await _scanService.requestPermissions();
    } catch (e) {
      return false;
    }
  }

  // Private helper methods

  PdfPageFormat _getPdfPageFormat(models.PdfPageSize size) {
    switch (size) {
      case models.PdfPageSize.a4:
        return PdfPageFormat.a4;
      case models.PdfPageSize.a5:
        return PdfPageFormat.a5;
      case models.PdfPageSize.letter:
        return PdfPageFormat.letter;
      case models.PdfPageSize.legal:
        return PdfPageFormat.legal;
      case models.PdfPageSize.custom:
        return PdfPageFormat.a4; // Default to A4 for custom
    }
  }

  pw.PageOrientation _getPdfOrientation(models.PdfOrientation orientation) {
    switch (orientation) {
      case models.PdfOrientation.portrait:
        return pw.PageOrientation.portrait;
      case models.PdfOrientation.landscape:
        return pw.PageOrientation.landscape;
      case models.PdfOrientation.auto:
        return pw.PageOrientation.natural;
    }
  }

  Future<String> _saveToDownloads(Uint8List pdfBytes, String fileName) async {
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      throw Exception('Downloads directory not available');
    }

    final file = File(path.join(directory.path, fileName));
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  Future<String> _saveToDocuments(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, fileName));
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  Future<String> _saveToCustomPath(
    Uint8List pdfBytes,
    String fileName,
    String customPath,
  ) async {
    final file = File(path.join(customPath, fileName));
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Converts a PDF file to JPG images
  /// Returns a list of file paths to the generated JPG images
  Future<List<String>> pdfToJpg(
    String pdfPath, {
    int quality = 90,
    void Function(double progress)? onProgress,
  }) async {
    final pdfFile = File(pdfPath);

    if (!pdfFile.existsSync()) {
      throw Exception('PDF file does not exist');
    }

    try {
      // Create the renderer instance with the PDF path
      final renderer = PdfImageRenderer(path: pdfPath);

      // Create output directory
      final outputDir = await _createOutputDirectory(pdfPath);
      final List<String> outputFilePaths = [];

      // Get the page count first
      final pageCount = await renderer.getPageCount();

      // Convert each page
      for (int i = 0; i < pageCount; i++) {
        // Update progress
        if (onProgress != null) {
          onProgress((i / pageCount) * 100);
        }

        // Render the page to an image
        final pageImage = await renderer.renderPage(
          pageIndex: i,
          scale: 2.0, // Scale for higher quality
        );

        if (pageImage != null) {
          // Save the image as JPG
          final outputPath = '${outputDir.path}/page_${i + 1}.jpg';
          final imageFile = File(outputPath);
          await imageFile.writeAsBytes(pageImage);

          outputFilePaths.add(outputPath);
        }
      }

      // Final progress update
      if (onProgress != null) {
        onProgress(100);
      }

      return outputFilePaths;
    } catch (e) {
      throw Exception('Failed to convert PDF to JPG: $e');
    }
  }

  /// Creates directory for output files
  Future<Directory> _createOutputDirectory(String pdfPath) async {
    final fileName = path.basenameWithoutExtension(pdfPath);
    final baseDir = await getApplicationDocumentsDirectory();
    final outputDirPath = '${baseDir.path}/pdf_to_jpg/$fileName';

    final outputDir = Directory(outputDirPath);
    if (!outputDir.existsSync()) {
      await outputDir.create(recursive: true);
    }

    return outputDir;
  }
}
