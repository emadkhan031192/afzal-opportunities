import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// App bar from the user's final UI: A-mark logo + "AFZAL-E SERVICES"
/// wordmark on the left; settings, notification bell (with dot), account
/// and logout actions on the right.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.onOpenSettings,
    this.onOpenNotifications,
    this.onOpenProfile,
    this.onLogout,
    this.hasUnreadNotifications = false,
    this.isSignedIn = false,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onLogout;
  final bool hasUnreadNotifications;
  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : const Color(0xFF1E1E2D);
    final iconBg = dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/logo/a_mark.svg',
            height: 28,
            width: 28,
            colorFilter: dark
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AFZAL-E',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: ink,
                  height: 1.1,
                ),
              ),
              const Text(
                'SERVICES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.8,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          _HeaderIconButton(
            background: iconBg,
            onTap: onOpenSettings,
            child: Icon(Icons.settings_outlined, size: 18, color: ink),
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            background: iconBg,
            onTap: onOpenNotifications,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, size: 18, color: ink),
                if (hasUnreadNotifications)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onOpenProfile,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_outline,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          if (isSignedIn) ...[
            const SizedBox(width: 8),
            _HeaderIconButton(
              background: iconBg,
              onTap: onLogout,
              child: Icon(Icons.logout_outlined, size: 18, color: ink),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.background,
    required this.child,
    this.onTap,
  });

  final Color background;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
