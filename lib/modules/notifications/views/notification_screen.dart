import 'package:flutter/material.dart';

import '../../../core/db/scan_repository.dart';
import '../../../core/db/user_repository.dart';
import '../../scan/views/scanner_screen.dart';
import '../controller/notification_controller.dart';
import '../widgets/notification_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = NotificationController(ScanRepository());
    controller.addListener(_refresh);
    _loadNotifications();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadNotifications() async {
    final user = await UserRepository().getCurrentUser();
    if (!mounted) return;

    if (user != null) {
      await controller.loadNotifications(user.userId);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : controller.alerts.isEmpty
              ? const _EmptyNotifications()
              : RefreshIndicator(
                  color: colors.primary,
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: controller.alerts.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> alert =
                          controller.alerts[index];

                      return NotificationCard(
                        disease: alert['disease']! as String,
                        severity: alert['severity']! as String,
                        date: alert['date']! as String,
                        onIgnore: () async {
                          await controller.dismissAlert(index);
                        },
                        onRescan: () async {
                          await controller.rescanAlert(index);

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const ScannerScreen(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 36,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "You're all caught up",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'New cacao scan reminders will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
