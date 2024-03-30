import 'package:flutter/material.dart';

enum Categories {
  vegetables,
  fruits,
  meat,
  dairy,
  carbs,
  sweets,
  spices,
  convenience,
  hygiene,
  others
}

class Category {
  Category(this.title,this.color);

  final String title;
  final Color color;
}
 