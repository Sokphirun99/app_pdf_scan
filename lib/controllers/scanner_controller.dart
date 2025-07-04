import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/camera_service.dart';
import '../services/document_detection_service.dart';
import '../services/scan_service.dart';

/// Scanner Controller
/// Manages the business logic for the advanced scanner
class ScannerController extends ChangeNotifier {
  // Services
  final CameraService _cameraService = CameraService();
  final DocumentDetectionService _detectionService = DocumentDetectionService();
  final ScanService _scanService = ScanService();

  // State
  bool _isAutoScanMode = true;
  bool _isScanning = false;
  String? _lastScannedImagePath;
  final List<String> _scannedDocuments = [];

  // Animation controllers (injected from UI)
  AnimationController? _pulseController;
  AnimationController? _slideController;

  // Getters
  bool get isAutoScanMode => _isAutoScanMode;
  bool get isScanning => _isScanning;
  bool get isCameraInitialized => _cameraService.isInitialized;
  bool get documentDetected => _detectionService.documentDetected;
  String? get lastScannedImagePath => _lastScannedImagePath;
  List<String> get scannedDocuments => List.unmodifiable(_scannedDocuments);
  CameraService get cameraService => _cameraService;

  /// Initialize the scanner
  Future<String?> initialize() async {
    try {
      // Initialize camera
      final success = await _cameraService.initialize();
      if (!success) {
        return 'Failed to initialize camera';
      }

      // Set up detection callbacks
      _detectionService.setCallbacks(
        onDocumentDetected: _onDocumentDetected,
        onDocumentLost: _onDocumentLost,
      );

      // Start auto scan if enabled
      if (_isAutoScanMode) {
        _detectionService.startAutoDetection();
      }

      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Initialization error: $e';
    }
  }

  /// Set animation controllers from UI
  void setAnimationControllers({
    AnimationController? pulseController,
    AnimationController? slideController,
  }) {
    _pulseController = pulseController;
    _slideController = slideController;
  }

  /// Toggle between auto and manual scan mode
  void toggleScanMode() {
    _isAutoScanMode = !_isAutoScanMode;

    if (_isAutoScanMode) {
      _detectionService.startAutoDetection();
    } else {
      _detectionService.stopAutoDetection();
    }

    notifyListeners();
  }

  /// Capture document manually
  Future<String?> captureDocument() async {
    if (_isScanning || !_cameraService.isInitialized) {
      return 'Camera not ready';
    }

    try {
      _isScanning = true;
      notifyListeners();

      final image = await _cameraService.takePicture();
      if (image != null) {
        _addScannedDocument(image.path);
        return null; // Success
      } else {
        return 'Failed to capture image';
      }
    } catch (e) {
      return 'Capture error: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Pick images from gallery
  Future<String?> pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        for (final image in images) {
          _addScannedDocument(image.path);
        }
        return null; // Success
      } else {
        return 'No images selected';
      }
    } catch (e) {
      return 'Gallery error: $e';
    }
  }

  /// Add scanned document to list
  void _addScannedDocument(String imagePath) {
    _scannedDocuments.add(imagePath);
    _lastScannedImagePath = imagePath;

    // Reset detection state
    // _detectionService will handle this internally

    // Trigger animations
    _pulseController?.stop();
    _slideController?.forward().then((_) {
      Timer(const Duration(seconds: 2), () {
        _slideController?.reverse();
      });
    });

    notifyListeners();
  }

  /// Remove document at index
  void removeDocument(int index) {
    if (index >= 0 && index < _scannedDocuments.length) {
      _scannedDocuments.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all documents
  void clearAllDocuments() {
    _scannedDocuments.clear();
    _lastScannedImagePath = null;
    notifyListeners();
  }

  /// Generate PDF with existing scan service
  Future<ScanResult> generatePdf() async {
    if (_scannedDocuments.isEmpty) {
      return ScanResult(
        success: false,
        error: 'No documents available for PDF generation',
        pageCount: 0,
      );
    }

    try {
      final files = _scannedDocuments.map((path) => XFile(path)).toList();
      final fileName =
          'Advanced_Scanner_${DateTime.now().millisecondsSinceEpoch}.pdf';

      return await _scanService.scanToPdf(files, fileName: fileName);
    } catch (e) {
      return ScanResult(
        success: false,
        error: 'Export error: $e',
        pageCount: _scannedDocuments.length,
      );
    }
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        _cameraService.pause();
        _detectionService.stopAutoDetection();
        break;
      case AppLifecycleState.resumed:
        _cameraService.resume();
        if (_isAutoScanMode) {
          _detectionService.startAutoDetection();
        }
        break;
      default:
        break;
    }
  }

  /// Document detected callback
  void _onDocumentDetected() {
    _pulseController?.repeat(reverse: true);

    if (_isAutoScanMode) {
      // Auto-capture after 2 seconds of detection
      Timer(const Duration(seconds: 2), () {
        if (documentDetected && _isAutoScanMode) {
          captureDocument();
        }
      });
    }

    notifyListeners();
  }

  /// Document lost callback
  void _onDocumentLost() {
    _pulseController?.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _detectionService.dispose();
    super.dispose();
  }
}
