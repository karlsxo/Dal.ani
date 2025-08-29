class Produce {
  final String name;
  final double minTemp;
  final double maxTemp;
  final double optimalTemp;
  final double optimalHumidity;
  final double maxSpoilageIndex;

  const Produce({
    required this.name,
    required this.minTemp,
    required this.maxTemp,
    required this.optimalHumidity,
    required this.maxSpoilageIndex,
  }) : optimalTemp = (minTemp + maxTemp) / 2;

  double calculateSpoilageRate(double currentTemp, double currentHumidity) {
    double tempFactor = _calculateTemperatureFactor(currentTemp);
    double humidityFactor = _calculateHumidityFactor(currentHumidity);
    return (tempFactor * 0.7 + humidityFactor * 0.3);
  }

  double _calculateTemperatureFactor(double temp) {
    if (temp < minTemp) {
      double deviation = minTemp - temp;
      return (deviation / minTemp) * 0.7;
    } else if (temp > maxTemp) {
      double deviation = temp - maxTemp;
      return (deviation / maxTemp) * 1.5;
    } else {
      return ((temp - optimalTemp).abs() / (maxTemp - minTemp)) * 0.3;
    }
  }

  double _calculateHumidityFactor(double humidity) {
    double deviation = (humidity - optimalHumidity).abs();
    return (deviation / optimalHumidity) * (humidity > optimalHumidity ? 1.2 : 0.8);
  }
}