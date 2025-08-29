import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';
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
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Add to your RTDBService class
class RTDBService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  Stream<DatabaseEvent> getSensorReadings() {
    try {
      return _database.child('sensor_readings').onValue;
    } catch (e) {
      // Return an empty stream if Firebase fails
      return Stream.empty();
    }
  }

  Future<void> saveTripData(Map<String, dynamic> tripData) async {
    try {
      await _database.child('trips').push().set(tripData);
    } catch (e) {
      print('Failed to save trip data: $e');
      rethrow;
    }
  }
}