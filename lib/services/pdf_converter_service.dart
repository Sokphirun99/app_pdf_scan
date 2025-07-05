import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_image_renderer/pdf_image_renderer.dart';

class PdfConverterService {
  /// Converts a PDF file to JPG images
  /// Returns a list of file paths to the generated JPG images
  Future<List<String>> pdfToJpg(
    String pdfPath, {
    int quality = 90,
    void Function(double progress)? onProgress,
  }) async {
    final pdfFile = File(pdfPath);

    if (!pdfFile.existsSync()) {
      throw Exception('PDF file does not exist');
    }

    try {
      // Create the renderer instance with the PDF path
      final renderer = PdfImageRenderer(path: pdfPath);

      // Create output directory
      final outputDir = await _createOutputDirectory(pdfPath);
      final List<String> outputFilePaths = [];

      // Get the page count first
      final pageCount = await renderer.getPageCount();

      // Convert each page
      for (int i = 0; i < pageCount; i++) {
        // Update progress
        if (onProgress != null) {
          onProgress((i / pageCount) * 100);
        }

        // Render the page to an image
        final pageImage = await renderer.renderPage(
          pageIndex: i,
          scale: 2.0, // Scale for higher quality
        );

        if (pageImage != null) {
          // Save the image as JPG
          final outputPath = '${outputDir.path}/page_${i + 1}.jpg';
          final imageFile = File(outputPath);
          await imageFile.writeAsBytes(pageImage);

          outputFilePaths.add(outputPath);
        }
      }

      // Final progress update
      if (onProgress != null) {
        onProgress(100);
      }

      return outputFilePaths;
    } catch (e) {
      throw Exception('Failed to convert PDF to JPG: $e');
    }
  }

  /// Creates directory for output files
  Future<Directory> _createOutputDirectory(String pdfPath) async {
    final fileName = path.basenameWithoutExtension(pdfPath);
    final baseDir = await getApplicationDocumentsDirectory();
    final outputDirPath = '${baseDir.path}/pdf_to_jpg/$fileName';

    final outputDir = Directory(outputDirPath);
    if (!outputDir.existsSync()) {
      await outputDir.create(recursive: true);
    }

    return outputDir;
  }
}
