import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/energy_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Foreground Content
          SingleChildScrollView(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                      height: size.height *
                          0.1), // Adjust dynamically based on height
                  // Logo
                  Image.asset(
                    'assets/images/logo.png', // Replace with your logo path
                    height: size.height * 0.5, // Dynamic height for logo
                  ),
                  SizedBox(height: size.height * 0), // Spacing
                  // Title Text (GreenVolt)
                  const Text(
                    'GreenVolt',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3BA040), // Updated color
                      fontFamily: 'Konkhmer Sleokchher',
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  // Subtitle Text (Handle the Energy you produce)
                  const Text(
                    'Handle the Energy you produce',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF3BA040), // Updated color
                      fontFamily: 'Konkhmer Sleokchher',
                    ),
                  ),
                  SizedBox(height: size.height * 0.05), // Dynamic spacing
                  // Buttons
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.1), // Dynamic padding
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'Login',
                          backgroundColor: const Color(0xFF3BA040),
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                        ),
                        SizedBox(height: size.height * 0.02), // Dynamic spacing
                        CustomButton(
                          text: 'Sign up',
                          backgroundColor: const Color(0xFF9FD210),
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
