import 'package:flutter/material.dart';
import '../../core/localization/localizations.dart';
import '../image_to_pdf/image_to_pdf_screen.dart';
import '../merger/merger_screen.dart';
import '../splitter/splitter_screen.dart';
import '../compressor/compressor_screen.dart';
import '../rotation/rotation_screen.dart';
import '../security/security_screen.dart';
import '../scanner/scanner_screen.dart';

class ToolsGridScreen extends StatelessWidget {
  const ToolsGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // List of tools with details
    final List<Map<String, dynamic>> tools = [
      {
        'title': local.translate('image_to_pdf'),
        'desc': 'Convert images to high quality PDF documents.',
        'icon': Icons.image,
        'color': theme.colorScheme.primary,
        'screen': const ImageToPdfScreen(),
      },
      {
        'title': local.translate('merge_pdf'),
        'desc': 'Combine multiple PDF files into one easily.',
        'icon': Icons.merge_type,
        'color': theme.colorScheme.secondary,
        'screen': const MergerScreen(),
      },
      {
        'title': local.translate('split_pdf'),
        'desc': 'Extract page ranges or split each page into a separate file.',
        'icon': Icons.call_split,
        'color': Colors.amber,
        'screen': const SplitterScreen(),
      },
      {
        'title': local.translate('compress_pdf'),
        'desc': 'Reduce PDF size with Low/Medium/High compression.',
        'icon': Icons.compress,
        'color': theme.colorScheme.error,
        'screen': const CompressorScreen(),
      },
      {
        'title': local.translate('rotate_pages'),
        'desc': 'Rotate specific pages or whole PDFs with a thumbnail grid.',
        'icon': Icons.rotate_right,
        'color': Colors.teal,
        'screen': const RotationScreen(),
      },
      {
        'title': local.translate('password_protect'),
        'desc': 'Add or remove passwords using secure AES encryption.',
        'icon': Icons.security,
        'color': Colors.purple,
        'screen': const SecurityScreen(),
      },
      {
        'title': local.translate('doc_scanner'),
        'desc': 'Scan documents using your camera with auto-edge detection.',
        'icon': Icons.document_scanner,
        'color': Colors.orange,
        'screen': const ScannerScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(local.translate('tools')),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tools.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, // Single column with modern wide lists is extremely readable
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3.5,
        ),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => tool['screen'] as Widget),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: (tool['color'] as Color).withOpacity(0.15),
                      child: Icon(tool['icon'] as IconData, color: tool['color'] as Color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tool['title'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tool['desc'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
