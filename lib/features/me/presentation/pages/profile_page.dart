import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/services/biometric_service.dart";
import "../../../../core/widgets/app_cached_image.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "package:inotra/features/main/presentation/widgets/main_scaffold.dart";
import "package:inotra/features/main/presentation/widgets/page_header.dart";

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final user = AuthSession.instance.value.user ?? {};
    final imageUrl = user["image"] as String?;

    return MainScaffold(
      title: t(lang, "profile.title"),
      showAppBar: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          PageHeader(
            title: t(lang, "profile.title"),
            onBack: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: 10),

          // 🔥 Glass profile header
          _GlassCard(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.onSurface.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? AppCachedImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 240,
                                  memCacheHeight: 240,
                                  maxWidthDiskCache: 320,
                                  maxHeightDiskCache: 320,
                                  errorBuilder: (_) =>
                                      _ProfileAvatarFallback(scheme: scheme),
                                  placeholderBuilder: (_) =>
                                      _ProfileAvatarFallback(scheme: scheme),
                                )
                              : _ProfileAvatarFallback(scheme: scheme),
                        ),
                      ),
                    ),
                    Container(
                      height: 26,
                      width: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  t(lang, "profile.user_profile"),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user["email"] ?? "",
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const _BiometricProfileCard(),

          const SizedBox(height: 18),

          // 🔥 Glass navigation group
          _GlassCard(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: _withDividers(context, [
                _ProfileNavTile(
                  icon: HugeIcons.strokeRoundedUser,
                  title: t(lang, "profile.account_details"),
                  subtitle: t(lang, "profile.account_details_sub"),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.profileAccount),
                ),
                _ProfileNavTile(
                  icon: HugeIcons.strokeRoundedLockPassword,
                  title: t(lang, "profile.change_password"),
                  subtitle: t(lang, "profile.change_password_sub"),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.profilePassword),
                ),
                _ProfileNavTile(
                  icon: Icons.warning_amber_rounded,
                  color: scheme.error,
                  title: t(lang, "profile.danger_zone"),
                  subtitle: t(lang, "profile.danger_zone_sub"),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.profileDanger),
                ),
                _ProfileNavTile(
                  icon: HugeIcons.strokeRoundedLogout02,
                  color: scheme.error,
                  title: t(lang, "nav.logout"),
                  subtitle: t(lang, "nav.logout_sub"),
                  onTap: () {
                    AuthSession.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _withDividers(BuildContext context, List<Widget> tiles) {
    final scheme = Theme.of(context).colorScheme;
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i != tiles.length - 1) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(left: 44, right: 6),
            child: Divider(
              height: 14,
              thickness: 1,
              color: scheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
        );
      }
    }
    return out;
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  final ColorScheme scheme;

  const _ProfileAvatarFallback({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.primary.withValues(alpha: 0.12),
      child: Center(child: Icon(Icons.person, size: 40, color: scheme.primary)),
    );
  }
}

class _BiometricProfileCard extends StatefulWidget {
  const _BiometricProfileCard();

  @override
  State<_BiometricProfileCard> createState() => _BiometricProfileCardState();
}

class _BiometricProfileCardState extends State<_BiometricProfileCard>
    with WidgetsBindingObserver {
  bool _checked = false;
  bool _available = false;
  bool _enabled = false;
  BiometricPresentationKind _presentation =
      BiometricPresentationKind.biometrics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BiometricService.instance.changes.addListener(_handleBiometricStateChanged);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  void _handleBiometricStateChanged() {
    _load();
  }

  Future<void> _load() async {
    final status = await BiometricService.instance.getStatus();
    if (!mounted) return;
    setState(() {
      _checked = true;
      _available = status.available;
      _enabled = status.enabled;
      _presentation = status.presentation;
    });
  }

  String _biometricTitle(String lang) {
    return switch (_presentation) {
      BiometricPresentationKind.faceId => t(lang, "biometric.face_id"),
      BiometricPresentationKind.touchId => t(lang, "biometric.touch_id"),
      BiometricPresentationKind.fingerprint => t(lang, "biometric.fingerprint"),
      BiometricPresentationKind.biometrics => t(lang, "biometric.generic"),
    };
  }

  dynamic _biometricIcon() {
    return switch (_presentation) {
      BiometricPresentationKind.faceId => HugeIcons.strokeRoundedFaceId,
      BiometricPresentationKind.touchId ||
      BiometricPresentationKind.fingerprint => Icons.fingerprint_rounded,
      BiometricPresentationKind.biometrics => Icons.lock_open_rounded,
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BiometricService.instance.changes.removeListener(
      _handleBiometricStateChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    final label = !_available
        ? t(lang, "settings.biometric_unavailable_label")
        : (_enabled
              ? t(lang, "settings.biometric_active_label")
              : t(lang, "settings.biometric_inactive_label"));
    final message = !_available
        ? t(lang, "settings.biometric_unavailable")
        : (_enabled
              ? t(lang, "settings.biometric_enabled_subtitle")
              : t(lang, "auth.biometric_setup_hint"));
    final accent = !_available
        ? scheme.outline
        : (_enabled ? scheme.primary : scheme.secondary);

    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: _biometricIcon(), color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: !_checked
                ? Text(
                    t(lang, "auth.wait"),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.75),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _biometricTitle(lang),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: scheme.onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileNavTile extends StatefulWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  State<_ProfileNavTile> createState() => _ProfileNavTileState();
}

class _ProfileNavTileState extends State<_ProfileNavTile> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = widget.color ?? scheme.primary;
    final isActive = _pressed || _hovered;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActive
                ? scheme.onSurface.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            scale: _pressed ? 0.985 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  _IconBadge(icon: widget.icon, color: tone),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14, // ✅ title 14
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12, // ✅ subtitle 12
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 160),
                    offset: isActive ? const Offset(0.06, 0) : Offset.zero,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final dynamic icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 30,
      width: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
      ),
      child: Center(
        child: icon is IconData
            ? Icon(icon as IconData, size: 14, color: color) // ✅ icon size 14
            : HugeIcon(
                icon: icon,
                size: 14, // ✅ icon size 14
                strokeWidth: 2,
                color: color,
              ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: scheme.surface.withValues(alpha: 0.55),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
