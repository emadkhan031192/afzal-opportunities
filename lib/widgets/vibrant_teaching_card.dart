import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
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
                // Job title.
                Text(
                  vacancy.jobTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                // School name.
                Text(
                  '${s.school}: ${vacancy.institutionName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                // Chips: type + location.
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      label: s.privateSchool,
                      background: _chipBg,
                      textColor: _ink,
                    ),
                    _Chip(
                      label: '📍 ${vacancy.district}',
                      background: _chipBg,
                      textColor: _ink,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: _ink.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: 12),
                // Qualification | Last date.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FactColumn(
                        label: s.qualification,
                        value: vacancy.qualification.trim().isEmpty
                            ? s.notSpecified
                            : vacancy.qualification.trim(),
                        ink: _ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FactColumn(
                        label: s.lastDate,
                        value: vacancy.applicationDeadline != null
                            ? _formatDate(vacancy.applicationDeadline!)
                            : s.notSpecified,
                        ink: _ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.tapForDetails,
                  style: TextStyle(
                    fontSize: 12,
                    color: _subtleInk,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: _ink.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: 12),
                // Apply options.
                Text(
                  s.applyOptions,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 10),
                _ApplyOptionsRow(vacancy: vacancy),
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _FactColumn extends StatelessWidget {
  const _FactColumn({
    required this.label,
    required this.value,
    required this.ink,
  });

  final String label;
  final String value;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ink,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Apply option buttons matching the approved design: large tinted buttons
/// with icon above label (Call / WhatsApp / Email).
///
/// Only enabled methods are shown, and only for signed-in users.
/// Tapping performs the action directly — never triggers card navigation.
/// Guests see a login button instead.
class _ApplyOptionsRow extends StatefulWidget {
  const _ApplyOptionsRow({required this.vacancy});

  final TeachingVacancy vacancy;

  @override
  State<_ApplyOptionsRow> createState() => _ApplyOptionsRowState();
}

class _ApplyOptionsRowState extends State<_ApplyOptionsRow> {
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
    final s = AppLocalizations.of(context);

    if (!_auth.isSignedIn) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            s.loginToApplyShort,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    final buttons = <Widget>[];
    if (v.enableCall) {
      buttons.add(
        _ApplyOptionButton(
          icon: Icons.call_outlined,
          label: s.call,
          background: const Color(0xFFE6F4EA),
          foreground: const Color(0xFF137333),
          onTap: _call,
        ),
      );
    }
    if (v.enableWhatsapp) {
      buttons.add(
        _ApplyOptionButton(
          icon: Icons.chat_outlined,
          label: s.whatsapp,
          background: const Color(0xFFE6F4EA),
          foreground: const Color(0xFF137333),
          onTap: _whatsapp,
        ),
      );
    }
    if (v.enableEmail) {
      buttons.add(
        _ApplyOptionButton(
          icon: Icons.email_outlined,
          label: s.email,
          background: const Color(0xFFE8EDFF),
          foreground: const Color(0xFF1E40AF),
          onTap: _email,
        ),
      );
    }
    if (buttons.isEmpty) {
      return Text(s.notSpecified, style: const TextStyle(fontSize: 13));
    }
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}

class _ApplyOptionButton extends StatelessWidget {
  const _ApplyOptionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: foreground),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
