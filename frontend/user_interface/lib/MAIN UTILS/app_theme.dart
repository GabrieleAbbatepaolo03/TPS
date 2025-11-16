import 'package:flutter/material.dart';

class AppTheme {
  

  static const BoxDecoration backgroundGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Color.fromARGB(255, 52, 12, 108), 
        Color.fromARGB(255, 2, 11, 60),  
      ],
    ),
  );

}