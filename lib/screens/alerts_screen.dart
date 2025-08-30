import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> alerts = [
    {
      'title': 'Temperature Spike',
      'message': 'Temperature exceeded safe threshold!',
      'time': '2 min ago',
      'icon': Icons.thermostat,
      'color': Colors.red,
    },
    {
      'title': 'Check Door',
      'message': 'Door was left open for more than 1 minute.',
      'time': '10 min ago',
      'icon': Icons.door_front_door,
      'color': Colors.orange,
    },
    {
      'title': 'Humidity Drop',
      'message': 'Humidity dropped below safe level.',
      'time': '30 min ago',
      'icon': Icons.water_drop,
      'color': Colors.blue,
    },
    // Add more sample alerts as needed
  ];

  AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
        centerTitle: true,
      ),
      body: alerts.isEmpty
          ? const Center(child: Text('No alerts at the moment.'))
          : ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(alert['icon'], color: alert['color'], size: 32),
                    title: Text(alert['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(alert['message']),
                    trailing: Text(alert['time'], style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                );
              },
            ),
    );
  }
}