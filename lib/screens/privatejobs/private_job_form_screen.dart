import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/brand_colors.dart';
import '../../models/private_job.dart';
import '../../models/teaching_vacancy.dart' show TeachingApproval;
import '../../services/private_job_service.dart';
import '../../services/teaching_auth.dart';
import '../../services/teaching_service.dart';
import '../../widgets/teaching_form_fields.dart';
import '../teaching/auth/verify_email_screen.dart';

/// Private-job submission / edit form for organizations.
///
/// Mirrors [VacancyFormScreen]: new jobs are always submitted as pending;
/// editing an approved job sends it back for re-approval (see
/// PrivateJobService). Requires a verified email before submitting.
/// At least one enabled apply channel with valid details is required.
class PrivateJobFormScreen extends StatefulWidget {
  const PrivateJobFormScreen({super.key, this.existing});

  final PrivateJob? existing;

  @override
  State<PrivateJobFormScreen> createState() => _PrivateJobFormScreenState();
}

class _PrivateJobFormScreenState extends State<PrivateJobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();

  String _city = AppConstants.kpkJobCities.first;
  bool _enableCall = false;
  bool _enableWhatsapp = false;
  bool _enableEmail = false;
  DateTime? _deadline;

  final _auth = TeachingAuth();
  final _service = PrivateJobService();
  final _teachingService = TeachingService();
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final j = widget.existing;
    if (j != null) {
      _titleController.text = j.title;
      _companyController.text = j.company;
      _descriptionController.text = j.description;
      _salaryController.text = j.salary ?? '';
      _city = AppConstants.kpkJobCities.contains(j.city)
          ? j.city
          : AppConstants.kpkJobCities.first;
      _enableCall = j.enableCall;
      _enableWhatsapp = j.enableWhatsapp;
      _enableEmail = j.enableEmail;
      _deadline = j.deadline;
      // Dashboard rows carry public docs only (no contact details), so
      // fetch the private contacts to prefill the form — otherwise
      // saving an edit would wipe them.
      _service.getJobContact(j.id).then((contact) {
        if (mounted && contact != null) {
          setState(() {
            _phoneController.text = contact.applyPhone ?? '';
            _whatsappController.text = contact.applyWhatsapp ?? '';
            _emailController.text = contact.applyEmail ?? '';
          });
        }
      });
    } else {
      // Prefill the company name from the organization's profile; the
      // poster may still edit it before submitting.
      _teachingService.getMyOrganization(_auth.currentUser?.uid ?? '').then((
        org,
      ) {
        if (mounted && org != null) {
          setState(() => _companyController.text = org.institutionName);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
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
        _enableCall && PrivateJob.isValidPhone(_phoneController.text.trim());
    final waOk =
        _enableWhatsapp &&
        PrivateJob.isValidPhone(_whatsappController.text.trim());
    final emailOk =
        _enableEmail && PrivateJob.isValidEmail(_emailController.text.trim());
    if (!phoneOk && !waOk && !emailOk) {
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
      final org = await _teachingService.getMyOrganization(uid);
      final job = PrivateJob(
        id: widget.existing?.id ?? '',
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        city: _city,
        description: _descriptionController.text.trim(),
        salary: _salaryController.text.trim().isEmpty
            ? null
            : _salaryController.text.trim(),
        deadline: _deadline,
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
        active: widget.existing?.active ?? true,
        postedBy: uid,
        postedByType: 'company',
        organizationId: org?.id,
      );
      if (_isEdit) {
        await _service.updateJob(job);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(s.privateJobUpdated)));
        }
      } else {
        await _service.submitJob(job);
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(s.privateJobSubmitted),
              content: Text(s.privateJobSubmittedDesc),
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
      appBar: AppBar(
        title: Text(_isEdit ? s.editPrivateJob : s.postPrivateJob),
      ),
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
              LabeledTextField(
                label: s.company,
                controller: _companyController,
                textCapitalization: TextCapitalization.words,
                validator: (v) => requiredValidator(context, v),
              ),
              LabeledDropdown<String>(
                label: s.city,
                value: _city,
                items: AppConstants.kpkJobCities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(
                  () => _city = v ?? AppConstants.kpkJobCities.first,
                ),
              ),
              LabeledTextField(
                label: s.jobDescription,
                controller: _descriptionController,
                maxLines: 5,
                validator: (v) => requiredValidator(context, v),
              ),
              LabeledTextField(
                label: s.salary,
                controller: _salaryController,
                hint: s.salaryOptional,
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
                  hint: 'company@example.com',
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
