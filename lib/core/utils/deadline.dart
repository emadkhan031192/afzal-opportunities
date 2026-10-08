/// Pure, testable deadline logic for Afzal Opportunities advertisements.
///
/// All calculations use Pakistan Standard Time (PKT, Asia/Karachi), a fixed
/// UTC+5 offset with no daylight-saving changes. A [lastDate] is a date-only
/// value: an advertisement stays active through 23:59:59 PKT on its last
/// date, and expires only once the next PKT day begins.
///
/// This file is intentionally free of Flutter widget dependencies so it can
/// be unit-tested in isolation.

/// Visual tone for a deadline badge.
enum DeadlineTone {
  /// No deadline information (e.g. "LAST DATE NOT SPECIFIED").
  neutral,

  /// Informational highlight.
  info,

  /// Positive state (plenty of time left).
  success,

  /// Attention needed (closing within a week).
  warning,

  /// Urgent or terminal (closing today / expired).
  danger,
}

/// Describes how an advertisement's deadline should be presented.
class DeadlineInfo {
  const DeadlineInfo({
    required this.label,
    required this.isExpired,
    required this.isNew,
    required this.daysLeft,
    required this.tone,
  });

  /// Human-readable deadline label, e.g. "5 DAYS LEFT".
  final String label;

  /// Whether the deadline has passed.
  final bool isExpired;

  /// Whether the advertisement counts as recently published (and is active).
  final bool isNew;

  /// Whole days from today (PKT) to the last date, or null when unspecified.
  final int? daysLeft;

  /// Suggested visual tone for the badge.
  final DeadlineTone tone;
}

/// Returns [now] (defaulting to the current time) in PKT (UTC+5, no DST).
DateTime pktNow([DateTime? now]) {
  return (now ?? DateTime.now()).toUtc().add(const Duration(hours: 5));
}

/// Computes the [DeadlineInfo] for an advertisement.
///
/// - [lastDate]: date-only deadline; null means "not specified".
/// - [publishedAt]: when the advertisement was published (for the NEW badge).
/// - [now]: injectable clock for tests; defaults to [DateTime.now].
DeadlineInfo getDeadlineInfo({
  DateTime? lastDate,
  DateTime? publishedAt,
  DateTime? now,
}) {
  final pkt = pktNow(now);
  final today = DateTime(pkt.year, pkt.month, pkt.day);

  if (lastDate == null) {
    return DeadlineInfo(
      label: 'LAST DATE NOT SPECIFIED',
      isExpired: false,
      isNew: _isNew(publishedAt: publishedAt, reference: pkt, active: true),
      daysLeft: null,
      tone: DeadlineTone.neutral,
    );
  }

  final target = DateTime(lastDate.year, lastDate.month, lastDate.day);
  final daysLeft = target.difference(today).inDays;

  if (daysLeft < 0) {
    return DeadlineInfo(
      label: 'EXPIRED',
      isExpired: true,
      isNew: false,
      daysLeft: daysLeft,
      tone: DeadlineTone.danger,
    );
  }

  final isNew = _isNew(publishedAt: publishedAt, reference: pkt, active: true);

  if (daysLeft == 0) {
    return DeadlineInfo(
      label: 'LAST DATE TODAY',
      isExpired: false,
      isNew: isNew,
      daysLeft: 0,
      tone: DeadlineTone.danger,
    );
  }
  if (daysLeft == 1) {
    return DeadlineInfo(
      label: 'CLOSING TOMORROW',
      isExpired: false,
      isNew: isNew,
      daysLeft: 1,
      tone: DeadlineTone.warning,
    );
  }
  if (daysLeft <= 7) {
    return DeadlineInfo(
      label: 'CLOSING SOON',
      isExpired: false,
      isNew: isNew,
      daysLeft: daysLeft,
      tone: DeadlineTone.warning,
    );
  }
  return DeadlineInfo(
    label: '$daysLeft DAYS LEFT',
    isExpired: false,
    isNew: isNew,
    daysLeft: daysLeft,
    tone: DeadlineTone.success,
  );
}

/// An advertisement counts as NEW when it was published within the last
/// 72 hours, is not from the future, and is still active.
bool _isNew({
  required DateTime? publishedAt,
  required DateTime reference,
  required bool active,
}) {
  if (!active || publishedAt == null) {
    return false;
  }
  final age = reference.difference(publishedAt.toUtc());
  return !age.isNegative && age.inHours < 72;
}
