import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../core/utils/deadline.dart';
import '../core/utils/share_text.dart';
import '../core/utils/url_utils.dart';
import '../models/teaching_vacancy.dart';
import '../services/teaching_auth.dart';
import '../services/teaching_service.dart';
import '../widgets/whatsapp_icon.dart';
import 'whatsapp_template_sheet.dart';

/// Vibrant teaching vacancy card from the user's final UI: alternating
/// yellow/blue backgrounds matching the advertisement cards, with the
/// vacancy title, institution, district, deadline and an Apply button.
class VibrantTeachingCard extends StatelessWidget {
  const VibrantTeachingCard({
    super.key,
    required this.vacancy,
    required this.index,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSave,
  });

  final TeachingVacancy vacancy;
  final int index;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  bool get _isYellow => index % 2 == 0;

  Color get _background =>
      _isYellow ? const Color(0xFFFDE047) : const Color(0xFF2563EB);
  Color get _ink => _isYellow ? const Color(0xFF0F172A) : Colors.white;
  Color get _subtleInk =>
      _isYellow ? const Color(0xFF334155) : const Color(0xFFE0E7FF);
  Color get _chipBg => _isYellow
      ? const Color(0xFF0F172A).withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.2);

  Future<void> _shareWhatsApp(BuildContext context) async {
    final text = Uri.encodeComponent(buildVacancyShareText(vacancy));
    await openUrl('https://api.whatsapp.com/send?text=$text');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final info = getDeadlineInfo(
      lastDate: vacancy.applicationDeadline,
      publishedAt: vacancy.publishedAt,
    );
    final expired = TeachingService.isExpired(vacancy);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _chipBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.teaching.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _CardIconButton(
                      background: _chipBg,
                      onTap: () => _shareWhatsApp(context),
                      child: WhatsAppIcon(size: 16, color: _ink),
                    ),
                    const SizedBox(width: 6),
                    _CardIconButton(
                      background: _chipBg,
                      onTap: onToggleSave,
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 16,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  vacancy.jobTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '🏫 ${vacancy.institutionName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _ink.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '📍 ${vacancy.district}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _subtleInk,
                  ),
                ),
                if (vacancy.applicationDeadline != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '📅 ${s.lastDate}: ${_formatDate(vacancy.applicationDeadline!)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _subtleInk,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _chipBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    expired
                        ? '⌛ ${s.expired}'.toUpperCase()
                        : '⏳ ${s.deadlineLabel(info)}'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _CardContactButtons(vacancy: vacancy),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isYellow
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${s.applyNow} ↗',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _isYellow
                              ? Colors.white
                              : const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Small contact-method buttons for signed-in users.
///
/// Only shown when the user is signed in and the vacancy has at least one
/// enabled method. Tapping fetches the private contact details (single
/// Firestore read) and performs the action directly — it never triggers
/// card navigation. Guests see nothing here.
class _CardContactButtons extends StatefulWidget {
  const _CardContactButtons({required this.vacancy});

  final TeachingVacancy vacancy;

  @override
  State<_CardContactButtons> createState() => _CardContactButtonsState();
}

class _CardContactButtonsState extends State<_CardContactButtons> {
  final TeachingAuth _auth = TeachingAuth();
  final TeachingService _service = TeachingService();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _call() async {
    final contact = await _service.getVacancyContact(widget.vacancy.id);
    if (contact?.applyPhone == null || !mounted) return;
    final merged = widget.vacancy.withContact(contact!);
    if (merged.canCall) openUrl('tel:${merged.applyPhone}');
  }

  Future<void> _whatsapp() async {
    if (!mounted) return;
    final contact = await _service.getVacancyContact(widget.vacancy.id);
    if (contact?.applyWhatsapp == null || !mounted) return;
    final merged = widget.vacancy.withContact(contact!);
    if (merged.canWhatsapp) WhatsappTemplateSheet.show(context, merged);
  }

  Future<void> _email() async {
    final contact = await _service.getVacancyContact(widget.vacancy.id);
    if (contact?.applyEmail == null || !mounted) return;
    final merged = widget.vacancy.withContact(contact!);
    if (!merged.canEmail) return;
    final subject = Uri.encodeComponent(
      'Application: ${merged.jobTitle} at ${merged.institutionName}',
    );
    openUrl('mailto:${merged.applyEmail}?subject=$subject');
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vacancy;
    if (!_auth.isSignedIn) return const SizedBox.shrink();
    if (!v.enableCall && !v.enableWhatsapp && !v.enableEmail) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (v.enableCall)
          _ContactIcon(icon: Icons.call_outlined, tooltip: 'Call', onTap: _call),
        if (v.enableWhatsapp)
          _ContactIcon(
            icon: Icons.chat_outlined,
            tooltip: 'WhatsApp',
            onTap: _whatsapp,
          ),
        if (v.enableEmail)
          _ContactIcon(
            icon: Icons.email_outlined,
            tooltip: 'Email',
            onTap: _email,
          ),
      ],
    );
  }
}

class _ContactIcon extends StatelessWidget {
  const _ContactIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
