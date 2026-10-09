import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../core/utils/deadline.dart';
import '../core/utils/url_utils.dart';
import '../models/advertisement.dart';
import '../widgets/whatsapp_icon.dart';

/// Vibrant advertisement card from the user's final UI: alternating
/// yellow/blue backgrounds, category badge + WhatsApp share + bookmark
/// actions on top, title, organization, last date, days-left badge and
/// an Apply button in the footer.
class VibrantAdCard extends StatelessWidget {
  const VibrantAdCard({
    super.key,
    required this.ad,
    required this.index,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSave,
  });

  final Advertisement ad;
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
      'Check out this job opportunity: ${ad.title}\n',
    );
    await openUrl('https://api.whatsapp.com/send?text=$text');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final info = getDeadlineInfo(
      lastDate: ad.lastDate,
      publishedAt: ad.publishedAt,
    );
    final daysText = s.deadlineLabel(info);

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
                        _categoryLabel(ad.category, s),
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
                  ad.title,
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
                  '🏢 ${ad.organization}',
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
                  '📅 ${s.lastDate}: ${_formatDate(ad.lastDate, s)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _subtleInk,
                  ),
                ),
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
                    '⏳ $daysText'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ),
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

  String _categoryLabel(String id, AppLocalizations s) {
    switch (id) {
      case 'jobs':
        return s.jobs;
      case 'scholarships':
        return s.scholarships;
      case 'admissions':
        return s.admissions;
      case 'other':
        return s.other;
      default:
        return id;
    }
  }

  String _formatDate(DateTime? date, AppLocalizations s) {
    if (date == null) return s.notSpecified;
    return '${date.day} ${_monthName(date.month, s)} ${date.year}';
  }

  String _monthName(int month, AppLocalizations s) {
    const en = [
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
    // Keep it simple: localized month names come from intl in details;
    // cards use the short English form to match the HTML design.
    return en[month - 1];
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
