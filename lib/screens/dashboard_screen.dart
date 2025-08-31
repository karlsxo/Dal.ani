import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme/colors.dart';
import '../services/rtdb_service.dart';
import '../constants/produce_data.dart';
import '../models/produce.dart';
import '../services/spoilage_tracker_service.dart';
import 'main_screen.dart';
import 'select_produce_screen.dart'; // Add this import

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
  final RTDBService _rtdbService = RTDBService();
  final SpoilageTrackerService _spoilageTracker = SpoilageTrackerService();
  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  
  // Real sensor data
  double _currentTemperature = 0.0;
  double _currentHumidity = 0.0;
  bool _hasValidData = false;
  bool _hasPermissionError = false;
  bool _useSimulation = false;
  Timer? _dataSimulatorTimer;
  
  // Spoilage calculation
  double _spoilagePercentage = 0;
  String _riskLevel = "Low Risk";
  Color _riskColor = AppColors.primaryGreen;
  
  // GPS data
  bool _gpsValid = false;

  // Target temperature and cooler status
  double _targetTemperature = 4.0;
  bool _coolerIsOn = true;
  
  // Trip duration
  final Stopwatch _tripStopwatch = Stopwatch();
  String _elapsedTime = '00:00:00';
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    
    print('🔍 Dashboard initialized with:');
    print('   Selected produce: ${widget.selectedProduce}');
    print('   Target temperature: ${widget.initialTargetTemperature}');
    
    // Redirect to select produce if no produce is selected
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
    
    // Set target temperature if provided
    if (widget.initialTargetTemperature != null) {
      _targetTemperature = widget.initialTargetTemperature!;
    }
    
    // Start trip timer
    _tripStopwatch.start();
    _startTripDurationTimer();
    
    _startListeningToFirebase();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _dataSimulatorTimer?.cancel();
    _durationTimer?.cancel();
    _tripStopwatch.stop();
    super.dispose();
  }

  void _startTripDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
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
    final seconds = (duration.inSeconds % 60);
    
    _elapsedTime = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startListeningToFirebase() {
    print('🔥 Starting to listen for real sensor data from Firebase...');
    
    _sensorSubscription = _rtdbService.getSensorReadings().listen(
      (event) {
        if (!mounted) return;
        
        setState(() {
          _hasPermissionError = false;
          _useSimulation = false;
        });
        
        try {
          final dataSnapshot = event.snapshot.value;
          
          if (dataSnapshot == null) {
            return;
          }
          
          if (dataSnapshot is Map && dataSnapshot.isNotEmpty) {
            // Convert to a list of entries with their keys
            final List<MapEntry<String, dynamic>> entries = [];
            dataSnapshot.forEach((key, value) {
              if (value is Map) {
                entries.add(MapEntry(key.toString(), value));
              }
            });
            
            if (entries.isEmpty) {
              return;
            }
            
            // Sort by timestamp to get the latest reading
            entries.sort((a, b) {
              final timestampA = a.value['timestamp'] ?? 0;
              final timestampB = b.value['timestamp'] ?? 0;
              return timestampB.compareTo(timestampA);
            });
            
            final latestEntry = entries.first;
            final latestReading = latestEntry.value;
            
            // Extract temperature and humidity
            if (latestReading.containsKey('temperature')) {
              final temp = double.tryParse(latestReading['temperature'].toString()) ?? 0.0;
              setState(() {
                _currentTemperature = temp;
              });
            }
            
            if (latestReading.containsKey('humidity')) {
              final humidity = double.tryParse(latestReading['humidity'].toString()) ?? 0.0;
              setState(() {
                _currentHumidity = humidity;
              });
            }
            
            // Extract GPS data if available
            if (latestReading.containsKey('gps')) {
              final gpsData = latestReading['gps'];
              if (gpsData is Map) {
                setState(() {
                  _gpsValid = gpsData['valid'] == true;
                });
              }
            }
            
            // Calculate spoilage using the produce data
            if (_currentTemperature > 0 || _currentHumidity > 0) {
              final produce = _getSelectedProduce();
              if (produce != null) {
                _spoilageTracker.addReading(_currentTemperature, _currentHumidity, DateTime.now(), produce);
                setState(() {
                  _spoilagePercentage = _spoilageTracker.getSpoilagePercentage(produce);
                  _hasValidData = true;
                });
                _updateRiskLevel();
              }
            }
            
          }
        } catch (e) {
          print('❌ Error processing sensor data: $e');
        }
      },
      onError: (error) {
        print('❌ Firebase sensor stream error: $error');
        
        if (error.toString().contains('permission-denied')) {
          setState(() {
            _hasPermissionError = true;
          });
        } else {
          // Fall back to simulation if connection fails
          if (!_useSimulation) {
            _startDataSimulation();
          }
        }
      },
    );
    
    // Fallback to simulation after 15 seconds if no valid data
    Timer(const Duration(seconds: 15), () {
      if (!_hasValidData && mounted && !_hasPermissionError) {
        _startDataSimulation();
      }
    });
  }

  void _startDataSimulation() {
    print('🎭 Starting temperature/humidity simulation...');
    setState(() {
      _useSimulation = true;
      _currentTemperature = _targetTemperature + (Random().nextDouble() - 0.5) * 4;
      _currentHumidity = 60 + (Random().nextDouble() * 20);
      _hasValidData = true;
    });
    
    _dataSimulatorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        // Simulate temperature changes
        final tempChange = (Random().nextDouble() - 0.5) * 0.5;
        _currentTemperature += tempChange;
        
        // Keep temperature within reasonable bounds
        if (_currentTemperature < _targetTemperature - 3) {
          _currentTemperature = _targetTemperature - 3;
        }
        if (_currentTemperature > _targetTemperature + 3) {
          _currentTemperature = _targetTemperature + 3;
        }

        // Simulate humidity changes
        final humidityChange = (Random().nextDouble() - 0.5) * 2;
        _currentHumidity += humidityChange;
        if (_currentHumidity < 30) _currentHumidity = 30;
        if (_currentHumidity > 90) _currentHumidity = 90;

        // Update spoilage tracking
        final produce = _getSelectedProduce();
        if (produce != null) {
          _spoilageTracker.addReading(_currentTemperature, _currentHumidity, DateTime.now(), produce);
          _spoilagePercentage = _spoilageTracker.getSpoilagePercentage(produce);
        }

        _updateRiskLevel();
      });
    });
  }

  Produce? _getSelectedProduce() {
    if (widget.selectedProduce == null) {
      print('⚠️ No selected produce found');
      return null;
    }
    
    // Use the type field directly if available
    String produceKey = '';
    if (widget.selectedProduce!.containsKey('type')) {
      produceKey = widget.selectedProduce!['type'];
      print('🔑 Using direct type mapping: $produceKey');
    } else {
      // Fallback to name-based mapping
      final String produceName = widget.selectedProduce!['name'].toLowerCase();
      
      if (produceName.contains('tomato')) {
        produceKey = 'tomatoes';
      } else if (produceName.contains('eggplant')) {
        produceKey = 'eggplant';
      } else if (produceName.contains('sweet potato') || produceName.contains('kamote')) {
        produceKey = 'sweet_potatoes';
      } else if (produceName.contains('mango')) {
        produceKey = 'mangoes';
      } else if (produceName.contains('bok choy') || produceName.contains('pechay')) {
        produceKey = 'bok_choy';
      } else if (produceName.contains('cabbage')) {
        produceKey = 'cabbage';
      } else if (produceName.contains('strawberry')) {
        produceKey = 'strawberries';
      } else if (produceName.contains('banana')) {
        produceKey = 'bananas';
      } else if (produceName.contains('lettuce')) {
        produceKey = 'lettuce';
      } else if (produceName.contains('pineapple')) {
        produceKey = 'pineapples';
      }
      print('🔑 Using name-based mapping: $produceName -> $produceKey');
    }
    
    final produce = ProduceData.produces[produceKey];
    if (produce == null) {
      print('❌ No produce found for key: $produceKey');
      print('📋 Available keys: ${ProduceData.produces.keys.toList()}');
    } else {
      print('✅ Found produce: ${produce.name} (${produce.optimalTemp}°C)');
    }
    
    return produce;
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
        _riskColor = AppColors.primaryGreen;
      });
    }
  }

  void _retryConnection() {
    _sensorSubscription?.cancel();
    _dataSimulatorTimer?.cancel();
    setState(() {
      _hasValidData = false;
      _useSimulation = false;
      _hasPermissionError = false;
    });
    _startListeningToFirebase();
  }

  @override
  Widget build(BuildContext context) {
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
              
              // Produce Image and Name
              if (widget.selectedProduce != null) ...[
                SizedBox(height: isTinyScreen ? 6 : 10),
                Container(
                  padding: EdgeInsets.all(isTinyScreen ? 8 : 12),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          widget.selectedProduce!['image'],
                          width: isTinyScreen ? 60 : isSmallScreen ? 80 : 100,
                          height: isTinyScreen ? 60 : isSmallScreen ? 80 : 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported_outlined,
                              size: isTinyScreen ? 60 : isSmallScreen ? 80 : 100,
                              color: AppColors.secondaryText,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: isTinyScreen ? 4 : 8),
                      Text(
                        widget.selectedProduce!['name'],
                        style: TextStyle(
                          fontSize: isTinyScreen ? 12 : isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_useSimulation) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'SIMULATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTinyScreen ? 8 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
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
                    Text(
                      '${_spoilagePercentage.toStringAsFixed(1)}% spoilage risk',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isTinyScreen ? 8 : isVerySmallScreen ? 9 : isSmallScreen ? 10 : 11,
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
                  color: _currentTemperature > _targetTemperature + 2 ? Colors.red : 
                         _hasPermissionError ? Colors.red :
                         _useSimulation ? Colors.orange : AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasPermissionError ? Icons.error : 
                      _currentTemperature > _targetTemperature + 2 ? Icons.warning : 
                      _useSimulation ? Icons.info : Icons.check_circle,
                      color: Colors.white, 
                      size: isTinyScreen ? 14 : isSmallScreen ? 16 : 18
                    ),
                    SizedBox(width: isTinyScreen ? 4 : isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        _hasPermissionError ? 'Firebase permission denied - check database rules' :
                        _currentTemperature > _targetTemperature + 2 
                            ? 'Temperature too high! Check cooler door'
                            : _useSimulation ? 'Using simulated data - tap refresh to reconnect'
                            : 'Temperature monitoring active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTinyScreen ? 9 : isVerySmallScreen ? 10 : isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_hasPermissionError || _useSimulation)
                      GestureDetector(
                        onTap: _retryConnection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTinyScreen ? 8 : 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                        Icon(
                          _gpsValid ? Icons.gps_fixed : Icons.gps_off, 
                          size: isTinyScreen ? 14 : isSmallScreen ? 16 : 18, 
                          color: _gpsValid ? AppColors.primaryGreen : Colors.grey
                        ),
                        SizedBox(width: isTinyScreen ? 4 : isSmallScreen ? 6 : 8),
                        Text(
                          'GPS Tracking ${_gpsValid ? "Active" : "Inactive"}',
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
                        fontFamily: 'monospace',
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
                  onPressed: () {
                    // You can add trip ending logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip ended successfully!'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
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
