import 'package:flutter/material.dart';

class AppColors {
  static const Color colordark = Color.fromRGBO(37, 14, 51, 1);
  static const Color colorlight = Color.fromARGB(255, 63, 19, 88);
  static const Color accentColor = Color(0xFF351452);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.center,
    end: Alignment.bottomCenter,
    colors: [colorlight, colordark],
  );
}
