import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../models/teaching_vacancy.dart';
import '../../services/bookmark_service.dart';
import '../../services/notification_service.dart';
import '../../services/teaching_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/notification_inbox_sheet.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/state_views.dart';
import '../../widgets/vibrant_teaching_card.dart';
import '../../widgets/welcome_carousel.dart';
import 'auth/account_screen.dart';
import 'vacancy_details_screen.dart';

/// Public Private Teaching Jobs tab: browse approved vacancies without
/// logging in. Search + district/subject/qualification/experience
/// filters, saved-jobs toggle, and vacancy details.
class TeachingScreen extends StatefulWidget {
  const TeachingScreen({
    super.key,
    required this.service,
    required this.bookmarks,
    required this.teachingBookmarks,
    required this.themeController,
    required this.localeController,
    required this.notificationService,
  });

  final TeachingService service;
  final BookmarkService bookmarks;
  final BookmarkService teachingBookmarks;
  final ThemeController themeController;
  final LocaleController localeController;
  final NotificationService notificationService;

  @override
  State<TeachingScreen> createState() => _TeachingScreenState();
}

class _TeachingScreenState extends State<TeachingScreen> {
  final TextEditingController _searchController = TextEditingController();
  VacancyFilter _filter = const VacancyFilter();
  bool _savedOnly = false;
  late final Stream<List<TeachingVacancy>> _vacanciesStream;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _vacanciesStream = widget.service.watchApprovedVacancies();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetails(TeachingVacancy vacancy) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VacancyDetailsScreen(
          vacancy: vacancy,
          bookmarks: widget.teachingBookmarks,
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await showTeachingFilterSheet(context, initial: _filter);
    if (result != null) {
      setState(
        () => _filter = VacancyFilter(
          query: _filter.query,
          district: result.district,
          subject: result.subject,
          qualification: result.qualification,
          experience: result.experience,
        ),
      );
    }
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
          const SliverToBoxAdapter(child: WelcomeCarousel(teaching: true)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                s.teachingSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: dark ? BrandColors.muted : BrandColors.mutedOnLight,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _searchRow(s, dark)),
          SliverToBoxAdapter(
            child: StreamBuilder<List<TeachingVacancy>>(
              stream: _vacanciesStream,
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
                          ? s.teachingPermissionDenied
                          : s.teachingLoadFailed,
                      onRetry: () async {
                        setState(() {});
                      },
                    ),
                  );
                }
                final allVacancies = TeachingService.applyFilter(
                  snapshot.data ?? [],
                  _filter,
                );
                final vacancies = _savedOnly
                    ? allVacancies
                          .where(
                            (v) => widget.teachingBookmarks.isBookmarked(v.id),
                          )
                          .toList()
                    : allVacancies;
                if (vacancies.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyView(
                      icon: Icons.school_outlined,
                      title: s.noVacanciesFound,
                      message: s.noVacanciesHint,
                    ),
                  );
                }
                return AnimatedBuilder(
                  animation: widget.teachingBookmarks,
                  builder: (context, _) => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: vacancies.length,
                    itemBuilder: (context, index) {
                      final vacancy = vacancies[index];
                      return VibrantTeachingCard(
                        vacancy: vacancy,
                        index: index,
                        isSaved: widget.teachingBookmarks.isBookmarked(
                          vacancy.id,
                        ),
                        onTap: () => _openDetails(vacancy),
                        onToggleSave: () =>
                            widget.teachingBookmarks.toggle(vacancy.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchRow(AppLocalizations s, bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(
                  () => _filter = VacancyFilter(
                    query: value,
                    district: _filter.district,
                    subject: _filter.subject,
                    qualification: _filter.qualification,
                    experience: _filter.experience,
                  ),
                ),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: s.searchTeachingHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: dark
                      ? Colors.white.withValues(alpha: 0.07)
                      : BrandColors.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.tune_outlined,
            tooltip: s.filter,
            active: _filter.isActive,
            onPressed: _openFilters,
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: widget.teachingBookmarks,
            builder: (context, _) => _IconButton(
              icon: _savedOnly ? Icons.bookmark : Icons.bookmark_border,
              tooltip: s.savedJobs,
              active: _savedOnly,
              onPressed: () => setState(() => _savedOnly = !_savedOnly),
            ),
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.person_outline,
            tooltip: s.account,
            active: false,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: active
            ? BrandColors.mockupBlue
            : (dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : BrandColors.lightBackground),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 20,
              color: active
                  ? Colors.white
                  : (dark ? Colors.white : BrandColors.nightBlue),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter bottom sheet for the teaching feed: district, subject,
/// qualification and experience. Subject/qualification match by text.
Future<VacancyFilter?> showTeachingFilterSheet(
  BuildContext context, {
  required VacancyFilter initial,
}) {
  return showModalBottomSheet<VacancyFilter>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _TeachingFilterSheet(initial: initial),
  );
}

class _TeachingFilterSheet extends StatefulWidget {
  const _TeachingFilterSheet({required this.initial});

  final VacancyFilter initial;

  @override
  State<_TeachingFilterSheet> createState() => _TeachingFilterSheetState();
}

class _TeachingFilterSheetState extends State<_TeachingFilterSheet> {
  late String _district;
  late String _experience;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _district = widget.initial.district;
    _experience = widget.initial.experience;
    _subjectController.text = widget.initial.subject;
    _qualificationController.text = widget.initial.qualification;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _district = '';
      _experience = '';
      _subjectController.clear();
      _qualificationController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(s.filter, style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton(onPressed: _reset, child: Text(s.reset)),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.district, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey(_district),
              initialValue: _district.isEmpty ? null : _district,
              hint: Text(s.anyOption),
              items: [
                DropdownMenuItem(value: '', child: Text(s.anyOption)),
                for (final d in AppConstants.kpDistricts)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => setState(() => _district = v ?? ''),
            ),
            const SizedBox(height: 16),
            Text(s.subject, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: s.anyOption,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(s.qualification, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _qualificationController,
              decoration: InputDecoration(
                hintText: s.anyOption,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(s.experience, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: '', label: Text(s.anyOption)),
                ButtonSegment(value: 'fresh', label: Text(s.freshEntry)),
                ButtonSegment(value: 'experienced', label: Text(s.experienced)),
              ],
              selected: {_experience},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _experience = selection.first),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                VacancyFilter(
                  district: _district,
                  subject: _subjectController.text.trim(),
                  qualification: _qualificationController.text.trim(),
                  experience: _experience,
                ),
              ),
              child: Text(s.applyFilters),
            ),
          ],
        ),
      ),
    );
  }
}
