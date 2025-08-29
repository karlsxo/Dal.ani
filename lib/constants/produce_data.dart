import '../models/produce.dart';

class ProduceData {
  static const Map<String, Produce> produces = {
    'bok_choy': Produce(
      name: 'Bok Choy (Pechay)',
      minTemp: 0,
      maxTemp: 4,
      optimalHumidity: 95,
      maxSpoilageIndex: 100,
    ),
    'cabbage': Produce(
      name: 'Cabbage',
      minTemp: 0,
      maxTemp: 2,
      optimalHumidity: 95,
      maxSpoilageIndex: 100,
    ),
    'lettuce': Produce(
      name: 'Lettuce',
      minTemp: 0,
      maxTemp: 2,
      optimalHumidity: 95,
      maxSpoilageIndex: 100,
    ),
    'strawberries': Produce(
      name: 'Strawberries',
      minTemp: 0,
      maxTemp: 2,
      optimalHumidity: 90,
      maxSpoilageIndex: 100,
    ),
    'tomatoes': Produce(
      name: 'Tomatoes',
      minTemp: 7,
      maxTemp: 10,
      optimalHumidity: 85,
      maxSpoilageIndex: 100,
    ),
    'pineapples': Produce(
      name: 'Pineapples',
      minTemp: 7,
      maxTemp: 12,
      optimalHumidity: 85,
      maxSpoilageIndex: 100,
    ),
    'eggplant': Produce(
      name: 'Eggplant',
      minTemp: 10,
      maxTemp: 12,
      optimalHumidity: 90,
      maxSpoilageIndex: 100,
    ),
    'mangoes': Produce(
      name: 'Mangoes',
      minTemp: 10,
      maxTemp: 12,
      optimalHumidity: 85,
      maxSpoilageIndex: 100,
    ),
    'bananas': Produce(
      name: 'Bananas',
      minTemp: 12,
      maxTemp: 13,
      optimalHumidity: 90,
      maxSpoilageIndex: 100,
    ),
    'sweet_potatoes': Produce(
      name: 'Sweet Potatoes (Kamote)',
      minTemp: 12,
      maxTemp: 16,
      optimalHumidity: 85,
      maxSpoilageIndex: 100,
    ),
  };
}