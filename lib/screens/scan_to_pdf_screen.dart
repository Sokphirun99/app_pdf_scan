import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import '../services/scan_service.dart';
import 'advanced_scanner_screen.dart';

class ScanToPdfScreen extends StatefulWidget {
  const ScanToPdfScreen({super.key});

  @override
  State<ScanToPdfScreen> createState() => _ScanToPdfScreenState();
}

class _ScanToPdfScreenState extends State<ScanToPdfScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final List<XFile> _scannedImages = [];
  final ScanService _scanService = ScanService();
  bool _isProcessing = false;
  bool _cameraInUse = false;

  // Keep state alive to prevent recreation after camera use
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pre-initialize service
    _initializeService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Cleanup temporary files when screen is disposed
    _scanService.cleanupTempFiles();
    super.dispose();
  }

  /// Pre-initialize the service to ensure readiness
  Future<void> _initializeService() async {
    try {
      await _scanService.requestPermissions();
    } catch (e) {
      // Ignore initialization errors
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed - likely after camera use
        if (_cameraInUse || _isProcessing) {
          _handleAppResumed();
        }
        break;
      case AppLifecycleState.paused:
        // App paused - likely for camera use
        if (_isProcessing) {
          _cameraInUse = true;
        }
        break;
      case AppLifecycleState.inactive:
        // App inactive - transitioning
        break;
      case AppLifecycleState.detached:
        // App detached
        break;
      case AppLifecycleState.hidden:
        // App hidden
        break;
    }
  }

  /// Handle app resumed after camera operation
  void _handleAppResumed() {
    // Reset states with delay to ensure proper initialization
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _cameraInUse = false;
        });

        // Force a rebuild to refresh UI
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      // Prevent multiple simultaneous captures
      if (_isProcessing || _cameraInUse) {
        _showErrorDialog('Camera is busy. Please wait and try again.');
        return;
      }

      // Show loading indicator
      setState(() {
        _isProcessing = true;
        _cameraInUse = true;
      });

      // Add delay to ensure UI updates and proper state
      await Future.delayed(const Duration(milliseconds: 300));

      // Attempt to capture image with retry logic
      XFile? image;
      int retryCount = 0;
      const maxRetries = 2;

      while (retryCount <= maxRetries && image == null) {
        try {
          image = await _scanService.captureImageSafe();
          break; // Success, exit retry loop
        } on ScanException {
          retryCount++;
          if (retryCount > maxRetries) {
            rethrow; // Max retries reached, propagate error
          }

          // Wait before retry
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (image != null && mounted) {
        // Optimize image to prevent memory issues
        try {
          final optimizedImage = await _scanService.optimizeImageForPdf(image);
          setState(() {
            _scannedImages.add(optimizedImage);
          });

          // Show success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image captured and optimized successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // Fallback to original image if optimization fails
          setState(() {
            _scannedImages.add(image!); // Using ! since we checked null above
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image captured successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else if (mounted) {
        // User cancelled camera
        _showInfoDialog('Camera operation was cancelled.');
      }
    } on ScanException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Unexpected camera error. Please restart the app if this continues.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _cameraInUse = false;
        });
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      // Show loading indicator
      setState(() {
        _isProcessing = true;
      });

      final List<XFile> images = await _scanService.pickMultipleImages();

      if (images.isNotEmpty) {
        setState(() {
          _scannedImages.addAll(images);
        });

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${images.length} image(s) selected successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } on ScanException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Unexpected error: $e');
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
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

  Future<void> _generatePdf() async {
    if (_scannedImages.isEmpty) {
      _showErrorDialog('Please add at least one image to create a PDF');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _scanService.scanToPdf(
        _scannedImages,
        fileName:
            'scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (result.success) {
        _showSuccessDialog(result.filePath!, result.pdfBytes!);
      } else {
        _showErrorDialog('Failed to generate PDF: ${result.error}');
      }
    } catch (e) {
      _showErrorDialog('Failed to generate PDF: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(String filePath, Uint8List pdfBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('PDF Created Successfully!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your document has been converted to PDF successfully!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saved to: ${filePath.split('/').last}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose what you\'d like to do next:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
            ],
          ),
          actions: [
            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            // Preview button
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await Printing.layoutPdf(onLayout: (format) => pdfBytes);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Preview'),
            ),
            // Share button
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _savePdfWithOptions(pdfBytes, filePath);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save_alt, size: 18),
              label: const Text('Save & Share'),
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

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('Information'),
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
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Choose how to add images',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your preferred method to capture documents',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Two main options
              Row(
                children: [
                  // Camera Option
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Take Photo',
                      description: 'Use camera to scan document',
                      color: const Color(0xFF1E40AF),
                      onTap: () {
                        Navigator.pop(context);
                        _captureImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Gallery Option
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.photo_library,
                      label: 'From Gallery',
                      description: 'Choose existing photos',
                      color: const Color(0xFF059669),
                      onTap: () {
                        Navigator.pop(context);
                        _pickMultipleImages();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
    String? description,
    Color? color,
  }) {
    final buttonColor = color ?? const Color(0xFF1E40AF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: buttonColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: buttonColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: buttonColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: buttonColor),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: buttonColor,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📄 Scan to PDF 🔥',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdvancedScannerScreen(),
                ),
              );
            },
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Advanced Scanner',
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large icon with gradient background
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E40AF).withValues(alpha: 0.1),
                    const Color(0xFF059669).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(70),
                border: Border.all(
                  color: const Color(0xFF1E40AF).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.document_scanner,
                size: 64,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 32),

            // Main title
            const Text(
              'Ready to Scan!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Tap the blue button below to get started.\nYou can take photos or choose from gallery.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // Visual hint with arrow pointing down
            Column(
              children: [
                Icon(Icons.arrow_downward, size: 32, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Start here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF1E40AF)),
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
            elevation: 8,
            icon:
                _isProcessing
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Main scan button - larger and more prominent
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E40AF).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.large(
            heroTag: "add_image",
            onPressed: _isProcessing ? null : _showImageSourceDialog,
            backgroundColor:
                _isProcessing ? Colors.grey : const Color(0xFF1E40AF),
            elevation: 0,
            child:
                _isProcessing
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: 32,
                    ),
          ),
        ),
      ],
    );
  }

  Future<void> _savePdfWithOptions(
    Uint8List pdfBytes,
    String currentFilePath,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Save & Share Your PDF',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to save or share your document',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Save options
              Column(
                children: [
                  // Share via apps
                  _buildSaveOption(
                    icon: Icons.share,
                    title: 'Share Document',
                    description: 'Send via email, messaging, or other apps',
                    color: const Color(0xFF1E40AF),
                    onTap: () async {
                      Navigator.pop(context);
                      await Printing.sharePdf(
                        bytes: pdfBytes,
                        filename: 'scanned_document.pdf',
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Save to device
                  _buildSaveOption(
                    icon: Icons.download,
                    title: 'Save to Downloads',
                    description: 'Save PDF to your device downloads folder',
                    color: const Color(0xFF059669),
                    onTap: () async {
                      Navigator.pop(context);
                      await _saveToDownloads(pdfBytes);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Print option
                  _buildSaveOption(
                    icon: Icons.print,
                    title: 'Print Document',
                    description: 'Send to printer or save as PDF',
                    color: const Color(0xFF7C3AED),
                    onTap: () async {
                      Navigator.pop(context);
                      await Printing.layoutPdf(onLayout: (format) => pdfBytes);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToDownloads(Uint8List pdfBytes) async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Saving PDF to Downloads...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Use the scan service to save to downloads
      final result = await _scanService.savePdfToLocation(
        pdfBytes,
        fileName:
            'scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf',
        location: SaveLocation.downloads,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(child: Text('PDF saved to ${result.saveLocation}!')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save PDF: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
