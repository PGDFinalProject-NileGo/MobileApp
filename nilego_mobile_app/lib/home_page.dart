import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../scanner_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Nile University Coordinates
  static const LatLng _nileUniversity = LatLng(9.0405, 7.3986);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
  label: const Text('Scan to Unlock'),
  icon: const Icon(Icons.qr_code_scanner),
  onPressed: () async {
    // Open the scanner and wait for the result
    final bikeId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerPage()),
    );

    if (bikeId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unlocking Bike: $bikeId')),
      );
    }
  },
),
      appBar: AppBar(
        title: const Text('NileGo', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _nileUniversity,
          zoom: 16,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}