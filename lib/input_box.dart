import 'package:flutter/material.dart';

Widget buildInputBox({String? label, IconData? icon, required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(35.0),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (label != null)
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        if (label != null) const SizedBox(height: 4),
        child,
      ],
    ),
  );
}
