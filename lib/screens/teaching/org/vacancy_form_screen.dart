import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../models/teaching_vacancy.dart';
import '../../../services/teaching_auth.dart';
import '../../../services/teaching_service.dart';
import '../../../widgets/teaching_form_fields.dart';
import '../auth/verify_email_screen.dart';

/// Vacancy submission / edit form for organizations.
///
/// New vacancies are always submitted as pending; editing an approved
/// vacancy sends it back for re-approval (see TeachingService).
/// Requires a verified email before submitting.
class VacancyFormScreen extends StatefulWidget {
  const VacancyFormScreen({super.key, this.existing});

  final TeachingVacancy? existing;

  @override
  State<VacancyFormScreen> createState() => _VacancyFormScreenState();
}

class _VacancyFormScreenState extends State<VacancyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _subjectsController = TextEditingController();
  final _gradesController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _positionsController = TextEditingController(text: '1');
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _appUrlController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();

  String _district = AppConstants.kpDistricts.first;
  String _employmentType = 'Full-time';
  String _gender = 'Any';
  bool _enableCall = false;
  bool _enableWhatsapp = false;
  bool _enableEmail = false;
  DateTime? _deadline;

  final _auth = TeachingAuth();
  final _service = TeachingService();
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    if (v != null) {
      _titleController.text = v.jobTitle;
      _cityController.text = v.city ?? '';
      _subjectsController.text = v.subjects.join(', ');
      _gradesController.text = v.gradeLevels.join(', ');
      _qualificationController.text = v.qualification;
      _experienceController.text = v.experienceRequired ?? '';
      _positionsController.text = '${v.positionsCount}';
      if (v.salaryMin != null) _salaryMinController.text = '${v.salaryMin}';
      if (v.salaryMax != null) _salaryMaxController.text = '${v.salaryMax}';
      _descriptionController.text = v.description;
      _appUrlController.text = v.applicationUrl ?? '';
      _contactController.text = v.contactInstructions ?? '';
      _phoneController.text = v.applyPhone ?? '';
      _whatsappController.text = v.applyWhatsapp ?? '';
      _emailController.text = v.applyEmail ?? '';
      _district = v.district;
      _employmentType = v.employmentType ?? 'Full-time';
      _gender = v.genderEligibility ?? 'Any';
      _enableCall = v.enableCall;
      _enableWhatsapp = v.enableWhatsapp;
      _enableEmail = v.enableEmail;
      // Legacy vacancies used the old method dropdown; map it onto the
      // new toggles so editing them preserves the previous behavior.
      if (!v.enableCall && !v.enableWhatsapp && !v.enableEmail) {
        final m = v.applicationMethod;
        if (m == 'contact' || m == 'both') _enableCall = true;
      }
      _deadline = v.applicationDeadline;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _subjectsController.dispose();
    _gradesController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _positionsController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _descriptionController.dispose();
    _appUrlController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final s = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: s.applicationDeadline,
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    final s = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (!_auth.isEmailVerified) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const VerifyEmailScreen()));
      return;
    }
    // At least one enabled channel with valid details is required.
    final phoneOk =
        _enableCall &&
        TeachingVacancy.isValidPhone(_phoneController.text.trim());
    final waOk =
        _enableWhatsapp &&
        TeachingVacancy.isValidPhone(_whatsappController.text.trim());
    final emailOk =
        _enableEmail &&
        TeachingVacancy.isValidEmail(_emailController.text.trim());
    final legacyOk =
        _appUrlController.text.trim().isNotEmpty ||
        _contactController.text.trim().isNotEmpty;
    if (!phoneOk && !waOk && !emailOk && !legacyOk) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.applyMethodRequired)));
      return;
    }
    if (_enableCall && !phoneOk) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.invalidPhone)));
      return;
    }
    if (_enableWhatsapp && !waOk) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.invalidPhone)));
      return;
    }
    if (_enableEmail && !emailOk) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.invalidEmail)));
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = _auth.currentUser!.uid;
      // Institution name is denormalized for public cards; refresh it
      // from the organization's profile at submit time.
      final org = await _service.getMyOrganization(uid);
      final institutionName = org?.institutionName ?? '';
      final vacancy = TeachingVacancy(
        id: widget.existing?.id ?? '',
        organizationId: org?.id ?? '',
        ownerUid: uid,
        jobTitle: _titleController.text.trim(),
        institutionName: institutionName,
        district: _district,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        subjects: parseCsv(_subjectsController.text),
        gradeLevels: parseCsv(_gradesController.text),
        qualification: _qualificationController.text.trim(),
        experienceRequired: _experienceController.text.trim().isEmpty
            ? null
            : _experienceController.text.trim(),
        positionsCount: int.tryParse(_positionsController.text.trim()) ?? 1,
        salaryMin: _salaryMinController.text.trim().isEmpty
            ? null
            : int.tryParse(_salaryMinController.text.trim()),
        salaryMax: _salaryMaxController.text.trim().isEmpty
            ? null
            : int.tryParse(_salaryMaxController.text.trim()),
        employmentType: _employmentType,
        genderEligibility: _gender == 'Any' ? null : _gender,
        description: _descriptionController.text.trim(),
        applicationDeadline: _deadline,
        applicationMethod: null,
        applicationUrl: _appUrlController.text.trim().isEmpty
            ? null
            : _appUrlController.text.trim(),
        contactInstructions: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        applyPhone: _enableCall && _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        applyWhatsapp:
            _enableWhatsapp && _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : null,
        applyEmail: _enableEmail && _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        enableCall: _enableCall,
        enableWhatsapp: _enableWhatsapp,
        enableEmail: _enableEmail,
        approvalStatus: TeachingApproval.pending,
      );
      if (_isEdit) {
        await _service.updateVacancy(vacancy);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(s.vacancyUpdated)));
        }
      } else {
        await _service.submitVacancy(vacancy);
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(s.vacancySubmitted),
              content: Text(s.vacancySubmittedDesc),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.ok),
                ),
              ],
            ),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.unknownError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? s.editVacancy : s.postVacancy)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                label: s.jobTitleLabel,
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                validator: (v) => requiredValidator(context, v),
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
                label: s.city,
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
              ),
              LabeledTextField(
                label: '${s.subject} *',
                controller: _subjectsController,
                hint: 'Mathematics, English',
                validator: (v) =>
                    parseCsv(v ?? '').isEmpty ? s.requiredField : null,
              ),
              LabeledTextField(
                label: s.gradeLevels,
                controller: _gradesController,
                hint: '9, 10',
              ),
              LabeledTextField(
                label: s.qualification,
                controller: _qualificationController,
                validator: (v) => requiredValidator(context, v),
              ),
              LabeledTextField(
                label: s.experienceRequired,
                controller: _experienceController,
                hint: 'e.g. 2 years teaching experience',
              ),
              LabeledTextField(
                label: s.positionsCount,
                controller: _positionsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => requiredValidator(context, v),
              ),
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: s.salaryMin,
                      controller: _salaryMinController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      hint: s.salaryOptional,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledTextField(
                      label: s.salaryMax,
                      controller: _salaryMaxController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      hint: s.salaryOptional,
                    ),
                  ),
                ],
              ),
              LabeledDropdown<String>(
                label: s.employmentType,
                value: _employmentType,
                items: const ['Full-time', 'Part-time', 'Visiting', 'Contract']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _employmentType = v ?? 'Full-time'),
              ),
              LabeledDropdown<String>(
                label: s.genderEligibility,
                value: _gender,
                items: const ['Any', 'Male', 'Female']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v ?? 'Any'),
              ),
              LabeledTextField(
                label: s.jobDescription,
                controller: _descriptionController,
                maxLines: 5,
                validator: (v) => requiredValidator(context, v),
              ),
              _DeadlineField(
                deadline: _deadline,
                onPick: _pickDeadline,
                onClear: () => setState(() => _deadline = null),
              ),
              _ChannelToggle(
                icon: Icons.call_outlined,
                title: s.applyByCall,
                enabled: _enableCall,
                onChanged: (v) => setState(() => _enableCall = v),
              ),
              if (_enableCall)
                LabeledTextField(
                  label: s.phoneNumber,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  hint: '0316 1185662',
                ),
              _ChannelToggle(
                icon: Icons.chat_outlined,
                title: s.applyByWhatsapp,
                enabled: _enableWhatsapp,
                onChanged: (v) => setState(() => _enableWhatsapp = v),
              ),
              if (_enableWhatsapp)
                LabeledTextField(
                  label: s.whatsappNumber,
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  hint: '0316 1185662',
                ),
              _ChannelToggle(
                icon: Icons.email_outlined,
                title: s.applyByEmail,
                enabled: _enableEmail,
                onChanged: (v) => setState(() => _enableEmail = v),
              ),
              if (_enableEmail)
                LabeledTextField(
                  label: s.emailAddress,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'school@example.com',
                ),
              LabeledTextField(
                label: s.applicationUrlOptional,
                controller: _appUrlController,
                keyboardType: TextInputType.url,
              ),
              LabeledTextField(
                label: s.contactInstructionsOptional,
                controller: _contactController,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? s.save : s.submit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelToggle extends StatelessWidget {
  const _ChannelToggle({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SwitchListTile(
        value: enabled,
        onChanged: onChanged,
        secondary: Icon(icon, color: BrandColors.mintDark),
        title: Text(title, style: Theme.of(context).textTheme.labelLarge),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}

class _DeadlineField extends StatelessWidget {
  const _DeadlineField({
    required this.deadline,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? deadline;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.applicationDeadline,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    deadline != null
                        ? DateFormat('d MMMM yyyy').format(deadline!)
                        : s.selectDate,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (deadline != null) ...[
                const SizedBox(width: 8),
                TextButton(onPressed: onClear, child: Text(s.clearDate)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
