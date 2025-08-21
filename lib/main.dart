import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: const WeatherScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Weather {
  final double temperature;
  final double windspeed;
  final int weathercode;
  final String time;

  Weather({
    required this.temperature,
    required this.windspeed,
    required this.weathercode,
    required this.time,
  });

  /// ใช้ map JSON โดยตรงจาก API
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temperature'] ?? 0).toDouble(),
      windspeed: (json['windspeed'] ?? 0).toDouble(),
      weathercode: (json['weathercode'] ?? 0).toInt(),
      time: json['time'] ?? '',
    );
  }

  String get weatherDescription {
    switch (weathercode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Mainly clear, partly cloudy, and overcast';
      case 45:
      case 48:
        return 'Fog and depositing rime fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle: Light, moderate, and dense intensity';
      case 61:
      case 63:
      case 65:
        return 'Rain: Slight, moderate and heavy intensity';
      case 80:
      case 81:
      case 82:
        return 'Rain showers: Slight, moderate, and violent';
      default:
        return 'Unknown';
    }
  }

  String get iconUrl {
    if (weathercode == 0) {
      return 'https://cdn-icons-png.flaticon.com/512/869/869869.png';
    } else if ([1, 2, 3].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/1163/1163661.png';
    } else if ([45, 48].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/4005/4005901.png';
    } else if ([51, 53, 55].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/414/414974.png';
    } else if ([61, 63, 65].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/3313/3313887.png';
    } else if ([80, 81, 82].contains(weathercode)) {
      return 'https://cdn-icons-png.flaticon.com/512/1779/1779940.png';
    } else {
      return 'https://cdn-icons-png.flaticon.com/512/869/869869.png';
    }
  }
}

class WeatherService {
  static const String apiUrl =
      'https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true';

  static Future<Weather> fetchWeather(double lat, double lon) async {
    final url = apiUrl
        .replaceFirst('{lat}', lat.toString())
        .replaceFirst('{lon}', lon.toString());
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final current = data['current_weather'];
      return Weather.fromJson(current);
    } else {
      throw Exception('Failed to load weather (code: ${response.statusCode})');
    }
  }
}

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Weather',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Weather>(
        future: WeatherService.fetchWeather(37.7749, -122.4194), // ซานฟรานซิสโก
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'ไม่พบข้อมูลสภาพอากาศ',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WeatherCard(weather: snapshot.data!),
            ],
          );
        },
      ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Weather Icon
              SizedBox(
                width: 120,
                child: Image.network(
                  weather.iconUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Weather Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        weather.weatherDescription,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Temperature: ${weather.temperature.toStringAsFixed(1)} °C',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Windspeed: ${weather.windspeed.toStringAsFixed(1)} km/h',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time: ${weather.time}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
