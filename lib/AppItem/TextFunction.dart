import 'package:flutter/material.dart';

Widget customText(  String text, {
  double fontSize = 16.0,
  FontWeight fontWeight = FontWeight.normal,
  String fontFamily = 'Nunito',
  Color color = Colors.black,
  TextAlign textAlign = TextAlign.start,
}) {
  return Text(
    text,
    textAlign: textAlign,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      color: color,
    ),
  );
}