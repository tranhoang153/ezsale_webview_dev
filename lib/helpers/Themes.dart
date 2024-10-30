import 'package:flutter/material.dart';

double figmaFullHeght = 844;
double figmaFullWidth = 390;

double perHeight(context, height) {
  return MediaQuery.of(context).size.height * height / figmaFullHeght;
}

double perWidth(context, width) {
  return MediaQuery.of(context).size.width * width / figmaFullWidth;
}

double fullHeight(context) {
  return MediaQuery.of(context).size.height;
}

double fullWidth(context) {
  return MediaQuery.of(context).size.width;
}
