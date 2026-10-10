import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../services/teaching_auth.dart';
import '../../services/teaching_service.dart';

/// Role-appropriate home greeting.
///
/// - Guest: "Welcome to Afzal-E Services."
/// - Institution: "Welcome, {Institution Name}."
/// - Teacher/job seeker: "Welcome, {First Name}."
class HomeGreeting extends StatefulWidget {
  const HomeGreeting({super.key});

  @override
  State<HomeGreeting> createState() => _HomeGreetingState();
}

class _HomeGreetingState extends State<HomeGreeting> {
  final TeachingAuth _auth = TeachingAuth();
  final TeachingService _service = TeachingService();
  String? _name;
  bool _isInstitution = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    _auth.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!_auth.isSignedIn) {
      if (mounted) {
        setState(() {
          _name = null;
          _loading = false;
        });
      }
      return;
    }
    try {
      final uid = _auth.currentUser!.uid;
      final org = await _service.getMyOrganization(uid);
      if (mounted && org != null) {
        setState(() {
          _name = org.institutionName;
          _isInstitution = true;
          _loading = false;
        });
        return;
      }
      final profile = await _service.getMyProfile(uid);
      if (mounted) {
        final firstName = (profile?.fullName ?? '').trim().split(' ').first;
        setState(() {
          _name = firstName.isEmpty ? null : firstName;
          _isInstitution = false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String text;
    if (_loading) {
      text = s.welcomeGuest;
    } else if (_name == null) {
      text = s.welcomeGuest;
    } else if (_isInstitution) {
      text = s.welcomeInstitution(_name!);
    } else {
      text = s.welcomeTeacher(_name!);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
