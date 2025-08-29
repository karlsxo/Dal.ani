import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'main_screen.dart';

class TripSummaryData {
  final String tripId;
  final String duration;
  final double avgTemperature;
  final int warnings;
  final double storageEfficiency;
  final DateTime startTime;

  TripSummaryData({
    required this.tripId,
    required this.duration,
    required this.avgTemperature,
    required this.warnings,
    required this.storageEfficiency,
    required this.startTime,
  });
}

class TripSummaryScreen extends StatelessWidget {
  final TripSummaryData summaryData;

  const TripSummaryScreen({super.key, required this.summaryData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Trip Summary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your produce stayed fresh!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMainSummaryCard(),
                      const SizedBox(height: 16),
                      _buildInfoGrid(),
                      const SizedBox(height: 16),
                      _buildDetailsCard(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Start New Trip',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              summaryData.tripId,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const Text(
              'Trip ID',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const Divider(height: 32),
            Text(
              '${summaryData.storageEfficiency.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Storage Efficiency',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        SummaryInfoCard(
          icon: Icons.timer_outlined,
          title: 'Duration',
          value: summaryData.duration,
        ),
        SummaryInfoCard(
          icon: Icons.thermostat,
          title: 'Avg Temperature',
          value: '${summaryData.avgTemperature.toStringAsFixed(1)}°C',
        ),
        SummaryInfoCard(
          icon: Icons.warning_amber_rounded,
          title: 'Warnings',
          value: summaryData.warnings.toString(),
        ),
        const SummaryInfoCard(
          icon: Icons.check_circle_outline,
          title: 'Status',
          value: 'Fresh',
          valueColor: AppColors.primaryGreen,
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'More Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Started:',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            Text(
              '${summaryData.startTime.toLocal()}'.split('.')[0],
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24),
          ],
        ),
      ),
    );
  }
}

class SummaryInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const SummaryInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.secondaryText),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}