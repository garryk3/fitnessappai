import 'package:flutter/material.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';

void main() {
  runApp(const FitnessAppAi());
}

class FitnessAppAi extends StatelessWidget {
  const FitnessAppAi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitnessAppAI',
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      home: const Scaffold(body: Center(child: Text('FitnessAppAI'))),
    );
  }
}
