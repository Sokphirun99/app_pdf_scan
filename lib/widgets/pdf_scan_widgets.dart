import 'package:flutter/material.dart';
import 'dart:io';
import '../models/scan_to_pdf_models.dart' as models;

/// PDF Scan Widgets
/// Contains reusable UI components for the scan-to-PDF functionality

class ImageSourceDialog extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onMultipleImages;
  final VoidCallback onAdvancedScanner;

  const ImageSourceDialog({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onMultipleImages,
    required this.onAdvancedScanner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Icon(Icons.add_a_photo, size: 48, color: theme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Add Images',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to add images to your PDF',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // Source options
            _buildSourceOption(
              context: context,
              icon: Icons.camera_alt,
              title: 'Camera',
              subtitle: 'Take a photo',
              onTap: onCamera,
              isDark: isDark,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              context: context,
              icon: Icons.photo_library,
              title: 'Gallery',
              subtitle: 'Choose from gallery',
              onTap: onGallery,
              isDark: isDark,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              context: context,
              icon: Icons.photo_library_outlined,
              title: 'Multiple Images',
              subtitle: 'Select multiple photos',
              onTap: onMultipleImages,
              isDark: isDark,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              context: context,
              icon: Icons.document_scanner,
              title: 'Advanced Scanner',
              subtitle: 'AI-powered document scanner',
              onTap: onAdvancedScanner,
              isDark: isDark,
              theme: theme,
            ),

            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: theme.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScannedImagesList extends StatelessWidget {
  final List<models.ScanToImageData> images;
  final Function(int) onRemove;
  final Function(int, int) onReorder;
  final VoidCallback? onTap;

  const ScannedImagesList({
    super.key,
    required this.images,
    required this.onRemove,
    required this.onReorder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: images.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final image = images[index];
        return _buildImageTile(context, image, index);
      },
    );
  }

  Widget _buildImageTile(
    BuildContext context,
    models.ScanToImageData image,
    int index,
  ) {
    return Card(
      key: ValueKey(image.path),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(image.path),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          image.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Scanned: ${_formatDateTime(image.scannedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_handle, color: Colors.grey[600]),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onRemove(index),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onAddImages;

  const EmptyStateWidget({super.key, required this.onAddImages});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No images selected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add images to create your PDF document',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAddImages,
            icon: const Icon(Icons.add),
            label: const Text('Add Images'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PdfSaveOptionsDialog extends StatefulWidget {
  final String initialFileName;
  final Function(models.PdfGenerationSettings, models.PdfSaveLocation) onSave;

  const PdfSaveOptionsDialog({
    super.key,
    required this.initialFileName,
    required this.onSave,
  });

  @override
  State<PdfSaveOptionsDialog> createState() => _PdfSaveOptionsDialogState();
}

class _PdfSaveOptionsDialogState extends State<PdfSaveOptionsDialog> {
  late TextEditingController _fileNameController;
  models.PdfPageSize _selectedPageSize = models.PdfPageSize.a4;
  models.PdfQuality _selectedQuality = models.PdfQuality.high;
  models.PdfSaveType _selectedSaveType = models.PdfSaveType.downloads;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.initialFileName);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Save PDF',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // File name
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'File Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Page size
            DropdownButtonFormField<models.PdfPageSize>(
              value: _selectedPageSize,
              decoration: const InputDecoration(
                labelText: 'Page Size',
                border: OutlineInputBorder(),
              ),
              items:
                  models.PdfPageSize.values.map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text(size.name.toUpperCase()),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPageSize = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Quality
            DropdownButtonFormField<models.PdfQuality>(
              value: _selectedQuality,
              decoration: const InputDecoration(
                labelText: 'Quality',
                border: OutlineInputBorder(),
              ),
              items:
                  models.PdfQuality.values.map((quality) {
                    return DropdownMenuItem(
                      value: quality,
                      child: Text(quality.name.toUpperCase()),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedQuality = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Save location
            DropdownButtonFormField<models.PdfSaveType>(
              value: _selectedSaveType,
              decoration: const InputDecoration(
                labelText: 'Save Location',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: models.PdfSaveType.downloads,
                  child: Text('Downloads'),
                ),
                const DropdownMenuItem(
                  value: models.PdfSaveType.documents,
                  child: Text('Documents'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSaveType = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _savePdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _savePdf() {
    final settings = models.PdfGenerationSettings(
      fileName: _fileNameController.text.trim(),
      pageSize: _selectedPageSize,
      quality: _selectedQuality,
    );

    final location = models.PdfSaveLocation(
      path: '',
      displayName: _selectedSaveType.name,
      type: _selectedSaveType,
    );

    Navigator.pop(context);
    widget.onSave(settings, location);
  }
}
