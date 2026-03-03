import 'package:flutter/material.dart';

class MyDropdownButton extends StatelessWidget {
  final List<String> currentList;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const MyDropdownButton({
    super.key,
    required this.currentList,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedValue,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
      isExpanded: true,
      underline: Container(),
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Nunito'),
      onChanged: (val) => onChanged(val!),
      items: currentList.map((e) => DropdownMenuItem(
        value: e,
        child: Text(e, overflow: TextOverflow.ellipsis),
      )).toList(),
    );
  }
}
