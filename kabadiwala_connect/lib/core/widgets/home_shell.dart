import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../providers/app_state.dart';
import 'offline_banner.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider);
    final lang = user.language;
    final location = GoRouterState.of(context).matchedLocation;
    final title = _titleForRoute(location, lang);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: AppHairlineBar(),
        ),
        actions: [
          const NetworkStatusPill(),
          TextButton(
            onPressed: () => _showLanguageModal(context, ref, lang),
            child: Text(
              lang.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          IconButton(
            tooltip: switch (lang) {
              'mr' => 'भूमिका बदला',
              'en' => 'Switch Role',
              _ => 'भूमिका बदलें',
            },
            icon: const Icon(Icons.swap_horiz, size: 20, color: AppColors.muted),
            onPressed: () => context.go(AppRoutes.role),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineSyncBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: AppColors.line),
          NavigationBar(
        selectedIndex: _indexForRoute(location),
        onDestinationSelected: (i) => _navTo(context, i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.center_focus_weak_outlined),
            selectedIcon: const Icon(Icons.center_focus_weak),
            label: switch (lang) {
              'mr' => 'स्कॅन',
              'en' => 'Scan',
              _ => 'स्कैन',
            },
          ),
          NavigationDestination(
            icon: const Icon(Icons.sell_outlined),
            selectedIcon: const Icon(Icons.sell),
            label: switch (lang) {
              'mr' => 'भाव',
              'en' => 'Rates',
              _ => 'भाव',
            },
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: switch (lang) {
              'mr' => 'कमाई',
              'en' => 'Cash',
              _ => 'कमाई',
            },
          ),
          NavigationDestination(
            icon: const Icon(Icons.shield_outlined),
            selectedIcon: const Icon(Icons.shield),
            label: switch (lang) {
              'mr' => 'सुरक्षा',
              'en' => 'Safety',
              _ => 'सुरक्षा',
            },
          ),
        ],
      ),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context, WidgetRef ref, String currentLang) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        switch (currentLang) {
                          'mr' => 'भाषा',
                          'en' => 'Language',
                          _ => 'भाषा',
                        },
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildLangTile(ctx: ctx, ref: ref, code: 'en', name: 'English', isSelected: currentLang == 'en'),
                const SizedBox(height: 8),
                _buildLangTile(ctx: ctx, ref: ref, code: 'hi', name: 'हिन्दी', isSelected: currentLang == 'hi'),
                const SizedBox(height: 8),
                _buildLangTile(ctx: ctx, ref: ref, code: 'mr', name: 'मराठी', isSelected: currentLang == 'mr'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangTile({
    required BuildContext ctx,
    required WidgetRef ref,
    required String code,
    required String name,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(appStateProvider.notifier).setLanguage(code);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.accentMuted : AppColors.ink,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check, color: AppColors.accent, size: 18),
          ],
        ),
      ),
    );
  }

  String _titleForRoute(String location, String lang) {
    if (location.startsWith(AppRoutes.priceBoard)) {
      return switch (lang) {
        'mr' => 'भाव',
        'en' => 'Rates',
        _ => 'भाव',
      };
    }
    if (location.startsWith(AppRoutes.earnings)) {
      return switch (lang) {
        'mr' => 'कमाई',
        'en' => 'Earnings',
        _ => 'कमाई',
      };
    }
    if (location.startsWith(AppRoutes.safety)) {
      return switch (lang) {
        'mr' => 'सुरक्षा',
        'en' => 'Safety',
        _ => 'सुरक्षा',
      };
    }
    return switch (lang) {
      'mr' => 'स्कॅन',
      'en' => 'Scan',
      _ => 'स्कैन',
    };
  }

  int _indexForRoute(String location) {
    if (location.startsWith(AppRoutes.priceBoard)) return 1;
    if (location.startsWith(AppRoutes.earnings)) return 2;
    if (location.startsWith(AppRoutes.safety)) return 3;
    return 0;
  }

  void _navTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.scanner);
        break;
      case 1:
        context.go(AppRoutes.priceBoard);
        break;
      case 2:
        context.go(AppRoutes.earnings);
        break;
      case 3:
        context.go(AppRoutes.safety);
        break;
    }
  }
}

class AppHairlineBar extends StatelessWidget {
  const AppHairlineBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.line,
      child: SizedBox(height: 1, width: double.infinity),
    );
  }
}
