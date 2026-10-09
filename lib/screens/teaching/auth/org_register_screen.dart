import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../models/teaching_accounts.dart';
import '../../../models/teaching_vacancy.dart';
import '../../../services/teaching_auth.dart';
import '../../../services/teaching_service.dart';
import '../../../widgets/teaching_form_fields.dart';
import 'verify_email_screen.dart';

/// Organization registration: Firebase email/password account +
/// institution profile (submitted as pending for admin review).
class OrgRegisterScreen extends StatefulWidget {
  const OrgRegisterScreen({super.key});

  @override
  State<OrgRegisterScreen> createState() => _OrgRegisterScreenState();
}

class _OrgRegisterScreenState extends State<OrgRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _type = 'School';
  String _district = AppConstants.kpDistricts.first;

  final _auth = TeachingAuth();
  final _service = TeachingService();
  bool _busy = false;
  String? _errorKey;

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final s = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      final credential = await _auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final uid = credential.user!.uid;
      await _service.saveOrganization(TeachingOrganization(
        id: '',
        ownerUid: uid,
        institutionName: _nameController.text.trim(),
        institutionType: _type,
        contactPerson: _contactPersonController.text.trim(),
        email: _emailController.text.trim(),
        district: _district,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        contactNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        approvalStatus: TeachingApproval.pending,
      ));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      }
    } catch (e) {
      setState(() => _errorKey = TeachingAuth.errorKey(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorText(AppLocalizations s) {
    switch (_errorKey) {
      case 'invalidEmail':
        return s.invalidEmail;
      case 'emailInUse':
        return s.emailInUse;
      case 'passwordTooShort':
        return s.passwordTooShort;
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
      appBar: AppBar(title: Text(s.iAmInstitution)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                label: s.institutionName,
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: (v) => requiredValidator(context, v),
              ),
              LabeledDropdown<String>(
                label: s.institutionType,
                value: _type,
                items: const ['School', 'Academy', 'College', 'Other']
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(_typeLabelStatic(t, s))))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'School'),
              ),
              LabeledTextField(
                label: s.contactPerson,
                controller: _contactPersonController,
                textCapitalization: TextCapitalization.words,
                validator: (v) => requiredValidator(context, v),
              ),
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
                validator: (v) => passwordValidator(context, v),
              ),
              LabeledDropdown<String>(
                label: s.district,
                value: _district,
                items: AppConstants.kpDistricts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _district = v ?? AppConstants.kpDistricts.first),
              ),
              LabeledTextField(
                label: s.city,
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
              ),
              LabeledTextField(
                label: s.address,
                controller: _addressController,
                maxLines: 2,
              ),
              LabeledTextField(
                label: s.contactNumber,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              if (_errorKey != null) ...[
                Text(
                  _errorText(s),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _busy ? null : _register,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.register),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _typeLabelStatic(String type, AppLocalizations s) {
    switch (type) {
      case 'Academy':
        return s.typeAcademy;
      case 'College':
        return s.typeCollege;
      case 'Other':
        return s.typeOther;
      case 'School':
      default:
        return s.typeSchool;
    }
  }
}
