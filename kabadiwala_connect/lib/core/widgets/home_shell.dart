import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../providers/app_state.dart';
import 'offline_banner.dart';

/// Minimalist, responsive Bottom-nav shell with instant language selection
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.0,
          ),
        ),
        actions: [
          const NetworkStatusPill(),
          const SizedBox(width: 4),
          // Language selector
          IconButton(
            tooltip: switch (lang) {
              'mr' => 'भाषा बदला',
              'en' => 'Change Language',
              _ => 'भाषा बदलें',
            },
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 16, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Text(
                    lang.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            onPressed: () => _showLanguageModal(context, ref, lang),
          ),
          // Switch role
          IconButton(
            tooltip: switch (lang) {
              'mr' => 'भूमिका बदला',
              'en' => 'Switch Role',
              _ => 'भूमिका बदलें',
            },
            icon: const Icon(Icons.switch_account_outlined, color: Color(0xFF475569), size: 22),
            onPressed: () => context.go(AppRoutes.role),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const OfflineSyncBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDCFCE7),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 64,
          selectedIndex: _indexForRoute(location),
          onDestinationSelected: (i) => _navTo(context, i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.qr_code_scanner_outlined, color: Color(0xFF64748B)),
              selectedIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFF059669)),
              label: switch (lang) {
                'mr' => 'स्कॅन / लॉट',
                'en' => 'Scan / Lot',
                _ => 'स्कैन / लॉट',
              },
            ),
            NavigationDestination(
              icon: const Icon(Icons.trending_up_outlined, color: Color(0xFF64748B)),
              selectedIcon: const Icon(Icons.trending_up, color: Color(0xFF059669)),
              label: switch (lang) {
                'mr' => 'भाव फलक',
                'en' => 'Rate Board',
                _ => 'भाव बोर्ड',
              },
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF64748B)),
              selectedIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF059669)),
              label: switch (lang) {
                'mr' => 'कमाई लेझर',
                'en' => 'Earnings',
                _ => 'कमाई लेज़र',
              },
            ),
            NavigationDestination(
              icon: const Icon(Icons.health_and_safety_outlined, color: Color(0xFF64748B)),
              selectedIcon: const Icon(Icons.health_and_safety, color: Color(0xFF059669)),
              label: switch (lang) {
                'mr' => 'सुरक्षा नियम',
                'en' => 'Safety',
                _ => 'सुरक्षा नियम',
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context, WidgetRef ref, String currentLang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      switch (currentLang) {
                        'mr' => 'भाषा निवडा (Select Language)',
                        'en' => 'Select App Language',
                        _ => 'भाषा चुनें (Select Language)',
                      },
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLangTile(
                  ctx: ctx,
                  ref: ref,
                  code: 'en',
                  name: 'English',
                  native: 'English (Formal & Accurate)',
                  isSelected: currentLang == 'en',
                ),
                const SizedBox(height: 8),
                _buildLangTile(
                  ctx: ctx,
                  ref: ref,
                  code: 'hi',
                  name: 'हिन्दी',
                  native: 'Hindi (सरल और प्रामाणिक)',
                  isSelected: currentLang == 'hi',
                ),
                const SizedBox(height: 8),
                _buildLangTile(
                  ctx: ctx,
                  ref: ref,
                  code: 'mr',
                  name: 'मराठी',
                  native: 'Marathi (स्थानिक भाषा)',
                  isSelected: currentLang == 'mr',
                ),
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
    required String native,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(appStateProvider.notifier).setLanguage(code);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    native,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF047857) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF059669), size: 22),
          ],
        ),
      ),
    );
  }

  String _titleForRoute(String location, String lang) {
    if (location.startsWith(AppRoutes.priceBoard)) {
      return switch (lang) {
        'mr' => 'आजचे ई-कचरा भाव',
        'en' => 'Live Scrap Rate Board',
        _ => 'आज के ई-कचरा भाव',
      };
    }
    if (location.startsWith(AppRoutes.earnings)) {
      return switch (lang) {
        'mr' => 'पारदर्शक कमाई लेझर',
        'en' => 'Transparent Earnings Ledger',
        _ => 'पारदर्शी कमाई लेज़र',
      };
    }
    if (location.startsWith(AppRoutes.safety)) {
      return switch (lang) {
        'mr' => 'ई-कचरा सुरक्षा नियम',
        'en' => 'E-Waste Safety Guidelines',
        _ => 'ई-कचरा सुरक्षा नियम',
      };
    }
    return switch (lang) {
      'mr' => 'कबाडीवाला कनेक्ट',
      'en' => 'Kabadiwala Connect',
      _ => 'कबाड़ीवाला कनेक्ट',
    };
  }

  int _indexForRoute(String location) {
    if (location.startsWith(AppRoutes.priceBoard)) return 1;
    if (location.startsWith(AppRoutes.earnings))   return 2;
    if (location.startsWith(AppRoutes.safety))     return 3;
    return 0;
  }

  void _navTo(BuildContext context, int index) {
    switch (index) {
      case 0: context.go(AppRoutes.scanner);    break;
      case 1: context.go(AppRoutes.priceBoard); break;
      case 2: context.go(AppRoutes.earnings);   break;
      case 3: context.go(AppRoutes.safety);     break;
    }
  }
}
