import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/gps_tracking_screen.dart';
import 'screens/start_screen.dart';
import 'theme/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
    // App will continue with simulation mode
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
      routes: {
        '/': (context) => const StartScreen(),
        '/gps': (context) => const GpsTrackingScreen(),
      },
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
    );
  }
}