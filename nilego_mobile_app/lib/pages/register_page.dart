import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 1. CONTROLLERS (Preserved)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 2. LOGIC ENGINE (Preserved 100%)
  Future signUp() async {
    // A. Check Password Match
    if (_passwordController.text.trim() == _confirmPasswordController.text.trim()) {
      try {
        // B. Firebase Call
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print("User Created!"); // kept this debug line for you
      } on FirebaseAuthException catch (e) {
        // C. Error Dialog
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(content: Text(e.message.toString()));
            });
      }
    } else {
      // D. Mismatch Dialog
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(content: Text("Passwords don't match!"));
          });
    }
  }

  // 3. CLEANUP (Preserved)
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 4. THE UI (Updated to Match Figma)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed to match Figma
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top Bar: Logo
                const SizedBox(height: 10),
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

                const SizedBox(height: 50),

                // Heading
                const Text(
                  'REGISTER',
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
                  controller: _emailController, // Linked to controller
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@mail.com',
                    filled: true,
                    fillColor: const Color(0xFFE8DEF8), // Figma Purple
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
                  controller: _passwordController, // Linked to controller
                  obscureText: true, // Hides text
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

                const SizedBox(height: 20),

                // Confirm Password Input
                TextField(
                  controller: _confirmPasswordController, // Linked to controller
                  obscureText: true, // Hides text
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'xxxxxx',
                    filled: true,
                    fillColor: const Color(0xFFE8DEF8),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.black54),
                      onPressed: () => _confirmPasswordController.clear(),
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

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already a member? ", style: TextStyle(fontSize: 12)),
                    GestureDetector(
                      onTap: widget.showLoginPage,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Sign Up Button
                SizedBox(
                  width: 150,
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: signUp, // Calls the Logic Engine
                    icon: const Icon(Icons.star, size: 18, color: Colors.white),
                    label: const Text(
                      'Sign Up',
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
                
                // Bottom spacing for scrolling
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}