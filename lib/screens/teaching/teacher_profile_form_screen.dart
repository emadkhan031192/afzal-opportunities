import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/teaching_accounts.dart';
import '../../models/teaching_vacancy.dart';
import '../../services/teaching_auth.dart';
import '../../services/teaching_service.dart';
import '../../widgets/teaching_form_fields.dart';

/// Edit an existing teacher profile. The approval status can never be
/// escalated here — the service strips it from updates.
class TeacherProfileFormScreen extends StatefulWidget {
  const TeacherProfileFormScreen({super.key, required this.existing});

  final TeacherProfile existing;

  @override
  State<TeacherProfileFormScreen> createState() =>
      _TeacherProfileFormScreenState();
}

class _TeacherProfileFormScreenState extends State<TeacherProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _qualificationController;
  late final TextEditingController _subjectsController;
  late final TextEditingController _experienceController;
  late final TextEditingController _summaryController;
  late String _district;
  late String _employmentType;
  late String _visibility;

  final _service = TeachingService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameController = TextEditingController(text: p.fullName);
    _qualificationController = TextEditingController(
      text: p.qualification ?? '',
    );
    _subjectsController = TextEditingController(text: p.subjects.join(', '));
    _experienceController = TextEditingController(
      text: p.experienceYears != null ? '${p.experienceYears}' : '',
    );
    _summaryController = TextEditingController(
      text: p.professionalSummary ?? '',
    );
    _district = p.district;
    _employmentType = p.preferredEmploymentType ?? 'Full-time';
    _visibility = p.profileVisibility;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qualificationController.dispose();
    _subjectsController.dispose();
    _experienceController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final p = widget.existing;
      await _service.saveProfile(
        TeacherProfile(
          id: p.id,
          ownerUid: p.ownerUid,
          fullName: _nameController.text.trim(),
          email: p.email,
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
          cvStoragePath: p.cvStoragePath,
          profileVisibility: _visibility,
          approvalStatus: p.approvalStatus,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.profileSaved)));
        Navigator.of(context).pop(true);
      }
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
      appBar: AppBar(title: Text(s.edit)),
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
                label: s.subject,
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
              LabeledDropdown<String>(
                label: s.profileVisibilityLabel,
                value: _visibility,
                items: [
                  DropdownMenuItem(
                    value: 'private',
                    child: Text(s.visibilityPrivate),
                  ),
                  DropdownMenuItem(
                    value: 'public',
                    child: Text(s.visibilityPublic),
                  ),
                ],
                onChanged: (v) => setState(() => _visibility = v ?? 'private'),
              ),
              Text(
                s.visibilityPublicNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.saveProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
