import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../models/teaching_accounts.dart';
import '../../services/teaching_auth.dart';
import '../../services/teaching_service.dart';
import '../../widgets/state_views.dart';
import 'auth/account_screen.dart';
import 'auth/login_screen.dart';
import 'org/org_dashboard.dart';
import 'teacher/teacher_dashboard.dart';

/// Profile tab: shows the signed-in user's info at a glance.
///
/// - Teacher: name, qualification, subjects, district, experience, status.
/// - Institution: institution name, contact person, district, status.
/// - Guest: login prompt.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.profile)),
      body: AnimatedBuilder(
        animation: _auth,
        builder: (context, _) {
          if (!_auth.isSignedIn) return _GuestView(auth: _auth);
          return _SignedInView(auth: _auth, service: _service);
        },
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView({required this.auth});

  final TeachingAuth auth;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              s.profileGuestTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s.profileGuestDesc,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: Text(s.login),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              },
              child: Text(s.createAccount),
            ),
          ],
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
        final results = snapshot.data ?? [];
        final org = results.isNotEmpty ? results[0] as TeachingOrganization? : null;
        final profile = results.length > 1 ? results[1] as TeacherProfile? : null;
        if (org != null) {
          return _InstitutionInfo(org: org, auth: auth);
        }
        if (profile != null) {
          return _TeacherInfo(profile: profile, auth: auth);
        }
        return _NoAccountView(auth: auth);
      },
    );
  }
}

class _TeacherInfo extends StatelessWidget {
  const _TeacherInfo({required this.profile, required this.auth});

  final TeacherProfile profile;
  final TeachingAuth auth;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header(
          icon: Icons.person_outline,
          title: profile.fullName,
          subtitle: profile.qualification ?? s.notSpecified,
        ),
        const SizedBox(height: 16),
        _InfoRow(label: s.email, value: profile.email),
        _InfoRow(label: s.district, value: profile.district),
        _InfoRow(
          label: s.subjects,
          value: profile.subjects.join(', '),
        ),
        _InfoRow(
          label: s.experience,
          value: profile.experienceYears != null
              ? '${profile.experienceYears} ${s.years}'
              : s.notSpecified,
        ),
        _InfoRow(label: s.status, value: profile.approvalStatus),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TeacherDashboard(auth: auth, service: TeachingService()),
              ),
            );
          },
          icon: const Icon(Icons.dashboard_outlined),
          label: Text(s.myProfile),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async => auth.signOut(),
          icon: const Icon(Icons.logout_outlined),
          label: Text(s.logout),
        ),
      ],
    );
  }
}

class _InstitutionInfo extends StatelessWidget {
  const _InstitutionInfo({required this.org, required this.auth});

  final TeachingOrganization org;
  final TeachingAuth auth;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header(
          icon: Icons.business_outlined,
          title: org.institutionName,
          subtitle: org.institutionType,
        ),
        const SizedBox(height: 16),
        _InfoRow(label: s.contactPerson, value: org.contactPerson),
        _InfoRow(label: s.email, value: org.email),
        _InfoRow(label: s.district, value: org.district),
        _InfoRow(label: s.city, value: org.city ?? s.notSpecified),
        _InfoRow(label: s.status, value: org.approvalStatus),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrgDashboard(auth: auth, service: TeachingService()),
              ),
            );
          },
          icon: const Icon(Icons.dashboard_outlined),
          label: Text(s.myVacancies),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async => auth.signOut(),
          icon: const Icon(Icons.logout_outlined),
          label: Text(s.logout),
        ),
      ],
    );
  }
}

class _NoAccountView extends StatelessWidget {
  const _NoAccountView({required this.auth});

  final TeachingAuth auth;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s.noProfileFound, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async => auth.signOut(),
              icon: const Icon(Icons.logout_outlined),
              label: Text(s.logout),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
