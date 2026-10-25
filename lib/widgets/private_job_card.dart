import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/l10n/app_localizations.dart';
import '../models/private_job.dart';

/// Private job card mirroring the vibrant teaching card: alternating
/// yellow/blue backgrounds, with the job title, company, city, salary
/// and deadline. Tapping opens the job details.
class PrivateJobCard extends StatelessWidget {
  const PrivateJobCard({
    super.key,
    required this.job,
    required this.index,
    required this.onTap,
  });

  final PrivateJob job;
  final int index;
  final VoidCallback onTap;

  bool get _isYellow => index % 2 == 0;

  Color get _background =>
      _isYellow ? const Color(0xFFFDE047) : const Color(0xFF2563EB);
  Color get _ink => _isYellow ? const Color(0xFF0F172A) : Colors.white;
  Color get _subtleInk =>
      _isYellow ? const Color(0xFF334155) : const Color(0xFFE0E7FF);
  Color get _chipBg => _isYellow
      ? const Color(0xFF0F172A).withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.2);

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
                        s.privateJobs.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  job.title,
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
                Text(
                  '${s.company}: ${job.company}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      label: '📍 ${job.city}',
                      background: _chipBg,
                      textColor: _ink,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: _ink.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FactColumn(
                        label: s.salary,
                        value: (job.salary ?? '').trim().isEmpty
                            ? s.notSpecified
                            : job.salary!.trim(),
                        ink: _ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FactColumn(
                        label: s.applicationDeadline,
                        value: job.deadline != null
                            ? DateFormat('d MMM yyyy').format(job.deadline!)
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
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ink.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
      ],
    );
  }
}
