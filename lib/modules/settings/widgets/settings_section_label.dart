import 'package:flutter/material.dart';

class SettingsSectionLabel extends StatelessWidget {
  final String label;
  final Color textMuted;

  const SettingsSectionLabel({
    super.key,
    required this.label,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textMuted,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}