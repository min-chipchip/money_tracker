import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/app_theme.dart';

class MyDropdownButton extends StatelessWidget {
  const MyDropdownButton({
    super.key,
    required this.currentList,
    required this.selectedValue,
    required this.onChanged,
    this.showArrow = true,
  });

  final List<String> currentList;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedValue,
      icon: showArrow
          ? const Icon(Icons.arrow_drop_down, color: AppColors.primary)
          : const SizedBox.shrink(),
      iconSize: showArrow ? 24 : 0,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      style: AppText.title.copyWith(
        color: Colors.black,
        fontFamily: AppText.fontFamily,
      ),
      onChanged: (val) => onChanged(val!),
      items: currentList
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
    );
  }
}
