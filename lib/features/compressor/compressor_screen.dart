import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';

class CompressorScreen extends ConsumerStatefulWidget {
  const CompressorScreen({super.key});

  @override
  ConsumerState<CompressorScreen> createState() => _CompressorScreenState();
}

class _CompressorScreenState extends ConsumerState<CompressorScreen> {
  File? _selectedPdf;
  int _originalSize = 0;
  int _compressedSize = 0;
  bool _isCompressing = false;
  bool _isFinished = false;

  String _compressionLevel = 'Medium'; // Low, Medium, High

  Future<void> _pickPdf() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPdf = File(result.files.single.path!);
          _originalSize = _selectedPdf!.lengthSync();
          _compressedSize = 0;
          _isFinished = false;
        });
      }
    } catch (e) {
      _showSnackbar('Error picking PDF: $e', isError: true);
    }
  }

  Future<void> _compressPdf() async {
    if (_selectedPdf == null) {
      _showSnackbar('Please select a PDF file first', isError: true);
      return;
    }

    setState(() {
      _isCompressing = true;
      _isFinished = false;
    });

    try {
      final bytes = await _selectedPdf!.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);

      // Apply compression settings
      sf.PdfCompressionLevel sfLevel;
      switch (_compressionLevel) {
        case 'High':
          sfLevel = sf.PdfCompressionLevel.best;
          break;
        case 'Low':
          sfLevel = sf.PdfCompressionLevel.belowNormal;
          break;
        case 'Medium':
        default:
          sfLevel = sf.PdfCompressionLevel.normal;
      }

      // Configure compression level
      document.compressionLevel = sfLevel;

      // Save document
      final List<int> compressedBytes = await document.save();
      document.dispose();

      // Write to storage
      final storage = ref.read(storageServiceProvider);
      final saveDir = await FileUtils.getSaveDirectory(customPath: storage.customStoragePath);
      final baseName = _selectedPdf!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      
      final File compressedFile = File('${saveDir.path}/${baseName}_compressed_${_compressionLevel.toLowerCase()}.pdf');
      await compressedFile.writeAsBytes(compressedBytes);

      setState(() {
        _compressedSize = compressedFile.lengthSync();
        _isFinished = true;
      });

      // Log statistics
      await storage.incrementCompressed();
      await storage.logActivity(
        'Compressed $baseName.pdf from ${FileUtils.formatBytes(_originalSize)} to ${FileUtils.formatBytes(_compressedSize)}',
        'compressed',
      );

      _showSnackbar('PDF compressed successfully!');
    } catch (e) {
      _showSnackbar('Compression error: $e', isError: true);
    } finally {
      setState(() => _isCompressing = false);
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

    // Calculate saving percentage
    double savingPercentage = 0.0;
    if (_originalSize > 0 && _compressedSize > 0) {
      savingPercentage = ((_originalSize - _compressedSize) / _originalSize) * 100;
      if (savingPercentage < 0) savingPercentage = 0.0; // Avoid negative savings
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(local.translate('compress_pdf')),
      ),
      body: _isCompressing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Compressing PDF file structure...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File Select Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (_selectedPdf == null) ...[
                            Icon(Icons.compress, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
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
                              subtitle: Text('Original Size: ${FileUtils.formatBytes(_originalSize)}'),
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
                    if (!_isFinished) ...[
                      // Select Level
                      Text(
                        local.translate('compress_level'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      Card(
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: Text(local.translate('low')),
                              subtitle: const Text('Minor size reduction, maximum image & text fidelity'),
                              value: 'Low',
                              groupValue: _compressionLevel,
                              onChanged: (val) {
                                if (val != null) setState(() => _compressionLevel = val);
                              },
                            ),
                            RadioListTile<String>(
                              title: Text(local.translate('medium')),
                              subtitle: const Text('Balanced size reduction and structural quality'),
                              value: 'Medium',
                              groupValue: _compressionLevel,
                              onChanged: (val) {
                                if (val != null) setState(() => _compressionLevel = val);
                              },
                            ),
                            RadioListTile<String>(
                              title: Text(local.translate('high')),
                              subtitle: const Text('Maximum size reduction, compressed images'),
                              value: 'High',
                              groupValue: _compressionLevel,
                              onChanged: (val) {
                                if (val != null) setState(() => _compressionLevel = val);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _compressPdf,
                        icon: const Icon(Icons.compress),
                        label: const Text('Compress PDF Now'),
                      ),
                    ] else ...[
                      // Finished Scorecard
                      Card(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 56, color: theme.colorScheme.secondary),
                              const SizedBox(height: 12),
                              const Text(
                                'Compression Finished!',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      const Text('Before', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        FileUtils.formatBytes(_originalSize),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                  Column(
                                    children: [
                                      const Text('After', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        FileUtils.formatBytes(_compressedSize),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 10),
                              Text(
                                'Saved ${savingPercentage.toStringAsFixed(1)}% of storage space!',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPdf = null;
                                  _isFinished = false;
                                });
                              },
                              child: const Text('Compress Another'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Back to Dashboard'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
