import 'package:flutter/material.dart';
import 'package:money_tracker/AppItem/app_theme.dart';

/// Dropdown over any type of value. [labelOf] turns a value into the text
/// shown, so values can be database ids while the user sees names.
class MyDropdownButton<T> extends StatelessWidget {
  const MyDropdownButton({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.labelOf,
    this.showArrow = true,
  });

  final List<T> items;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelOf;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
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
      onChanged: (val) => onChanged(val as T),
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item,
            child: Text(labelOf?.call(item) ?? '$item', overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}
