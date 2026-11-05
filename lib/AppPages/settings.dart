import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';

class MySettingsForm extends StatelessWidget {
  const MySettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.settings,
      title: 'Settings',
      message: 'Your settings will appear here.',
    );
  }
}
