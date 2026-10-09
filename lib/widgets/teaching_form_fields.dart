import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/l10n/app_localizations.dart';

/// Shared form building blocks for the teaching-module auth, profile and
/// vacancy forms: labeled fields with consistent validation styling.

String? requiredValidator(BuildContext context, String? value) {
  if ((value ?? '').trim().isEmpty) {
    return AppLocalizations.of(context).requiredField;
  }
  return null;
}

String? emailValidator(BuildContext context, String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return AppLocalizations.of(context).requiredField;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
    return AppLocalizations.of(context).invalidEmail;
  }
  return null;
}

String? passwordValidator(BuildContext context, String? value) {
  final text = value ?? '';
  if (text.isEmpty) return AppLocalizations.of(context).requiredField;
  if (text.length < 6) return AppLocalizations.of(context).passwordTooShort;
  return null;
}

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool obscureText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            obscureText: obscureText,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            validator: validator,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Comma-separated text field for list inputs (subjects, grade levels).
List<String> parseCsv(String raw) {
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
