import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/app_theme.dart';

/// White rounded box with an optional small label (and icon) above its content.
class InputBox extends StatelessWidget {
  const InputBox({super.key, this.label, this.icon, required this.child});

  final String? label;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.boxRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label!, style: AppText.label),
              ],
            ),
            const SizedBox(height: 4),
          ],
          child,
        ],
      ),
    );
  }
}
