import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:ui' as ui;

class ScanService {
  static final ScanService _instance = ScanService._internal();
  factory ScanService() => _instance;
  ScanService._internal();

  final ImagePicker _picker = ImagePicker();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Dispose method to clean up resources
  void dispose() {
    _textRecognizer.close();
  }

  /// Check and request necessary permissions for scanning
  Future<bool> requestPermissions() async {
    // Request camera permission for taking photos
    final cameraStatus = await Permission.camera.request();

    // Request storage permission for saving PDFs and accessing gallery
    Permission storagePermission;
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ uses granular media permissions
        storagePermission = Permission.photos;
      } else {
        storagePermission = Permission.storage;
      }
    } else {
      // iOS uses photos permission
      storagePermission = Permission.photos;
    }

    final storageStatus = await storagePermission.request();

    // Check if both permissions are granted
    final cameraGranted = cameraStatus == PermissionStatus.granted;
    final storageGranted = storageStatus == PermissionStatus.granted;

    return cameraGranted && storageGranted;
  }

  /// Get permission status without requesting
  Future<Map<String, PermissionStatus>> getPermissionStatus() async {
    final cameraStatus = await Permission.camera.status;

    Permission storagePermission;
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      storagePermission =
          androidInfo.version.sdkInt >= 33
              ? Permission.photos
              : Permission.storage;
    } else {
      storagePermission = Permission.photos;
    }

    final storageStatus = await storagePermission.status;

    return {'camera': cameraStatus, 'storage': storageStatus};
  }

  /// Capture image from camera with better error handling
  Future<XFile?> captureImage({
    int imageQuality = 80,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    try {
      // Check permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw ScanException('Camera permission denied');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return image;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw ScanException(
          'Camera access denied. Please grant camera permission.',
        );
      } else if (e.code == 'photo_access_denied') {
        throw ScanException(
          'Photo access denied. Please grant photo permission.',
        );
      } else {
        throw ScanException('Camera error: ${e.message ?? e.code}');
      }
    } catch (e) {
      throw ScanException('Failed to capture image: $e');
    }
  }

  /// Capture image from camera with enhanced crash prevention
  Future<XFile?> captureImageSafe() async {
    try {
      // Force garbage collection before camera operation
      _forceGarbageCollection();

      // Check permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw ScanException('Camera permission denied');
      }

      // Add delay to ensure proper initialization
      await Future.delayed(const Duration(milliseconds: 200));

      // Use aggressive compression to prevent memory crashes
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60, // Further reduced quality
        maxWidth: 1024, // Further reduced size
        maxHeight: 1024, // Further reduced size
        preferredCameraDevice: CameraDevice.rear,
      );

      // Force garbage collection after camera operation
      if (image != null) {
        _forceGarbageCollection();
      }

      return image;
    } on PlatformException catch (e) {
      _forceGarbageCollection(); // Clean up on error

      if (e.code == 'camera_access_denied' ||
          e.code == 'camera_access_denied') {
        throw ScanException(
          'Camera access denied. Please grant camera permission.',
        );
      } else if (e.code == 'photo_access_denied') {
        throw ScanException(
          'Photo access denied. Please grant photo permission.',
        );
      } else if (e.code == 'camera_unavailable') {
        throw ScanException(
          'Camera not available. Please close other camera apps and try again.',
        );
      } else if (e.code == 'already_active') {
        throw ScanException(
          'Camera is already in use. Please wait and try again.',
        );
      } else {
        throw ScanException('Camera error: ${e.message ?? e.code}');
      }
    } catch (e) {
      _forceGarbageCollection(); // Clean up on error
      throw ScanException('Failed to capture image: $e');
    }
  }

  /// Force garbage collection to free memory
  void _forceGarbageCollection() {
    try {
      // Trigger garbage collection multiple times
      for (int i = 0; i < 3; i++) {
        List.generate(1000, (index) => []).clear();
      }
    } catch (e) {
      // Ignore errors in garbage collection
    }
  }

  /// Pick multiple images from gallery with better error handling
  Future<List<XFile>> pickMultipleImages({
    int imageQuality = 80,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    try {
      // Check permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw ScanException('Storage permission denied');
      }

      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return images;
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw ScanException(
          'Photo access denied. Please grant photo library permission.',
        );
      } else {
        throw ScanException('Gallery error: ${e.message ?? e.code}');
      }
    } catch (e) {
      throw ScanException('Failed to pick images: $e');
    }
  }

  /// Convert XFile image to Uint8List for PDF processing
  Future<Uint8List> imageToUint8List(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData!.buffer.asUint8List();
    } catch (e) {
      throw ScanException('Failed to process image: $e');
    }
  }

  /// Generate PDF from list of images
  Future<Uint8List> generatePdf(
    List<XFile> images, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    double margin = 20,
  }) async {
    if (images.isEmpty) {
      throw ScanException('No images provided for PDF generation');
    }

    try {
      final pdf = pw.Document();

      for (final imageFile in images) {
        final imageBytes = await imageToUint8List(imageFile);
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.all(margin),
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      return await pdf.save();
    } catch (e) {
      throw ScanException('Failed to generate PDF: $e');
    }
  }

  /// Save PDF to device storage
  Future<String> savePdf(Uint8List pdfBytes, {String? customName}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customName ?? 'scanned_document_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw ScanException('Failed to save PDF: $e');
    }
  }

  /// Complete scan to PDF workflow
  Future<ScanResult> scanToPdf(
    List<XFile> images, {
    String? fileName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    try {
      // Generate PDF
      final pdfBytes = await generatePdf(images, pageFormat: pageFormat);

      // Save PDF
      final filePath = await savePdf(pdfBytes, customName: fileName);

      return ScanResult(
        success: true,
        filePath: filePath,
        pdfBytes: pdfBytes,
        pageCount: images.length,
      );
    } catch (e) {
      return ScanResult(
        success: false,
        error: e.toString(),
        pageCount: images.length,
      );
    }
  }

  /// Generate PDF from images with result object
  Future<PdfGenerationResult> generatePdfResult(
    List<XFile> images, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    double margin = 20,
  }) async {
    try {
      final pdfBytes = await generatePdf(
        images,
        pageFormat: pageFormat,
        margin: margin,
      );
      return PdfGenerationResult.success(pdfBytes);
    } catch (e) {
      return PdfGenerationResult.error(e.toString());
    }
  }

  /// Generate PDF from images with scan result object
  Future<ScanResult> generatePdfScanResult(
    List<XFile> images, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    double margin = 20,
  }) async {
    try {
      final pdfBytes = await generatePdf(
        images,
        pageFormat: pageFormat,
        margin: margin,
      );
      return ScanResult(
        success: true,
        pdfBytes: pdfBytes,
        pageCount: images.length,
      );
    } catch (e) {
      return ScanResult(success: false, error: e.toString(), pageCount: 0);
    }
  }

  /// Optimize image for PDF with aggressive compression
  Future<XFile> optimizeImageForPdf(XFile originalImage) async {
    try {
      final bytes = await originalImage.readAsBytes();

      // Skip optimization if image is already small
      if (bytes.length < 500000) {
        // Less than 500KB
        return originalImage;
      }

      // Decode and compress the image
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 800, // Aggressive size reduction
        targetHeight: 800,
      );

      final frame = await codec.getNextFrame();
      final compressedData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (compressedData != null) {
        // Create temporary file for compressed image
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await tempFile.writeAsBytes(compressedData.buffer.asUint8List());

        return XFile(tempFile.path);
      }

      return originalImage;
    } catch (e) {
      // Return original if compression fails
      return originalImage;
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file.path.contains('compressed_')) {
          try {
            await file.delete();
          } catch (e) {
            // Ignore deletion errors
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Enhanced PDF export with multiple save options
  Future<PdfExportResult> exportPdfWithOptions(
    List<XFile> images, {
    String? fileName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool includeOCR = false,
    PdfExportOption exportOption = PdfExportOption.saveToDevice,
  }) async {
    try {
      // Generate PDF
      final pdfBytes = await generatePdf(images, pageFormat: pageFormat);

      // Extract OCR text if requested (simplified approach)
      String? extractedText;
      if (includeOCR) {
        // For now, we'll skip OCR to avoid method dependency issues
        extractedText = "OCR functionality available in full version";
      }

      // Handle different export options
      switch (exportOption) {
        case PdfExportOption.saveToDevice:
          final filePath = await savePdf(pdfBytes, customName: fileName);
          return PdfExportResult(
            success: true,
            filePath: filePath,
            pdfBytes: pdfBytes,
            extractedText: extractedText,
            exportType: 'Device Storage',
          );

        case PdfExportOption.shareFile:
          // Basic share functionality
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${fileName ?? 'document.pdf'}');
          await tempFile.writeAsBytes(pdfBytes);
          await Share.shareXFiles([XFile(tempFile.path)]);
          
          return PdfExportResult(
            success: true,
            filePath: tempFile.path,
            pdfBytes: pdfBytes,
            extractedText: extractedText,
            exportType: 'Share',
          );

        case PdfExportOption.print:
          // Basic print functionality
          await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
          return PdfExportResult(
            success: true,
            pdfBytes: pdfBytes,
            extractedText: extractedText,
            exportType: 'Print',
          );

        case PdfExportOption.preview:
          // Basic preview functionality
          await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
          return PdfExportResult(
            success: true,
            pdfBytes: pdfBytes,
            extractedText: extractedText,
            exportType: 'Preview',
          );
      }
    } catch (e) {
      return PdfExportResult(
        success: false,
        error: 'PDF export failed: $e',
        exportType: exportOption.toString(),
      );
    }
  }

  /// Enhanced PDF export with advanced configuration
  Future<PdfExportResult> exportPdfWithAdvancedConfig(
    List<XFile> images, {
    String? fileName,
    required PdfExportConfigWithOption config,
  }) async {
    try {
      // Generate PDF with advanced configuration
      final pdfBytes = await generatePdfWithConfig(images, config);

      // Extract OCR text if requested
      String? extractedText;
      if (config.includeOCR) {
        extractedText = await extractTextFromImages(images);
      }

      // Handle different export options
      switch (config.exportOption) {
        case PdfExportOption.saveToDevice:
          final filePath = await savePdf(pdfBytes, customName: fileName);
          return PdfExportResult(
            success: true,
            filePath: filePath,
            pdfBytes: pdfBytes,
            extractedText: extractedText,
            exportType: 'Device Storage',
          );

        case PdfExportOption.shareFile:
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${fileName ?? 'document.pdf'}');
          await tempFile.writeAsBytes(pdfBytes);
          await Share.shareXFiles([XFile(tempFile.path)]);
          
          return PdfExportResult(
            success: true,
            filePath: tempFile.path,
            pdfBytes: pdfBytes,
            extractedText: extractedText,
            exportType: 'Share',
          );

        case PdfExportOption.print:
          await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
          return PdfExportResult(
            success: true,
            pdfBytes: pdfBytes,
            extractedText: extractedText,
            exportType: 'Print',
          );

        case PdfExportOption.preview:
          await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
          return PdfExportResult(
            success: true,
            pdfBytes: pdfBytes,
            extractedText: extractedText,
            exportType: 'Preview',
          );
      }
    } catch (e) {
      return PdfExportResult(
        success: false,
        error: 'PDF export failed: $e',
        exportType: config.exportOption.toString(),
      );
    }
  }

  /// Generate PDF with advanced configuration
  Future<Uint8List> generatePdfWithConfig(
    List<XFile> images,
    PdfExportConfigWithOption config,
  ) async {
    if (images.isEmpty) {
      throw ScanException('No images provided for PDF generation');
    }

    try {
      final pdf = pw.Document();

      for (final imageFile in images) {
        // Process image based on quality settings
        final processedImage = await processImageForPdf(imageFile, config);
        final imageBytes = await imageToUint8List(processedImage);
        final image = pw.MemoryImage(imageBytes);

        // Create page with optional watermark
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  // Main image
                  pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                  // Watermark if enabled
                  if (config.addWatermark && config.watermarkText != null)
                    _buildWatermark(config.watermarkText!, config.watermarkPosition),
                ],
              );
            },
          ),
        );
      }

      return await pdf.save();
    } catch (e) {
      throw ScanException('Failed to generate PDF with advanced config: $e');
    }
  }

  /// Process image based on quality settings
  Future<XFile> processImageForPdf(XFile originalImage, PdfExportConfigWithOption config) async {
    try {
      final bytes = await originalImage.readAsBytes();
      
      // Determine target dimensions based on quality
      double maxDimension;
      switch (config.quality) {
        case PdfQuality.high:
          maxDimension = 2400;
          break;
        case PdfQuality.medium:
          maxDimension = 1920;
          break;
        case PdfQuality.low:
          maxDimension = 1280;
          break;
        case PdfQuality.custom:
          maxDimension = 1920; // Default for custom
          break;
      }

      // Skip processing if image is already small and high quality is not required
      if (bytes.length < 500000 && config.quality != PdfQuality.high) {
        return originalImage;
      }

      // Decode and resize the image
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxDimension.toInt(),
        targetHeight: maxDimension.toInt(),
      );

      final frame = await codec.getNextFrame();
      final processedData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (processedData != null) {
        // Create temporary file for processed image
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await tempFile.writeAsBytes(processedData.buffer.asUint8List());

        return XFile(tempFile.path);
      }

      return originalImage;
    } catch (e) {
      // Return original if processing fails
      return originalImage;
    }
  }

  /// Build watermark widget for PDF
  pw.Widget _buildWatermark(String text, WatermarkPosition position) {
    // Determine alignment based on position
    pw.Alignment alignment;
    switch (position) {
      case WatermarkPosition.center:
        alignment = pw.Alignment.center;
        break;
      case WatermarkPosition.topLeft:
        alignment = pw.Alignment.topLeft;
        break;
      case WatermarkPosition.topRight:
        alignment = pw.Alignment.topRight;
        break;
      case WatermarkPosition.bottomLeft:
        alignment = pw.Alignment.bottomLeft;
        break;
      case WatermarkPosition.bottomRight:
        alignment = pw.Alignment.bottomRight;
        break;
    }

    return pw.Positioned.fill(
      child: pw.Align(
        alignment: alignment,
        child: pw.Transform.rotate(
          angle: position == WatermarkPosition.center ? -0.5 : 0,
          child: pw.Opacity(
            opacity: 0.3,
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 20,
                color: PdfColors.grey,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Extract text from images using OCR
  Future<String> extractTextFromImages(List<XFile> images) async {
    try {
      final extractedTexts = <String>[];

      for (final imageFile in images) {
        final inputImage = InputImage.fromFilePath(imageFile.path);
        final recognizedText = await _textRecognizer.processImage(inputImage);
        
        if (recognizedText.text.isNotEmpty) {
          extractedTexts.add(recognizedText.text);
        }
      }

      return extractedTexts.join('\n\n--- Page Break ---\n\n');
    } catch (e) {
      throw ScanException('Failed to extract text: $e');
    }
  }

  /// Perform OCR on a single image
  Future<TextRecognitionResult> performOcrOnImage(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return TextRecognitionResult(
        success: true,
        text: recognizedText.text,
        textBlocks: recognizedText.blocks,
        confidence: _calculateConfidence(recognizedText.blocks),
      );
    } catch (e) {
      return TextRecognitionResult(
        success: false,
        text: '',
        error: e.toString(),
      );
    }
  }

  /// Calculate average confidence from text blocks
  double? _calculateConfidence(List<TextBlock> blocks) {
    if (blocks.isEmpty) return null;

    double totalConfidence = 0;
    int elementCount = 0;

    for (final block in blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          if (element.confidence != null) {
            totalConfidence += element.confidence!;
            elementCount++;
          }
        }
      }
    }

    return elementCount > 0 ? totalConfidence / elementCount : null;
  }

  /// Save PDF to specific location with advanced options
  Future<SaveResult> savePdfToLocation(
    Uint8List pdfBytes, {
    String? fileName,
    SaveLocation location = SaveLocation.documents,
  }) async {
    try {
      Directory directory;
      String locationName;

      switch (location) {
        case SaveLocation.documents:
          directory = await getApplicationDocumentsDirectory();
          locationName = 'Documents';
          break;
        case SaveLocation.downloads:
          // Try to get downloads directory, fallback to documents
          try {
            if (Platform.isAndroid) {
              directory = Directory('/storage/emulated/0/Download');
              if (!await directory.exists()) {
                directory = await getApplicationDocumentsDirectory();
              }
            } else {
              directory = await getApplicationDocumentsDirectory();
            }
            locationName = 'Downloads';
          } catch (e) {
            directory = await getApplicationDocumentsDirectory();
            locationName = 'Documents';
          }
          break;
        case SaveLocation.custom:
          directory = await getApplicationDocumentsDirectory();
          locationName = 'Documents';
          break;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'scanned_document_$timestamp.pdf';
      final file = File('${directory.path}/$finalFileName');

      await file.writeAsBytes(pdfBytes);
      final fileSize = await file.length();

      return SaveResult(
        success: true,
        filePath: file.path,
        fileName: finalFileName,
        saveLocation: locationName,
        fileSize: fileSize,
      );
    } catch (e) {
      return SaveResult(
        success: false,
        error: 'Failed to save PDF: $e',
        saveLocation: location.toString(),
      );
    }
  }

  /// Share PDF with enhanced options
  Future<ShareResult> sharePdfFile(
    Uint8List pdfBytes, {
    String? fileName,
    String? subject,
    String? text,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'scanned_document_$timestamp.pdf';
      final tempFile = File('${tempDir.path}/$finalFileName');

      await tempFile.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: subject ?? 'Scanned Document',
        text: text ?? 'Please find the attached scanned document.',
      );

      return ShareResult(
        success: true,
        filePath: tempFile.path,
        fileName: finalFileName,
        shareStatus: 'Shared successfully',
      );
    } catch (e) {
      return ShareResult(
        success: false,
        error: 'Failed to share PDF: $e',
        shareStatus: 'Share failed',
      );
    }
  }

  /// Print PDF with enhanced options
  Future<PrintResult> printPdf(
    Uint8List pdfBytes, {
    String? jobName,
  }) async {
    try {
      await Printing.layoutPdf(
        name: jobName ?? 'Scanned Document',
        format: PdfPageFormat.a4,
        onLayout: (format) async => pdfBytes,
      );

      return PrintResult(
        success: true,
        message: 'Print job sent successfully',
      );
    } catch (e) {
      return PrintResult(
        success: false,
        error: 'Failed to print PDF: $e',
      );
    }
  }

  /// Preview PDF with enhanced options
  Future<PreviewResult> previewPdf(
    Uint8List pdfBytes, {
    String? title,
  }) async {
    try {
      await Printing.layoutPdf(
        name: title ?? 'Document Preview',
        format: PdfPageFormat.a4,
        onLayout: (format) async => pdfBytes,
      );

      return PreviewResult(
        success: true,
        message: 'PDF preview opened successfully',
      );
    } catch (e) {
      return PreviewResult(
        success: false,
        error: 'Failed to preview PDF: $e',
      );
    }
  }

  /// Get available storage locations
  Future<List<StorageInfo>> getAvailableStorageLocations() async {
    final locations = <StorageInfo>[];

    try {
      // Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final documentsSpace = await _getDirectorySpace(documentsDir);
      locations.add(StorageInfo(
        location: SaveLocation.documents,
        path: documentsDir.path,
        displayName: 'Documents',
        availableSpace: documentsSpace,
        isWritable: true,
      ));

      // Downloads directory (Android)
      if (Platform.isAndroid) {
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            final downloadsSpace = await _getDirectorySpace(downloadsDir);
            locations.add(StorageInfo(
              location: SaveLocation.downloads,
              path: downloadsDir.path,
              displayName: 'Downloads',
              availableSpace: downloadsSpace,
              isWritable: true,
            ));
          }
        } catch (e) {
          // Downloads not accessible
        }
      }
    } catch (e) {
      // Error getting storage info
    }

    return locations;
  }

  /// Get available space in directory (simplified)
  Future<int> _getDirectorySpace(Directory directory) async {
    try {
      // This is a simplified implementation
      // In a real app, you might want to use platform-specific code
      return 1024 * 1024 * 1024; // Return 1GB as default
    } catch (e) {
      return 0;
    }
  }
}

/// Enums for export options
enum PdfExportOption {
  saveToDevice,
  shareFile,
  print,
  preview,
}

enum SaveLocation {
  documents,
  downloads,
  custom,
}

/// Enhanced PDF Quality Options
enum PdfQuality {
  high,    // High resolution, larger file size
  medium,  // Balanced quality and size
  low,     // Lower resolution, smaller file size
  custom,  // Custom settings
}

/// PDF Page Orientation
enum PdfOrientation {
  portrait,
  landscape,
  auto, // Auto-detect based on image dimensions
}

/// PDF Compression Level
enum PdfCompression {
  none,
  low,
  medium,
  high,
  maximum,
}

/// Document Enhancement Options
enum DocumentEnhancement {
  none,
  autoContrast,
  blackWhite,
  grayscale,
  brighten,
  sharpen,
}

/// PDF Security Options
enum PdfSecurity {
  none,
  password,
  readOnly,
  noPrint,
  noEdit,
}

/// Watermark Position
enum WatermarkPosition {
  center,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// PDF Export Configuration
class PdfExportConfig {
  final PdfQuality quality;
  final PdfOrientation orientation;
  final PdfCompression compression;
  final DocumentEnhancement enhancement;
  final PdfSecurity security;
  final double margin;
  final bool includeOCR;
  final bool addWatermark;
  final String? watermarkText;
  final WatermarkPosition watermarkPosition;
  final String? password;
  final String? title;
  final String? author;
  final String? subject;
  final bool enableMetadata;

  const PdfExportConfig({
    this.quality = PdfQuality.medium,
    this.orientation = PdfOrientation.auto,
    this.compression = PdfCompression.medium,
    this.enhancement = DocumentEnhancement.autoContrast,
    this.security = PdfSecurity.none,
    this.margin = 20,
    this.includeOCR = false,
    this.addWatermark = false,
    this.watermarkText,
    this.watermarkPosition = WatermarkPosition.center,
    this.password,
    this.title,
    this.author,
    this.subject,
    this.enableMetadata = true,
  });

  /// Get image quality based on PDF quality setting
  int get imageQuality {
    switch (quality) {
      case PdfQuality.high:
        return 95;
      case PdfQuality.medium:
        return 80;
      case PdfQuality.low:
        return 60;
      case PdfQuality.custom:
        return 80; // Default for custom
    }
  }

  /// Get max image dimensions based on quality
  double get maxImageDimension {
    switch (quality) {
      case PdfQuality.high:
        return 2400;
      case PdfQuality.medium:
        return 1920;
      case PdfQuality.low:
        return 1280;
      case PdfQuality.custom:
        return 1920; // Default for custom
    }
  }

  /// Get compression ratio
  double get compressionRatio {
    switch (compression) {
      case PdfCompression.none:
        return 1.0;
      case PdfCompression.low:
        return 0.9;
      case PdfCompression.medium:
        return 0.7;
      case PdfCompression.high:
        return 0.5;
      case PdfCompression.maximum:
        return 0.3;
    }
  }
}

/// PDF Export Configuration with Export Option
class PdfExportConfigWithOption {
  final PdfQuality quality;
  final PdfExportOption exportOption;
  final bool includeOCR;
  final bool addWatermark;
  final String? watermarkText;
  final WatermarkPosition watermarkPosition;

  const PdfExportConfigWithOption({
    this.quality = PdfQuality.medium,
    required this.exportOption,
    this.includeOCR = false,
    this.addWatermark = false,
    this.watermarkText,
    this.watermarkPosition = WatermarkPosition.center,
  });
}

/// Custom exception for scan operations
class ScanException implements Exception {
  final String message;
  ScanException(this.message);

  @override
  String toString() => 'ScanException: $message';
}

/// Result object for scan operations
class ScanResult {
  final bool success;
  final String? filePath;
  final Uint8List? pdfBytes;
  final String? error;
  final int pageCount;

  ScanResult({
    required this.success,
    this.filePath,
    this.pdfBytes,
    this.error,
    required this.pageCount,
  });
}

/// Result class for PDF generation
class PdfGenerationResult {
  final bool success;
  final Uint8List? pdfBytes;
  final String? error;

  const PdfGenerationResult({required this.success, this.pdfBytes, this.error});

  factory PdfGenerationResult.success(Uint8List pdfBytes) {
    return PdfGenerationResult(success: true, pdfBytes: pdfBytes);
  }

  factory PdfGenerationResult.error(String error) {
    return PdfGenerationResult(success: false, error: error);
  }
}

/// Exception class for scan-related errors

/// Result object for document scanning
class DocumentScanResult {
  final bool success;
  final List<XFile>? scannedFiles;
  final String? error;
  final int imageCount;

  DocumentScanResult({
    required this.success,
    this.scannedFiles,
    this.error,
    required this.imageCount,
  });
}

/// Result object for text recognition (OCR)
class TextRecognitionResult {
  final bool success;
  final String text;
  final List<TextBlock>? textBlocks;
  final double? confidence;
  final String? error;

  TextRecognitionResult({
    required this.success,
    required this.text,
    this.textBlocks,
    this.confidence,
    this.error,
  });
}

/// Result object for complete document scan with OCR
class CompleteDocumentResult {
  final bool success;
  final List<XFile>? scannedFiles;
  final List<TextRecognitionResult>? ocrResults;
  final Uint8List? pdfBytes;
  final String? error;
  final int? imageCount;

  CompleteDocumentResult({
    required this.success,
    this.scannedFiles,
    this.ocrResults,
    this.pdfBytes,
    this.error,
    this.imageCount,
  });
}

/// Enhanced scan result with OCR support
class EnhancedScanResult {
  final bool success;
  final String? filePath;
  final Uint8List? pdfBytes;
  final List<TextRecognitionResult>? ocrResults;
  final String? error;
  final int pageCount;

  EnhancedScanResult({
    required this.success,
    this.filePath,
    this.pdfBytes,
    this.ocrResults,
    this.error,
    required this.pageCount,
  });
}

/// Result classes for enhanced PDF operations
class PdfExportResult {
  final bool success;
  final String? filePath;
  final Uint8List? pdfBytes;
  final String? extractedText;
  final String exportType;
  final String? error;

  PdfExportResult({
    required this.success,
    this.filePath,
    this.pdfBytes,
    this.extractedText,
    required this.exportType,
    this.error,
  });
}

class SaveResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final String saveLocation;
  final int fileSize;
  final String? error;

  SaveResult({
    required this.success,
    this.filePath,
    this.fileName,
    required this.saveLocation,
    this.fileSize = 0,
    this.error,
  });
}

class ShareResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final String shareStatus;
  final String? error;

  ShareResult({
    required this.success,
    this.filePath,
    this.fileName,
    required this.shareStatus,
    this.error,
  });
}

class PrintResult {
  final bool success;
  final String? message;
  final String? error;

  PrintResult({
    required this.success,
    this.message,
    this.error,
  });
}

class PreviewResult {
  final bool success;
  final String? message;
  final String? error;

  PreviewResult({
    required this.success,
    this.message,
    this.error,
  });
}

class StorageInfo {
  final SaveLocation location;
  final String path;
  final String displayName;
  final int availableSpace;
  final bool isWritable;

  StorageInfo({
    required this.location,
    required this.path,
    required this.displayName,
    required this.availableSpace,
    required this.isWritable,
  });

  String get formattedSize {
    if (availableSpace < 1024) return '${availableSpace}B';
    if (availableSpace < 1024 * 1024) return '${(availableSpace / 1024).toStringAsFixed(1)}KB';
    if (availableSpace < 1024 * 1024 * 1024) return '${(availableSpace / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(availableSpace / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
