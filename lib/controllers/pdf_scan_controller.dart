import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/scan_to_pdf_models.dart' as models;
import '../services/pdf_generation_service.dart';

/// PDF Scan Controller
/// Manages the business logic for the scan-to-PDF functionality
class PdfScanController extends ChangeNotifier {
  final PdfGenerationService _pdfService = PdfGenerationService();

  models.ScanToPdfState _state = const models.ScanToPdfState();

  // Getters
  models.ScanToPdfState get state => _state;
  List<models.ScanToImageData> get images => _state.images;
  bool get isProcessing => _state.isProcessing;
  bool get cameraInUse => _state.cameraInUse;
  bool get hasImages => _state.images.isNotEmpty;
  String? get lastError => _state.lastError;
  String? get lastGeneratedPdfPath => _state.lastGeneratedPdfPath;

  /// Initialize the controller
  Future<void> initialize() async {
    try {
      final hasPermissions = await _pdfService.requestPermissions();
      if (!hasPermissions) {
        _updateState(
          _state.copyWith(
            lastError: 'Camera and storage permissions are required',
          ),
        );
      }
    } catch (e) {
      _updateState(_state.copyWith(lastError: 'Failed to initialize: $e'));
    }
  }

  /// Capture image from camera
  Future<void> captureFromCamera() async {
    await _captureImage(ImageSource.camera);
  }

  /// Pick image from gallery
  Future<void> pickFromGallery() async {
    await _captureImage(ImageSource.gallery);
  }

  /// Pick multiple images from gallery
  Future<void> pickMultipleImages() async {
    try {
      _updateState(_state.copyWith(isProcessing: true, lastError: null));

      final newImages = await _pdfService.pickMultipleImages();
      if (newImages.isNotEmpty) {
        final allImages = List<models.ScanToImageData>.from(_state.images)
          ..addAll(newImages);

        _updateState(_state.copyWith(images: allImages, isProcessing: false));
      } else {
        _updateState(
          _state.copyWith(isProcessing: false, lastError: 'No images selected'),
        );
      }
    } catch (e) {
      _updateState(
        _state.copyWith(
          isProcessing: false,
          lastError: 'Failed to pick images: $e',
        ),
      );
    }
  }

  /// Remove image at index
  Future<void> removeImage(int index) async {
    if (index >= 0 && index < _state.images.length) {
      try {
        final updatedImages = List<models.ScanToImageData>.from(_state.images);
        final removedImage = updatedImages.removeAt(index);

        // Clean up the file
        await _pdfService.removeImage([removedImage], 0);

        _updateState(_state.copyWith(images: updatedImages));
      } catch (e) {
        _updateState(_state.copyWith(lastError: 'Failed to remove image: $e'));
      }
    }
  }

  /// Reorder images
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final updatedImages = List<models.ScanToImageData>.from(_state.images);
    final item = updatedImages.removeAt(oldIndex);
    updatedImages.insert(newIndex, item);

    _updateState(_state.copyWith(images: updatedImages));
  }

  /// Generate and save PDF
  Future<void> generatePdf(
    models.PdfGenerationSettings settings,
    models.PdfSaveLocation location,
  ) async {
    if (_state.images.isEmpty) {
      _updateState(_state.copyWith(lastError: 'No images to generate PDF'));
      return;
    }

    try {
      _updateState(
        _state.copyWith(
          isProcessing: true,
          lastError: null,
          settings: settings,
        ),
      );

      // Generate PDF
      final pdfBytes = await _pdfService.generatePdf(_state.images, settings);

      // Save PDF
      final savedPath = await _pdfService.savePdf(pdfBytes, settings, location);

      _updateState(
        _state.copyWith(isProcessing: false, lastGeneratedPdfPath: savedPath),
      );
    } catch (e) {
      _updateState(
        _state.copyWith(
          isProcessing: false,
          lastError: 'Failed to generate PDF: $e',
        ),
      );
    }
  }

  /// Share PDF
  Future<void> shareAsPdf(models.PdfGenerationSettings settings) async {
    if (_state.images.isEmpty) {
      _updateState(_state.copyWith(lastError: 'No images to share'));
      return;
    }

    try {
      _updateState(_state.copyWith(isProcessing: true, lastError: null));

      final pdfBytes = await _pdfService.generatePdf(_state.images, settings);
      await _pdfService.sharePdf(pdfBytes, settings.fileName);

      _updateState(_state.copyWith(isProcessing: false));
    } catch (e) {
      _updateState(
        _state.copyWith(
          isProcessing: false,
          lastError: 'Failed to share PDF: $e',
        ),
      );
    }
  }

  /// Preview PDF
  Future<void> previewPdf(models.PdfGenerationSettings settings) async {
    if (_state.images.isEmpty) {
      _updateState(_state.copyWith(lastError: 'No images to preview'));
      return;
    }

    try {
      _updateState(_state.copyWith(isProcessing: true, lastError: null));

      final pdfBytes = await _pdfService.generatePdf(_state.images, settings);
      await _pdfService.previewPdf(pdfBytes, settings.fileName);

      _updateState(_state.copyWith(isProcessing: false));
    } catch (e) {
      _updateState(
        _state.copyWith(
          isProcessing: false,
          lastError: 'Failed to preview PDF: $e',
        ),
      );
    }
  }

  /// Clear all images
  void clearAllImages() {
    _updateState(_state.copyWith(images: []));
  }

  /// Clear last error
  void clearError() {
    _updateState(_state.copyWith(lastError: null));
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(bool isResumed) {
    if (isResumed && _state.cameraInUse) {
      _updateState(_state.copyWith(cameraInUse: false, isProcessing: false));
    }
  }

  /// Mark camera as in use
  void setCameraInUse(bool inUse) {
    _updateState(_state.copyWith(cameraInUse: inUse));
  }

  // Private methods

  Future<void> _captureImage(ImageSource source) async {
    try {
      _updateState(
        _state.copyWith(
          isProcessing: true,
          cameraInUse: source == ImageSource.camera,
          lastError: null,
        ),
      );

      final imageData = await _pdfService.captureImage(source);

      if (imageData != null) {
        final updatedImages = List<models.ScanToImageData>.from(_state.images)
          ..add(imageData);

        _updateState(
          _state.copyWith(
            images: updatedImages,
            isProcessing: false,
            cameraInUse: false,
          ),
        );
      } else {
        _updateState(
          _state.copyWith(
            isProcessing: false,
            cameraInUse: false,
            lastError: 'No image captured',
          ),
        );
      }
    } catch (e) {
      _updateState(
        _state.copyWith(
          isProcessing: false,
          cameraInUse: false,
          lastError: 'Failed to capture image: $e',
        ),
      );
    }
  }

  void _updateState(models.ScanToPdfState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _pdfService.cleanupTempFiles();
    super.dispose();
  }
}
