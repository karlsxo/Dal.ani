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
  // State variables
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

  Widget _buildRiskCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _riskColor, width: 2.0),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: _riskColor, size: 28),
              const SizedBox(width: 8),
              Text(
                'Spoilage Risk Level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _riskColor
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _riskLevel,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _riskColor
            ),
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
            icon: Icons.thermostat,
            title: 'Temperature',
            value: '${_currentTemperature.toStringAsFixed(1)}°C',
            subtitle: 'Target: ${_targetTemperature.toStringAsFixed(1)}°C',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InfoCard(
            icon: Icons.water_drop,
            title: 'Humidity',
            value: '${_currentHumidity.toStringAsFixed(1)}%',
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
            _buildRiskCard(),
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
                _dataSimulatorTimer.cancel();
                _tripStopwatch.stop();

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

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripSummaryScreen(summaryData: summaryData),
                  ),
                ).then((_) {
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
  final IconData? icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color? valueColor;

  const InfoCard({
    super.key,
    this.icon,
    required this.title,
    required this.value,
    this.subtitle,
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
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.secondaryText, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.primaryText,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}