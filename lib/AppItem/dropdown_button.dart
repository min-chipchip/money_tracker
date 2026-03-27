import 'package:flutter/material.dart';

class MyDropdownButton extends StatelessWidget {
  final List<String> currentList;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final int? textSize;
  final bool? hideTriangularIcon;

  const MyDropdownButton({
    super.key,
    required this.currentList,
    required this.selectedValue,
    required this.onChanged,
    this.textSize,
    this.hideTriangularIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedValue,
      icon: ((hideTriangularIcon ?? false) ? SizedBox(width: 0) : Icon(Icons.arrow_drop_down, color: Colors.blue)),
      iconSize: (hideTriangularIcon ?? false) ? 0.0 : 24.0,
      isExpanded: true,
      underline: Container(),
      style: TextStyle(fontSize: (textSize ?? 21).toDouble(), fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Nunito'),
      onChanged: (val) => onChanged(val!),
      items: currentList.map((e) => DropdownMenuItem(
        value: e,
        child: Text(e, overflow: TextOverflow.ellipsis),
      )).toList(),
    );
  }
}
