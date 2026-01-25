import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nilego_mobile_app/ride_summary_page.dart'; // Make sure this import matches your file name

class ActiveRidePage extends StatefulWidget {
  final String bikeId;
  const ActiveRidePage({super.key, required this.bikeId});

  @override
  State<ActiveRidePage> createState() => _ActiveRidePageState();
}

class _ActiveRidePageState extends State<ActiveRidePage> {
  // Logic Variables
  int _secondsElapsed = 0;
  Timer? _timer;
  
  // 🟢 TODO: ADJUST PRICING LATER IF NEEDED
  final double _costPerMinute = 10.0; 
  
  // 🟢 TODO: REMOVE THIS SIMULATION VARIABLE WHEN GPS IS REAL
  double _simulatedDistanceKm = 0.0;

  // Nile University Coordinates (Center of Map)
  static const LatLng _nileUniversity = LatLng(9.0405, 7.3986);

  @override
  void initState() {
    super.initState();
    _startRide();
  }

  void _startRide() {
    // Start the Timer & Simulation
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
          
          // 🟢 TODO: DELETE THIS LINE WHEN HARDWARE/GPS IS READY
          // This simulates movement for the demo because you are sitting in a room.
          // Adds 3 meters every second.
          _simulatedDistanceKm += 0.003; 
        });
      }
    });
  }

  Future<void> _endRide() async {
    _timer?.cancel();

    // 1. Calculate Final Cost
    double totalCost = (_secondsElapsed / 60) * _costPerMinute;
    if (totalCost < 5.0) totalCost = 5.0; // Minimum charge 5 Naira

    // 2. Lock the Bike in Database (Critical for Hardware)
    try {
      await FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId).update({
        'status': 'available',
        'is_locked': true, // <--- RE-LOCKS THE BIKE
        'current_rider': null,
      });

      if (mounted) {
        // 3. Go to Summary Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RideSummaryPage(
              bikeId: widget.bikeId,
              duration: "${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}",
              cost: totalCost,
              // 🟢 TODO: REPLACE WITH REAL GPS DISTANCE LATER
              distanceKm: _simulatedDistanceKm,
              routePoints: const [], // Empty route for now since we are simulating
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Formatting time
    String minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    String seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    // Fake milliseconds for techy effect
    String millis = ((_secondsElapsed * 37) % 100).toString().padLeft(2, '0'); 

    // Calculate live cost for display
    double currentCost = (_secondsElapsed / 60) * _costPerMinute;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't let them go back!
        leading: const Icon(Icons.pedal_bike, color: Colors.black, size: 28),
        title: const Text("NileGo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      
      body: Stack(
        children: [
          // 🗺️ MAP BACKGROUND
          const GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _nileUniversity,
              zoom: 16,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: true, // Show Blue Dot (You are here)
          ),

          // ⏱️ CENTER HUD
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Slightly transparent
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Ride Active", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    "$minutes:$seconds:$millis",
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(Icons.map, "${_simulatedDistanceKm.toStringAsFixed(2)} km"),
                      Container(width: 1, height: 30, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 15)),
                      _buildStatItem(Icons.money, "₦${currentCost.toStringAsFixed(1)}"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🔴 END RIDE BUTTON
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252), // Red
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.white, size: 30),
                label: const Text("End Ride & Lock", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: _endRide,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }
}