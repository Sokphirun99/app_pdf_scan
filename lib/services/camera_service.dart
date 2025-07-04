import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/scan_service.dart';

/// Camera Service - Handles all camera-related operations
/// This makes camera management easier to debug and maintain
class CameraService {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  final ScanService _scanService = ScanService();

  // Getters
  CameraController? get controller => _cameraController;
  bool get isInitialized => _isInitialized;
  List<CameraDescription> get cameras => _cameras;

  /// Initialize camera
  Future<bool> initialize() async {
    try {
      // Request permissions
      final hasPermission = await _scanService.requestPermissions();
      if (!hasPermission) {
        throw Exception('Camera permission is required for scanning');
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      // Initialize camera controller with back camera
      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      debugPrint('Camera initialization error: $e');
      return false;
    }
  }

  /// Take a picture
  Future<XFile?> takePicture() async {
    if (!_isInitialized || _cameraController == null) {
      throw Exception('Camera not initialized');
    }

    try {
      final image = await _cameraController!.takePicture();
      return image;
    } catch (e) {
      debugPrint('Failed to take picture: $e');
      return null;
    }
  }

  /// Dispose camera resources
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _isInitialized = false;
  }

  /// Resume camera (for app lifecycle)
  Future<void> resume() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Pause camera (for app lifecycle)
  void pause() {
    _cameraController?.dispose();
    _isInitialized = false;
  }
}
