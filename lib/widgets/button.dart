import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, required this.label, this.onPressed});
  final String label;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    // Get screen width and height from MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Adjust button size based on screen size
    double buttonWidth = screenWidth * 0.2; // 25% of screen width (smaller)
    double buttonHeight = screenHeight * 0.03; // 5% of screen height (smaller)

    return SizedBox(
      width: buttonWidth, // Dynamically adjusted width
      height: buttonHeight, // Dynamically adjusted height
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(fontSize: screenWidth * 0.02), // Smaller font size
        ),
      ),
    );
  }
}
