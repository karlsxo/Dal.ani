import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'alerts_screen.dart';
import 'gps_tracking_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic>? selectedProduce;
  final double? initialTargetTemperature;
  
  const MainScreen({
    super.key, 
    this.initialIndex = 0,
    this.selectedProduce,
    this.initialTargetTemperature,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
  
  // Static method to access from child widgets
  static _MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenState>();
  }
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Public method to change tab
  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => <Widget>[
    DashboardScreen(
      selectedProduce: widget.selectedProduce,
      initialTargetTemperature: widget.initialTargetTemperature,
    ),      // Monitor
    AlertsScreen(),         // Alerts
    GpsTrackingScreen(),    // GPS
    HistoryScreen(),        // History
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Monitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gps_fixed),
            label: 'GPS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}