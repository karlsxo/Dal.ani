import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'dashboard_screen.dart';

class SelectProduceScreen extends StatefulWidget {
  const SelectProduceScreen({super.key});

  @override
  State<SelectProduceScreen> createState() => _SelectProduceScreenState();
}

class _SelectProduceScreenState extends State<SelectProduceScreen> {
  Map<String, dynamic>? selectedProduce;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> produceList = [
      {'name': 'Tomato/ Kamatis', 'image': 'assets/tomato.png', 'temp': 10.0},
      {'name': 'Eggplant/ Tarong', 'image': 'assets/eggplant.png', 'temp': 12.0},
      {'name': 'Sweet Potato/ Kamote', 'image': 'assets/kamote.png', 'temp': 16.0},
      {'name': 'Mango/ Mangga', 'image': 'assets/mango.png', 'temp': 12.0},
      {'name': 'Bok Choy/ Pechay', 'image': 'assets/pechay.png', 'temp': 4.0},
      {'name': 'Cabbage', 'image': 'assets/cabbage.png', 'temp': 0.0},
      {'name': 'Strawberry', 'image': 'assets/strawberry.png', 'temp': 2.0},
      {'name': 'Banana/ Saging', 'image': 'assets/banana.png', 'temp': 12.0},
      {'name': 'Lettuce', 'image': 'assets/lettuce.png', 'temp': 2.0},
      {'name': 'Pineapple', 'image': 'assets/pineapple.png', 'temp': 12.0},
    ];

    return Scaffold(
      backgroundColor: AppColors.lightGreenBackground,
      appBar: AppBar(
        title: const Text('Start a New Trip', 
          style: TextStyle(color: AppColors.darkText)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What are you storing today?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select produce to optimize cooling.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: produceList.length,
                itemBuilder: (context, index) {
                  final produce = produceList[index];
                  final bool isSelected = selectedProduce != null && 
                                       selectedProduce!['name'] == produce['name'];
                  
                  return ProduceListItem(
                    name: produce['name'],
                    temperature: produce['temp'],
                    imageAsset: produce['image'],
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        selectedProduce = produce;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 5,
              ),
              onPressed: selectedProduce == null 
                  ? null 
                  : () {
                      // Add debug print to verify data
                      print('Selected produce: $selectedProduce');
                      print('Target temperature: ${selectedProduce!['temp']}');
                      
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DashboardScreen(
                            selectedProduce: {
                              'name': selectedProduce!['name'],
                              'type': selectedProduce!['name'].toLowerCase().replaceAll(' ', '_'),
                              'image': selectedProduce!['image'],
                            },
                            initialTargetTemperature: selectedProduce!['temp'],
                          ),
                        ),
                      );
                    },
              child: const Text(
                'Start Trip',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProduceListItem extends StatelessWidget {
  final String name;
  final double temperature;
  final String imageAsset;
  final bool isSelected;
  final VoidCallback onTap;

  const ProduceListItem({
    super.key,
    required this.name,
    required this.temperature,
    required this.imageAsset,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Image.asset(
                imageAsset,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 80,
                    color: AppColors.secondaryText,
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${temperature.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}