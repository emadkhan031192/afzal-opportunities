import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../services/teaching_auth.dart';
import '../services/teaching_service.dart';

/// Attractive greeting banner shown above the welcome carousel.
///
/// - Guest: "Welcome to Afzal-E Services."
/// - Institution: "Welcome, {Institution Name}."
/// - Teacher/job seeker: "Welcome, {First Name}."
///
/// The banner shows for a few seconds, then fades away on purpose to give
/// space to the content below. It stays hidden for the rest of the session.
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
  bool _visible = true;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_refresh);
    _refresh();
    // Show briefly, then fade away to free space for the content below.
    _fadeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    String text;
    IconData icon;
    if (_loading || _name == null) {
      text = s.welcomeGuest;
      icon = Icons.waving_hand_outlined;
    } else if (_isInstitution) {
      text = s.welcomeInstitution(_name!);
      icon = Icons.business_outlined;
    } else {
      text = s.welcomeTeacher(_name!);
      icon = Icons.person_outline;
    }
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      onEnd: () {
        if (mounted && !_visible) setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        height: _visible ? null : 0,
        child: _visible
            ? Container(
                margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? const [Color(0xFF065F46), Color(0xFF047857)]
                        : const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : const Color(0xFF065F46),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
