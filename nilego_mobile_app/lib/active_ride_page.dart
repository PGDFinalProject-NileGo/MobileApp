import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nilego_mobile_app/ride_summary_page.dart'; 
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ActiveRidePage extends StatefulWidget {
  final String bikeId;
  final BluetoothDevice connectedDevice;

  const ActiveRidePage({
    super.key, 
    required this.bikeId, 
    required this.connectedDevice
  });

  @override
  State<ActiveRidePage> createState() => _ActiveRidePageState();
}

class _ActiveRidePageState extends State<ActiveRidePage> {
  // --- VARIABLES ---
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isBikeLocked = false;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription? _bluetoothSubscription;
  GoogleMapController? _mapController;
  
  final double _costPerMinute = 10.0; 
  
  Position? _currentPosition;
  double _totalDistanceKm = 0.0;
  LatLng? _lastPosition;

  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylinePoints = [];
  static const LatLng _nileUniversity = LatLng(9.0405, 7.3986);

  // --- 1. FIREBASE START LOGIC ---
  void _registerRideStart() {
    final user = FirebaseAuth.instance.currentUser;
    // Database Logic Check: matches your "End Ride" logic perfectly.
    FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId).update({
      'status': 'in_use',
      'is_locked': false,
      'current_rider': user?.uid,
      'start_time': FieldValue.serverTimestamp(),
    });
  }

  // --- 2. SINGLE INIT STATE (FIXED) ---
  @override
  void initState() {
    super.initState();
    _registerRideStart();      // Update DB
    _unlockBike();             // Open Lock
    _startRide();              // Start Timer/GPS
    _setupBluetoothListener(); // Listen for Lock
  }

  // --- FUNCTION 3: AUTO UNLOCK ---
  void _unlockBike() async {
    // Safety check: Ensure device is connected
    if (widget.connectedDevice.isConnected == false) {
       try { await widget.connectedDevice.connect(); } catch (e) { print(e); }
    }

    List<BluetoothService> services = await widget.connectedDevice.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString() == "4fafc201-1fb5-459e-8fcc-c5c9c331914b") {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid.toString() == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
            String command = "UNLOCK";
            await c.write(command.codeUnits);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Unlocking Bike..."), backgroundColor: Colors.blue)
              );
            }
          }
        }
      }
    }
  }

  // --- FUNCTION 4: START RIDE (GPS & TIMER) ---
  void _startRide() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return; 
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, 
      ),
    ).listen((Position pos) {
      if (mounted) {
        LatLng currentLatLng = LatLng(pos.latitude, pos.longitude);
        _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));

        setState(() {
          _currentPosition = pos;
          _polylinePoints.add(currentLatLng);
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ride_path'),
              points: _polylinePoints,
              color: const Color(0xFF6750A4),
              width: 5,
            ),
          );

          if (_lastPosition != null) {
            double distanceMeters = Geolocator.distanceBetween(
              _lastPosition!.latitude, _lastPosition!.longitude,
              pos.latitude, pos.longitude,
            );
            _totalDistanceKm += distanceMeters / 1000;
          }
          _lastPosition = currentLatLng;
        });
      }
    });
  }

  // --- FUNCTION 5: BLUETOOTH LISTENER (SECURITY) ---
  void _setupBluetoothListener() async {
    List<BluetoothService> services = await widget.connectedDevice.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
          
          await c.setNotifyValue(true);
          _bluetoothSubscription = c.lastValueStream.listen((value) {
            String message = String.fromCharCodes(value);
            
            if (message.contains("LOCKED")) {
              setState(() {
                _isBikeLocked = true; 
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bike Locked! Ready to end ride."), backgroundColor: Colors.green)
                );
              }
            }
          });
        }
      }
    }
  }

  // --- FUNCTION 6: END RIDE ---
  Future<void> _endRide() async {
    if (!_isBikeLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ You must physically lock the bike first!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        )
      );
      return; 
    }

    _timer?.cancel();
    _positionStream?.cancel();

    double totalCost = (_secondsElapsed / 60) * _costPerMinute;
    if (totalCost < 5.0) totalCost = 5.0; 

    try {
      final user = FirebaseAuth.instance.currentUser;

      // 1. Update Bike Status (Make available again)
      await FirebaseFirestore.instance.collection('bikes').doc(widget.bikeId).update({
        'status': 'available',
        'is_locked': true,
        'current_rider': null,
      });

      // 2. Add to History
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
    _bluetoothSubscription?.cancel();
    super.dispose();
  }

  // --- UI BUILDER ---
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
                  
                  // OPTIONAL: Manual Unlock Button for Demo
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: _unlockBike, 
                    icon: const Icon(Icons.lock_open, color: Colors.blue),
                    label: const Text("Tap to Unlock", style: TextStyle(color: Colors.blue)),
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
                  backgroundColor: _isBikeLocked ? const Color(0xFFFF5252) : Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                icon: Icon(_isBikeLocked ? Icons.stop_circle_outlined : Icons.lock_open, color: Colors.white, size: 30),
                label: Text(
                  _isBikeLocked ? "End Ride & Pay" : "Lock Bike to End Ride", 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
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