import 'package:firebase_database/firebase_database.dart';

class RTDBService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getSensorReadings() {
    try {
      // Add debug print
      print('Attempting to fetch sensor data from Firebase...');
      
      return _database
          .child('readings')
          .orderByKey()
          .limitToLast(1)
          .onValue;
    } catch (e) {
      print('Error in RTDBService: $e');
      throw Exception('Failed to get sensor readings: $e');
    }
  }

  Future<void> saveTripData(Map<String, dynamic> tripData) async {
    try {
      await _database.child('trips').push().set(tripData);
    } catch (e) {
      throw Exception('Failed to save trip data: $e');
    }
  }
}