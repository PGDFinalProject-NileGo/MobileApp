import 'package:cloud_firestore/cloud_firestore.dart'; // <--- ADD THIS
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 2. UPDATED LOGIC ENGINE
  Future signUp() async {
    // A. Check Password Match
    if (_passwordController.text.trim() == _confirmPasswordController.text.trim()) {
      try {
        // B. Firebase Auth Call
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // ✨ NEW: Create the Wallet document for the new user
        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('wallets')
              .doc(userCredential.user!.uid)
              .set({
            'balance': 0, // Starting balance
            'user_email': _emailController.text.trim(),
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        print("User & Wallet Created!"); 
      } on FirebaseAuthException catch (e) {
        // C. Error Dialog (Matches your existing style)
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(content: Text(e.message.toString()));
            });
      }
    } else {
      // D. Mismatch Dialog (Matches your existing style)
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(content: Text("Passwords don't match!"));
          });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... rest of your build method (UI) remains 100% the same ...
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
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
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
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
                SizedBox(
                  width: 150,
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: signUp,
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}