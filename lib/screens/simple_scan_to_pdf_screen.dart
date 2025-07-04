import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/pdf_scan_controller.dart';
import '../widgets/pdf_scan_widgets.dart';
import '../models/scan_to_pdf_models.dart' as models;
import 'advanced_scanner_screen.dart';

/// Simple Scan-to-PDF Screen
/// A clean, organized screen using our modular components
class SimpleScanToPdfScreen extends StatefulWidget {
  const SimpleScanToPdfScreen({super.key});

  @override
  State<SimpleScanToPdfScreen> createState() => _SimpleScanToPdfScreenState();
}

class _SimpleScanToPdfScreenState extends State<SimpleScanToPdfScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late PdfScanController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PdfScanController();
    _initializeController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _initializeController() async {
    await _controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _controller.handleAppLifecycleChange(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(),
        body: Consumer<PdfScanController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                // Error display
                if (controller.lastError != null)
                  _buildErrorBanner(controller.lastError!),

                // Main content
                Expanded(
                  child:
                      controller.hasImages
                          ? _buildImagesList(controller)
                          : EmptyStateWidget(
                            onAddImages: _showImageSourceDialog,
                          ),
                ),

                // Processing indicator
                if (controller.isProcessing) const LinearProgressIndicator(),
              ],
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButtons(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Scan to PDF',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF1E40AF),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Consumer<PdfScanController>(
          builder: (context, controller, child) {
            if (!controller.hasImages) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleMenuAction(value, controller),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'preview',
                      child: ListTile(
                        leading: Icon(Icons.preview),
                        title: Text('Preview PDF'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text('Share PDF'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: ListTile(
                        leading: Icon(Icons.clear_all, color: Colors.red),
                        title: Text(
                          'Clear All',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade100,
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _controller.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesList(PdfScanController controller) {
    return Column(
      children: [
        // Images count header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                '${controller.images.length} image(s) selected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showImageSourceDialog,
                child: const Text('Add More'),
              ),
            ],
          ),
        ),

        // Images list
        Expanded(
          child: ScannedImagesList(
            images: controller.images,
            onRemove: controller.removeImage,
            onReorder: controller.reorderImages,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButtons() {
    return Consumer<PdfScanController>(
      builder: (context, controller, child) {
        if (!controller.hasImages) {
          return FloatingActionButton(
            onPressed: _showImageSourceDialog,
            backgroundColor: const Color(0xFF1E40AF),
            child: const Icon(Icons.add, color: Colors.white),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Generate PDF button
            FloatingActionButton.extended(
              onPressed: controller.isProcessing ? null : _showSaveDialog,
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate PDF'),
            ),
            const SizedBox(height: 12),

            // Add more images button
            FloatingActionButton(
              onPressed: _showImageSourceDialog,
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => ImageSourceDialog(
            onCamera: () => _controller.captureFromCamera(),
            onGallery: () => _controller.pickFromGallery(),
            onMultipleImages: () => _controller.pickMultipleImages(),
            onAdvancedScanner: _openAdvancedScanner,
          ),
    );
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder:
          (context) => PdfSaveOptionsDialog(
            initialFileName:
                'scanned_document_${DateTime.now().millisecondsSinceEpoch}',
            onSave:
                (settings, location) =>
                    _controller.generatePdf(settings, location),
          ),
    );
  }

  void _openAdvancedScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdvancedScannerScreen()),
    );
  }

  void _handleMenuAction(String action, PdfScanController controller) {
    switch (action) {
      case 'preview':
        controller.previewPdf(
          const models.PdfGenerationSettings(fileName: 'preview_document'),
        );
        break;
      case 'share':
        controller.shareAsPdf(
          const models.PdfGenerationSettings(fileName: 'shared_document'),
        );
        break;
      case 'clear':
        _showClearConfirmationDialog(controller);
        break;
    }
  }

  void _showClearConfirmationDialog(PdfScanController controller) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Images'),
            content: const Text(
              'Are you sure you want to remove all images? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.clearAllImages();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }
}
