import 'package:flutter/material.dart';

import '../theme/colors.dart';

class GpsTrackingScreen extends StatelessWidget {
  const GpsTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreenBackground,
      appBar: AppBar(
        title: const Text('GPS Tracking',
          style: TextStyle(color: AppColors.darkText)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: const Center(
        child: Text('GPS Tracking Screen'),
      ),
    );
  }
}
