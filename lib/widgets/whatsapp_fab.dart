import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/l10n/app_localizations.dart';
import '../core/utils/url_utils.dart';

/// Floating WhatsApp button from the user's final UI: a green circular
/// button that expands a "Join our WhatsApp Channel" label on tap before
/// opening the channel link.
class WhatsAppFab extends StatefulWidget {
  const WhatsAppFab({super.key});

  @override
  State<WhatsAppFab> createState() => _WhatsAppFabState();
}

class _WhatsAppFabState extends State<WhatsAppFab> {
  bool _expanded = false;

  Future<void> _onTap() async {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await openUrl(AppConstants.whatsappChannelUrl);
      if (mounted) setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: _expanded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(_expanded ? 0 : 10, 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              s.joinWhatsAppChannel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.chat, size: 26, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
