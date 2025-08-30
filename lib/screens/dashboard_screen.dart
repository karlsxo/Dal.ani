import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../constants/produce_data.dart';
import '../models/produce.dart';
import '../services/rtdb_service.dart';
import '../services/spoilage_tracker_service.dart';
import '../theme/colors.dart';
import 'main_screen.dart';
import 'select_produce_screen.dart';
import 'trip_summary_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedProduce;
  final double? initialTargetTemperature;

  const DashboardScreen({
    super.key, 
    this.selectedProduce,
    this.initialTargetTemperature,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State variables
  bool _coolerIsOn = true;
  late double _targetTemperature;
  double _currentTemperature = 7.4;
  double _currentHumidity = 7.4;
  double _spoilagePercentage = 0;
  String _riskLevel = "High Risk";
  Color _riskColor = Colors.red;
  bool _isLoading = false;

  // Firebase and simulation related variables
  final RTDBService _rtdbService = RTDBService();
  final SpoilageTrackerService _spoilageTracker = SpoilageTrackerService();
  StreamSubscription<DatabaseEvent>? _readingsSubscription;
  Timer? _dataSimulatorTimer;
  bool _useSimulation = false;

  final Stopwatch _tripStopwatch = Stopwatch();
  String _elapsedTime = '2 hrs 5 mins';
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    
    if (widget.selectedProduce == null || widget.initialTargetTemperature == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SelectProduceScreen()),
          );
        }
      });
      return;
    }
    
    _targetTemperature = widget.initialTargetTemperature!;
    _tripStopwatch.start();
    _startTripDurationTimer();
    _initializeDataSource();
  }

  void _initializeDataSource() {
    try {
      _listenForSensorReadings();
      
      Timer(const Duration(seconds: 10), () {
        if (_isLoading && mounted) {
          print('No Firebase data received in 10 seconds, switching to simulation');
          _readingsSubscription?.cancel();
          _useSimulation = true;
          _startDataSimulation();
        }
      });
    } catch (e) {
      print('Firebase connection failed, falling back to simulation: $e');
      _useSimulation = true;
      _startDataSimulation();
    }
  }

  void _listenForSensorReadings() {
    _readingsSubscription = _rtdbService.getSensorReadings().listen(
      (event) {
        if (!mounted) return;

        try {
          final dataSnapshot = event.snapshot.value;
          print('dataSnapshot: $dataSnapshot');

          if (dataSnapshot == null) {
            print('No data available in snapshot');
            setState(() => _isLoading = false);
            return;
          }

          if (dataSnapshot is Map) {
            final latestReading = (dataSnapshot.values.toList().last);
            print('Latest reading: $latestReading');

            final humidity = latestReading['humidity'];
            final temperature = latestReading['temperature'];
            final timestamp = latestReading['timestamp'];
            final gps = latestReading['gps'];
            final gpsValid = gps != null ? gps['valid'] : null;

            print('Humidity: $humidity, Temperature: $temperature, Timestamp: $timestamp, GPS valid: $gpsValid');

            if (latestReading is Map) {
              final temp = double.parse(latestReading['temperature'].toString());
              final humidity = double.parse(latestReading['humidity'].toString());
              
              final Produce? produce = ProduceData.produces[widget.selectedProduce?['type']];
              if (produce != null) {
                _spoilageTracker.addReading(temp, humidity, DateTime.now(), produce);
                
                setState(() {
                  _currentTemperature = temp;
                  _currentHumidity = humidity;
                  _spoilagePercentage = _spoilageTracker.getSpoilagePercentage(produce);
                  _isLoading = false;
                });

                _updateRiskLevel();
              }
            }
          }
        } catch (e) {
          print('Error processing Firebase data: $e');
          if (_isLoading) {
            print('Falling back to simulation due to processing error');
            _useSimulation = true;
            _startDataSimulation();
          }
        }
      },
      onError: (error) {
        print('Firebase stream error: $error');
        if (_isLoading && mounted) {
          print('Firebase stream failed, falling back to simulation');
          _useSimulation = true;
          _startDataSimulation();
        }
      },
    );
  }

  void _startTripDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tripStopwatch.isRunning) {
        setState(() {
          _updateElapsedTime();
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _updateElapsedTime() {
    final duration = _tripStopwatch.elapsed;
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60);
    _elapsedTime = '${hours} hrs ${minutes} mins';
  }

  void _updateRiskLevel() {
    if (_spoilagePercentage >= 75) {
      setState(() {
        _riskLevel = "Critical Risk";
        _riskColor = Colors.red;
      });
    } else if (_spoilagePercentage >= 50) {
      setState(() {
        _riskLevel = "High Risk";
        _riskColor = Colors.red;
      });
    } else if (_spoilagePercentage >= 25) {
      setState(() {
        _riskLevel = "Medium Risk";
        _riskColor = Colors.orange;
      });
    } else {
      setState(() {
        _riskLevel = "Low Risk";
        _riskColor = Colors.green;
      });
    }
  }

  void _startDataSimulation() {
    print('Starting data simulation...');
    setState(() {
      _isLoading = false;
      _currentTemperature = _targetTemperature + (Random().nextDouble() - 0.5) * 4;
      _currentHumidity = 60 + (Random().nextDouble() * 20);
    });
    
    _dataSimulatorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      
      setState(() {
        final tempChange = (Random().nextDouble() - 0.5) * 0.5;
        _currentTemperature += tempChange;
        
        if (_currentTemperature < _targetTemperature - 3) {
          _currentTemperature = _targetTemperature - 3;
        }
        if (_currentTemperature > _targetTemperature + 3) {
          _currentTemperature = _targetTemperature + 3;
        }

        final humidityChange = (Random().nextDouble() - 0.5) * 2;
        _currentHumidity += humidityChange;
        if (_currentHumidity < 30) _currentHumidity = 30;
        if (_currentHumidity > 90) _currentHumidity = 90;

        final produce = ProduceData.produces[widget.selectedProduce?['type']];
        if (produce != null) {
          _spoilageTracker.addReading(_currentTemperature, _currentHumidity, DateTime.now(), produce);
          _spoilagePercentage = _spoilageTracker.getSpoilagePercentage(produce);
        }

        _updateRiskLevel();
      });
    });
  }

  void _endTrip() async {
    if (!mounted) return;
    
    _readingsSubscription?.cancel();
    _dataSimulatorTimer?.cancel();
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
        _initializeDataSource();
      });
    });
  }

  @override
  void dispose() {
    _readingsSubscription?.cancel();
    _dataSimulatorTimer?.cancel();
    _durationTimer?.cancel();
    _tripStopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.lightGreenBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isTinyScreen = screenHeight < 550;

    return Scaffold(
      backgroundColor: AppColors.lightGreenBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTinyScreen ? 6.0 : isVerySmallScreen ? 8.0 : isSmallScreen ? 10.0 : 12.0),
          child: Column(
            children: [
              // Header
              Text(
                'Dal-ani Monitor',
                style: TextStyle(
                  fontSize: isTinyScreen ? 16 : isVerySmallScreen ? 18 : isSmallScreen ? 20 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              Text(
                widget.selectedProduce?['name'] ?? 'Tomatoes',
                style: TextStyle(
                  fontSize: isTinyScreen ? 12 : isSmallScreen ? 13 : 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: isTinyScreen ? 6 : isVerySmallScreen ? 8 : isSmallScreen ? 10 : 15),

              // Risk Level Container
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTinyScreen ? 8 : isVerySmallScreen ? 10 : isSmallScreen ? 12 : 15),
                decoration: BoxDecoration(
                  color: _riskColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Risk Level',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTinyScreen ? 10 : isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
                      ),
                    ),
                    SizedBox(height: isTinyScreen ? 2 : 3),
                    Text(
                      _riskLevel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTinyScreen ? 16 : isVerySmallScreen ? 18 : isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTinyScreen ? 6 : isVerySmallScreen ? 8 : isSmallScreen ? 10 : 15),

              // Temperature and Humidity Cards
              Row(
                children: [
                  // Temperature Card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(isTinyScreen ? 6 : isVerySmallScreen ? 8 : isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.thermostat,
                            size: isTinyScreen ? 20 : isVerySmallScreen ? 25 : isSmallScreen ? 28 : 32,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(height: isTinyScreen ? 3 : isSmallScreen ? 4 : 6),
                          Text(
                            'Temperature',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isTinyScreen ? 9 : isVerySmallScreen ? 10 : isSmallScreen ? 11 : 12,
                            ),
                          ),
                          SizedBox(height: isTinyScreen ? 1 : 2),
                          Text(
                            '${_currentTemperature.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              fontSize: isTinyScreen ? 14 : isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            'Target: ${_targetTemperature.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: isTinyScreen ? 7 : isVerySmallScreen ? 8 : isSmallScreen ? 9 : 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isTinyScreen ? 6 : isSmallScreen ? 8 : 10),
                  // Humidity Card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(isTinyScreen ? 6 : isVerySmallScreen ? 8 : isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: isTinyScreen ? 20 : isVerySmallScreen ? 25 : isSmallScreen ? 28 : 32,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(height: isTinyScreen ? 3 : isSmallScreen ? 4 : 6),
                          Text(
                            'Humidity',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isTinyScreen ? 9 : isVerySmallScreen ? 10 : isSmallScreen ? 11 : 12,
                            ),
                          ),
                          SizedBox(height: isTinyScreen ? 1 : 2),
                          Text(
                            '${_currentHumidity.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: isTinyScreen ? 14 : isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            'Current Level',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: isTinyScreen ? 7 : isVerySmallScreen ? 8 : isSmallScreen ? 9 : 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTinyScreen ? 5 : isVerySmallScreen ? 6 : isSmallScreen ? 8 : 12),

              // Alert banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTinyScreen ? 6 : isVerySmallScreen ? 8 : isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: isTinyScreen ? 14 : isSmallScreen ? 16 : 18),
                    SizedBox(width: isTinyScreen ? 4 : isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        'Cooler temperature too high, Check door',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTinyScreen ? 9 : isVerySmallScreen ? 10 : isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTinyScreen ? 5 : isVerySmallScreen ? 6 : isSmallScreen ? 8 : 12),

              // GPS Tracking Active
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTinyScreen ? 6 : isVerySmallScreen ? 8 : isSmallScreen ? 10 : 12,
                  vertical: isTinyScreen ? 4 : isVerySmallScreen ? 6 : isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gps_fixed, size: isTinyScreen ? 14 : isSmallScreen ? 16 : 18, color: AppColors.primaryGreen),
                        SizedBox(width: isTinyScreen ? 4 : isSmallScreen ? 6 : 8),
                        Text(
                          'GPS Tracking Active',
                          style: TextStyle(fontSize: isTinyScreen ? 10 : isVerySmallScreen ? 11 : isSmallScreen ? 12 : 14),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final mainScreenState = MainScreen.of(context);
                        if (mainScreenState != null) {
                          mainScreenState.switchToTab(2);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: EdgeInsets.symmetric(
                          horizontal: isTinyScreen ? 6 : isVerySmallScreen ? 8 : isSmallScreen ? 10 : 12,
                          vertical: isTinyScreen ? 2 : isVerySmallScreen ? 3 : isSmallScreen ? 4 : 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'View Maps',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTinyScreen ? 8 : isVerySmallScreen ? 9 : isSmallScreen ? 10 : 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTinyScreen ? 4 : isVerySmallScreen ? 5 : isSmallScreen ? 6 : 8),

              // Cooler Status
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTinyScreen ? 6 : isVerySmallScreen ? 8 : isSmallScreen ? 10 : 12,
                  vertical: isTinyScreen ? 4 : isVerySmallScreen ? 6 : isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.ac_unit, size: isTinyScreen ? 14 : isSmallScreen ? 16 : 18, color: AppColors.primaryGreen),
                        SizedBox(width: isTinyScreen ? 4 : isSmallScreen ? 6 : 8),
                        Text(
                          'Cooler Status',
                          style: TextStyle(fontSize: isTinyScreen ? 10 : isVerySmallScreen ? 11 : isSmallScreen ? 12 : 14),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Off', style: TextStyle(color: Colors.grey, fontSize: isTinyScreen ? 9 : isSmallScreen ? 10 : 12)),
                        SizedBox(width: isTinyScreen ? 2 : isSmallScreen ? 4 : 6),
                        Transform.scale(
                          scale: isTinyScreen ? 0.6 : isSmallScreen ? 0.7 : 0.8,
                          child: Switch(
                            value: _coolerIsOn,
                            onChanged: (value) {
                              setState(() {
                                _coolerIsOn = value;
                              });
                            },
                            activeColor: AppColors.primaryGreen,
                          ),
                        ),
                        SizedBox(width: isTinyScreen ? 2 : isSmallScreen ? 4 : 6),
                        Text('On', style: TextStyle(color: AppColors.primaryGreen, fontSize: isTinyScreen ? 9 : isSmallScreen ? 10 : 12)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTinyScreen ? 4 : isVerySmallScreen ? 5 : isSmallScreen ? 6 : 8),

              // Duration
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTinyScreen ? 6 : isVerySmallScreen ? 8 : isSmallScreen ? 10 : 12,
                  vertical: isTinyScreen ? 4 : isVerySmallScreen ? 6 : isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: isTinyScreen ? 14 : isSmallScreen ? 16 : 18, color: AppColors.primaryGreen),
                    SizedBox(width: isTinyScreen ? 4 : isSmallScreen ? 6 : 8),
                    Text(
                      'Duration:',
                      style: TextStyle(fontSize: isTinyScreen ? 10 : isVerySmallScreen ? 11 : isSmallScreen ? 12 : 14),
                    ),
                    const Spacer(),
                    Text(
                      _elapsedTime,
                      style: TextStyle(
                        fontSize: isTinyScreen ? 10 : isVerySmallScreen ? 11 : isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // End Trip Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _endTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: EdgeInsets.symmetric(vertical: isTinyScreen ? 8 : isVerySmallScreen ? 10 : isSmallScreen ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'End Trip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTinyScreen ? 12 : isVerySmallScreen ? 14 : isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
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
