// PDF Generation Models
// Contains data models for PDF generation and image management

class ScanToImageData {
  final String path;
  final String name;
  final DateTime scannedAt;
  final double? rotation;
  final Map<String, dynamic>? metadata;

  const ScanToImageData({
    required this.path,
    required this.name,
    required this.scannedAt,
    this.rotation,
    this.metadata,
  });

  ScanToImageData copyWith({
    String? path,
    String? name,
    DateTime? scannedAt,
    double? rotation,
    Map<String, dynamic>? metadata,
  }) {
    return ScanToImageData(
      path: path ?? this.path,
      name: name ?? this.name,
      scannedAt: scannedAt ?? this.scannedAt,
      rotation: rotation ?? this.rotation,
      metadata: metadata ?? this.metadata,
    );
  }
}

class PdfGenerationSettings {
  final String fileName;
  final PdfPageSize pageSize;
  final PdfQuality quality;
  final bool includeMetadata;
  final bool compressImages;
  final String? watermark;
  final PdfOrientation orientation;

  const PdfGenerationSettings({
    required this.fileName,
    this.pageSize = PdfPageSize.a4,
    this.quality = PdfQuality.high,
    this.includeMetadata = true,
    this.compressImages = true,
    this.watermark,
    this.orientation = PdfOrientation.auto,
  });

  PdfGenerationSettings copyWith({
    String? fileName,
    PdfPageSize? pageSize,
    PdfQuality? quality,
    bool? includeMetadata,
    bool? compressImages,
    String? watermark,
    PdfOrientation? orientation,
  }) {
    return PdfGenerationSettings(
      fileName: fileName ?? this.fileName,
      pageSize: pageSize ?? this.pageSize,
      quality: quality ?? this.quality,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      compressImages: compressImages ?? this.compressImages,
      watermark: watermark ?? this.watermark,
      orientation: orientation ?? this.orientation,
    );
  }
}

enum PdfPageSize { a4, a5, letter, legal, custom }

enum PdfQuality { low, medium, high, lossless }

enum PdfOrientation { auto, portrait, landscape }

class PdfSaveLocation {
  final String path;
  final String displayName;
  final PdfSaveType type;
  final Map<String, dynamic>? options;

  const PdfSaveLocation({
    required this.path,
    required this.displayName,
    required this.type,
    this.options,
  });
}

enum PdfSaveType { downloads, documents, customPath, share, cloudStorage }

class ScanToPdfState {
  final List<ScanToImageData> images;
  final bool isProcessing;
  final bool cameraInUse;
  final PdfGenerationSettings settings;
  final String? lastError;
  final String? lastGeneratedPdfPath;

  const ScanToPdfState({
    this.images = const [],
    this.isProcessing = false,
    this.cameraInUse = false,
    this.settings = const PdfGenerationSettings(fileName: 'scanned_document'),
    this.lastError,
    this.lastGeneratedPdfPath,
  });

  ScanToPdfState copyWith({
    List<ScanToImageData>? images,
    bool? isProcessing,
    bool? cameraInUse,
    PdfGenerationSettings? settings,
    String? lastError,
    String? lastGeneratedPdfPath,
  }) {
    return ScanToPdfState(
      images: images ?? this.images,
      isProcessing: isProcessing ?? this.isProcessing,
      cameraInUse: cameraInUse ?? this.cameraInUse,
      settings: settings ?? this.settings,
      lastError: lastError ?? this.lastError,
      lastGeneratedPdfPath: lastGeneratedPdfPath ?? this.lastGeneratedPdfPath,
    );
  }
}
