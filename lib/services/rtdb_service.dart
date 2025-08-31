import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class RTDBService {
  static final RTDBService _instance = RTDBService._internal();
  factory RTDBService() => _instance;
  RTDBService._internal();

  final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(), // Required parameter - use default Firebase app
    databaseURL: 'https://dal-ani-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  // Get sensor readings from /sensorReadings path
  Stream<DatabaseEvent> getSensorReadings() {
    print('🔥 RTDBService: Connecting to /sensorReadings...');
    print('🔥 Database URL: https://dal-ani-default-rtdb.asia-southeast1.firebasedatabase.app');
    
    return _database.child('sensorReadings').onValue;
  }

  // Test connection method
  Future<void> testConnection() async {
    try {
      print('🧪 Testing Firebase connection...');
      final snapshot = await _database.child('sensorReadings').get();
      print('✅ Connection successful!');
      print('📊 Data exists: ${snapshot.exists}');
      print('📊 Data value: ${snapshot.value}');
      if (snapshot.value is Map) {
        final data = snapshot.value as Map;
        print('📊 Number of entries: ${data.length}');
        print('📊 Keys: ${data.keys.toList()}');
      }
    } catch (e) {
      print('❌ Connection failed: $e');
    }
  }
}