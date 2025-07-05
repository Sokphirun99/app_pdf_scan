import 'package:flutter/material.dart';

class PDFTool {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final bool isNew;
  final bool isPremium;

  const PDFTool({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    this.isNew = false,
    this.isPremium = false,
  });

  static List<PDFTool> getAllTools() {
    return [
      // PDFTool(
      //   id: 'merge',
      //   title: 'Merge PDF',
      //   description: 'Combine PDFs in the order you want',
      //   icon: Icons.merge_type,
      //   color: const Color(0xFF1E40AF), // Deep Blue
      //   category: 'Organize',
      // ),
      // PDFTool(
      //   id: 'split',
      //   title: 'Split PDF',
      //   description: 'Separate pages into independent PDF files',
      //   icon: Icons.call_split,
      //   color: const Color(0xFF059669), // Emerald
      //   category: 'Organize',
      // ),
      // PDFTool(
      //   id: 'compress',
      //   title: 'Compress PDF',
      //   description: 'Reduce file size while optimizing quality',
      //   icon: Icons.compress,
      //   color: const Color(0xFF0D9488), // Teal
      //   category: 'Optimize',
      // ),
      // PDFTool(
      //   id: 'pdf_to_word',
      //   title: 'PDF to Word',
      //   description: 'Convert PDF files into editable DOC documents',
      //   icon: Icons.description,
      //   color: const Color(0xFF7C3AED), // Purple
      //   category: 'Convert',
      // ),
      // PDFTool(
      //   id: 'word_to_pdf',
      //   title: 'Word to PDF',
      //   description: 'Make DOC and DOCX files easy to read',
      //   icon: Icons.picture_as_pdf,
      //   color: const Color(0xFFDC2626), // Red
      //   category: 'Convert',
      // ),
      PDFTool(
        id: 'pdf_to_jpg',
        title: 'PDF to JPG',
        description: 'Convert each PDF page into a JPG image',
        icon: Icons.image,
        color: const Color(0xFFDB2777), // Pink
        category: 'Convert',
      ),
      // PDFTool(
      //   id: 'jpg_to_pdf',
      //   title: 'JPG to PDF',
      //   description: 'Convert JPG images to PDF in seconds',
      //   icon: Icons.photo_library,
      //   color: const Color(0xFFEA580C), // Orange
      //   category: 'Convert',
      // ),
      // PDFTool(
      //   id: 'sign',
      //   title: 'Sign PDF',
      //   description: 'Sign documents or request signatures',
      //   icon: Icons.draw,
      //   color: const Color(0xFF6366F1), // Indigo
      //   category: 'Edit',
      // ),
      // PDFTool(
      //   id: 'watermark',
      //   title: 'Watermark',
      //   description: 'Stamp an image or text over your PDF',
      //   icon: Icons.branding_watermark,
      //   color: const Color(0xFF0891B2), // Sky Blue
      //   category: 'Edit',
      // ),
      // PDFTool(
      //   id: 'rotate',
      //   title: 'Rotate PDF',
      //   description: 'Rotate your PDFs the way you need them',
      //   icon: Icons.rotate_right,
      //   color: const Color(0xFF059669), // Emerald
      //   category: 'Edit',
      // ),
      // PDFTool(
      //   id: 'unlock',
      //   title: 'Unlock PDF',
      //   description: 'Remove PDF password security',
      //   icon: Icons.lock_open,
      //   color: const Color(0xFF16A34A), // Green
      //   category: 'Security',
      // ),
      // PDFTool(
      //   id: 'protect',
      //   title: 'Protect PDF',
      //   description: 'Protect PDF files with a password',
      //   icon: Icons.lock,
      //   color: const Color(0xFFDC2626), // Red
      //   category: 'Security',
      // ),
      // PDFTool(
      //   id: 'edit',
      //   title: 'Edit PDF',
      //   description: 'Add text, images, shapes or annotations',
      //   icon: Icons.edit,
      //   color: const Color(0xFF8B5CF6), // Violet
      //   category: 'Edit',
      //   isNew: true,
      // ),
      // PDFTool(
      //   id: 'organize',
      //   title: 'Organize PDF',
      //   description: 'Sort pages of your PDF file',
      //   icon: Icons.reorder,
      //   color: const Color(0xFF374151), // Gray
      //   category: 'Organize',
      // ),
      PDFTool(
        id: 'scan',
        title: 'Scan to PDF',
        description: 'Capture document scans from your device',
        icon: Icons.document_scanner,
        color: const Color(0xFF7C3AED), // Purple
        category: 'Create',
      ),
      // PDFTool(
      //   id: 'ocr',
      //   title: 'OCR PDF',
      //   description: 'Convert scanned PDF into searchable documents',
      //   icon: Icons.text_fields,
      //   color: const Color(0xFFF59E0B), // Amber
      //   category: 'Convert',
      //   isNew: true,
      // ),
    ];
  }

  static List<String> getCategories() {
    return [
      'All',
      'Convert',
      'Organize',
      'Edit',
      'Security',
      'Optimize',
      'Create',
    ];
  }

  static List<PDFTool> getToolsByCategory(String category) {
    final allTools = getAllTools();
    if (category == 'All') return allTools;
    return allTools.where((tool) => tool.category == category).toList();
  }
}
