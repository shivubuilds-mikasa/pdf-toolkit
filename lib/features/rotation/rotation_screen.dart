import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';

class RotationScreen extends ConsumerStatefulWidget {
  const RotationScreen({super.key});

  @override
  ConsumerState<RotationScreen> createState() => _RotationScreenState();
}

class _RotationScreenState extends ConsumerState<RotationScreen> {
  File? _selectedPdf;
  int _totalPages = 0;
  bool _isProcessing = false;
  
  // Track page rotation angles: 0, 90, 180, 270 degrees
  final List<int> _pageAngles = [];
  final Set<int> _selectedPages = {}; // 0-based page indices

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
          _pageAngles.clear();
          _selectedPages.clear();
          
          for (int i = 0; i < _totalPages; i++) {
            // Read initial page rotation
            final rotation = doc.pages[i].rotation;
            int angle = 0;
            if (rotation == sf.PdfPageRotateAngle.rotateAngle90) angle = 90;
            if (rotation == sf.PdfPageRotateAngle.rotateAngle180) angle = 180;
            if (rotation == sf.PdfPageRotateAngle.rotateAngle270) angle = 270;
            _pageAngles.add(angle);
          }
        });
        doc.dispose();
      }
    } catch (e) {
      _showSnackbar('Error reading PDF: $e', isError: true);
    }
  }

  void _toggleSelectPage(int index) {
    setState(() {
      if (_selectedPages.contains(index)) {
        _selectedPages.remove(index);
      } else {
        _selectedPages.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedPages.length == _totalPages) {
        _selectedPages.clear();
      } else {
        _selectedPages.clear();
        _selectedPages.addAll(List.generate(_totalPages, (i) => i));
      }
    });
  }

  void _rotateSelected(int degree) {
    if (_selectedPages.isEmpty) {
      _showSnackbar('Please select pages to rotate first', isError: true);
      return;
    }
    setState(() {
      for (var pageIdx in _selectedPages) {
        _pageAngles[pageIdx] = (_pageAngles[pageIdx] + degree) % 360;
      }
    });
  }

  Future<void> _saveRotatedPdf() async {
    if (_selectedPdf == null) return;

    setState(() => _isProcessing = true);

    try {
      final bytes = await _selectedPdf!.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);

      for (int i = 0; i < _totalPages; i++) {
        final angle = _pageAngles[i];
        sf.PdfPageRotateAngle sfAngle;
        switch (angle) {
          case 90:
            sfAngle = sf.PdfPageRotateAngle.rotateAngle90;
            break;
          case 180:
            sfAngle = sf.PdfPageRotateAngle.rotateAngle180;
            break;
          case 270:
            sfAngle = sf.PdfPageRotateAngle.rotateAngle270;
            break;
          case 0:
          default:
            sfAngle = sf.PdfPageRotateAngle.rotateAngle0;
        }
        document.pages[i].rotation = sfAngle;
      }

      final List<int> outBytes = await document.save();
      document.dispose();

      // Write to storage
      final storage = ref.read(storageServiceProvider);
      final saveDir = await FileUtils.getSaveDirectory(customPath: storage.customStoragePath);
      final baseName = _selectedPdf!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      
      final File outFile = File('${saveDir.path}/${baseName}_rotated.pdf');
      await outFile.writeAsBytes(outBytes);

      // Log statistics
      await storage.incrementCreated();
      await storage.logActivity('Rotated selected pages of $baseName.pdf', 'created');

      _showSnackbar('Rotated PDF saved successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Error saving rotated PDF: $e', isError: true);
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
        title: Text(local.translate('rotate_pages')),
        actions: [
          if (_selectedPdf != null)
            TextButton(
              onPressed: _selectAll,
              child: Text(
                _selectedPages.length == _totalPages ? 'Deselect All' : 'Select All',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing page rotations...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Column(
              children: [
                // Top PDF selector card
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          if (_selectedPdf == null) ...[
                            Icon(Icons.rotate_right, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
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
                              subtitle: Text('Total pages: $_totalPages (${_selectedPages.length} selected)'),
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
                ),

                // Grid of pages
                Expanded(
                  child: _selectedPdf == null
                      ? Center(
                          child: Text(
                            'Please load a PDF to configure page rotations',
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12.0),
                          itemCount: _totalPages,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                          itemBuilder: (context, index) {
                            final isSelected = _selectedPages.contains(index);
                            final angle = _pageAngles[index];

                            return GestureDetector(
                              onTap: () => _toggleSelectPage(index),
                              child: Card(
                                color: isSelected
                                    ? theme.colorScheme.primary.withOpacity(0.15)
                                    : theme.colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface.withOpacity(0.1),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: AnimatedRotation(
                                                turns: angle / 360,
                                                duration: const Duration(milliseconds: 300),
                                                child: Icon(
                                                  Icons.article_outlined,
                                                  size: 48,
                                                  color: isSelected
                                                      ? theme.colorScheme.primary
                                                      : theme.colorScheme.onSurface.withOpacity(0.7),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Page ${index + 1}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          Text(
                                            '$angle°',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PositionBorder(
                                      alignment: Alignment.topRight,
                                      child: Checkbox(
                                        value: isSelected,
                                        shape: const CircleBorder(),
                                        onChanged: (val) => _toggleSelectPage(index),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Footer Actions
                if (_selectedPdf != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rotateSelected(90),
                                icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
                                label: const Text('+90°'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rotateSelected(180),
                                icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
                                label: const Text('+180°'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rotateSelected(270),
                                icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
                                label: const Text('+270°'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _saveRotatedPdf,
                          icon: const Icon(Icons.save),
                          label: Text(local.translate('save')),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// Simple alignment widget wrapper for placing elements in absolute layout
class PositionBorder extends StatelessWidget {
  final Alignment alignment;
  final Widget child;

  const PositionBorder({
    super.key,
    required this.alignment,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: child,
    );
  }
}
