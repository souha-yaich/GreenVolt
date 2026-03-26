import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:greenvolt/screens/home.dart';
import 'package:greenvolt/services/session_service.dart'; // Import your SessionService

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SessionService _sessionService =
      SessionService(); // Instance of SessionService

  // Signup method
  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user session after successful signup
      await _sessionService.saveUserSession(userCredential.user?.uid ?? '');

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => const HomePage()));
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {}
  }

  // Login method
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user session after successful login
      await _sessionService.saveUserSession(userCredential.user?.uid ?? '');

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Catch Firebase specific errors
      throw e; // Rethrow the error for UI handling
    } catch (e) {
      // Catch any other general errors
      throw Exception("An unexpected error occurred.");
    }
  }

  // Logout method
  Future<void> logout() async {
    await _auth.signOut();
    // Clear user session on logout
    await _sessionService.clearUserSession();
  }
}
