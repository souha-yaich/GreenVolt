import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:greenvolt/screens/area.dart';
import 'package:greenvolt/screens/weather.dart';
import 'screens/welcome_screen.dart'; // Import the WelcomeScreen file
import 'screens/login_form.dart';
import 'screens/register_form.dart';
import 'screens/home.dart';
import 'screens/battery.dart';

// Main function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyAC5Wgu2FSAY_JOmWDiu7U5F0DxLbnbZP8",
        appId: "1:233738305831:android:236b5839c6a0673b666902",
        messagingSenderId: "233738305831",
        projectId: "greenvolt-480dd",
        databaseURL: 'https://greenvolt-480dd-default-rtdb.firebaseio.com/',
      ),
    );
    print("✅ Firebase initialized successfully!");
  } catch (e) {
    print("❌ Error initializing Firebase: ${e.toString()}");
    return;
  }

  runApp(const MyApp());

  // Listen for Firebase Authentication state changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      print("No user is signed in.");
    } else {
      print("User is signed in: ${user.uid}");
    }
  });
}

// MyApp class
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("✅ Building MyApp");

    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/signup': (context) => RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/welcome': (context) => const WelcomeScreen(),
        '/battery': (context) => const BatteryPage(),
        '/weather': (context) => WeatherScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/area') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => AreaPage(
                areaId: args['areaId'],
                areaName: args['areaName'],
              ),
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => const HomePage(), // Fallback route
            );
          }
        }
        return null;
      },
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print("✅ StreamBuilder triggered");

          if (snapshot.connectionState == ConnectionState.waiting) {
            print("✅ Showing loading screen");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            print("✅ User is signed in, navigating to HomePage");
            return const HomePage();
          }

          print("✅ No user signed in, navigating to WelcomeScreen");
          return const WelcomeScreen();
        },
      ),
    );
  }
}
