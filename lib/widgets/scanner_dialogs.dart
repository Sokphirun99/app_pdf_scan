import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pdf_export_models.dart';

/// Export Options Dialog
/// Reusable dialog for PDF export options
class ExportOptionsDialog extends StatelessWidget {
  const ExportOptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Icon(Icons.picture_as_pdf, size: 48, color: theme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Export PDF',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to export your scanned document',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // Export options
            ..._buildExportOptions(context, isDark, theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExportOptions(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    final options = [
      {
        'option': PdfExportOption.saveToDevice,
        'icon': Icons.save_alt,
        'title': 'Save to Device',
        'subtitle': 'Save PDF to device storage',
      },
      {
        'option': PdfExportOption.shareFile,
        'icon': Icons.share,
        'title': 'Share File',
        'subtitle': 'Share with other apps',
      },
      {
        'option': PdfExportOption.print,
        'icon': Icons.print,
        'title': 'Print',
        'subtitle': 'Print document directly',
      },
      {
        'option': PdfExportOption.preview,
        'icon': Icons.preview,
        'title': 'Preview',
        'subtitle': 'Open PDF preview',
      },
    ];

    return options.map((option) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(option['option']),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    option['icon'] as IconData,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['subtitle'] as String,
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
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Success Dialog
/// Reusable success dialog for various operations
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool showViewButton;
  final String? filePath;
  final String? ocrText;
  final VoidCallback? onViewFile;
  final VoidCallback? onViewOCR;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.showViewButton = false,
    this.filePath,
    this.ocrText,
    this.onViewFile,
    this.onViewOCR,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ),
                if (showViewButton && onViewFile != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewFile!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('View File'),
                    ),
                  ),
                ],
                if (ocrText != null &&
                    ocrText!.isNotEmpty &&
                    onViewOCR != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewOCR!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('View OCR'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// OCR Results Dialog
/// Dialog to display OCR text results
class OCRResultsDialog extends StatelessWidget {
  final String ocrText;

  const OCRResultsDialog({super.key, required this.ocrText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.text_fields, size: 32, color: theme.primaryColor),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.copy, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Text copied to clipboard!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                      ),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
