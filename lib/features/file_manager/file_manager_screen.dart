import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';
import 'pdf_viewer_screen.dart';

class FileManagerScreen extends ConsumerStatefulWidget {
  const FileManagerScreen({super.key});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen> {
  List<File> _allFiles = [];
  List<File> _filteredFiles = [];
  bool _isLoading = true;

  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  String _sortBy = 'Date'; // Name, Date, Size
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _refreshFileList();
  }

  // Load and apply settings
  Future<void> _refreshFileList() async {
    setState(() => _isLoading = true);
    final storage = ref.read(storageServiceProvider);
    final files = await FileUtils.listSavedPdfs(customPath: storage.customStoragePath);
    
    if (mounted) {
      setState(() {
        _allFiles = files;
        _isLoading = false;
        _applyFiltersAndSort();
      });
    }
  }

  void _applyFiltersAndSort() {
    final storage = ref.read(storageServiceProvider);
    List<File> temp = List.from(_allFiles);

    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      temp = temp.where((f) {
        final name = f.path.split(Platform.pathSeparator).last.toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // 2. Favorites only
    if (_showFavoritesOnly) {
      temp = temp.where((f) => storage.isFavorite(f.path)).toList();
    }

    // 3. Sorting
    temp.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'Name':
          final aName = a.path.split(Platform.pathSeparator).last;
          final bName = b.path.split(Platform.pathSeparator).last;
          cmp = aName.compareTo(bName);
          break;
        case 'Size':
          cmp = a.lengthSync().compareTo(b.lengthSync());
          break;
        case 'Date':
        default:
          cmp = a.lastModifiedSync().compareTo(b.lastModifiedSync());
          break;
      }
      return _sortAscending ? cmp : -cmp; // Reverse for descending
    });

    setState(() {
      _filteredFiles = temp;
    });
  }

  // Show Rename dialog
  void _showRenameDialog(File file) {
    final controller = TextEditingController(
      text: file.path.split(Platform.pathSeparator).last.replaceAll('.pdf', ''),
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename PDF File'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'File Name',
              suffixText: '.pdf',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  final renamed = await FileUtils.renameFile(file, newName);
                  if (renamed != null) {
                    _showSnackbar('File renamed successfully!');
                    _refreshFileList();
                  } else {
                    _showSnackbar('Rename failed.', isError: true);
                  }
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  // Confirm delete dialog
  void _showDeleteDialog(File file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete File?'),
          content: Text('Are you sure you want to permanently delete "${file.path.split(Platform.pathSeparator).last}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await FileUtils.deleteFile(file);
                if (success) {
                  _showSnackbar('File deleted.');
                  _refreshFileList();
                } else {
                  _showSnackbar('Delete failed.', isError: true);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // File Options bottom sheet
  void _showFileOptions(File file) {
    final local = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final storage = ref.read(storageServiceProvider);
    final isFav = storage.isFavorite(file.path);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
                ),
                title: Text(file.path.split(Platform.pathSeparator).last, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(FileUtils.formatBytes(file.lengthSync())),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chrome_reader_mode),
                title: const Text('Open in App'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfFile: file)));
                },
              ),
              ListTile(
                leading: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                title: Text(isFav ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () async {
                  await storage.toggleFavorite(file.path);
                  setState(() {});
                  _applyFiltersAndSort();
                  if (mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(local.translate('rename')),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(local.translate('share')),
                onTap: () {
                  Navigator.pop(context);
                  FileUtils.shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(local.translate('delete'), style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(file);
                },
              ),
            ],
          ),
        );
      },
    );
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
    final storage = ref.watch(storageServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(local.translate('saved_files')),
        actions: [
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.favorite : Icons.favorite_border, color: _showFavoritesOnly ? Colors.red : null),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
                _applyFiltersAndSort();
              });
            },
            tooltip: 'Filter Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Open sort selector dialog
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(local.translate('sort_by')),
                    content: StatefulBuilder(
                      builder: (context, setDialogState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: _sortBy,
                              isExpanded: true,
                              items: ['Name', 'Date', 'Size']
                                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => _sortBy = val);
                                  setState(() => _sortBy = val);
                                }
                              },
                            ),
                            CheckboxListTile(
                              title: const Text('Sort Ascending'),
                              value: _sortAscending,
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => _sortAscending = val);
                                  setState(() => _sortAscending = val);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          _applyFiltersAndSort();
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: local.translate('search_files'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _applyFiltersAndSort();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFiltersAndSort();
                });
              },
            ),
          ),

          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              _showFavoritesOnly
                                  ? local.translate('empty_favorites')
                                  : local.translate('empty_files'),
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshFileList,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredFiles.length,
                          itemBuilder: (context, index) {
                            final file = _filteredFiles[index];
                            final stats = file.statSync();
                            final dateStr = DateFormat('yMMMd').format(stats.modified);
                            final sizeStr = FileUtils.formatBytes(file.lengthSync());
                            final isFav = storage.isFavorite(file.path);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                                  child: Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
                                ),
                                title: Text(
                                  file.path.split(Platform.pathSeparator).last,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text('$dateStr | $sizeStr'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isFav) const Icon(Icons.favorite, color: Colors.red, size: 16),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () => _showFileOptions(file),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfFile: file)),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
