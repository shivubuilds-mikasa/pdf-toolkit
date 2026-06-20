import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';

class SplitterScreen extends ConsumerStatefulWidget {
  const SplitterScreen({super.key});

  @override
  ConsumerState<SplitterScreen> createState() => _SplitterScreenState();
}

class _SplitterScreenState extends ConsumerState<SplitterScreen> {
  File? _selectedPdf;
  int _totalPages = 0;
  bool _isSplitting = false;

  // Split configurations
  String _splitType = 'range'; // range, specific, every
  final _startPageController = TextEditingController(text: '1');
  final _endPageController = TextEditingController(text: '1');
  final _specificPagesController = TextEditingController();

  Future<void> _pickPdf() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final doc = sf.PdfDocument(inputBytes: bytes);
        
        setState(() {
          _selectedPdf = file;
          _totalPages = doc.pages.count;
          _endPageController.text = _totalPages.toString();
        });
        doc.dispose();
      }
    } catch (e) {
      _showSnackbar('Error loading PDF: $e', isError: true);
    }
  }

  Future<void> _splitPdf() async {
    if (_selectedPdf == null) {
      _showSnackbar('Please select a PDF file first', isError: true);
      return;
    }

    setState(() => _isSplitting = true);

    try {
      final bytes = await _selectedPdf!.readAsBytes();
      final sf.PdfDocument sourceDoc = sf.PdfDocument(inputBytes: bytes);
      final storage = ref.read(storageServiceProvider);
      final saveDir = await FileUtils.getSaveDirectory(customPath: storage.customStoragePath);
      final baseName = _selectedPdf!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');

      int countGenerated = 0;

      if (_splitType == 'range') {
        final int start = int.tryParse(_startPageController.text) ?? 1;
        final int end = int.tryParse(_endPageController.text) ?? _totalPages;

        if (start < 1 || end > _totalPages || start > end) {
          throw Exception('Invalid page range settings.');
        }

        final sf.PdfDocument targetDoc = sf.PdfDocument();
        for (int i = start - 1; i <= end - 1; i++) {
          final sf.PdfPage originalPage = sourceDoc.pages[i];
          final sf.PdfTemplate template = originalPage.createTemplate();
          
          targetDoc.pageSettings.size = originalPage.size;
          targetDoc.pageSettings.margins.all = 0;
          
          final sf.PdfPage page = targetDoc.pages.add();
          page.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
        final List<int> outBytes = await targetDoc.save();
        targetDoc.dispose();

        final File outFile = File('${saveDir.path}/${baseName}_split_${start}_to_$end.pdf');
        await outFile.writeAsBytes(outBytes);
        countGenerated = 1;
        
        await storage.logActivity('Split pages $start to $end from $baseName.pdf', 'created');
      } else if (_splitType == 'specific') {
        final List<int> pageIndices = [];
        final parts = _specificPagesController.text.split(',');
        for (var part in parts) {
          final pageNum = int.tryParse(part.trim());
          if (pageNum != null && pageNum >= 1 && pageNum <= _totalPages) {
            pageIndices.add(pageNum - 1); // 0-based index
          }
        }

        if (pageIndices.isEmpty) {
          throw Exception('Please specify valid page numbers.');
        }

        final sf.PdfDocument targetDoc = sf.PdfDocument();
        for (var idx in pageIndices) {
          final sf.PdfPage originalPage = sourceDoc.pages[idx];
          final sf.PdfTemplate template = originalPage.createTemplate();
          
          targetDoc.pageSettings.size = originalPage.size;
          targetDoc.pageSettings.margins.all = 0;
          
          final sf.PdfPage page = targetDoc.pages.add();
          page.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
        final List<int> outBytes = await targetDoc.save();
        targetDoc.dispose();

        final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
        final File outFile = File('${saveDir.path}/${baseName}_extracted_$stamp.pdf');
        await outFile.writeAsBytes(outBytes);
        countGenerated = 1;

        await storage.logActivity('Extracted ${pageIndices.length} pages from $baseName.pdf', 'created');
      } else if (_splitType == 'every') {
        for (int i = 0; i < _totalPages; i++) {
          final sf.PdfDocument targetDoc = sf.PdfDocument();
          final sf.PdfPage originalPage = sourceDoc.pages[i];
          final sf.PdfTemplate template = originalPage.createTemplate();
          
          targetDoc.pageSettings.size = originalPage.size;
          targetDoc.pageSettings.margins.all = 0;
          
          final sf.PdfPage page = targetDoc.pages.add();
          page.graphics.drawPdfTemplate(template, const Offset(0, 0));
          
          final List<int> outBytes = await targetDoc.save();
          targetDoc.dispose();

          final File outFile = File('${saveDir.path}/${baseName}_page_${i + 1}.pdf');
          await outFile.writeAsBytes(outBytes);
        }
        countGenerated = _totalPages;

        await storage.logActivity('Split every page of $baseName.pdf as individual files', 'created');
      }

      // Log statistics
      for (int k = 0; k < countGenerated; k++) {
        await storage.incrementCreated();
      }

      sourceDoc.dispose();
      _showSnackbar('Successfully split PDF into $countGenerated file(s)!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Error during split: $e', isError: true);
    } finally {
      setState(() => _isSplitting = false);
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
        title: Text(local.translate('split_pdf')),
      ),
      body: _isSplitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Splitting PDF file pages...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File selector card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (_selectedPdf == null) ...[
                            Icon(Icons.call_split, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text('No PDF file selected.', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickPdf,
                              icon: const Icon(Icons.file_open),
                              label: const Text('Choose PDF'),
                            ),
                          ] else ...[
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                child: Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
                              ),
                              title: Text(
                                _selectedPdf!.path.split(Platform.pathSeparator).last,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Total pages: $_totalPages'),
                              trailing: IconButton(
                                icon: const Icon(Icons.change_circle),
                                onPressed: _pickPdf,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_selectedPdf != null) ...[
                    // Split configuration options
                    Text(
                      local.translate('split_settings'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Radio list for split type
                    Card(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Split by Page Range'),
                            subtitle: const Text('E.g. extract pages 2 to 5'),
                            value: 'range',
                            groupValue: _splitType,
                            onChanged: (val) {
                              if (val != null) setState(() => _splitType = val);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Extract Specific Pages'),
                            subtitle: const Text('E.g. extract page 1, 3, and 7 (comma-separated)'),
                            value: 'specific',
                            groupValue: _splitType,
                            onChanged: (val) {
                              if (val != null) setState(() => _splitType = val);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Split Every Single Page'),
                            subtitle: const Text('Create a separate PDF for every single page'),
                            value: 'every',
                            groupValue: _splitType,
                            onChanged: (val) {
                              if (val != null) setState(() => _splitType = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Settings field based on selected type
                    if (_splitType == 'range') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _startPageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Start Page',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _endPageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'End Page',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_splitType == 'specific') ...[
                      TextField(
                        controller: _specificPagesController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Page Numbers (separated by commas)',
                          hintText: 'e.g. 1,3,5',
                        ),
                      ),
                    ] else if (_splitType == 'every') ...[
                      Card(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This will create $_totalPages single-page PDF documents in your "PDF Toolkit" folder.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _splitPdf,
                      icon: const Icon(Icons.call_split),
                      label: const Text('Perform Split Operation'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
