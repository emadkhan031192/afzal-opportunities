import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../services/teaching_auth.dart';
import '../services/teaching_service.dart';

/// "Delete account" flow for the teaching module (Play Store
/// data-deletion requirement). Shows a confirmation dialog, then deletes
/// the user's Firestore data and their Firebase Auth account.
class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({
    super.key,
    required this.auth,
    required this.service,
  });

  final TeachingAuth auth;
  final TeachingService service;

  Future<void> _confirmAndDelete(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteAccount),
        content: Text(s.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(s.deleteAccount),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await service.deleteMyAccountData(uid);
      await auth.deleteAccount();
      if (context.mounted) {
        Navigator.of(context)
          ..pop() // close progress
          ..popUntil((r) => r.isFirst);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.accountDeleted)));
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close progress
        final message = e.code == 'requires-recent-login'
            ? s.deleteAccountRelogin
            : s.somethingWentWrong;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close progress
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.somethingWentWrong)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
      tooltip: s.deleteAccount,
      onPressed: () => _confirmAndDelete(context),
    );
  }
}
