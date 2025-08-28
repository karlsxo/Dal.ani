import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'theme/colors.dart';

void main() {
  runApp(const DalAniApp());
}

class DalAniApp extends StatelessWidget {
  const DalAniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dal-Ani',
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.lightGreenBackground,
        useMaterial3: true,
      ),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}