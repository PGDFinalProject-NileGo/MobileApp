import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nilego_mobile_app/home_page.dart'; // Make sure this path matches your project
class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;
  const LoginPage({super.key, required this.showRegisterPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

Future signIn() async {
    // 1. Show Loading Indicator so user knows something is happening
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Attempt the Login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. SUCCESS! Navigate to Home Page
      if (mounted) {
        Navigator.pop(context); // Close the loading circle
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 4. ERROR! Close loading and show message
      if (mounted) {
        Navigator.pop(context); // Close the loading circle
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Login Failed"),
              content: Text(e.message.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. THIS PREVENTS THE OVERFLOW
      body: SafeArea(
        child: Center( // Keeps it centered when keyboard is closed
          child: SingleChildScrollView(
            // 2. Added physics so it bounces nicely
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Name
                  Row(
                    children: const [
                      Icon(Icons.pedal_bike, size: 30, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        'NileGo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 50), // Spacing

                  // Heading
                  const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Email Input
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'user@mail.com',
                      filled: true,
                      fillColor: const Color(0xFFE8DEF8),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.black54),
                        onPressed: () => _emailController.clear(),
                      ),
                      border: const UnderlineInputBorder(),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black54),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password Input
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'xxxxxx',
                      filled: true,
                      fillColor: const Color(0xFFE8DEF8),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.black54),
                        onPressed: () => _passwordController.clear(),
                      ),
                      border: const UnderlineInputBorder(),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black54),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(fontSize: 12)),
                      GestureDetector(
                        onTap: widget.showRegisterPage,
                        child: const Text(
                          'Register.',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Forgot Password
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sign In Button
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: signIn,
                      icon: const Icon(Icons.star, size: 18, color: Colors.white),
                      label: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20), // Bottom cushion
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }}