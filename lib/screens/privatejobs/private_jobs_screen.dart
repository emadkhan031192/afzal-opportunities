import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../models/private_job.dart';
import '../../services/notification_service.dart';
import '../../services/private_job_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/notification_inbox_sheet.dart';
import '../../widgets/private_job_card.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/state_views.dart';
import 'private_job_details_screen.dart';
import '../teaching/auth/account_screen.dart';

/// Public Private Jobs tab: browse approved + active private jobs.
/// A horizontal city filter sits on top: All + the 20 KPK cities.
/// Tapping a chip filters the list instantly (client-side, no new query).
class PrivateJobsScreen extends StatefulWidget {
  const PrivateJobsScreen({
    super.key,
    required this.service,
    required this.themeController,
    required this.localeController,
    required this.notificationService,
    this.onOpenProfile,
  });

  final PrivateJobService service;
  final ThemeController themeController;
  final LocaleController localeController;
  final NotificationService notificationService;

  /// Jumps to the Profile tab (apply-instructions prompt). Null when the
  /// screen is hosted outside MainShell.
  final VoidCallback? onOpenProfile;

  @override
  State<PrivateJobsScreen> createState() => _PrivateJobsScreenState();
}

class _PrivateJobsScreenState extends State<PrivateJobsScreen> {
  String _city = '';
  late final Stream<List<PrivateJob>> _jobsStream;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _jobsStream = widget.service.watchApprovedJobs();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    final count = await widget.notificationService.getUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  Future<void> _openInbox() async {
    await NotificationInboxSheet.show(context, widget.notificationService);
    await _loadUnread();
  }

  void _openDetails(PrivateJob job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivateJobDetailsScreen(
          job: job,
          onOpenProfile: widget.onOpenProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              onOpenSettings: () => SettingsSheet.show(
                context,
                themeController: widget.themeController,
                localeController: widget.localeController,
                notificationService: widget.notificationService,
              ),
              onOpenNotifications: _openInbox,
              onOpenProfile: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
              ),
              hasUnreadNotifications: _unreadCount > 0,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                s.privateJobsSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: dark ? BrandColors.muted : BrandColors.mutedOnLight,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _cityChips(s, dark)),
          SliverToBoxAdapter(
            child: StreamBuilder<List<PrivateJob>>(
              stream: _jobsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: LoadingView(),
                  );
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final isPermissionDenied = error.toString().contains(
                    'permission-denied',
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: ErrorView(
                      message: isPermissionDenied
                          ? s.privateJobsPermissionDenied
                          : s.privateJobsLoadFailed,
                      onRetry: () async {
                        setState(() {});
                      },
                    ),
                  );
                }
                final jobs = PrivateJobService.applyPublicFilter(
                  snapshot.data ?? [],
                  city: _city,
                );
                if (jobs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyView(
                      icon: Icons.business_center_outlined,
                      title: s.noPrivateJobsFound,
                      message: s.noPrivateJobsHint,
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return PrivateJobCard(
                      job: job,
                      index: index,
                      onTap: () => _openDetails(job),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal city filter chips: All + the 20 KPK cities. Tapping a
  /// chip switches the filter instantly (setState only — the stream is
  /// already loaded, so there is no new Firestore query).
  Widget _cityChips(AppLocalizations s, bool dark) {
    final cities = <String>['', ...AppConstants.kpkJobCities];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: cities.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = cities[index];
          final selected = _city == city;
          return ChoiceChip(
            label: Text(city.isEmpty ? s.allCities : city),
            selected: selected,
            onSelected: (_) => setState(() => _city = city),
            selectedColor: BrandColors.mockupBlue,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : (dark ? Colors.white : BrandColors.nightBlue),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            backgroundColor: dark
                ? Colors.white.withValues(alpha: 0.07)
                : BrandColors.lightBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide.none,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
