import 'package:flutter/material.dart';
import '../models/pdf_tool.dart';
import 'scan_to_pdf_screen.dart';

class ToolDetailScreen extends StatelessWidget {
  final PDFTool tool;

  const ToolDetailScreen({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(tool.title),
        backgroundColor: tool.color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tool.color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(tool.icon, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  tool.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tool.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // File picker area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tool.title == 'Scan to PDF' 
                              ? Icons.document_scanner 
                              : Icons.cloud_upload_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tool.title == 'Scan to PDF' 
                              ? 'Scan documents with camera' 
                              : 'Select PDF files',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tool.title == 'Scan to PDF' 
                              ? 'Capture multiple pages' 
                              : 'or drop them here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _selectFiles(context);
                            },
                            icon: Icon(tool.title == 'Scan to PDF' 
                              ? Icons.camera_alt 
                              : Icons.folder_open),
                            label: Text(tool.title == 'Scan to PDF' 
                              ? 'Start Scanning' 
                              : 'Select Files'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tool.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Features section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Features',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(Icons.security, 'Secure processing'),
                        _buildFeatureItem(Icons.speed, 'Fast conversion'),
                        _buildFeatureItem(
                          Icons.high_quality,
                          'High quality output',
                        ),
                        _buildFeatureItem(
                          Icons.free_cancellation,
                          'Completely free',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tool.color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _selectFiles(BuildContext context) {
    // Special handling for Scan to PDF
    if (tool.title == 'Scan to PDF') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ScanToPdfScreen(),
        ),
      );
      return;
    }

    // Here you would implement file picker functionality for other tools
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File picker for ${tool.title} would open here'),
        backgroundColor: tool.color,
      ),
    );
  }
}
