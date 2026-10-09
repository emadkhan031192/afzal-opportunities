import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../services/teaching_auth.dart';
import '../../../widgets/teaching_form_fields.dart';

/// Email/password login for teaching-module accounts.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = TeachingAuth();
  bool _busy = false;
  String? _errorKey;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      await _auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorKey = TeachingAuth.errorKey(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final s = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorKey = 'invalidEmail');
      return;
    }
    try {
      await _auth.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.resetLinkSent)),
        );
      }
    } catch (e) {
      setState(() => _errorKey = TeachingAuth.errorKey(e));
    }
  }

  String _errorText(AppLocalizations s) {
    switch (_errorKey) {
      case 'invalidEmail':
        return s.invalidEmail;
      case 'loginFailed':
        return s.loginFailed;
      case 'tooManyRequests':
        return s.tooManyRequests;
      case 'networkError':
        return s.networkError;
      default:
        return s.unknownError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.login)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                label: s.email,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => emailValidator(context, v),
              ),
              LabeledTextField(
                label: s.password,
                controller: _passwordController,
                obscureText: true,
                validator: (v) => requiredValidator(context, v),
              ),
              if (_errorKey != null) ...[
                Text(
                  _errorText(s),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _busy ? null : _login,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.login),
              ),
              TextButton(
                onPressed: _busy ? null : _forgotPassword,
                child: Text(s.forgotPassword),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
