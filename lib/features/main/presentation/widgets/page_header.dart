import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../i18n/lang.dart";

/// Reusable page header with a back icon and dynamic title.
class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final dynamic icon;
  final TextStyle? titleStyle;

  const PageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.icon = HugeIcons.strokeRoundedArrowLeft01,
    this.titleStyle,
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
            tooltip: tr("nav.back"),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  titleStyle ??
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
