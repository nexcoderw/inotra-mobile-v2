import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../widgets/main_scaffold.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: "Settings",
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: "Personalization",
            tiles: [
              _tile(
                context,
                icon: HugeIcons.strokeRoundedMoon02,
                title: "Theme",
                subtitle: "Light / Dark / System",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Theme picker coming soon"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _tile(
                context,
                icon: HugeIcons.strokeRoundedLanguageSkill,
                title: "Language",
                subtitle: "Change display language",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Language selector coming soon"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: "Account & Privacy",
            tiles: [
              _tile(
                context,
                icon: HugeIcons.strokeRoundedShield02,
                title: "Privacy Policy",
                subtitle: "How we handle your data",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Privacy policy view coming soon"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _tile(
                context,
                icon: HugeIcons.strokeRoundedFileUnlocked,
                title: "Terms of Service",
                subtitle: "Review the terms",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Terms of service view coming soon"),
                      behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: "Support",
            tiles: [
              _tile(
                context,
                icon: HugeIcons.strokeRoundedMessageQuestion,
                title: "Help Center",
                subtitle: "FAQs and guides",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Help Center coming soon"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _tile(
                context,
                icon: HugeIcons.strokeRoundedCallRinging03,
                title: "Contact Support",
                subtitle: "Chat or email us",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Support contact coming soon"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: scheme.surfaceVariant.withOpacity(0.5),
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primary.withOpacity(0.12),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDiscoverCircle,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              title: const Text(
                "App version",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                "1.0.0",
                style: TextStyle(color: scheme.onSurface.withOpacity(0.65)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required dynamic icon, // HugeIcons.* uses custom IconData type
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary.withOpacity(0.12),
          child: HugeIcon(icon: icon, color: scheme.primary, size: 20, strokeWidth: 2),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: scheme.onSurface.withOpacity(0.65)),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> tiles;

  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...tiles,
      ],
    );
  }
}
