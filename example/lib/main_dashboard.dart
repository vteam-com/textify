// ignore_for_file: unnecessary_this

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'home_screen.dart';

/// The entry point of the application. Runs the [MainApp] widget.
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Textify',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const ui.Color.fromRGBO(41, 79, 138, 1),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
