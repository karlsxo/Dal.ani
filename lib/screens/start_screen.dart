import 'package:flutter/material.dart';
import '../theme/colors.dart'; 
import 'main_screen.dart'; 

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreenBackground, // Use a themed background color
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Your App Logo (assuming you have one in assets)
              // Uncomment and replace with your actual logo path
              // Image.asset(
              //   'assets/app_logo.png', // Make sure this path is correct in pubspec.yaml
              //   height: 150,
              // ),
              // const SizedBox(height: 48),

              const Text(
                'Welcome to Dal-Ani App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your intelligent companion for optimizing produce storage and minimizing waste.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () {
                  // Navigate to the MainScreen, replacing the StartScreen
                  // so the user can't go back to the start screen using the back button.
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen, // Use your primary green color
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded corners for the button
                  ),
                  elevation: 5, // Add some shadow
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Text color for the button
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}