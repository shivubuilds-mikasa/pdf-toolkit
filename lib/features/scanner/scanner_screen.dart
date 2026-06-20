import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final List<File> _scannedPages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  // Primary ML Kit Scan
  Future<void> _startMlKitScan() async {
    setState(() => _isProcessing = true);
    try {
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
      );

      final documentScanner = DocumentScanner(options: options);
      final result = await documentScanner.scanDocument();
      documentScanner.close();

      if (result.images.isNotEmpty) {
        setState(() {
          _scannedPages.addAll(result.images.map((path) => File(path)));
        });
        _showSnackbar('Added ${result.images.length} scanned page(s).');
      }
    } catch (e) {
      // Graceful fallback to Standard Camera Capture
      _showSnackbar('ML Kit scanner not available on this device. Opening camera...', isError: true);
      await _startCameraFallback();
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Camera Capture Fallback
  Future<void> _startCameraFallback() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _scannedPages.add(File(image.path));
        });
        _showSnackbar('Captured page successfully!');
      }
    } catch (e) {
      _showSnackbar('Error capturing image: $e', isError: true);
    }
  }

  void _removePage(int index) {
    setState(() {
      _scannedPages.removeAt(index);
    });
  }

  // Save all pages as a unified PDF
  Future<void> _compileScanToPdf() async {
    if (_scannedPages.isEmpty) {
      _showSnackbar('Please scan or capture pages first', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final sf.PdfDocument document = sf.PdfDocument();

      for (var pageFile in _scannedPages) {
        final List<int> bytes = await pageFile.readAsBytes();
        final sf.PdfBitmap bitmap = sf.PdfBitmap(bytes);

        // Add page matching A4 standard dimensions
        final sf.PdfPage page = document.pages.add();
        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
        );
      }

      final List<int> pdfBytes = await document.save();
      document.dispose();

      // Save PDF in Toolkit folder
      final storage = ref.read(storageServiceProvider);
      final saveDir = await FileUtils.getSaveDirectory(customPath: storage.customStoragePath);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File pdfFile = File('${saveDir.path}/SCAN_$timestamp.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // Log statistics
      await storage.incrementCreated();
      await storage.logActivity('Scanned & created SCAN_$timestamp.pdf with ${_scannedPages.length} pages', 'created');

      _showSnackbar('Scanned document saved successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Error compiling scanned pages: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(local.translate('doc_scanner')),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing scan items...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Column(
              children: [
                // Visual layout representing pages
                Expanded(
                  child: _scannedPages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.document_scanner, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              const Text(
                                'No pages scanned yet.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'Tap "Scan Page" to launch the smart edge-detecting scanner.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12.0),
                          itemCount: _scannedPages.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) {
                            final file = _scannedPages[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Page Number Indicator
                                  Positioned(
                                    left: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Page ${index + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  // Delete Button
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black.withOpacity(0.6),
                                      radius: 16,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red, size: 14),
                                        onPressed: () => _removePage(index),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Scanner controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _startMlKitScan,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Scan Page'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _scannedPages.isEmpty ? null : _compileScanToPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Compile PDF'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
