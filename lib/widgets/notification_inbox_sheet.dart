import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../services/notification_service.dart';

/// In-app notification inbox: shows the log of fired notifications
/// (newest first). Opened from the header bell; viewing it marks all
/// entries as read and clears the bell dot.
class NotificationInboxSheet extends StatelessWidget {
  const NotificationInboxSheet({super.key, required this.service});

  final NotificationService service;

  static Future<void> show(
    BuildContext context,
    NotificationService service,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => NotificationInboxSheet(service: service),
      ),
    );
    await service.markInboxRead();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<List<({DateTime at, String title, String body})>>(
      future: service.getInbox(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    s.notifications,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: dark ? Colors.white38 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s.noNotificationsYet,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: dark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            item.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            _timeAgo(item.at),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _timeAgo(DateTime at) {
    final diff = DateTime.now().toUtc().difference(at);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
