import '../models/produce.dart';

class SpoilageReading {
  final double temperature;
  final double humidity;
  final DateTime timestamp;
  final double spoilageIndex;

  SpoilageReading({
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    required this.spoilageIndex,
  });
}

class SpoilageTrackerService {
  final List<SpoilageReading> _readings = [];
  double _currentSpoilageIndex = 0;
  DateTime? _lastReadingTime;

  double get currentSpoilageIndex => _currentSpoilageIndex;
  List<SpoilageReading> get readings => List.unmodifiable(_readings);

  void addReading(
    double temperature,
    double humidity,
    DateTime timestamp,
    Produce produce,
  ) {
    final timeDiff = _lastReadingTime != null
        ? timestamp.difference(_lastReadingTime!).inMinutes
        : 0;

    final baseRate = produce.calculateSpoilageRate(temperature, humidity);
    final spoilageIncrement = baseRate * (timeDiff / 60);
    _currentSpoilageIndex += spoilageIncrement;

    _readings.add(SpoilageReading(
      temperature: temperature,
      humidity: humidity,
      timestamp: timestamp,
      spoilageIndex: _currentSpoilageIndex,
    ));

    _lastReadingTime = timestamp;
  }

  double getSpoilagePercentage(Produce produce) {
    return (_currentSpoilageIndex / produce.maxSpoilageIndex) * 100;
  }

  void reset() {
    _readings.clear();
    _currentSpoilageIndex = 0;
    _lastReadingTime = null;
  }
}