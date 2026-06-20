import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Select custom folder
  Future<void> _pickCustomFolder() async {
    try {
      final String? selectedPath = await FilePicker.platform.getDirectoryPath();
      if (selectedPath != null) {
        final storage = ref.read(storageServiceProvider);
        await storage.setCustomStoragePath(selectedPath);
        
        // Re-create folder structure if not exist
        final dir = Directory('$selectedPath/${FileUtils.defaultFolderName}');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        setState(() {});
        _showSnackbar('Storage location changed successfully!');
      }
    } catch (e) {
      _showSnackbar('Failed to pick directory: $e', isError: true);
    }
  }

  // Clear custom folder and return to default
  Future<void> _resetToDefaultFolder() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setCustomStoragePath('');
    setState(() {});
    _showSnackbar('Reset storage folder to default documents path.');
  }

  // Export JSON backup
  Future<void> _exportBackup() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final String payload = storage.exportBackup();
      
      final tempDir = await getTemporaryDirectory();
      final File backupFile = File('${tempDir.path}/pdftoolkit_backup.json');
      await backupFile.writeAsString(payload);
      
      await Share.shareXFiles([XFile(backupFile.path)], text: 'PDF Toolkit Settings Backup');
      _showSnackbar('Backup generated and shared successfully!');
    } catch (e) {
      _showSnackbar('Backup failed: $e', isError: true);
    }
  }

  // Import JSON backup
  Future<void> _importBackup() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        final storage = ref.read(storageServiceProvider);
        final success = await storage.importBackup(content);
        
        if (success) {
          _showSnackbar('Backup restored successfully!');
          
          // Re-sync UI state
          ref.read(themeModeProvider.notifier); // Trigger reload
          ref.read(localeProvider.notifier).setLocale(Locale(storage.language));
          
          setState(() {});
        } else {
          _showSnackbar('Failed to restore backup: Invalid payload.', isError: true);
        }
      }
    } catch (e) {
      _showSnackbar('Restoration failed: $e', isError: true);
    }
  }

  // Export activity history as CSV
  Future<void> _exportActivityHistory() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final List<Map<String, dynamic>> logs = storage.activities;
      
      if (logs.isEmpty) {
        _showSnackbar('No activity logs found to export.', isError: true);
        return;
      }

      final StringBuffer csv = StringBuffer();
      csv.writeln('Action Title,Action Type,Timestamp');
      
      for (var log in logs) {
        final title = (log['title'] as String).replaceAll(',', ';'); // simple escaping
        final type = log['type'] as String;
        final time = log['timestamp'] as String;
        csv.writeln('$title,$type,$time');
      }

      final tempDir = await getTemporaryDirectory();
      final File csvFile = File('${tempDir.path}/pdftoolkit_activity_logs.csv');
      await csvFile.writeAsString(csv.toString());
      
      await Share.shareXFiles([XFile(csvFile.path)], text: 'PDF Toolkit Activity History');
      _showSnackbar('Activity logs exported successfully!');
    } catch (e) {
      _showSnackbar('Failed to export history: $e', isError: true);
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
    final storage = ref.watch(storageServiceProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    // Get current save folder display
    String currentPathText = 'App Documents Directory (Default)';
    if (storage.customStoragePath.isNotEmpty) {
      currentPathText = storage.customStoragePath;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(local.translate('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Switch Card
          Card(
            child: SwitchListTile(
              title: Text(local.translate('dark_mode')),
              subtitle: const Text('Toggle dark theme aesthetics'),
              secondary: const Icon(Icons.palette),
              value: isDarkMode,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const SizedBox(height: 12),

          // Language Card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.language, color: Colors.grey),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('App Language', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Select active language', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: storage.language,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                      DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        await storage.setLanguage(val);
                        ref.read(localeProvider.notifier).setLocale(Locale(val));
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Custom Storage Path Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder, color: Colors.grey),
                      const SizedBox(width: 16),
                      Text(local.translate('storage_location'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentPathText,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickCustomFolder,
                          child: const Text('Change Location'),
                        ),
                      ),
                      if (storage.customStoragePath.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.red),
                          onPressed: _resetToDefaultFolder,
                          tooltip: 'Reset to Default',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Database & Actions Section
          const Text('Preference Operations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload),
                  title: const Text('Backup Preferences'),
                  subtitle: const Text('Export favorites, history and settings as JSON'),
                  onTap: _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download),
                  title: const Text('Restore Preferences'),
                  subtitle: const Text('Import backup preferences payload'),
                  onTap: _importBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_edu),
                  title: Text(local.translate('export_history')),
                  subtitle: const Text('Compile activities and share as a CSV log sheet'),
                  onTap: _exportActivityHistory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
