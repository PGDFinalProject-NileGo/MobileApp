import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nilego_mobile_app/history_page.dart';
import 'package:nilego_mobile_app/profile_page.dart';
import 'package:nilego_mobile_app/wallet_page.dart';
import 'scanner_page.dart'; // ✅ Ensure this import is correct

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const LatLng _nileUniversity = LatLng(9.0405, 7.3986);
  int _selectedIndex = 0;
  GoogleMapController? _mapController; 

  final List<Widget> _pages = [
    const SizedBox(), // Placeholder for Map (Index 0)
    const WalletPage(),
    const HistoryPage(),
  ];

  Set<Marker> _bikeMarkers = {};

  @override
  void initState() {
    super.initState();
    _locateUser(); 
    _fetchAvailableBikes(); // Start listening for bikes immediately
  }

  Future<void> _locateUser() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
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

  // --- SHOW AVAILABLE BIKES ON MAP ---
  void _fetchAvailableBikes() {
    FirebaseFirestore.instance
        .collection('bikes')
        .where('status', isEqualTo: 'available') // Changed to match your DB logic usually
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _bikeMarkers = snapshot.docs.map((doc) {
            // Safety check for lat/lng
            double lat = doc.data().containsKey('lat') ? doc['lat'] : 9.0405;
            double lng = doc.data().containsKey('lng') ? doc['lng'] : 7.3986;
            
            return Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: "Bike: ${doc.id}"),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            );
          }).toSet();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar(
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
      ) : null,

      body: _selectedIndex == 0 
        ? GoogleMap(
            initialCameraPosition: const CameraPosition(target: _nileUniversity, zoom: 16),
            markers: _bikeMarkers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _locateUser(); 
            },
          )
        : _pages[_selectedIndex], 

      // ✅ FAB JUST OPENS SCANNER (Scanner handles the rest)
      floatingActionButton: _selectedIndex == 0 
        ? FloatingActionButton.extended(
            label: const Text('Scan to Unlock', style: TextStyle(color: Color(0xFF6750A4), fontWeight: FontWeight.bold, fontSize: 16)),
            icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF6750A4)),
            backgroundColor: const Color(0xFFE8DEF8), 
            onPressed: () {
               // Simply navigate to Scanner. 
               // Scanner will connect and push ActiveRidePage automatically.
               Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (context) => const ScannerPage())
               );
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}