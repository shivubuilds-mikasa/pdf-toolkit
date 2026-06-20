import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';

class MergerScreen extends ConsumerStatefulWidget {
  const MergerScreen({super.key});

  @override
  ConsumerState<MergerScreen> createState() => _MergerScreenState();
}

class _MergerScreenState extends ConsumerState<MergerScreen> {
  final List<File> _selectedPdfs = [];
  bool _isMerging = false;

  Future<void> _pickPdfs() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          _selectedPdfs.addAll(result.paths.where((p) => p != null).map((p) => File(p!)));
        });
      }
    } catch (e) {
      _showSnackbar('Error picking PDF files: $e', isError: true);
    }
  }

  void _removePdf(int index) {
    setState(() {
      _selectedPdfs.removeAt(index);
    });
  }

  Future<void> _mergePdfs() async {
    if (_selectedPdfs.length < 2) {
      _showSnackbar('Please select at least 2 PDF files to merge', isError: true);
      return;
    }

    setState(() => _isMerging = true);

    try {
      // Create destination PDF document
      final sf.PdfDocument destinationDoc = sf.PdfDocument();

      for (var pdfFile in _selectedPdfs) {
        final List<int> bytes = await pdfFile.readAsBytes();
        final sf.PdfDocument sourceDoc = sf.PdfDocument(inputBytes: bytes);
        
        // Import all pages of the source document to the destination document
        for (int i = 0; i < sourceDoc.pages.count; i++) {
          final sf.PdfPage originalPage = sourceDoc.pages[i];
          final sf.PdfTemplate template = originalPage.createTemplate();
          
          destinationDoc.pageSettings.size = originalPage.size;
          destinationDoc.pageSettings.margins.all = 0;
          
          final sf.PdfPage page = destinationDoc.pages.add();
          page.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
        
        sourceDoc.dispose();
      }

      // Save the merged document
      final List<int> mergedBytes = await destinationDoc.save();
      destinationDoc.dispose();

      // Write merged file to storage
      final storage = ref.read(storageServiceProvider);
      final saveDir = await FileUtils.getSaveDirectory(customPath: storage.customStoragePath);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File mergedFile = File('${saveDir.path}/MERGE_$timestamp.pdf');
      await mergedFile.writeAsBytes(mergedBytes);

      // Increment stats and log activity
      await storage.incrementMerged();
      await storage.logActivity('Merged ${_selectedPdfs.length} PDFs into MERGE_$timestamp.pdf', 'merged');

      _showSnackbar('PDF files merged successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Error merging PDFs: $e', isError: true);
    } finally {
      setState(() => _isMerging = false);
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
        title: Text(local.translate('merge_pdf')),
      ),
      body: _isMerging
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Merging PDF files...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _selectedPdfs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.merge_type, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'Select PDFs to merge',
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final File item = _selectedPdfs.removeAt(oldIndex);
                              _selectedPdfs.insert(newIndex, item);
                            });
                          },
                          itemCount: _selectedPdfs.length,
                          itemBuilder: (context, index) {
                            final file = _selectedPdfs[index];
                            final sizeStr = FileUtils.formatBytes(file.lengthSync());
                            return Card(
                              key: ValueKey(file.path),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                                  child: Icon(Icons.picture_as_pdf, color: theme.colorScheme.secondary),
                                ),
                                title: Text(file.path.split(Platform.pathSeparator).last),
                                subtitle: Text(sizeStr),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.drag_handle, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removePdf(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickPdfs,
                          icon: const Icon(Icons.add),
                          label: Text(local.translate('select_files')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedPdfs.length < 2 ? null : _mergePdfs,
                          icon: const Icon(Icons.call_merge),
                          label: Text(local.translate('merge_files')),
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
