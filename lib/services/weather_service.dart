import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _geocodeUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String _weatherUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<String> getWeather(String city) async {
    final geoResponse = await http
        .get(
            Uri.parse('$_geocodeUrl?name=${Uri.encodeComponent(city)}&count=1'))
        .timeout(const Duration(seconds: 15));

    if (geoResponse.statusCode != 200) {
      throw WeatherServiceException('Could not look up "$city".');
    }

    final geoData = jsonDecode(geoResponse.body);
    final results = geoData['results'];
    if (results == null || (results as List).isEmpty) {
      throw WeatherServiceException('No location found for "$city".');
    }

    final place = results[0];
    final lat = place['latitude'];
    final lon = place['longitude'];
    final resolvedName = place['name'];
    final country = place['country'] ?? '';

    final weatherResponse = await http
        .get(Uri.parse(
            '$_weatherUrl?latitude=$lat&longitude=$lon&current_weather=true'))
        .timeout(const Duration(seconds: 15));

    if (weatherResponse.statusCode != 200) {
      throw WeatherServiceException('Could not fetch weather for "$city".');
    }

    final weatherData = jsonDecode(weatherResponse.body);
    final current = weatherData['current_weather'];
    final temp = current['temperature'];
    final windSpeed = current['windspeed'];
    final weatherCode = current['weathercode'];

    final condition = _describeWeatherCode(weatherCode);

    return 'Weather in $resolvedName, $country: $temp°C, $condition, '
        'wind ${windSpeed}km/h.';
  }

  String _describeWeatherCode(int code) {
    if (code == 0) return 'clear sky';
    if (code <= 3) return 'partly cloudy';
    if (code <= 48) return 'foggy';
    if (code <= 57) return 'drizzle';
    if (code <= 67) return 'rain';
    if (code <= 77) return 'snow';
    if (code <= 82) return 'rain showers';
    if (code <= 86) return 'snow showers';
    if (code <= 99) return 'thunderstorm';
    return 'unknown conditions';
  }
}

class WeatherServiceException implements Exception {
  final String message;
  WeatherServiceException(this.message);

  @override
  String toString() => message;
}
