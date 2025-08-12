import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drip_emporium/screens/login_screen.dart';
import 'package:drip_emporium/screens/signup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart'; // For Google Sign-In

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in with Google: $e')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Sign In with Email'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: const Text('Sign Up with Email'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                UserCredential? userCredential = await _signInWithGoogle();
                if (userCredential != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Signed in as ${userCredential.user!.displayName}')),
                  );
                  // Navigate to home screen or dashboard
                  // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
                }
              },
              icon: Image.asset('assets/images/google_logo.png', height: 24.0), // Placeholder for Google logo
              label: const Text('Sign In with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
