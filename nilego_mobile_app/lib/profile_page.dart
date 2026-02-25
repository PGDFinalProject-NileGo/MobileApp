import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      // 🟢 APP BAR IS HERE (Correct Position)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      
      // 🟢 BODY IS HERE
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          // Default Value
          String fullName = "Nile Student"; 
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            // Safe access to data map
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null && data.containsKey('full_name')) {
              fullName = data['full_name'];
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Avatar
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFE8DEF8),
                  child: Icon(Icons.person_outline, size: 50, color: Color(0xFF6750A4)),
                ),
                const SizedBox(height: 40),

                // Read-Only Fields
                _buildProfileField("Full Name", fullName), 
                _buildProfileField("Email", user?.email ?? "student@nile.edu.ng"),
                _buildProfileField("User UID", user?.uid ?? "Unknown"), 

                const SizedBox(height: 40),
                
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50], // Light red background
                      foregroundColor: Colors.red,     // Red text/icon
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.red, width: 1.5)
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text("Log Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        // Pop all routes until we reach the root (Auth Page)
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    // We use a key to force the TextField to update if the value changes
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        key: ValueKey(value), 
        readOnly: true, // Better than enabled: false (allows copying text)
        controller: TextEditingController(text: value),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}