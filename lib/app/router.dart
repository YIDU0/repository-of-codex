import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/journal_theme.dart';
import '../features/platform_probe/presentation/platform_probe_page.dart';

const platformProbesEnabled =
    !kReleaseMode && bool.fromEnvironment('ENABLE_PLATFORM_PROBES');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            JournalShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const JournalWelcome()),
          GoRoute(
            path: '/calendar',
            builder: (_, _) => const FeaturePlaceholder(
              title: '把努力留在日历里',
              description: '月历与每日工时记录将在后续阶段加入。',
              icon: Icons.calendar_month_rounded,
            ),
          ),
          GoRoute(
            path: '/statistics',
            builder: (_, _) => const FeaturePlaceholder(
              title: '收获慢慢积累',
              description: '这里将展示真实记录的月度和年度汇总。',
              icon: Icons.bar_chart_rounded,
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const FeaturePlaceholder(
              title: '按你的习惯来',
              description: '时薪、提醒和备份设置将在后续阶段加入。',
              icon: Icons.tune_rounded,
            ),
          ),
        ],
      ),
      if (platformProbesEnabled)
        GoRoute(
          path: '/dev/platform',
          builder: (_, _) => const PlatformProbePage(),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class JournalShell extends StatelessWidget {
  const JournalShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;
  static const paths = ['/', '/calendar', '/statistics', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工时手账'),
        actions: [
          if (platformProbesEnabled)
            IconButton(
              tooltip: '开发版平台验证',
              onPressed: () => context.push('/dev/platform'),
              icon: const Icon(Icons.science_outlined),
            ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: paths.indexOf(location),
        onDestinationSelected: (index) => context.go(paths[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: '首页'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: '月历',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: '统计',
          ),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: '设置'),
        ],
      ),
    );
  }
}

class JournalWelcome extends StatelessWidget {
  const JournalWelcome({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholder(
    title: '每一份努力，都值得记下',
    description: '欢迎来到你的工时手账。\n当前是工程验证版，工时与收入功能还在准备中。',
    icon: Icons.auto_stories_rounded,
  );
}

class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: JournalColors.butter,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Icon(icon, size: 48, color: JournalColors.ink),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
