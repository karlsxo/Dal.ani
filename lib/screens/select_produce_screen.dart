import 'package:flutter/material.dart';
import '../theme/colors.dart'; // Corrected import path for colors.dart

class SelectProduceScreen extends StatelessWidget {
  const SelectProduceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List of produce. You can add image paths here.
    final List<Map<String, dynamic>> produceList = [
      {'name': 'Tomato', 'image': 'assets/tomato.png', 'temp': 13.0},
      {'name': 'Eggplant', 'image': 'assets/eggplant.png', 'temp': 13.0},
      {'name': 'Kamote', 'image': 'assets/kamote.png', 'temp': 13.0},
      {'name': 'Mango', 'image': 'assets/mango.png', 'temp': 13.0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start a New Trip', style: TextStyle(color: AppColors.darkText)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What are you storing today?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select produce to optimize cooling.',
              style: TextStyle(fontSize: 16, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: produceList.length,
                itemBuilder: (context, index) {
                  final produce = produceList[index];
                  // TODO: Create a state variable to track selection
                  return ProduceListItem(
                    name: produce['name'],
                    temperature: produce['temp'],
                    // imageAsset: produce['image'], // Add images to your project
                    onTap: () {
                      print('${produce['name']} selected');
                    },
                  );
                },
              ),
            ),
            // TODO: Add "Custom Temperature" option
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              onPressed: () {
                // TODO: Navigate to Dashboard and start the trip
                print('Start Trip button pressed');
              },
              child: const Text('Start Trip'),
            ),
          ],
        ),
      ),
    );
  }
}

// A reusable widget for the produce list item
class ProduceListItem extends StatelessWidget {
  final String name;
  final double temperature;
  final VoidCallback onTap;
  // final String imageAsset; // Uncomment when you have images

  const ProduceListItem({
    super.key,
    required this.name,
    required this.temperature,
    required this.onTap,
    // required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // TODO: Add border color change on selection
        side: const BorderSide(color: Colors.transparent, width: 2),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        // leading: Image.asset(imageAsset, width: 50, height: 50),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          '${temperature.toStringAsFixed(0)}°C',
          style: const TextStyle(fontSize: 16, color: AppColors.secondaryText),
        ),
      ),
    );
  }
}