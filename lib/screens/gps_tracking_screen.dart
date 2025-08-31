import 'dart:async';
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
  
  // GPS Data - ONLY REAL DATA
  LatLng _currentLocation = LatLng(14.5995, 120.9842); // Default Manila only for map initialization
  List<LatLng> _routePoints = [];
  bool _hasValidGPS = false;
  String _lastUpdateTime = 'No updates';
  double _currentSpeed = 0.0;
  double _totalDistance = 0.0;
  String _gpsStatus = 'No Signal';
  int _satelliteCount = 0;
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _currentReadingKey = 'Connecting...';
  String _connectionStatus = 'Initializing...';
  int _totalEntries = 0;
  bool _hasPermissionError = false;

  @override
  void initState() {
    super.initState();
    _testConnectionAndListen();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _testConnectionAndListen() async {
    setState(() {
      _connectionStatus = 'Testing connection...';
      _hasPermissionError = false;
    });
    
    // Test the connection first
    await _rtdbService.testConnection();
    
    // Start listening
    _listenForRealGpsData();
  }

  void _listenForRealGpsData() {
    print('🛰️ Starting to listen for REAL GPS data from /sensorReadings...');
    
    setState(() {
      _connectionStatus = 'Connecting to Firebase...';
    });
    
    _gpsSubscription = _rtdbService.getSensorReadings().listen(
      (event) {
        if (!mounted) return;
        
        setState(() {
          _connectionStatus = 'Connected ✅';
          _hasPermissionError = false;
        });
        
        try {
          final dataSnapshot = event.snapshot.value;
          print('📡 Firebase data received: ${dataSnapshot != null ? 'Data exists' : 'No data'}');
          
          if (dataSnapshot == null) {
            print('❌ No data in /sensorReadings path');
            setState(() {
              _currentReadingKey = 'No data found';
              _totalEntries = 0;
            });
            return;
          }
          
          if (dataSnapshot is Map && dataSnapshot.isNotEmpty) {
            print('📊 Raw Firebase keys: ${dataSnapshot.keys.toList()}');
            
            // Convert to a list of entries with their keys
            final List<MapEntry<String, dynamic>> entries = [];
            dataSnapshot.forEach((key, value) {
              if (value is Map) {
                entries.add(MapEntry(key.toString(), value));
                print('🔑 Found entry: $key with timestamp: ${value['timestamp']}');
              }
            });
            
            setState(() {
              _totalEntries = entries.length;
            });
            
            print('📊 Found ${entries.length} valid entries in Firebase');
            
            if (entries.isEmpty) {
              print('❌ No valid entries found');
              setState(() {
                _currentReadingKey = 'No valid entries';
              });
              return;
            }
            
            // Sort by timestamp to get the truly latest reading
            entries.sort((a, b) {
              final timestampA = a.value['timestamp'] ?? 0;
              final timestampB = b.value['timestamp'] ?? 0;
              return timestampB.compareTo(timestampA); // Sort descending (newest first)
            });
            
            final latestEntry = entries.first; // Now this is truly the latest
            final latestKey = latestEntry.key;
            final latestReading = latestEntry.value;
            
            print('📍 Latest key: $latestKey');
            print('📍 Latest reading timestamp: ${latestReading['timestamp']}');
            print('📍 Latest reading data: $latestReading');
            
            // Update the current reading key for display
            setState(() {
              _currentReadingKey = latestKey;
            });
            
            if (latestReading.containsKey('gps')) {
              final gpsData = latestReading['gps'];
              print('🛰️ GPS data found: $gpsData');
              
              if (gpsData is Map) {
                // Extract GPS values exactly as they appear in Firebase
                final bool gpsValid = gpsData['valid'] == true;
                final String status = gpsData['status']?.toString() ?? 'Unknown';
                final int satellites = int.tryParse(gpsData['satellites']?.toString() ?? '0') ?? 0;
                final double speed = double.tryParse(gpsData['speed']?.toString() ?? '0') ?? 0.0;
                final double lat = double.tryParse(gpsData['latitude']?.toString() ?? '0') ?? 0.0;
                final double lng = double.tryParse(gpsData['longitude']?.toString() ?? '0') ?? 0.0;
                
                print('🔍 Parsed GPS: Valid=$gpsValid, Status=$status, Lat=$lat, Lng=$lng, Satellites=$satellites');
                
                setState(() {
                  _gpsStatus = status;
                  _satelliteCount = satellites;
                  _currentSpeed = speed;
                  _latitude = lat;
                  _longitude = lng;
                  _lastUpdateTime = DateTime.now().toString().substring(11, 19);
                  
                  // Only update location and tracking if GPS is valid AND coordinates are not 0,0
                  if (gpsValid && lat != 0.0 && lng != 0.0) {
                    print('✅ Valid GPS coordinates received: $lat, $lng');
                    _hasValidGPS = true;
                    _currentLocation = LatLng(lat, lng);
                    
                    // Add to route (only if it's significantly different from last point)
                    if (_routePoints.isEmpty || 
                        (_routePoints.last.latitude - lat).abs() > 0.0001 ||
                        (_routePoints.last.longitude - lng).abs() > 0.0001) {
                      _routePoints.add(_currentLocation);
                      
                      // Calculate distance if we have previous points
                      if (_routePoints.length > 1) {
                        final Distance distance = Distance();
                        _totalDistance += distance.as(LengthUnit.Meter, 
                          _routePoints[_routePoints.length - 2], _currentLocation) / 1000;
                      }
                      
                      // Limit route points to prevent memory issues
                      if (_routePoints.length > 200) {
                        _routePoints.removeAt(0);
                      }
                    }
                    
                    // Move map to real location
                    _mapController.move(_currentLocation, 16.0);
                  } else {
                    print('❌ Invalid GPS: Valid=$gpsValid, Coordinates=($lat, $lng)');
                    _hasValidGPS = false;
                  }
                });
              } else {
                print('❌ GPS data is not a Map: $gpsData');
              }
            } else {
              print('❌ No GPS data found in latest reading');
            }
          } else {
            print('❌ dataSnapshot is not a valid Map or is empty');
            setState(() {
              _currentReadingKey = 'Invalid data format';
              _totalEntries = 0;
            });
          }
        } catch (e) {
          print('❌ Error processing GPS data: $e');
          setState(() {
            _connectionStatus = 'Error: $e';
            _currentReadingKey = 'Processing error';
          });
        }
      },
      onError: (error) {
        print('❌ Firebase GPS stream error: $error');
        
        // Check if it's a permission error
        if (error.toString().contains('permission-denied')) {
          setState(() {
            _hasPermissionError = true;
            _connectionStatus = 'Permission Denied ❌';
            _currentReadingKey = 'Check Firebase Rules';
          });
        } else {
          setState(() {
            _connectionStatus = 'Stream error: $error';
            _currentReadingKey = 'Connection error';
          });
        }
      },
    );
  }

  void _retryConnection() {
    _gpsSubscription?.cancel();
    _testConnectionAndListen();
  }

  void _centerOnCurrentLocation() {
    if (_hasValidGPS) {
      _mapController.move(_currentLocation, 16.0);
    } else {
      // Show message that GPS is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No valid GPS location available\nLatest: (${_latitude}, ${_longitude})\nStatus: $_gpsStatus\nReading: $_currentReadingKey\nConnection: $_connectionStatus'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _totalDistance = 0.0;
    });
  }

  Color _getStatusColor() {
    switch (_gpsStatus.toLowerCase()) {
      case 'gps fix':
        return AppColors.primaryGreen;
      case 'searching':
        return Colors.yellow;
      case 'no signal':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
                    'Real GPS Tracking',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  
                  // Connection status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _connectionStatus.contains('✅') ? Colors.green.withOpacity(0.1) : 
                             _hasPermissionError ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _connectionStatus.contains('✅') ? Colors.green : 
                                              _hasPermissionError ? Colors.red : Colors.orange),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _connectionStatus,
                            style: TextStyle(
                              fontSize: 10,
                              color: _connectionStatus.contains('✅') ? Colors.green : 
                                     _hasPermissionError ? Colors.red : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_hasPermissionError)
                          GestureDetector(
                            onTap: _retryConnection,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Permission error message
                  if (_hasPermissionError)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '🚫 Firebase Permission Denied',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Please check Firebase Database Rules:\n1. Go to Firebase Console\n2. Realtime Database → Rules\n3. Set read/write permissions',
                            style: TextStyle(fontSize: 10, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  
                  // GPS Status
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasValidGPS ? Icons.gps_fixed : Icons.gps_off,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _gpsStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  
                  // Current reading key (for debugging) - only show if no permission error
                  if (!_hasPermissionError)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Reading Key (${_totalEntries} total):',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentReadingKey,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  
                  // GPS Data Row 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusItem(
                        'Latitude', 
                        _latitude.toStringAsFixed(6),
                        _hasValidGPS ? AppColors.primaryGreen : Colors.grey,
                        isSmallScreen,
                      ),
                      _buildStatusItem(
                        'Longitude', 
                        _longitude.toStringAsFixed(6),
                        _hasValidGPS ? AppColors.primaryGreen : Colors.grey,
                        isSmallScreen,
                      ),
                      _buildStatusItem(
                        'Speed', 
                        '${_currentSpeed.toStringAsFixed(1)} km/h',
                        AppColors.darkText,
                        isSmallScreen,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  
                  // GPS Data Row 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusItem(
                        'Satellites', 
                        '$_satelliteCount',
                        _satelliteCount >= 4 ? AppColors.primaryGreen : Colors.orange,
                        isSmallScreen,
                      ),
                      _buildStatusItem(
                        'Route Points', 
                        '${_routePoints.length}',
                        AppColors.darkText,
                        isSmallScreen,
                      ),
                      _buildStatusItem(
                        'Distance', 
                        '${_totalDistance.toStringAsFixed(3)} km',
                        AppColors.darkText,
                        isSmallScreen,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  
                  // Last update
                  Text(
                    'Last Update: $_lastUpdateTime',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  
                  // GPS Debug Info
                  if (!_hasValidGPS && !_hasPermissionError)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _gpsStatus == 'GPS Fix' ? '⚠️ GPS Fix but coordinates are (0,0)' : '⚠️ Waiting for GPS Signal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Current coordinates: (${_latitude}, ${_longitude})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            _gpsStatus == 'GPS Fix' 
                                ? 'GPS module has fix but location is not valid'
                                : 'Move device to area with clear sky view',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Map section (rest remains the same)
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
                      initialCenter: _currentLocation,
                      initialZoom: _hasValidGPS ? 16.0 : 12.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
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
                      
                      // Route polyline (only show if we have valid GPS points)
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
                      
                      // Markers (only show if we have valid GPS)
                      if (_hasValidGPS)
                        MarkerLayer(
                          markers: [
                            // Current location marker
                            Marker(
                              point: _currentLocation,
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getStatusColor(),
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
                                child: Container(
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
                      onPressed: _centerOnCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Center'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasValidGPS ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clearRoute,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Route'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
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
            fontSize: isSmall ? 9 : 11,
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: isSmall ? 2 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmall ? 10 : 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
