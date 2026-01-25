import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nilego_mobile_app/active_ride_page.dart';
import 'package:nilego_mobile_app/history_page.dart';
import 'package:nilego_mobile_app/profile_page.dart';
import 'package:nilego_mobile_app/wallet_page.dart';
import 'scanner_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Nile University (Fallback location)
  static const LatLng _nileUniversity = LatLng(9.0405, 7.3986);
  
  int _selectedIndex = 0;
  GoogleMapController? _mapController; // 🟢 To control the camera

  final List<Widget> _pages = [
    // We will build the map dynamically in the build method
    const SizedBox(), // Placeholder
    const WalletPage(),
    const HistoryPage(),
  ];

  @override
  void initState() {
    super.initState();
    _locateUser(); // 🟢 Trigger permission & move camera
  }

  // 🟢 NEW: Ask Permission & Move Camera to User
  Future<void> _locateUser() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      
      // Move the map camera to the user
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17,
          ),
        ),
      );
    }
  }

  // LOGIC: Unlock Bike
  Future<void> handleBikeUnlock(String bikeId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final bikeRef = FirebaseFirestore.instance.collection('bikes').doc(bikeId);
      final doc = await bikeRef.get();
      
      if (!doc.exists) throw "Bike not found in Database!";

      await bikeRef.update({
        'status': 'in_use',
        'is_locked': false,
        'current_rider': user?.uid,
        'start_time': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bike Unlocked!"), backgroundColor: Colors.green));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ActiveRidePage(bikeId: bikeId)),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Unlock Failed: $e");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar( // Only show AppBar on Map
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0, 
        leading: const Icon(Icons.pedal_bike, color: Colors.black, size: 28),
        title: const Text("NileGo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
              child: CircleAvatar(backgroundColor: Colors.grey[200], child: const Icon(Icons.person, color: Colors.black54)),
            ),
          ),
        ],
      ) : null, // No AppBar for Wallet/History (they have their own or look better without)

      body: _selectedIndex == 0 
        ? GoogleMap( // 🟢 The Map is directly here now
            initialCameraPosition: const CameraPosition(target: _nileUniversity, zoom: 16),
            myLocationEnabled: true,
            myLocationButtonEnabled: true, // 🟢 Enabled this button
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _locateUser(); // Try locating again when map is ready
            },
          )
        : _pages[_selectedIndex], 

      floatingActionButton: _selectedIndex == 0 
        ? FloatingActionButton.extended(
            label: const Text('Scan to Unlock', style: TextStyle(color: Color(0xFF6750A4), fontWeight: FontWeight.bold, fontSize: 16)),
            icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF6750A4)),
            backgroundColor: const Color(0xFFE8DEF8), 
            onPressed: () async {
              final scannedCode = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerPage()));
              if (scannedCode != null) handleBikeUnlock(scannedCode);
            },
          )
        : null, 
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: const Color(0xFFF3EDF7), 
        indicatorColor: const Color(0xFFE8DEF8),  
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}