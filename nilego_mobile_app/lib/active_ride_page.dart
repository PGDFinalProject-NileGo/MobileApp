import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nilego_mobile_app/ride_summary_page.dart';
import 'package:geolocator/geolocator.dart';

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
  StreamSubscription<Position>? _positionStream;
  GoogleMapController? _mapController;
  
  final double _costPerMinute = 10.0; 
  
  Position? _currentPosition;
  double _totalDistanceKm = 0.0;
  LatLng? _lastPosition;

  // Polylines for drawing the path
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylinePoints = [];

  static const LatLng _nileUniversity = LatLng(9.0405, 7.3986);

  @override
  void initState() {
    super.initState();
    _startRide();
  }

  void _startRide() async {
    // 1. Request Permission
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return; 
    }

    // 2. Start UI Timer (For the clock display)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    // 3. Start GPS Location Stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Updates every 3 meters moved
      ),
    ).listen((Position pos) {
      if (mounted) {
        LatLng currentLatLng = LatLng(pos.latitude, pos.longitude);
        
        // Move camera to follow the user
        _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));

        setState(() {
          _currentPosition = pos;
          _polylinePoints.add(currentLatLng);

          // Update Polyline path
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ride_path'),
              points: _polylinePoints,
              color: const Color(0xFF6750A4),
              width: 5,
            ),
          );

          // Calculate distance
          if (_lastPosition != null) {
            double distanceMeters = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              pos.latitude,
              pos.longitude,
            );
            _totalDistanceKm += distanceMeters / 1000;
          }
          
          _lastPosition = currentLatLng;
        });
      }
    });
  }

  Future<void> _endRide() async {
    _timer?.cancel();
    _positionStream?.cancel();

    double totalCost = (_secondsElapsed / 60) * _costPerMinute;
    if (totalCost < 5.0) totalCost = 5.0; 

    try {
      final user = FirebaseAuth.instance.currentUser;

      // 1. Update Bike Status
      await FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId).update({
        'status': 'available',
        'is_locked': true,
        'current_rider': null,
      });

      // 2. Save History (Using your exact Firebase field names)
      await FirebaseFirestore.instance.collection('ride_history').add({
        'user_id': user?.uid,
        'bike_id': widget.bikeId,
        'cost': totalCost,
        'distance_km': _totalDistanceKm,
        'duration_seconds': _secondsElapsed, 
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RideSummaryPage(
              bikeId: widget.bikeId,
              duration: "${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}",
              cost: totalCost,
              distanceKm: _totalDistanceKm,
              routePoints: _polylinePoints,
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
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    String seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    String millis = ((_secondsElapsed * 37) % 100).toString().padLeft(2, '0'); 
    double currentCost = (_secondsElapsed / 60) * _costPerMinute;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const Icon(Icons.pedal_bike, color: Colors.black, size: 28),
        title: const Text("NileGo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: _nileUniversity,
              zoom: 17,
            ),
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),

          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
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
                      _buildStatItem(Icons.map, "${_totalDistanceKm.toStringAsFixed(2)} km"),
                      Container(width: 1, height: 30, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 15)),
                      _buildStatItem(Icons.money, "₦${currentCost.toStringAsFixed(1)}"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
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