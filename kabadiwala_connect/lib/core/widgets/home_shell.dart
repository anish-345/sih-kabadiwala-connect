import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import 'offline_banner.dart';

/// Bottom-nav shell for the collector flow with network status indicator and offline banner
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final title = _titleForRoute(location);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          const NetworkStatusPill(),
          IconButton(
            tooltip: 'भाषा बदलें (Change Language)',
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => context.go(AppRoutes.language),
          ),
          IconButton(
            tooltip: 'भूमिका बदलें (Switch Role)',
            icon: const Icon(Icons.switch_account_outlined, color: Colors.white),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexForRoute(location),
        onDestinationSelected: (i) => _navTo(context, i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'स्कैन / लॉट',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'भाव बोर्ड',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'कमाई लेज़र',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: 'सुरक्षा मार्गदर्शिका',
          ),
        ],
      ),
    );
  }

  String _titleForRoute(String location) {
    if (location.startsWith(AppRoutes.priceBoard)) return 'आज के ई-कचरा भाव';
    if (location.startsWith(AppRoutes.earnings))   return 'पारदर्शी कमाई लेज़र';
    if (location.startsWith(AppRoutes.safety))     return 'ई-कचरा सुरक्षा नियम';
    return 'कबाड़ीवाला कनेक्ट';
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
