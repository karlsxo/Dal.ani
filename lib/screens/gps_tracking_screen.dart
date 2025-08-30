import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme/colors.dart';
import '../services/rtdb_service.dart';

class GpsTrackingScreen extends StatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  final MapController _mapController = MapController();
  final RTDBService _rtdbService = RTDBService();
  StreamSubscription<DatabaseEvent>? _gpsSubscription;
  Timer? _simulationTimer;
  
  // GPS Data
  LatLng _currentLocation = LatLng(14.5995, 120.9842); // Manila default
  List<LatLng> _routePoints = [];
  bool _isTracking = false;
  String _lastUpdateTime = 'No updates';
  double _currentSpeed = 0.0;
  double _totalDistance = 0.0;
  bool _useSimulation = true; // Start with simulation

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _initializeTracking() {
    // Try to get real GPS data first
    _listenForRealGpsData();
    
    // Fall back to simulation after 5 seconds if no real data
    Timer(const Duration(seconds: 5), () {
      if (!_isTracking && mounted) {
        print('No real GPS data received, starting simulation');
        _startSimulation();
      }
    });
  }

  void _listenForRealGpsData() {
    _gpsSubscription = _rtdbService.getSensorReadings().listen(
      (event) {
        if (!mounted) return;
        
        try {
          final dataSnapshot = event.snapshot.value;
          if (dataSnapshot is Map) {
            final latestReading = dataSnapshot.values.toList().last;
            final gpsData = latestReading['gps'];
            
            if (gpsData != null && gpsData['valid'] == true) {
              final double lat = double.parse(gpsData['latitude'].toString());
              final double lng = double.parse(gpsData['longitude'].toString());
              final double speed = double.parse(gpsData['speed']?.toString() ?? '0');
              
              setState(() {
                _currentLocation = LatLng(lat, lng);
                _currentSpeed = speed;
                _isTracking = true;
                _useSimulation = false;
                _lastUpdateTime = DateTime.now().toString().substring(11, 19);
                
                // Add to route
                _routePoints.add(_currentLocation);
                
                // Calculate distance
                if (_routePoints.length > 1) {
                  final Distance distance = Distance();
                  _totalDistance += distance.as(LengthUnit.Meter, 
                    _routePoints[_routePoints.length - 2], _currentLocation) / 1000;
                }
              });
              
              // Move map to current location
              _mapController.move(_currentLocation, 16.0);
            }
          }
        } catch (e) {
          print('Error processing GPS data: $e');
        }
      },
    );
  }

  void _startSimulation() {
    setState(() {
      _useSimulation = true;
      _isTracking = true;
    });
    
    // Simulate movement around Manila
    final random = Random();
    double lat = 14.5995;
    double lng = 120.9842;
    
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      
      // Simulate realistic movement
      lat += (random.nextDouble() - 0.5) * 0.001; // Small movements
      lng += (random.nextDouble() - 0.5) * 0.001;
      
      setState(() {
        _currentLocation = LatLng(lat, lng);
        _currentSpeed = 20 + random.nextDouble() * 40; // 20-60 km/h
        _lastUpdateTime = DateTime.now().toString().substring(11, 19);
        
        // Add to route
        _routePoints.add(_currentLocation);
        
        // Calculate simulated distance
        if (_routePoints.length > 1) {
          final Distance distance = Distance();
          _totalDistance += distance.as(LengthUnit.Meter, 
            _routePoints[_routePoints.length - 2], _currentLocation) / 1000;
        }
        
        // Limit route points to last 100 to prevent memory issues
        if (_routePoints.length > 100) {
          _routePoints.removeAt(0);
        }
      });
      
      // Move map to follow the route
      _mapController.move(_currentLocation, _mapController.zoom);
    });
  }

  void _centerOnCurrentLocation() {
    _mapController.move(_currentLocation, 16.0);
  }

  void _toggleTracking() {
    setState(() {
      if (_isTracking) {
        _simulationTimer?.cancel();
        _gpsSubscription?.cancel();
        _isTracking = false;
      } else {
        _initializeTracking();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.lightGreenBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    'GPS Tracking',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  
                  // Status indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusItem(
                        'Status', 
                        _isTracking ? 'Active' : 'Inactive',
                        _isTracking ? AppColors.primaryGreen : Colors.grey,
                        isSmallScreen,
                      ),
                      _buildStatusItem(
                        'Speed', 
                        '${_currentSpeed.toStringAsFixed(1)} km/h',
                        AppColors.darkText,
                        isSmallScreen,
                      ),
                      _buildStatusItem(
                        'Distance', 
                        '${_totalDistance.toStringAsFixed(2)} km',
                        AppColors.darkText,
                        isSmallScreen,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusItem(
                        'Mode', 
                        _useSimulation ? 'Simulation' : 'Real GPS',
                        _useSimulation ? Colors.orange : AppColors.primaryGreen,
                        isSmallScreen,
                      ),
                      _buildStatusItem(
                        'Last Update', 
                        _lastUpdateTime,
                        AppColors.secondaryText,
                        isSmallScreen,
                      ),
                      _buildStatusItem(
                        'Points', 
                        '${_routePoints.length}',
                        AppColors.secondaryText,
                        isSmallScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Map
            Expanded(
              child: Container(
                margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation, // Changed from 'center'
                      initialZoom: 15.0, // Changed from 'zoom'
                      minZoom: 10.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions( // Changed from 'interactiveFlags'
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // Map tiles
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.dalani.app',
                        maxZoom: 18,
                      ),
                      
                      // Route polyline
                      if (_routePoints.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: AppColors.primaryGreen,
                              strokeWidth: 4.0,
                              borderColor: Colors.white,
                              borderStrokeWidth: 2.0,
                            ),
                          ],
                        ),
                      
                      // Current location marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation,
                            width: 50,
                            height: 50,
                            child: Container( // Fixed: changed from 'builder' to 'child'
                              decoration: BoxDecoration(
                                color: _isTracking ? AppColors.primaryGreen : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          
                          // Start point marker (if route exists)
                          if (_routePoints.isNotEmpty)
                            Marker(
                              point: _routePoints.first,
                              width: 30,
                              height: 30,
                              child: Container( // Fixed: changed from 'builder' to 'child'
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Control buttons
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleTracking,
                      icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
                      label: Text(_isTracking ? 'Stop' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking ? Colors.red : AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _centerOnCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Center'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color, bool isSmall) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 10 : 12,
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: isSmall ? 2 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmall ? 11 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
