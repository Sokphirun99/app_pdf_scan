// Models for PDF export functionality
// This file contains all data structures used for PDF export operations

/// PDF Export Options
enum PdfExportOption { saveToDevice, shareFile, print, preview }

/// PDF Quality Settings
enum PdfQuality {
  high, // High resolution, larger file size
  medium, // Balanced quality and size
  low, // Lower resolution, smaller file size
  custom, // Custom settings
}

/// PDF Export Configuration
class PdfExportConfig {
  final PdfQuality quality;
  final bool includeOCR;
  final bool addWatermark;
  final String? watermarkText;

  const PdfExportConfig({
    required this.quality,
    this.includeOCR = false,
    this.addWatermark = false,
    this.watermarkText,
  });

  PdfExportConfig copyWith({
    PdfQuality? quality,
    bool? includeOCR,
    bool? addWatermark,
    String? watermarkText,
  }) {
    return PdfExportConfig(
      quality: quality ?? this.quality,
      includeOCR: includeOCR ?? this.includeOCR,
      addWatermark: addWatermark ?? this.addWatermark,
      watermarkText: watermarkText ?? this.watermarkText,
    );
  }
}

/// PDF Export Configuration with Export Option
class PdfExportConfigWithOption extends PdfExportConfig {
  final PdfExportOption exportOption;

  const PdfExportConfigWithOption({
    required super.quality,
    super.includeOCR = false,
    super.addWatermark = false,
    super.watermarkText,
    required this.exportOption,
  });
}

/// Export Result
class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;
  final String? extractedText;

  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
    this.extractedText,
  });

  factory ExportResult.success({String? filePath, String? extractedText}) {
    return ExportResult(
      success: true,
      filePath: filePath,
      extractedText: extractedText,
    );
  }

  factory ExportResult.error(String error) {
    return ExportResult(success: false, error: error);
  }
}

/// Quality Helper Functions
class QualityHelper {
  static String getDisplayName(PdfQuality quality) {
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

  static String getDescription(PdfQuality quality) {
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
}
