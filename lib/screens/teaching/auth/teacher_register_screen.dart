import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../models/teaching_accounts.dart';
import '../../../models/teaching_vacancy.dart';
import '../../../services/teaching_auth.dart';
import '../../../services/teaching_service.dart';
import '../../../widgets/teaching_form_fields.dart';
import 'verify_email_screen.dart';

/// Teacher registration: Firebase email/password account + teacher
/// profile (private by default, pending admin review).
class TeacherRegisterScreen extends StatefulWidget {
  const TeacherRegisterScreen({super.key, this.returnVacancy});

  /// When set, registration was triggered from a job's apply flow;
  /// on success the screen pops with `true` so the caller returns the
  /// applicant to that job.
  final TeachingVacancy? returnVacancy;

  @override
  State<TeacherRegisterScreen> createState() => _TeacherRegisterScreenState();
}

class _TeacherRegisterScreenState extends State<TeacherRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _subjectsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _summaryController = TextEditingController();
  String _district = AppConstants.kpDistricts.first;
  String _employmentType = 'Full-time';

  final _auth = TeachingAuth();
  final _service = TeachingService();
  bool _busy = false;
  String? _errorKey;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _qualificationController.dispose();
    _subjectsController.dispose();
    _experienceController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
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
      await _service.saveProfile(
        TeacherProfile(
          id: '',
          ownerUid: uid,
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          district: _district,
          qualification: _qualificationController.text.trim().isEmpty
              ? null
              : _qualificationController.text.trim(),
          subjects: parseCsv(_subjectsController.text),
          experienceYears: int.tryParse(_experienceController.text.trim()),
          preferredEmploymentType: _employmentType,
          professionalSummary: _summaryController.text.trim().isEmpty
              ? null
              : _summaryController.text.trim(),
          approvalStatus: TeachingApproval.pending,
        ),
      );
      if (mounted) {
        if (widget.returnVacancy != null) {
          // Guest apply flow: verify email, then return to the job.
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const VerifyEmailScreen()));
          if (mounted) Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
          );
        }
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
      appBar: AppBar(title: Text(s.iAmTeacher)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                label: s.fullName,
                controller: _nameController,
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
                onChanged: (v) => setState(
                  () => _district = v ?? AppConstants.kpDistricts.first,
                ),
              ),
              LabeledTextField(
                label: s.qualification,
                controller: _qualificationController,
                textCapitalization: TextCapitalization.words,
              ),
              LabeledTextField(
                label: '${s.subject} (${s.anyOption}: Mathematics, English)',
                controller: _subjectsController,
                hint: 'Mathematics, English, Physics',
              ),
              LabeledTextField(
                label: s.experienceYears,
                controller: _experienceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              LabeledDropdown<String>(
                label: s.preferredEmploymentType,
                value: _employmentType,
                items: const ['Full-time', 'Part-time', 'Visiting', 'Any']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _employmentType = v ?? 'Full-time'),
              ),
              LabeledTextField(
                label: s.professionalSummary,
                controller: _summaryController,
                maxLines: 3,
              ),
              if (_errorKey != null) ...[
                Text(
                  _errorText(s),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
}
