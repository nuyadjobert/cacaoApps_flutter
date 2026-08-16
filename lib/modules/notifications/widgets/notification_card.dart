import 'package:cacao_apps/core/utils/disease_name_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final String disease;
  final String severity;
  final String date;
  final VoidCallback onRescan;
  final VoidCallback onIgnore;

  const NotificationCard({
    super.key,
    required this.disease,
    required this.severity,
    required this.date,
    required this.onRescan,
    required this.onIgnore,
  });

  Color _severityColor(ColorScheme colors) {
    switch (severity.toLowerCase()) {
      case 'severe':
      case 'high':
        return colors.error;
      case 'moderate':
        return colors.tertiary;
      default:
        return colors.primary;
    }
  }

  String _formatNotificationDate() {
    final DateTime? parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) return 'Date unavailable';

    final DateTime dt = parsedDate.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime alertDay = DateTime(dt.year, dt.month, dt.day);
    final String time = DateFormat('h:mm a').format(dt);

    if (alertDay == today) return 'Today \u2022 $time';
    if (alertDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday \u2022 $time';
    }

    return DateFormat('MMM d, yyyy \u2022 h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = _severityColor(colors);
    final String displayDisease = formatDiseaseName(disease);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.health_and_safety_outlined,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayDisease,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _formatNotificationDate(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SeverityBadge(
                  severity: severity,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool useVerticalActions = constraints.maxWidth < 300;
                final Widget dismissButton = OutlinedButton.icon(
                  onPressed: onIgnore,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Dismiss'),
                );
                final Widget rescanButton = FilledButton.icon(
                  onPressed: onRescan,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Rescan'),
                );

                if (useVerticalActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      rescanButton,
                      const SizedBox(height: 8),
                      dismissButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: dismissButton),
                    const SizedBox(width: 10),
                    Expanded(child: rescanButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color color;

  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        severity.trim().toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}
