import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideSummaryPage extends StatefulWidget {
  final String bikeId;
  final String duration;
  final double cost;
  final double distanceKm;
  final List<LatLng> routePoints;

  const RideSummaryPage({
    super.key,
    required this.bikeId,
    required this.duration,
    required this.cost,
    required this.distanceKm,
    required this.routePoints,
  });

  @override
  State<RideSummaryPage> createState() => _RideSummaryPageState();
}

class _RideSummaryPageState extends State<RideSummaryPage> {
  static const LatLng _nileUniversity = LatLng(9.0405, 7.3986);
  final Set<Polyline> _polylines = {};
  
  // STATE MANAGEMENT FOR PAYMENT FLOW
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.routePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ride_route'),
          points: widget.routePoints,
          color: Colors.greenAccent[400]!,
          width: 5,
        ),
      );
    }
  }

  // 📡 THE REAL PAYMENT & LOCK LOGIC
  Future<void> _handlePayment() async {
    // 1. SWITCH UI TO "PROCESSING"
    setState(() {
      _isProcessing = true;
    });

    // Fake Payment Gateway Delay (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    try {
      // 2. NOW WE SAVE HISTORY
      final user = FirebaseAuth.instance.currentUser;
      final historyRef = FirebaseFirestore.instance.collection('ride_history');

      // Save History
      await historyRef.add({
        'user_id': user?.uid,
        'bike_id': widget.bikeId,
        'cost': widget.cost,
        'distance_km': widget.distanceKm,
        'duration_seconds': _parseDurationToSeconds(widget.duration), // Helper for history
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. SWITCH UI TO "SUCCESS"
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
      }

    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: $e")));
    }
  }
  
  // Helper to save duration as a number for history
  int _parseDurationToSeconds(String durationStr) {
    try {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
      }
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const Icon(Icons.pedal_bike, color: Colors.black, size: 28),
        title: const Text("NileGo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: Stack(
        children: [
          // 🗺️ MAP BACKGROUND
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.routePoints.isNotEmpty ? widget.routePoints.last : _nileUniversity,
              zoom: 15.5,
            ),
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // ◼️ DARK OVERLAY (Shows when Processing or Success)
          if (_isProcessing || _isSuccess)
            Container(color: Colors.black.withOpacity(0.6)),

          // 🔲 CENTER CARD (Changes based on State)
          Center(
            child: _buildCenterCard(),
          ),

          // ⚠️ BOTTOM WARNING (Only show in Summary State)
          if (!_isProcessing && !_isSuccess)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildBottomAction(),
            ),
        ],
      ),
    );
  }

  // LOGIC TO SWITCH THE CARD CONTENT
  Widget _buildCenterCard() {
    // STATE 2: PROCESSING
    if (_isProcessing) {
      return Container(
        width: 300,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60, height: 60,
              child: CircularProgressIndicator(color: Color(0xFF6750A4), strokeWidth: 6),
            ),
            const SizedBox(height: 20),
            const Text("Processing Payment...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text("Deducting ₦${widget.cost.toStringAsFixed(2)} from Wallet", style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    // STATE 3: SUCCESS
    if (_isSuccess) {
      return Container(
        width: 300,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, color: Colors.green, size: 80), // Big Green Check
            const SizedBox(height: 20),
            const Text("Payment Successful", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            const Text("New Balance: ₦4,850.00", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8DEF8), // Light Purple
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.home, color: Color(0xFF6750A4)),
                label: const Text("Back to Home", style: TextStyle(color: Color(0xFF6750A4), fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ),
          ],
        ),
      );
    }

    // STATE 1: SUMMARY (Default)
    return Container(
      width: 300,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text("Ride Completed.", style: TextStyle(color: Colors.green, fontSize: 18, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          _buildStatLine("Time", widget.duration),
          _buildStatLine("Distance", "${widget.distanceKm.toStringAsFixed(1)}km"),
          _buildStatLine("Total Cost", "₦${widget.cost.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFEBC346), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(child: Text("Warning:\n\"Please ensure the physical lock is closed.\"", textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600))),
              Icon(Icons.close, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 180,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 4),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text("Pay & Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            onPressed: _handlePayment, // 🟢 Trigger the 3-step flow
          ),
        ),
      ],
    );
  }

  Widget _buildStatLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.white),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w400)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}