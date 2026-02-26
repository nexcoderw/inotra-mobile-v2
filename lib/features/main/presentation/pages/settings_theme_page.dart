import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:hugeicons/hugeicons.dart";

import "../widgets/main_scaffold.dart";
import "../widgets/page_header.dart";
import "../../../../core/services/theme_notifier.dart";

class SettingsThemePage extends StatelessWidget {
  const SettingsThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    final current = notifier.mode;

    return MainScaffold(
      title: "Theme",
      showAppBar: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(title: "Theme"),
            const SizedBox(height: 12),
            _ThemeOption(
              label: "Light",
              icon: HugeIcons.strokeRoundedSun01,
              selected: current == ThemeMode.light,
              onTap: () => notifier.setMode(ThemeMode.light),
            ),
            const SizedBox(height: 10),
            _ThemeOption(
              label: "Dark",
              icon: HugeIcons.strokeRoundedMoon02,
              selected: current == ThemeMode.dark,
              onTap: () => notifier.setMode(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final dynamic icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? scheme.primary.withOpacity(0.6)
                : scheme.onSurface.withOpacity(0.08),
            width: 1.4,
          ),
          color: selected
              ? scheme.primary.withOpacity(0.10)
              : scheme.surface.withOpacity(0.6),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primary.withOpacity(0.12),
              child: HugeIcon(
                icon: icon,
                size: 18,
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selected ? 1 : 0,
              child: Icon(
                Icons.check_circle,
                color: scheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
