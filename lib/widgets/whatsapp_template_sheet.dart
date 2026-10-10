import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../core/utils/url_utils.dart';
import '../core/utils/whatsapp_templates.dart';
import '../models/teaching_vacancy.dart';

/// Bottom sheet for choosing a WhatsApp application message: version 1–3
/// and English/Urdu, with a live preview. The applicant reviews the
/// message and taps "Open WhatsApp" to send it manually.
class WhatsappTemplateSheet extends StatefulWidget {
  const WhatsappTemplateSheet({super.key, required this.vacancy});

  final TeachingVacancy vacancy;

  static Future<void> show(BuildContext context, TeachingVacancy vacancy) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WhatsappTemplateSheet(vacancy: vacancy),
    );
  }

  @override
  State<WhatsappTemplateSheet> createState() => _WhatsappTemplateSheetState();
}

class _WhatsappTemplateSheetState extends State<WhatsappTemplateSheet> {
  int _version = 0;
  bool _urdu = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WhatsappTemplates.loadLastChoice().then((choice) {
      if (mounted) {
        setState(() {
          _version = choice.version;
          _urdu = choice.urdu;
          _loaded = true;
        });
      }
    });
  }

  String get _city {
    final c = (widget.vacancy.city ?? '').trim();
    return c.isNotEmpty ? c : widget.vacancy.district;
  }

  String get _message => WhatsappTemplates.fill(
    version: _version,
    urdu: _urdu,
    jobTitle: widget.vacancy.jobTitle,
    schoolName: widget.vacancy.institutionName,
    city: _city,
  );

  Future<void> _openWhatsapp() async {
    final number = widget.vacancy.whatsappInternational;
    if (number == null) return;
    await WhatsappTemplates.saveLastChoice(version: _version, urdu: _urdu);
    final text = Uri.encodeComponent(_message);
    final ok = await openUrl('https://wa.me/$number?text=$text');
    if (!ok && mounted) {
      final s = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.whatsappNotFound)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.chooseMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            // Version selector.
            Row(
              children: List.generate(3, (i) {
                final selected = i == _version;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: ChoiceChip(
                      label: Text('${s.version} ${i + 1}'),
                      selected: selected,
                      onSelected: (_) => setState(() => _version = i),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            // Language toggle.
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(s.english)),
                ButtonSegment(value: true, label: Text(s.urdu)),
              ],
              selected: {_urdu},
              onSelectionChanged: (sel) => setState(() => _urdu = sel.first),
            ),
            const SizedBox(height: 12),
            // Preview.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _loaded ? _message : '…',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openWhatsapp,
              icon: const Icon(Icons.chat_outlined),
              label: Text(s.openWhatsapp),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
