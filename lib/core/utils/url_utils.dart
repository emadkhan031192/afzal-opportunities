import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Returns true when [raw] is a safe, openable web URL.
///
/// Only `http`/`https` URLs with a non-empty host are accepted. Anything
/// else — deep links, `javascript:` pseudo-URLs, malformed text — is
/// rejected so advertisement text can never be treated as executable code.
bool isSafeHttpUrl(String? raw) {
  if (raw == null) {
    return false;
  }
  final text = raw.trim();
  if (text.isEmpty) {
    return false;
  }
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasScheme) {
    return false;
  }
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    return false;
  }
  if (!uri.hasAuthority || uri.host.isEmpty) {
    return false;
  }
  return true;
}

/// Opens [raw] in the external browser when it passes [isSafeHttpUrl].
///
/// Returns true when the URL was launched, false otherwise (unsafe URL,
/// launch failure, or platform error). Never throws.
Future<bool> openUrl(String? raw) async {
  if (!isSafeHttpUrl(raw)) {
    debugPrint('Blocked unsafe URL: $raw');
    return false;
  }
  final uri = Uri.parse(raw!.trim());
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (error) {
    debugPrint('Failed to launch URL $uri: $error');
    return false;
  }
}
