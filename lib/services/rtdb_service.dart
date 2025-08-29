import 'package:firebase_database/firebase_database.dart';

class RTDBService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getSensorReadings() {
    try {
      return _database
          .child('readings')
          .orderByChild('timestamp')
          .limitToLast(1)
          .onValue;
    } catch (e) {
      throw Exception('Failed to get sensor readings: $e');
    }
  }

  Future<void> saveTripData(Map<String, dynamic> tripData) async {
    try {
      final tripRef = _database.child('trips').push();
      await tripRef.set({
        ...tripData,
        'id': tripRef.key,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to save trip data: $e');
    }
  }
}