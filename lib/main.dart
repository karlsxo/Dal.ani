import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  // Add this import for kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/start_screen.dart';
import 'theme/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add platform check
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
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