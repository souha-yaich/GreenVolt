import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:greenvolt/screens/welcome_screen.dart';
import 'package:greenvolt/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String city = "Sfax";
  String apiKey = "69af3c774e644468a42164412250802";
  Map<String, dynamic>? weatherData;
  String sunrise = "";
  String sunset = "";
  String sunHours = "";
  double cloudCoverForDay = 0;
  double adjustedSunHours = 0;
  String? userId; // Stocker l'ID utilisateur

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final url = Uri.parse(
          "http://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$city&days=3&aqi=no&alerts=yes");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        if (data['forecast'] == null) {
          print("Aucune prévision météo trouvée.");
          return;
        }

        setState(() {
          weatherData = data;
          extractSunTimes(data);

          double totalCloudCover = 0;
          int hoursInDay = data['forecast']['forecastday'][0]['hour'].length;

          for (var hourData in data['forecast']['forecastday'][0]['hour']) {
            totalCloudCover += hourData['cloud'];
          }

          cloudCoverForDay = totalCloudCover / hoursInDay;
          adjustedSunHours = double.parse(sunHours.split('h')[0]) *
              (1 - cloudCoverForDay / 100);
        });

        // Récupérer l'ID utilisateur et enregistrer dans Firestore
        await fetchUserId();
        if (userId != null) {
          await saveToFirestore(adjustedSunHours);
        }
      } else {
        print(
            "Erreur lors de la récupération des données météo: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception lors de la récupération météo: $e");
    }
  }

  Future<void> fetchUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    } else {
      print("Aucun utilisateur connecté.");
    }
  }

  Future<void> saveToFirestore(double adjustedSunHours) async {
    try {
      if (userId == null) return;

      await FirebaseFirestore.instance.collection("users").doc(userId).set({
        "adjustedSunHours": adjustedSunHours,
        "cloudCoverForDay": cloudCoverForDay,
      }, SetOptions(merge: true));

      print("Données météo sauvegardées pour l'utilisateur: $userId");
    } catch (e) {
      print("Erreur lors de la sauvegarde Firestore: $e");
    }
  }

  void extractSunTimes(Map<String, dynamic> data) {
    try {
      sunrise = data['forecast']['forecastday'][0]['astro']['sunrise'];
      sunset = data['forecast']['forecastday'][0]['astro']['sunset'];

      DateFormat format = DateFormat("h:mm a"); // Format plus tolérant
      DateTime sunriseTime = format.parse(sunrise);
      DateTime sunsetTime = format.parse(sunset);
      Duration sunDuration = sunsetTime.difference(sunriseTime);

      sunHours = "${sunDuration.inHours}h ${sunDuration.inMinutes % 60}m";
    } catch (e) {
      print("Erreur de parsing des horaires: $e");
      sunrise = "N/A";
      sunset = "N/A";
      sunHours = "0h 0m";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: weatherData == null
          ? Center(child: CircularProgressIndicator())
          : Container(
              width: screenSize.width,
              height: screenSize.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/weather1.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildHeader(),
                  SizedBox(height: screenSize.height * 0.04),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          buildWeatherCard(),
                          SizedBox(height: screenSize.height * 0.02),
                          buildSunInfoCard(screenSize),
                          SizedBox(height: screenSize.height * 0.02),
                          if (userId != null) buildCloudCoverCard(screenSize),
                        ],
                      ),
                    ),
                  ),
                  buildBottomNavigationBar(),
                ],
              ),
            ),
    );
  }

  Widget buildSunInfoCard(Size screenSize) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sun Info",
              style: GoogleFonts.roboto(
                fontSize: screenSize.width * 0.06,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(WeatherIcons.sunrise,
                        color: Colors.orangeAccent, size: 40),
                    SizedBox(height: 5),
                    Text("Sunrise",
                        style: GoogleFonts.montserrat(
                            fontSize: 18, color: Colors.black)),
                    Text(sunrise,
                        style: GoogleFonts.montserrat(
                            fontSize: 18, color: Colors.black)),
                  ],
                ),
                Column(
                  children: [
                    Icon(WeatherIcons.sunset,
                        color: Colors.deepOrange, size: 40),
                    SizedBox(height: 5),
                    Text("Sunset",
                        style: GoogleFonts.montserrat(
                            fontSize: 18, color: Colors.black)),
                    Text(sunset,
                        style: GoogleFonts.montserrat(
                            fontSize: 18, color: Colors.black)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              "Sun Hours: $sunHours",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCloudCoverCard(Size screenSize) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Pas de données météo disponibles.'));
        }

        double adjustedSunHours =
            (snapshot.data!['adjustedSunHours'] ?? 0.0).toDouble();
        double cloudCoverForDay =
            (snapshot.data!['cloudCoverForDay'] ?? 0.0).toDouble();

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            width: double.infinity, // Ensures full width
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Cloud Cover",
                    style: GoogleFonts.roboto(
                        fontSize: screenSize.width * 0.06,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 10),
                Text(
                    "cloud Cover For Day: ${cloudCoverForDay.toStringAsFixed(1)}%",
                    style: GoogleFonts.montserrat(fontSize: 18)),
                SizedBox(height: 10),
                Text(
                    "adjusted Sun Hours: ${adjustedSunHours.toStringAsFixed(2)} h",
                    style: GoogleFonts.montserrat(fontSize: 18)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFF3BA040),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Weather',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Tooltip(
            message: 'Log Out',
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await AuthService().logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => WelcomeScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWeatherCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,

      margin: EdgeInsets.symmetric(
          horizontal: 20, vertical: 10), // Same as other cards
      child: Container(
        width: double.infinity, // Ensures full width
        padding: EdgeInsets.all(20), // Less padding for consistency
        child: Column(
          children: [
            Text(
              city,
              style: GoogleFonts.roboto(
                fontSize: 50, // Slightly smaller for consistency
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2), // Reduced spacing
            Icon(
              getWeatherIcon(weatherData!['current']['condition']['code']),
              size: 50, // Slightly smaller for better balance
            ),
            SizedBox(height: 2),
            Text(
              "${weatherData!['current']['temp_c']}°C",
              style: GoogleFonts.montserrat(
                fontSize: 32, // Smaller to match other cards
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Wind: ${weatherData!['current']['wind_kph']} km/h",
              style: GoogleFonts.roboto(
                  fontSize: 18), // Slightly smaller for uniformity
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFF3BA040),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.battery_charging_full,
                color: Colors.white.withOpacity(0.5)),
            onPressed: () {
              Navigator.pushNamed(context, '/battery');
            },
          ),
          IconButton(
            icon: Icon(Icons.home, color: Colors.white.withOpacity(0.5)),
            onPressed: () {
              Navigator.pushNamed(context, '/home');
            },
          ),
          IconButton(
            icon: Icon(Icons.cloud, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/weather');
            },
          ),
        ],
      ),
    );
  }

  IconData getWeatherIcon(int conditionCode) {
    if (conditionCode == 1000) return WeatherIcons.day_sunny;
    if (conditionCode == 1003) return WeatherIcons.day_cloudy;
    if (conditionCode == 1006) return WeatherIcons.cloudy;
    return WeatherIcons.cloudy;
  }
}
