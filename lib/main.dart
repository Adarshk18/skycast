import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final apiKey = '1046a53cacf0fb1ee5359302a7151fc7';
  double temperature = 0;
  String weatherCondition = '';
  Map<String, dynamic>? weatherData;
  TextEditingController cityController = TextEditingController();

  List<String> favoriteLocations = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteLocations();
  }

  Future<void> _loadFavoriteLocations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteLocations = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _saveFavoriteLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    favoriteLocations.add(location);
    prefs.setStringList('favorites', favoriteLocations);
  }

  Future<void> _fetchWeather() async {
    final city = cityController.text;
    const apiUrl = 'https://api.openweathermap.org/data/2.5/weather';
    final response = await http.get(Uri.parse('$apiUrl?q=$city&appid=$apiKey'));

    if (response.statusCode == 200) {
      setState(() {
        weatherData = json.decode(response.body);
        temperature =
            (weatherData!['main']['temp'] - 273.15); // Convert to Celsius
        weatherCondition = weatherData!['weather'][0]['main'];
      });
    } else {
      // Handling errors
      print('Error: ${response.reasonPhrase}');
      print('Response Body: ${response.body}');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'Failed to fetch weather data. Please enter a valid city name.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'Enter City',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    print('Entered City: $value');
                    // Handle city input
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (temperature == 0 && weatherCondition.isEmpty)
                const SpinKitCircle(
                  color: Colors.blue,
                  size: 50.0,
                )
              else
                Column(
                  children: [
                    Text('Temperature: ${temperature.toStringAsFixed(2)}°C'),
                    Text('Weather Condition: $weatherCondition'),
                    if (weatherData != null && weatherData!.containsKey('wind'))
                      Text('Wind Speed: ${weatherData!['wind']['speed']} m/s'),
                  ],
                ),
              const SizedBox(
                height: 40,
              ),
              ElevatedButton(
                onPressed: () {
                  // Triggering weather data
                  _fetchWeather();
                  //saving the fav location
                  _saveFavoriteLocation(cityController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text('Get Weather'),
              ),
              const SizedBox(height: 30),
              if (favoriteLocations.isNotEmpty)
                Card(
                  elevation: 5,
                  margin: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text(
                          'Favorite Locations:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      for (final location in favoriteLocations)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
