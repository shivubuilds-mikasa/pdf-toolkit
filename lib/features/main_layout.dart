import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/localization/localizations.dart';
import 'dashboard/dashboard_screen.dart';
import 'tools/tools_grid_screen.dart';
import 'file_manager/file_manager_screen.dart';
import 'settings/settings_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final labels = [
      local.translate('dashboard'),
      local.translate('tools'),
      local.translate('saved_files'),
      local.translate('settings'),
    ];
    final icons = [
      (Icons.dashboard_outlined, Icons.dashboard_rounded),
      (Icons.grid_view_rounded, Icons.grid_view_rounded),
      (Icons.folder_open_outlined, Icons.folder_rounded),
      (Icons.settings_outlined, Icons.settings_rounded),
    ];

    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF111326),
                    Color(0xFF1C2140),
                    Color(0xFF101E2A)
                  ]
                : const [
                    Color(0xFFF5F0FF),
                    Color(0xFFE9F2FF),
                    Color(0xFFFFF3F8)
                  ],
          ),
        ),
        child: BackdropGroup(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              const DashboardScreen(),
              const ToolsGridScreen(),
              FileManagerScreen(isActive: _currentIndex == 2),
              const SettingsScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF292B42) : Colors.white)
                    .withOpacity(isDark ? 0.14 : 0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.24 : 0.52)),
              ),
              child: Row(
                children: List.generate(labels.length, (index) {
                  final selected = index == _currentIndex;
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: labels[index],
                      child: Tooltip(
                        message: labels[index],
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => setState(() => _currentIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: selected
                                  ? primary.withOpacity(isDark ? 0.15 : 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              border: selected
                                  ? Border.all(color: primary.withOpacity(0.16))
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  selected ? icons[index].$2 : icons[index].$1,
                                  size: 22,
                                  color: selected
                                      ? primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.68),
                                ),
                                if (selected) ...[
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      labels[index],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
