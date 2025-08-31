import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'main_screen.dart';

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
      {'name': 'Tomato/ Kamatis', 'image': 'assets/tomato.png', 'temp': 10.0, 'type': 'tomatoes'},
      {'name': 'Eggplant/ Tarong', 'image': 'assets/eggplant.png', 'temp': 12.0, 'type': 'eggplant'},
      {'name': 'Sweet Potato/ Kamote', 'image': 'assets/kamote.png', 'temp': 16.0, 'type': 'sweet_potatoes'},
      {'name': 'Mango/ Mangga', 'image': 'assets/mango.png', 'temp': 12.0, 'type': 'mangoes'},
      {'name': 'Bok Choy/ Pechay', 'image': 'assets/pechay.png', 'temp': 4.0, 'type': 'bok_choy'},
      {'name': 'Cabbage', 'image': 'assets/cabbage.png', 'temp': 0.0, 'type': 'cabbage'},
      {'name': 'Strawberry', 'image': 'assets/strawberry.png', 'temp': 2.0, 'type': 'strawberries'},
      {'name': 'Banana/ Saging', 'image': 'assets/banana.png', 'temp': 12.0, 'type': 'bananas'},
      {'name': 'Lettuce', 'image': 'assets/lettuce.png', 'temp': 2.0, 'type': 'lettuce'},
      {'name': 'Pineapple', 'image': 'assets/pineapple.png', 'temp': 12.0, 'type': 'pineapples'},
    ];

    return Scaffold(
      backgroundColor: AppColors.lightGreenBackground,
      appBar: AppBar(
        title: const Text(
          'Select Produce',
          style: TextStyle(color: AppColors.darkText),
        ),
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
                      print('🔄 Selected produce: ${selectedProduce!['name']}');
                      print('🔄 Target temperature: ${selectedProduce!['temp']}');
                      print('🔄 Image path: ${selectedProduce!['image']}');
                      print('🔄 Type: ${selectedProduce!['type']}');
                      
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainScreen(
                            initialIndex: 0, // Start on Dashboard tab
                            selectedProduce: {
                              'name': selectedProduce!['name'],
                              'type': selectedProduce!['type'], // Use the explicit type
                              'image': selectedProduce!['image'],
                            },
                            initialTargetTemperature: selectedProduce!['temp'],
                          ),
                        ),
                      );
                    },
              child: Text(
                selectedProduce == null ? 'Select a produce first' : 'Start Trip',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: selectedProduce == null ? Colors.grey : Colors.white,
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
        side: isSelected ? const BorderSide(color: AppColors.primaryGreen, width: 2) : BorderSide.none,
      ),
      color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imageAsset,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 40,
                        color: AppColors.secondaryText,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isSelected ? AppColors.primaryGreen : AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target: ${temperature.toStringAsFixed(1)}°C',
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