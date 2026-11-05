import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/app_theme.dart';

/// Big icon + title + message, centered. Used for empty lists and placeholder pages.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.pie_chart_rounded,
    this.title = 'No Data Yet',
    this.message = 'Add some entries to see your statistics.',
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(title, style: AppText.headline),
            const SizedBox(height: 10),
            Text(message, style: AppText.bodyMuted, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Full-width rounded blue button with an icon.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.check_circle,
  });

  final String label;

  /// Null shows the button disabled.
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.boxRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(label, style: AppText.title),
        ],
      ),
    );
  }
}

/// Star icon that is filled (yellow) when [isOn], outlined (grey) when off.
class StarButton extends StatelessWidget {
  const StarButton({super.key, required this.isOn, required this.onPressed, this.size = 24});

  final bool isOn;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isOn ? Icons.star : Icons.star_border,
        color: isOn ? AppColors.star : AppColors.starOff,
        size: size,
      ),
    );
  }
}

/// Row of numbered circles (1..[max]); every circle up to [value] is highlighted.
class RatingPicker extends StatelessWidget {
  const RatingPicker({super.key, required this.value, required this.onChanged, this.max = 5});

  final int value;
  final ValueChanged<int> onChanged;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var n = 1; n <= max; n++)
          // Circles are 35px, but shrink on narrow screens instead of overflowing.
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 35, maxHeight: 35),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GestureDetector(
                    onTap: () => onChanged(n),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: n <= value ? AppColors.primary : AppColors.inactive,
                      ),
                      child: Text(
                        '$n',
                        style: AppText.strong.copyWith(
                          color: n <= value ? Colors.white : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Full-screen page with a Return button and a big blue title above [child].
/// Used by the edit and deposit pages.
class FormPage extends StatelessWidget {
  const FormPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: Colors.black,
              ),
              child: const Text('Return', style: AppText.title),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 30, AppSpacing.page, 20),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: AppText.body.copyWith(color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      duration: const Duration(seconds: 2),
    ),
  );
}
