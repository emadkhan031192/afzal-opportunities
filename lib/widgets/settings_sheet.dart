import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/l10n/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/brand_colors.dart';
import '../core/theme/theme_controller.dart';
import '../services/notification_service.dart';

/// Bottom sheet with app settings: appearance, language, notification
/// preferences, and the Afzal E Services WhatsApp channel link.
///
/// Shown from the header settings button. All choices persist.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.notificationService,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final NotificationService notificationService;

  static Future<void> show(
    BuildContext context, {
    required ThemeController themeController,
    required LocaleController localeController,
    required NotificationService notificationService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SettingsSheet(
        themeController: themeController,
        localeController: localeController,
        notificationService: notificationService,
      ),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final Map<NotificationType, bool> _notifState = {};
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final type in NotificationType.values) {
      _notifState[type] = await widget.notificationService.isEnabled(type);
    }
    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _version = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _setNotif(NotificationType type, bool value) async {
    if (value) {
      await widget.notificationService.requestPermission();
    }
    await widget.notificationService.setEnabled(type, value);
    setState(() => _notifState[type] = value);
  }

  Future<void> _openWhatsappChannel() async {
    final uri = Uri.parse(AppConstants.whatsappChannelUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(s.settings, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            _SectionTitle(s.appearance),
            _ThemeRow(
              controller: widget.themeController,
              lightLabel: s.lightMode,
              darkLabel: s.darkMode,
            ),
            const SizedBox(height: 16),
            _SectionTitle(s.language),
            ...LocaleController.choices.map(
              (choice) => RadioListTile<String>(
                value: choice,
                groupValue: widget.localeController.choice,
                onChanged: (v) =>
                    v == null ? null : widget.localeController.setChoice(v),
                title: Text(_languageLabel(choice, s)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const SizedBox(height: 8),
            _SectionTitle(s.notifications),
            ...NotificationType.values.map(
              (type) => SwitchListTile(
                value: _notifState[type] ??
                    NotificationService.defaultEnabled(type),
                onChanged: (v) => _setNotif(type, v),
                title: Text(_notifTitle(type, s)),
                subtitle: Text(_notifDesc(type, s)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const SizedBox(height: 8),
            _SectionTitle(s.about),
            ListTile(
              leading: const Icon(Icons.campaign_outlined,
                  color: BrandColors.mintDark),
              title: Text(s.followWhatsappChannel),
              trailing: const Icon(Icons.open_in_new, size: 18),
              contentPadding: EdgeInsets.zero,
              dense: true,
              onTap: _openWhatsappChannel,
            ),
            if (_version != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${s.version} $_version',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _languageLabel(String choice, AppLocalizations s) {
    switch (choice) {
      case 'en':
        return s.english;
      case 'ur':
        return s.urdu;
      default:
        return s.systemDefault;
    }
  }

  String _notifTitle(NotificationType type, AppLocalizations s) {
    switch (type) {
      case NotificationType.newAds:
        return s.notifNewAds;
      case NotificationType.closingSoon:
        return s.notifClosingSoon;
      case NotificationType.teaching:
        return s.notifTeaching;
      case NotificationType.promotions:
        return s.notifPromotions;
    }
  }

  String _notifDesc(NotificationType type, AppLocalizations s) {
    switch (type) {
      case NotificationType.newAds:
        return s.notifNewAdsDesc;
      case NotificationType.closingSoon:
        return s.notifClosingSoonDesc;
      case NotificationType.teaching:
        return s.notifTeachingDesc;
      case NotificationType.promotions:
        return s.notifPromotionsDesc;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: BrandColors.mintDark,
            ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.controller,
    required this.lightLabel,
    required this.darkLabel,
  });

  final ThemeController controller;
  final String lightLabel;
  final String darkLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => SegmentedButton<bool>(
        segments: [
          ButtonSegment(
            value: false,
            icon: const Icon(Icons.light_mode_outlined),
            label: Text(lightLabel),
          ),
          ButtonSegment(
            value: true,
            icon: const Icon(Icons.dark_mode_outlined),
            label: Text(darkLabel),
          ),
        ],
        selected: {controller.isDark},
        onSelectionChanged: (selected) =>
            controller.setMode(selected.first ? ThemeMode.dark : ThemeMode.light),
      ),
    );
  }
}
