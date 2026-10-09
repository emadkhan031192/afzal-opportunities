import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../services/teaching_auth.dart';

/// Prompt shown after registration: the user must verify their email
/// before posting vacancies or publishing their profile.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _auth = TeachingAuth();
  bool _busy = false;
  bool _sent = false;

  Future<void> _check() async {
    setState(() => _busy = true);
    await _auth.reload();
    setState(() => _busy = false);
    if (_auth.isEmailVerified && mounted) {
      // Back to the account root, which routes to the right dashboard.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _resend() async {
    await _auth.sendEmailVerification();
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final email = _auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(s.verifyEmailTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.mark_email_read_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              s.verifyEmailBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                email,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _busy ? null : _check,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.checkVerification),
            ),
            TextButton(
              onPressed: _resend,
              child: Text(_sent ? s.verificationResent : s.resendEmail),
            ),
          ],
        ),
      ),
    );
  }
}
