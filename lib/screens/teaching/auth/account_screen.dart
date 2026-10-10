import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../models/teaching_vacancy.dart';
import '../../../services/teaching_auth.dart';
import '../../../services/teaching_service.dart';
import '../../../widgets/state_views.dart';
import '../org/org_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import 'login_screen.dart';
import 'org_register_screen.dart';
import 'teacher_register_screen.dart';

/// Entry point for organization/teacher accounts from the Teaching tab.
///
/// Routes signed-out visitors to login/registration, and signed-in users
/// to their organization or teacher dashboard (or the account-type
/// chooser when they have no profile yet).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.returnVacancy});

  /// When set, the account flow was triggered from a job's apply flow;
  /// on successful sign-in the screen pops with `true` so the caller can
  /// return the applicant to that job.
  final TeachingVacancy? returnVacancy;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
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
    // Return-to-job flow: once signed in, pop with success.
    if (widget.returnVacancy != null && _auth.isSignedIn && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).account)),
      body: AnimatedBuilder(
        animation: _auth,
        builder: (context, _) {
          if (!_auth.isSignedIn) return const _SignedOutView();
          return _SignedInView(auth: _auth, service: _service);
        },
      ),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(
            Icons.school_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            s.teachingTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            s.teachingSubtitle,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _ChoiceCard(
            icon: Icons.business_outlined,
            title: s.iAmInstitution,
            subtitle: s.iAmInstitutionUrdu,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrgRegisterScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            icon: Icons.person_outline,
            title: s.iAmTeacher,
            subtitle: s.iAmTeacherUrdu,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeacherRegisterScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            icon: Icons.login,
            title: s.haveAccount,
            subtitle: s.haveAccountUrdu,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            icon: Icons.visibility_outlined,
            title: s.continueAsGuest,
            subtitle: s.continueAsGuestUrdu,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;

  /// Urdu explanation shown under the title (always in Urdu script).
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInView extends StatelessWidget {
  const _SignedInView({required this.auth, required this.service});

  final TeachingAuth auth;
  final TeachingService service;

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser!.uid;
    return FutureBuilder(
      future: Future.wait([
        service.getMyOrganization(uid),
        service.getMyProfile(uid),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: AppLocalizations.of(context).somethingWentWrong,
            onRetry: () async {},
          );
        }
        final results = snapshot.data ?? [];
        final org = results.isNotEmpty ? results[0] : null;
        final profile = results.length > 1 ? results[1] : null;
        if (org != null) {
          return OrgDashboard(auth: auth, service: service);
        }
        if (profile != null) {
          return TeacherDashboard(auth: auth, service: service);
        }
        return _ChooseTypeView(auth: auth);
      },
    );
  }
}

/// Signed in but no profile yet: pick the account type to register.
class _ChooseTypeView extends StatelessWidget {
  const _ChooseTypeView({required this.auth});

  final TeachingAuth auth;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            s.createAccount,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _ChoiceCard(
            icon: Icons.business_outlined,
            title: s.iAmInstitution,
            subtitle: s.iAmInstitutionUrdu,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrgRegisterScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            icon: Icons.person_outline,
            title: s.iAmTeacher,
            subtitle: s.iAmTeacherUrdu,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeacherRegisterScreen()),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await auth.signOut();
            },
            icon: const Icon(Icons.logout_outlined),
            label: Text(s.logout),
          ),
        ],
      ),
    );
  }
}
