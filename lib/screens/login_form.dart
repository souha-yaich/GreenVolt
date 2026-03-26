import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:greenvolt/screens/home.dart';
import 'package:greenvolt/screens/register_form.dart';
import 'package:greenvolt/services/auth_service.dart'; // Import your AuthService class

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State to track if there are any errors
  final ValueNotifier<bool> _emailError = ValueNotifier(false);
  final ValueNotifier<bool> _passwordError = ValueNotifier(false);
  bool _isLoading = false; // Track loading state for UI feedback

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Container(
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Form Overlay
            Positioned(
              top: size.height * 0.3, // Adjust the starting point of the form
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    const Text(
                      'WELCOME BACK',
                      style: TextStyle(
                        fontSize: 28,
                        color: Color(0xFF3BA040),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Login to your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Email field
                    ValueListenableBuilder(
                      valueListenable: _emailError,
                      builder: (context, emailError, child) {
                        return TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            errorText: emailError ? 'Email is required' : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    ValueListenableBuilder(
                      valueListenable: _passwordError,
                      builder: (context, passwordError, child) {
                        return TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: const Icon(Icons.visibility),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            errorText:
                                passwordError ? 'Password is required' : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Handle Forgot Password logic here
                        },
                        child: const Text(
                          'Forgot your password?',
                          style: TextStyle(
                            color: Color(0xFF3BA040),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Button
                    SizedBox(
                      width: size.width * 0.7,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3BA040),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                // Validate fields
                                bool isEmailEmpty =
                                    _emailController.text.isEmpty;
                                bool isPasswordEmpty =
                                    _passwordController.text.isEmpty;

                                _emailError.value = isEmailEmpty;
                                _passwordError.value = isPasswordEmpty;

                                if (isEmailEmpty || isPasswordEmpty) {
                                  Fluttertoast.showToast(
                                    msg: "Email and password are required!",
                                    toastLength: Toast.LENGTH_LONG,
                                    gravity: ToastGravity.SNACKBAR,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                    fontSize: 14.0,
                                  );
                                  return;
                                }

                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  // Try logging in using AuthService
                                  final user = await AuthService().login(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  );

                                  if (user != null) {
                                    // If login is successful, show a success message and navigate
                                    Fluttertoast.showToast(
                                      msg: "Login successful!",
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.SNACKBAR,
                                      backgroundColor: Colors.green,
                                      textColor: Colors.white,
                                      fontSize: 14.0,
                                    );

                                    // Navigate to HomePage after a short delay
                                    await Future.delayed(
                                        const Duration(seconds: 1));
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HomePage(), // Replace with your actual home screen
                                      ),
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  // Handle errors from Firebase Auth
                                  Fluttertoast.showToast(
                                    msg: e.message ??
                                        "An error occurred during login.",
                                    toastLength: Toast.LENGTH_LONG,
                                    gravity: ToastGravity.SNACKBAR,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                    fontSize: 14.0,
                                  );
                                } catch (e) {
                                  // Handle any other errors
                                  Fluttertoast.showToast(
                                    msg: "Unexpected error occurred.",
                                    toastLength: Toast.LENGTH_LONG,
                                    gravity: ToastGravity.SNACKBAR,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                    fontSize: 14.0,
                                  );
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              },
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Signup prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don’t have an account? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RegisterScreen()));
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: Color(0xFF3BA040),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
