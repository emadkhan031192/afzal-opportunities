import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../core/utils/deadline.dart';
import '../core/utils/url_utils.dart';
import '../models/teaching_vacancy.dart';
import '../services/teaching_service.dart';

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
    final text = Uri.encodeComponent(
      'Check out this teaching job: ${vacancy.jobTitle} at ${vacancy.institutionName}\n',
    );
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
                      child: Icon(Icons.chat_outlined, size: 16, color: _ink),
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
                Row(
                  children: [
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
                    const Spacer(),
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isYellow
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${s.applyNow} ↗',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _isYellow
                                ? Colors.white
                                : const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ),
                  ],
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
