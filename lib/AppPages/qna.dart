import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/common_widgets.dart';

class MyQnAForm extends StatelessWidget {
  const MyQnAForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.question_answer,
      title: 'QnA',
      message: 'Your QnA will appear here.',
    );
  }
}
