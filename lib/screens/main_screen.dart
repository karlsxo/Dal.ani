import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'select_produce_screen.dart';
import 'trip_summary_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;

  // Create dummy data for TripSummaryScreen
  final TripSummaryData dummyData = TripSummaryData(
    tripId: 'No Active Trip',
    duration: '00:00:00',
    avgTemperature: 0.0,
    warnings: 0,
    storageEfficiency: 0,
    startTime: DateTime.now(),
  );

  // Updated widget list with proper initialization
  late final List<Widget> _widgetOptions = <Widget>[
    TripSummaryScreen(summaryData: dummyData), // Changed from DashboardScreen
    const SelectProduceScreen(),
    TripSummaryScreen(summaryData: dummyData),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            activeIcon: Icon(Icons.monitor_heart),
            label: 'Monitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'New Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize_outlined),
            activeIcon: Icon(Icons.summarize),
            label: 'Summary',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryGreen,
        onTap: _onItemTapped,
      ),
    );
  }
}