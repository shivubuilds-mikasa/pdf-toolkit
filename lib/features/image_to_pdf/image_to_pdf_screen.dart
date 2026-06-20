import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';

class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  
  String _pageSize = 'A4'; // A4, Letter, Legal, Original
  double _quality = 80.0; // 10% - 100%
  bool _isConverting = false;

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      _showSnackbar('Error picking images: $e', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) {
      _showSnackbar('Please select at least one image', isError: true);
      return;
    }

    setState(() => _isConverting = true);

    try {
      final sf.PdfDocument document = sf.PdfDocument();

      for (var imgFile in _selectedImages) {
        final List<int> imageBytes = await imgFile.readAsBytes();
        final sf.PdfBitmap bitmap = sf.PdfBitmap(imageBytes);

        Size targetSize;
        switch (_pageSize) {
          case 'Letter':
            targetSize = sf.PdfPageSize.letter;
            break;
          case 'Legal':
            targetSize = sf.PdfPageSize.legal;
            break;
          case 'Original':
            targetSize = Size(bitmap.width.toDouble(), bitmap.height.toDouble());
            break;
          case 'A4':
          default:
            targetSize = sf.PdfPageSize.a4;
        }

        // Set document page settings size
        document.pageSettings.size = targetSize;

        // Create page
        final sf.PdfPage page = document.pages.add();
        
        // Draw image stretched to cover page client area
        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
        );
      }

      // Save document
      final List<int> pdfBytes = await document.save();
      document.dispose();

      // Write to local storage
      final storage = ref.read(storageServiceProvider);
      final saveDir = await FileUtils.getSaveDirectory(customPath: storage.customStoragePath);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File pdfFile = File('${saveDir.path}/IMG_$timestamp.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // Log statistics & activity
      await storage.incrementCreated();
      await storage.logActivity('Created IMG_$timestamp.pdf from ${_selectedImages.length} images', 'created');

      _showSnackbar('PDF created successfully!');
      
      if (mounted) {
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      _showSnackbar('Error creating PDF: $e', isError: true);
    } finally {
      setState(() => _isConverting = false);
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
        title: Text(local.translate('image_to_pdf')),
      ),
      body: _isConverting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Compiling images into PDF document...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Column(
              children: [
                // Top control bar for settings
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(local.translate('page_size'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                value: _pageSize,
                                items: ['A4', 'Letter', 'Legal', 'Original']
                                    .map((size) => DropdownMenuItem(value: size, child: Text(size)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _pageSize = val);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(local.translate('quality'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Slider(
                                  value: _quality,
                                  min: 10,
                                  max: 100,
                                  divisions: 9,
                                  label: '${_quality.round()}%',
                                  onChanged: (val) {
                                    setState(() => _quality = val);
                                  },
                                ),
                              ),
                              Text('${_quality.round()}%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Selected Images list / placeholder
                Expanded(
                  child: _selectedImages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_search, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'Select images to compile',
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
                              final File item = _selectedImages.removeAt(oldIndex);
                              _selectedImages.insert(newIndex, item);
                            });
                          },
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            final file = _selectedImages[index];
                            return Card(
                              key: ValueKey(file.path),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: Image.file(
                                  file,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(file.path.split(Platform.pathSeparator).last),
                                subtitle: Text('Index: $index'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.drag_handle, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Bottom actions
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_a_photo),
                          label: Text(local.translate('select_files')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedImages.isEmpty ? null : _convertToPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Convert'),
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
