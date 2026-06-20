import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/localization/localizations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/file_utils.dart';
import '../image_to_pdf/image_to_pdf_screen.dart';
import '../merger/merger_screen.dart';
import '../compressor/compressor_screen.dart';
import '../scanner/scanner_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _storageUsed = 0;
  bool _isLoadingStorage = true;

  @override
  void initState() {
    super.initState();
    _loadStorageSize();
  }

  Future<void> _loadStorageSize() async {
    setState(() => _isLoadingStorage = true);
    final storage = ref.read(storageServiceProvider);
    final size = await FileUtils.getStorageUsed(customPath: storage.customStoragePath);
    if (mounted) {
      setState(() {
        _storageUsed = size;
        _isLoadingStorage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final storage = ref.watch(storageServiceProvider);
    final activities = storage.activities;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.translate('dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStorageSize,
            tooltip: 'Refresh Storage Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStorageSize,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Storage Gauge Card
              Card(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.15),
                        theme.colorScheme.secondary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: 0.65, // Demonstrative target percent
                              strokeWidth: 8,
                              color: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                            ),
                          ),
                          const Icon(Icons.storage, size: 30),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              local.translate('storage_used'),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            _isLoadingStorage
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    FileUtils.formatBytes(_storageUsed),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            const SizedBox(height: 4),
                            Text(
                              'In PDF Toolkit Folder',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Statistics Grid
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  _buildStatCard(
                    context,
                    local.translate('total_created'),
                    storage.totalCreated.toString(),
                    Icons.add_box,
                    theme.colorScheme.primary,
                  ),
                  _buildStatCard(
                    context,
                    local.translate('total_merged'),
                    storage.totalMerged.toString(),
                    Icons.call_merge,
                    theme.colorScheme.secondary,
                  ),
                  _buildStatCard(
                    context,
                    local.translate('total_compressed'),
                    storage.totalCompressed.toString(),
                    Icons.compress,
                    theme.colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions Grid
              Text(
                local.translate('quick_actions'),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildQuickActionCard(
                    context,
                    local.translate('image_to_pdf'),
                    Icons.image,
                    theme.colorScheme.primary,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageToPdfScreen())),
                  ),
                  _buildQuickActionCard(
                    context,
                    local.translate('merge_pdf'),
                    Icons.merge_type,
                    theme.colorScheme.secondary,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MergerScreen())),
                  ),
                  _buildQuickActionCard(
                    context,
                    local.translate('compress_pdf'),
                    Icons.compress,
                    theme.colorScheme.error,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompressorScreen())),
                  ),
                  _buildQuickActionCard(
                    context,
                    local.translate('doc_scanner'),
                    Icons.document_scanner,
                    Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    local.translate('recent_activity'),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (activities.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.history_toggle_off),
                      onPressed: () {},
                    ),
                ],
              ),
              const SizedBox(height: 10),
              activities.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 40, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            const SizedBox(height: 8),
                            Text(
                              local.translate('no_recent_activity'),
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length > 5 ? 5 : activities.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final act = activities[index];
                        final dt = DateTime.parse(act['timestamp'] as String);
                        final dateStr = DateFormat('yMMMd').add_jm().format(dt);
                        IconData icon;
                        Color iconColor;

                        switch (act['type']) {
                          case 'created':
                            icon = Icons.picture_as_pdf;
                            iconColor = theme.colorScheme.primary;
                            break;
                          case 'merged':
                            icon = Icons.call_merge;
                            iconColor = theme.colorScheme.secondary;
                            break;
                          case 'compressed':
                            icon = Icons.compress;
                            iconColor = theme.colorScheme.error;
                            break;
                          default:
                            icon = Icons.edit_document;
                            iconColor = Colors.orange;
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: iconColor.withOpacity(0.1),
                            child: Icon(icon, color: iconColor),
                          ),
                          title: Text(
                            act['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(dateStr),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String val, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              val,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
