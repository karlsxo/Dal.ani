import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme/colors.dart';
import '../services/rtdb_service.dart';

class GpsTrackingScreen extends StatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  GoogleMapController? _mapController;
  final RTDBService _rtdbService = RTDBService();
  StreamSubscription<DatabaseEvent>? _gpsSubscription;
  
  // Current location
  LatLng _currentLocation = const LatLng(14.5995, 120.9842); // Default to Manila
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  
  bool _isTracking = false;
  String _lastUpdateTime = '';
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _startGpsTracking();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  void _startGpsTracking() {
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
                _lastUpdateTime = DateTime.now().toString().substring(11, 19);
                
                // Add to route
                _routePoints.add(_currentLocation);
                
                // Update markers
                _markers = {
                  Marker(
                    markerId: const MarkerId('current_location'),
                    position: _currentLocation,
                    infoWindow: InfoWindow(
                      title: 'Current Location',
                      snippet: 'Speed: ${speed.toStringAsFixed(1)} km/h',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  ),
                };
                
                // Update route polyline
                _polylines = {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: _routePoints,
                    color: AppColors.primaryGreen,
                    width: 3,
                  ),
                };
              });
              
              // Move camera to current location
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(_currentLocation),
              );
            }
          }
        } catch (e) {
          print('Error processing GPS data: $e');
        }
      },
    );
  }

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
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.gps_fixed : Icons.gps_off),
            color: _isTracking ? AppColors.primaryGreen : Colors.grey,
            onPressed: () {
              // Toggle tracking
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // GPS Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  'Status',
                  _isTracking ? 'Active' : 'Inactive',
                  _isTracking ? AppColors.primaryGreen : Colors.grey,
                ),
                _buildStatusItem(
                  'Speed',
                  '${_currentSpeed.toStringAsFixed(1)} km/h',
                  AppColors.primaryText,
                ),
                _buildStatusItem(
                  'Last Update',
                  _lastUpdateTime,
                  AppColors.secondaryText,
                ),
              ],
            ),
          ),
          
          // Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: true,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
