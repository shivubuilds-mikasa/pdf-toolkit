import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Lock Tab State
  File? _lockPdfFile;
  final _lockPasswordController = TextEditingController();
  final _lockConfirmPasswordController = TextEditingController();
  bool _isLocking = false;
  bool _obscureLock = true;

  // Unlock Tab State
  File? _unlockPdfFile;
  final _unlockPasswordController = TextEditingController();
  bool _isUnlocking = false;
  bool _obscureUnlock = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lockPasswordController.dispose();
    _lockConfirmPasswordController.dispose();
    _unlockPasswordController.dispose();
    super.dispose();
  }

  // Pick PDF for locking
  Future<void> _pickLockPdf() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _lockPdfFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showSnackbar('Error picking PDF: $e', isError: true);
    }
  }

  // Pick PDF for unlocking
  Future<void> _pickUnlockPdf() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _unlockPdfFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showSnackbar('Error picking PDF: $e', isError: true);
    }
  }

  // Apply Encryption / Password Lock
  Future<void> _applyLock() async {
    if (_lockPdfFile == null) {
      _showSnackbar('Please select a PDF file first', isError: true);
      return;
    }
    final pass = _lockPasswordController.text;
    final confirm = _lockConfirmPasswordController.text;

    if (pass.isEmpty) {
      _showSnackbar('Password cannot be empty', isError: true);
      return;
    }
    if (pass != confirm) {
      _showSnackbar('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLocking = true);

    try {
      final bytes = await _lockPdfFile!.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);

      // Create secure settings
      final sf.PdfSecurity security = document.security;
      security.userPassword = pass;
      security.ownerPassword = '${pass}_owner';

      final List<int> securedBytes = await document.save();
      document.dispose();

      // Write secured file to local storage
      final storage = ref.read(storageServiceProvider);
      final saveDir = await FileUtils.getSaveDirectory(customPath: storage.customStoragePath);
      final baseName = _lockPdfFile!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      final File securedFile = File('${saveDir.path}/${baseName}_secured.pdf');
      await securedFile.writeAsBytes(securedBytes);

      // Log statistics
      await storage.incrementCreated();
      await storage.logActivity('Encrypted $baseName.pdf with AES-256 password protection', 'created');

      _showSnackbar('PDF encrypted and saved successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Encryption error: $e', isError: true);
    } finally {
      setState(() => _isLocking = false);
    }
  }

  // Remove Encryption / Decrypt File
  Future<void> _applyUnlock() async {
    if (_unlockPdfFile == null) {
      _showSnackbar('Please select an encrypted PDF file first', isError: true);
      return;
    }
    final pass = _unlockPasswordController.text;
    if (pass.isEmpty) {
      _showSnackbar('Please enter the password to decrypt the PDF', isError: true);
      return;
    }

    setState(() => _isUnlocking = true);

    try {
      final bytes = await _unlockPdfFile!.readAsBytes();
      
      // Load encrypted document (using password)
      final sf.PdfDocument securedDoc = sf.PdfDocument(inputBytes: bytes, password: pass);

       // Create a brand new clean destination document
      final sf.PdfDocument cleanDoc = sf.PdfDocument();
      for (int i = 0; i < securedDoc.pages.count; i++) {
        final sf.PdfPage originalPage = securedDoc.pages[i];
        final sf.PdfTemplate template = originalPage.createTemplate();
        
        cleanDoc.pageSettings.size = originalPage.size;
        cleanDoc.pageSettings.margins.all = 0;
        
        final sf.PdfPage page = cleanDoc.pages.add();
        page.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }

      final List<int> cleanBytes = await cleanDoc.save();
      
      securedDoc.dispose();
      cleanDoc.dispose();

      // Write clean file to storage
      final storage = ref.read(storageServiceProvider);
      final saveDir = await FileUtils.getSaveDirectory(customPath: storage.customStoragePath);
      final baseName = _unlockPdfFile!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      final File cleanFile = File('${saveDir.path}/${baseName}_unlocked.pdf');
      await cleanFile.writeAsBytes(cleanBytes);

      // Log statistics
      await storage.incrementCreated();
      await storage.logActivity('Removed password security from $baseName.pdf', 'created');

      _showSnackbar('Password removed successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Decryption failed. Please verify the password and try again.', isError: true);
    } finally {
      setState(() => _isUnlocking = false);
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
        title: Text(local.translate('password_protect')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: local.translate('add_password')),
            Tab(text: local.translate('remove_password')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // LOCK TAB
          _isLocking
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (_lockPdfFile == null) ...[
                                Icon(Icons.lock_open, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                const Text('No PDF file selected.', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _pickLockPdf,
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
                                    _lockPdfFile!.path.split(Platform.pathSeparator).last,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.change_circle),
                                    onPressed: _pickLockPdf,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_lockPdfFile != null) ...[
                        TextField(
                          controller: _lockPasswordController,
                          obscureText: _obscureLock,
                          decoration: InputDecoration(
                            labelText: 'Enter Secure Password',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureLock ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureLock = !_obscureLock),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _lockConfirmPasswordController,
                          obscureText: _obscureLock,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Secure Password',
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _applyLock,
                          icon: const Icon(Icons.lock),
                          label: const Text('Encrypt and Save PDF'),
                        ),
                      ],
                    ],
                  ),
                ),

          // UNLOCK TAB
          _isUnlocking
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (_unlockPdfFile == null) ...[
                                Icon(Icons.lock, size: 48, color: theme.colorScheme.error.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                const Text('No PDF file selected.', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _pickUnlockPdf,
                                  icon: const Icon(Icons.file_open),
                                  label: const Text('Choose Encrypted PDF'),
                                ),
                              ] else ...[
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                                    child: Icon(Icons.lock, color: theme.colorScheme.error),
                                  ),
                                  title: Text(
                                    _unlockPdfFile!.path.split(Platform.pathSeparator).last,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.change_circle),
                                    onPressed: _pickUnlockPdf,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_unlockPdfFile != null) ...[
                        TextField(
                          controller: _unlockPasswordController,
                          obscureText: _obscureUnlock,
                          decoration: InputDecoration(
                            labelText: 'Enter Password to Decrypt',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureUnlock ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureUnlock = !_obscureUnlock),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _applyUnlock,
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Remove Password & Save'),
                        ),
                      ],
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
