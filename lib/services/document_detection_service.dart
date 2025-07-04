import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Document Detection Service
/// Handles automatic document detection logic
class DocumentDetectionService {
  bool _isDetecting = false;
  bool _documentDetected = false;
  Timer? _detectionTimer;
  VoidCallback? _onDocumentDetected;
  VoidCallback? _onDocumentLost;

  // Getters
  bool get isDetecting => _isDetecting;
  bool get documentDetected => _documentDetected;

  /// Set detection callbacks
  void setCallbacks({
    VoidCallback? onDocumentDetected,
    VoidCallback? onDocumentLost,
  }) {
    _onDocumentDetected = onDocumentDetected;
    _onDocumentLost = onDocumentLost;
  }

  /// Start automatic document detection
  void startAutoDetection() {
    stopAutoDetection(); // Stop any existing detection

    _detectionTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) => _detectDocument(),
    );
  }

  /// Stop automatic document detection
  void stopAutoDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _isDetecting = false;
    _setDocumentDetected(false);
  }

  /// Perform document detection (simulation for demo)
  Future<void> _detectDocument() async {
    if (_isDetecting) return;

    _isDetecting = true;

    try {
      // Simulate processing delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate document detection (in real app, this would use edge detection)
      final hasDocument = _simulateDocumentDetection();

      _setDocumentDetected(hasDocument);
    } catch (e) {
      debugPrint('Document detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Simulate document detection for demo
  bool _simulateDocumentDetection() {
    // Random detection for demo purposes
    // In a real implementation, this would analyze camera frames
    final random = Random();
    return random.nextBool();
  }

  /// Set document detection state and trigger callbacks
  void _setDocumentDetected(bool detected) {
    if (_documentDetected != detected) {
      _documentDetected = detected;

      if (detected) {
        _onDocumentDetected?.call();
      } else {
        _onDocumentLost?.call();
      }
    }
  }

  /// Manual document detection trigger
  Future<bool> detectNow() async {
    if (_isDetecting) return _documentDetected;

    _isDetecting = true;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final detected = _simulateDocumentDetection();
      _setDocumentDetected(detected);
      return detected;
    } finally {
      _isDetecting = false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoDetection();
    _onDocumentDetected = null;
    _onDocumentLost = null;
  }
}
