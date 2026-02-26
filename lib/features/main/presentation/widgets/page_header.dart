import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

/// Reusable page header with a back icon and dynamic title.
class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final dynamic icon;

  const PageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.icon = HugeIcons.strokeRoundedArrowLeft01,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          IconButton(
            icon: HugeIcon(
              icon: icon,
              size: 20,
              strokeWidth: 2,
              color: scheme.onSurface,
            ),
            onPressed: onBack ?? () => Navigator.maybePop(context),
            tooltip: "Back",
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
