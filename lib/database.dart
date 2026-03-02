import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

List<String> category = <String>['Food', 'Drink', 'Education', 'Social Life', 'Apparels'];
List<String> account = <String>['Cash', 'Credit Card', 'Bank Account'];

const List<Widget> _pages = <Widget>[
  Text("Home Page"),
  Text("Statistics Page"),
  Text("Insights Page"),
  Text("Receipt Scan Page"),
  Text("QnA"),
  Text("Settings")
];

int rating = 3;
int selected_page = 0;

void addCategory(List<String> currentList, String newCategory){
  if(!currentList.contains(newCategory)) {
    currentList.add(newCategory);
  }
}

void deleteCategory(List<String> currentList, String deleteCategory){
  currentList.remove(deleteCategory);
}