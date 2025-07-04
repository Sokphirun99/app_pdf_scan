import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../services/scan_service.dart';

class AdvancedScannerScreen extends StatefulWidget {
  const AdvancedScannerScreen({super.key});

  @override
  State<AdvancedScannerScreen> createState() => _AdvancedScannerScreenState();
}

class _AdvancedScannerScreenState extends State<AdvancedScannerScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isAutoScanMode = true;
  bool _isScanning = false;
  bool _documentDetected = false;
  String? _lastScannedImagePath;
  Timer? _autoScanTimer;

  final ScanService _scanService = ScanService();
  final List<String> _scannedDocuments = [];

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _scanService.requestPermissions();
      if (!hasPermission) {
        _showErrorDialog('Camera permission is required for scanning');
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showErrorDialog('No cameras available on this device');
        return;
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

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startAutoScanMode();
      }
    } catch (e) {
      _showErrorDialog('Failed to initialize camera: $e');
    }
  }

  void _startAutoScanMode() {
    if (_isAutoScanMode) {
      _autoScanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_isCameraInitialized && !_isScanning) {
          _detectDocument();
        }
      });
    }
  }

  void _stopAutoScanMode() {
    _autoScanTimer?.cancel();
    _autoScanTimer = null;
  }

  Future<void> _detectDocument() async {
    if (!_isCameraInitialized || _isScanning) return;

    try {
      setState(() {
        _isScanning = true;
      });

      // Simulate document detection (in real implementation, this would use edge detection)
      await Future.delayed(const Duration(milliseconds: 500));

      // For demo purposes, randomly detect documents
      final hasDocument = DateTime.now().millisecond % 3 == 0;

      if (hasDocument != _documentDetected) {
        setState(() {
          _documentDetected = hasDocument;
        });

        if (hasDocument) {
          _pulseController.repeat(reverse: true);
          if (_isAutoScanMode) {
            // Auto-capture after 2 seconds of detection
            Timer(const Duration(seconds: 2), () {
              if (_documentDetected && _isAutoScanMode) {
                _captureDocument();
              }
            });
          }
        } else {
          _pulseController.stop();
        }
      }
    } catch (e) {
      // Error detecting document - silently handle in production
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _captureDocument() async {
    if (!_isCameraInitialized || _isScanning) return;

    try {
      setState(() {
        _isScanning = true;
      });

      // For now, we'll use camera capture for all scanning
      final image = await _cameraController!.takePicture();
      _addScannedDocument(image.path);
    } catch (e) {
      _showErrorDialog('Failed to capture document: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _addScannedDocument(String imagePath) {
    setState(() {
      _scannedDocuments.add(imagePath);
      _lastScannedImagePath = imagePath;
      _documentDetected = false;
    });

    _pulseController.stop();
    _slideController.forward().then((_) {
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _slideController.reverse();
        }
      });
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document captured! Total: ${_scannedDocuments.length}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleScanMode() {
    setState(() {
      _isAutoScanMode = !_isAutoScanMode;
    });

    if (_isAutoScanMode) {
      _startAutoScanMode();
    } else {
      _stopAutoScanMode();
      _pulseController.stop();
      setState(() {
        _documentDetected = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        for (final image in images) {
          _addScannedDocument(image.path);
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to pick images: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showScannedDocuments() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF4F4F4F)
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Scanned Documents (${_scannedDocuments.length})',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? const Color(0xFFE8E8E8)
                                        : Colors.black87,
                              ),
                            ),
                            if (_scannedDocuments.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: _generatePdfFromScans,
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 18,
                                ),
                                label: const Text('Create PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark
                                          ? const Color(0xFF1E40AF)
                                          : Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Documents grid
                      Expanded(
                        child:
                            _scannedDocuments.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.document_scanner_outlined,
                                        size: 80,
                                        color:
                                            isDark
                                                ? const Color(0xFF4F4F4F)
                                                : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No documents scanned yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color:
                                              isDark
                                                  ? const Color(0xFFB0B0B0)
                                                  : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Use the camera or gallery to scan documents',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              isDark
                                                  ? const Color(0xFF808080)
                                                  : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : GridView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(20),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.75,
                                      ),
                                  itemCount: _scannedDocuments.length,
                                  itemBuilder: (context, index) {
                                    final imagePath = _scannedDocuments[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: isDark ? 0.3 : 0.1,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          children: [
                                            Image.file(
                                              File(imagePath),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                            // Delete button
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: GestureDetector(
                                                onTap:
                                                    () =>
                                                        _removeDocument(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withValues(alpha: 0.9),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Page number
                                            Positioned(
                                              bottom: 8,
                                              left: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.black.withValues(
                                                        alpha: 0.8,
                                                      ),
                                                      Colors.black.withValues(
                                                        alpha: 0.6,
                                                      ),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Page ${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
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
                ),
          ),
    );
  }

  void _removeDocument(int index) {
    setState(() {
      _scannedDocuments.removeAt(index);
    });
    Navigator.of(context).pop();
    _showScannedDocuments();
  }

  Future<void> _generatePdfFromScans() async {
    if (_scannedDocuments.isEmpty) return;

    try {
      // Convert file paths to XFile objects
      final xFiles = _scannedDocuments.map((path) => XFile(path)).toList();

      // Use the scanToPdf method from ScanService
      final result = await _scanService.scanToPdf(
        xFiles,
        fileName: 'Advanced_Scanner_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close bottom sheet

        if (result.success && result.filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'PDF created successfully!\nSaved to: ${result.filePath}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        } else {
          _showErrorDialog(
            'Failed to create PDF: ${result.error ?? "Unknown error"}',
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to create PDF: $e');
    }
  }

  /// Enhanced PDF export with advanced options
  Future<void> _generatePdfWithAdvancedOptions() async {
    if (_scannedDocuments.isEmpty) {
      _showErrorDialog('No documents available for PDF generation');
      return;
    }

    // Show advanced export options dialog
    final config = await _showAdvancedExportDialog();
    if (config == null) return;

    try {
      setState(() {
        _isScanning = true;
      });

      final files = _scannedDocuments.map((path) => XFile(path)).toList();
      final fileName = 'PDF_Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Use the enhanced export with advanced configuration
      final result = await _scanService.exportPdfWithAdvancedConfig(
        files,
        fileName: fileName,
        config: config,
      );

      if (result.success) {
        switch (config.exportOption) {
          case PdfExportOption.saveToDevice:
            _showSuccessDialog(
              'PDF Saved Successfully',
              'High-quality PDF saved to: ${result.filePath}',
              showViewButton: true,
              filePath: result.filePath,
              ocrText: result.extractedText,
            );
            break;
          case PdfExportOption.shareFile:
            _showSnackBar(
              'PDF shared successfully!',
              Colors.green,
              icon: Icons.share,
            );
            break;
          case PdfExportOption.print:
            _showSnackBar(
              'PDF sent to printer!',
              Colors.green,
              icon: Icons.print,
            );
            break;
          case PdfExportOption.preview:
            _showSnackBar(
              'PDF preview opened!',
              Colors.green,
              icon: Icons.preview,
            );
            break;
        }

        // Show OCR results if available
        if (result.extractedText != null && result.extractedText!.isNotEmpty) {
          _showOcrResultDialog(result.extractedText!);
        }
      } else {
        _showErrorDialog(result.error ?? 'PDF export failed');
      }
    } catch (e) {
      _showErrorDialog('Export error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  /// Show success dialog with options
  void _showSuccessDialog(
    String title,
    String message, {
    bool showViewButton = false,
    String? filePath,
    String? ocrText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        ),
                      ),
                      if (showViewButton && filePath != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _viewSavedFile(filePath);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('View File'),
                          ),
                        ),
                      ],
                      if (ocrText != null && ocrText.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showOcrResultDialog(ocrText);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('View OCR'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// View saved file (copy path to clipboard)
  void _viewSavedFile(String filePath) {
    Clipboard.setData(ClipboardData(text: filePath));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File path copied to clipboard'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Open Folder',
          textColor: Colors.white,
          onPressed: () {
            // In a real implementation, you could open the file manager
            // For now, we'll just show the path
          },
        ),
      ),
    );
  }

  /// Show advanced export options dialog with quality settings
  Future<PdfExportConfigWithOption?> _showAdvancedExportDialog() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    PdfQuality selectedQuality = PdfQuality.medium;
    PdfExportOption selectedExportOption = PdfExportOption.saveToDevice;
    bool includeOCR = false;
    bool addWatermark = false;
    String watermarkText = '';

    return showDialog<PdfExportConfigWithOption>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  backgroundColor:
                      isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 600,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              Icons.settings,
                              size: 32,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Advanced PDF Export',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Scrollable content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quality Settings
                                _buildSectionHeader('PDF Quality', isDark),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          isDark
                                              ? Colors.white24
                                              : Colors.black12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children:
                                        PdfQuality.values.map((quality) {
                                          return RadioListTile<PdfQuality>(
                                            title: Text(
                                              _getQualityDisplayName(quality),
                                              style: TextStyle(
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                            subtitle: Text(
                                              _getQualityDescription(quality),
                                              style: TextStyle(
                                                color:
                                                    isDark
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            value: quality,
                                            groupValue: selectedQuality,
                                            activeColor: theme.primaryColor,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedQuality = value!;
                                              });
                                            },
                                          );
                                        }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Export Options
                                _buildSectionHeader('Export Option', isDark),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          isDark
                                              ? Colors.white24
                                              : Colors.black12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildExportOptionTile(
                                        PdfExportOption.saveToDevice,
                                        Icons.save_alt,
                                        'Save to Device',
                                        'Save PDF to device storage',
                                        selectedExportOption,
                                        isDark,
                                        theme,
                                        (value) => setState(
                                          () => selectedExportOption = value!,
                                        ),
                                      ),
                                      _buildExportOptionTile(
                                        PdfExportOption.shareFile,
                                        Icons.share,
                                        'Share File',
                                        'Share with other apps',
                                        selectedExportOption,
                                        isDark,
                                        theme,
                                        (value) => setState(
                                          () => selectedExportOption = value!,
                                        ),
                                      ),
                                      _buildExportOptionTile(
                                        PdfExportOption.print,
                                        Icons.print,
                                        'Print',
                                        'Print document directly',
                                        selectedExportOption,
                                        isDark,
                                        theme,
                                        (value) => setState(
                                          () => selectedExportOption = value!,
                                        ),
                                      ),
                                      _buildExportOptionTile(
                                        PdfExportOption.preview,
                                        Icons.preview,
                                        'Preview',
                                        'Open PDF preview',
                                        selectedExportOption,
                                        isDark,
                                        theme,
                                        (value) => setState(
                                          () => selectedExportOption = value!,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Advanced Features
                                _buildSectionHeader(
                                  'Advanced Features',
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          isDark
                                              ? Colors.white24
                                              : Colors.black12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      SwitchListTile(
                                        title: Text(
                                          'Include OCR Text',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Extract and include searchable text',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        value: includeOCR,
                                        activeColor: theme.primaryColor,
                                        onChanged: (value) {
                                          setState(() {
                                            includeOCR = value;
                                          });
                                        },
                                      ),
                                      SwitchListTile(
                                        title: Text(
                                          'Add Watermark',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Add custom watermark to PDF',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        value: addWatermark,
                                        activeColor: theme.primaryColor,
                                        onChanged: (value) {
                                          setState(() {
                                            addWatermark = value;
                                          });
                                        },
                                      ),
                                      if (addWatermark) ...[
                                        const SizedBox(height: 8),
                                        TextField(
                                          decoration: InputDecoration(
                                            labelText: 'Watermark Text',
                                            hintText: 'Enter watermark text',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            labelStyle: TextStyle(
                                              color:
                                                  isDark
                                                      ? Colors.white70
                                                      : Colors.black54,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                          ),
                                          onChanged: (value) {
                                            watermarkText = value;
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  final config = PdfExportConfigWithOption(
                                    quality: selectedQuality,
                                    includeOCR: includeOCR,
                                    addWatermark: addWatermark,
                                    watermarkText:
                                        addWatermark ? watermarkText : null,
                                    exportOption: selectedExportOption,
                                  );
                                  Navigator.of(context).pop(config);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Export PDF'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  /// Build export option tile
  Widget _buildExportOptionTile(
    PdfExportOption option,
    IconData icon,
    String title,
    String subtitle,
    PdfExportOption selectedOption,
    bool isDark,
    ThemeData theme,
    Function(PdfExportOption?) onChanged,
  ) {
    return RadioListTile<PdfExportOption>(
      title: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 12,
        ),
      ),
      value: option,
      groupValue: selectedOption,
      activeColor: theme.primaryColor,
      onChanged: onChanged,
    );
  }

  /// Get quality display name
  String _getQualityDisplayName(PdfQuality quality) {
    switch (quality) {
      case PdfQuality.high:
        return 'High Quality';
      case PdfQuality.medium:
        return 'Medium Quality';
      case PdfQuality.low:
        return 'Low Quality';
      case PdfQuality.custom:
        return 'Custom';
    }
  }

  /// Get quality description
  String _getQualityDescription(PdfQuality quality) {
    switch (quality) {
      case PdfQuality.high:
        return 'Best quality, larger file size';
      case PdfQuality.medium:
        return 'Balanced quality and size (recommended)';
      case PdfQuality.low:
        return 'Smaller size, lower quality';
      case PdfQuality.custom:
        return 'Custom quality settings';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoScanMode();
    _cameraController?.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F23) : const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          'Advanced Document Scanner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE8E8E8) : Colors.white,
          ),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1A1A2E) : const Color(0xFF2D2D2D),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFE8E8E8) : Colors.white,
        ),
        actions: [
          // PDF Export Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed:
                  _scannedDocuments.isNotEmpty
                      ? _generatePdfWithAdvancedOptions
                      : null,
              icon: Icon(
                Icons.picture_as_pdf,
                color:
                    _scannedDocuments.isNotEmpty
                        ? (isDark ? const Color(0xFFE8E8E8) : Colors.white)
                        : Colors.grey,
              ),
              tooltip: 'Export PDF',
            ),
          ),
          // Scanned Documents Folder
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _showScannedDocuments,
              icon: Badge(
                label: Text(
                  '${_scannedDocuments.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor:
                    isDark ? const Color(0xFF059669) : Colors.green,
                child: Icon(
                  Icons.folder_outlined,
                  color: isDark ? const Color(0xFFE8E8E8) : Colors.white,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _pickFromGallery,
              icon: Icon(
                Icons.photo_library_outlined,
                color: isDark ? const Color(0xFFE8E8E8) : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: isDark ? const Color(0xFF1E40AF) : Colors.blue,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing camera...',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFE8E8E8) : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Document detection overlay
          if (_documentDetected)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: (isDark
                                ? const Color(0xFF10B981)
                                : Colors.greenAccent)
                            .withValues(alpha: 0.9),
                        width: 4 * _pulseAnimation.value,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                                  ? const Color(0xFF10B981)
                                  : Colors.greenAccent)
                              .withValues(alpha: 0.3 * _pulseAnimation.value),
                          blurRadius: 8 * _pulseAnimation.value,
                          spreadRadius: 2 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Scan mode toggle
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: _toggleScanMode,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        _isAutoScanMode
                            ? [
                              isDark ? const Color(0xFF10B981) : Colors.green,
                              isDark
                                  ? const Color(0xFF059669)
                                  : Colors.green.shade700,
                            ]
                            : [
                              isDark ? const Color(0xFFF59E0B) : Colors.orange,
                              isDark
                                  ? const Color(0xFFD97706)
                                  : Colors.orange.shade700,
                            ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: (_isAutoScanMode
                              ? (isDark
                                  ? const Color(0xFF10B981)
                                  : Colors.green)
                              : (isDark
                                  ? const Color(0xFFF59E0B)
                                  : Colors.orange))
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAutoScanMode ? Icons.auto_mode : Icons.touch_app,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isAutoScanMode ? 'AUTO' : 'MANUAL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status indicator
          if (_documentDetected)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? const Color(0xFF10B981) : Colors.green,
                      isDark ? const Color(0xFF059669) : Colors.green.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF10B981) : Colors.green)
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Document Detected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Manual capture button
          if (!_isAutoScanMode)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isScanning ? null : _captureDocument,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient:
                          _isScanning
                              ? LinearGradient(
                                colors: [
                                  Colors.grey.shade400,
                                  Colors.grey.shade600,
                                ],
                              )
                              : LinearGradient(
                                colors: [Colors.white, Colors.grey.shade100],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isScanning ? Icons.hourglass_empty : Icons.camera_alt,
                      color: _isScanning ? Colors.white : Colors.black87,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

          // Last scanned document preview
          if (_lastScannedImagePath != null)
            SlideTransition(
              position: _slideAnimation,
              child: Positioned(
                bottom: 140,
                right: 20,
                child: Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          File(_lastScannedImagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isDark
                                      ? const Color(0xFF10B981)
                                      : Colors.green,
                              width: 2,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Latest',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _scannedDocuments.isNotEmpty
              ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? const Color(0xFF1E40AF) : Colors.blue,
                      isDark ? const Color(0xFF1D4ED8) : Colors.blue.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF1E40AF) : Colors.blue)
                          .withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _generatePdfWithAdvancedOptions,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Export PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Show enhanced snackbar with icon
  void _showSnackBar(String message, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show OCR results dialog
  void _showOcrResultDialog(String ocrText) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 32,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Extracted Text (OCR)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: ocrText));
                          _showSnackBar(
                            'Text copied to clipboard!',
                            Colors.green,
                            icon: Icons.copy,
                          );
                        },
                        icon: Icon(Icons.copy, color: theme.primaryColor),
                        tooltip: 'Copy to Clipboard',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // OCR Text Content
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          ocrText.isEmpty
                              ? 'No text detected in the images.'
                              : ocrText,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.87)
                                    : Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
