import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'trip_summary_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE VARIABLES ---
  bool _coolerIsOn = true;
  double _targetTemperature = 5.0;
  double _currentTemperature = 7.4;
  double _currentHumidity = 65.3;
  String _riskLevel = "High Risk";
  Color _riskColor = AppColors.highRisk;
  late Timer _dataSimulatorTimer;
  final Stopwatch _tripStopwatch = Stopwatch();
  String _elapsedTime = '00:00:00';

  @override
  void initState() {
    super.initState();
    _tripStopwatch.start();
    _startDataSimulation();
  }

  @override
  void dispose() {
    _dataSimulatorTimer.cancel();
    _tripStopwatch.stop();
    super.dispose();
  }

  void _startDataSimulation() {
    _dataSimulatorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        final tempChange = (Random().nextDouble() - 0.5) * 0.5;
        _currentTemperature += tempChange;

        final humidityChange = (Random().nextDouble() - 0.5) * 2;
        _currentHumidity += humidityChange;
        if (_currentHumidity < 30) _currentHumidity = 30;
        if (_currentHumidity > 90) _currentHumidity = 90;

        _updateElapsedTime();
        _updateRiskLevel();
      });
    });
  }

  void _updateElapsedTime() {
    final duration = _tripStopwatch.elapsed;
    _elapsedTime = 
      '${duration.inHours.toString().padLeft(2, '0')}:'
      '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
      '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void _updateRiskLevel() {
    final difference = (_currentTemperature - _targetTemperature).abs();
    if (difference > 2.0) {
      _riskLevel = "High Risk";
      _riskColor = AppColors.highRisk;
    } else if (difference > 1.0) {
      _riskLevel = "Low Risk";
      _riskColor = AppColors.lowRisk;
    } else {
      _riskLevel = "Good";
      _riskColor = AppColors.goodRisk;
    }
  }

  Widget _buildTemperatureCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.thermostat, color: AppColors.secondaryText),
              SizedBox(width: 8),
              Text('Current Cooler Temperature', 
                style: TextStyle(fontSize: 16, color: AppColors.secondaryText)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_currentTemperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              fontSize: 64, 
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText
            ),
          ),
          const Divider(height: 20),
          Text(
            'Target: ${_targetTemperature.toStringAsFixed(1)}°C',
            style: const TextStyle(fontSize: 16, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(
          child: InfoCard(
            title: 'Humidity',
            value: '${_currentHumidity.toStringAsFixed(1)}%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InfoCard(
            title: 'Risk Level',
            value: _riskLevel,
            valueColor: _riskColor,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Cooler Status', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Switch(
          value: _coolerIsOn,
          onChanged: (value) {
            setState(() {
              _coolerIsOn = value;
            });
          },
          activeTrackColor: AppColors.primaryGreen.withOpacity(0.5),
          activeThumbColor: AppColors.primaryGreen,
        ),
      ],
    );
  }

  Widget _buildManualTempAdjust() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle, 
            color: AppColors.primaryGreen, size: 40),
          onPressed: () {
            setState(() {
              _targetTemperature -= 0.5;
            });
          },
        ),
        const SizedBox(width: 20),
        const Text("Adjust Target", 
          style: TextStyle(fontSize: 16, color: AppColors.secondaryText)),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.add_circle, 
            color: AppColors.primaryGreen, size: 40),
          onPressed: () {
            setState(() {
              _targetTemperature += 0.5;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreenBackground,
      appBar: AppBar(
        title: const Text('Dal-Ani Monitor', 
          style: TextStyle(color: AppColors.darkText)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTemperatureCard(),
            const SizedBox(height: 24),
            _buildInfoRow(),
            const SizedBox(height: 24),
            _buildControls(),
            const Divider(height: 40),
            Center(
              child: Column(
                children: [
                  const Text('TRIP DURATION', 
                    style: TextStyle(
                      color: AppColors.secondaryText, 
                      letterSpacing: 1.5
                    )
                  ),
                  const SizedBox(height: 8),
                  Text(_elapsedTime, 
                    style: const TextStyle(
                      fontSize: 36, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildManualTempAdjust(),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highRisk,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                // Stop the timers
                _dataSimulatorTimer.cancel();
                _tripStopwatch.stop();

                // Create summary data
                final summaryData = TripSummaryData(
                  tripId: 'TRIP-${DateTime.now().millisecondsSinceEpoch}',
                  duration: _elapsedTime,
                  avgTemperature: _currentTemperature,
                  warnings: _riskLevel == "High Risk" ? 1 : 0,
                  storageEfficiency: _riskLevel == "Good" ? 95 : 
                                   _riskLevel == "Low Risk" ? 80 : 60,
                  startTime: DateTime.now().subtract(
                    Duration(seconds: _tripStopwatch.elapsed.inSeconds)
                  ),
                );

                // Navigate to summary screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripSummaryScreen(summaryData: summaryData),
                  ),
                ).then((_) {
                  // Reset dashboard when returning
                  setState(() {
                    _tripStopwatch.reset();
                    _elapsedTime = '00:00:00';
                    _startDataSimulation();
                  });
                });
              },
              child: const Text(
                'End Trip',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, 
            style: const TextStyle(
              fontSize: 14, 
              color: AppColors.secondaryText
            )
          ),
          const SizedBox(height: 8),
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
    );
  }
}