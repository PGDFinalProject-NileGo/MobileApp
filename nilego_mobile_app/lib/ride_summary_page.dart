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
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializeRoute();
  }

  void _initializeRoute() {
    if (widget.routePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ride_route'),
          points: widget.routePoints,
          color: const Color(0xFF6750A4),
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (widget.routePoints.isNotEmpty) {
      LatLngBounds bounds = _getBounds(widget.routePoints);
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLat = points.first.latitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // --- 📡 UPDATED PAYMENT LOGIC ---
  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      // 1. Check Wallet Balance
      final walletDoc = await FirebaseFirestore.instance.collection('wallets').doc(user.uid).get();
      
      if (!walletDoc.exists || (walletDoc.data()?['balance'] ?? 0) < widget.cost) {
        throw "Insufficient balance. Please top up your wallet.";
      }

      // 2. Perform Atomic Transaction (Deduct Balance + Save History)
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Deduct from Wallet
      batch.update(FirebaseFirestore.instance.collection('wallets').doc(user.uid), {
        'balance': FieldValue.increment(-widget.cost),
      });

      // Save to History
      DocumentReference historyRef = FirebaseFirestore.instance.collection('ride_history').doc();
      batch.set(historyRef, {
        'user_id': user.uid,
        'bike_id': widget.bikeId,
        'cost': widget.cost,
        'distance_km': widget.distanceKm,
        'duration': widget.duration,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Payment Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text("Ride Summary", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.routePoints.isNotEmpty ? widget.routePoints.first : const LatLng(9.0405, 7.3986),
              zoom: 15,
            ),
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          if (_isProcessing || _isSuccess)
            Container(color: Colors.black.withOpacity(0.7)),

          Center(child: _buildCenterCard()),

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

  Widget _buildCenterCard() {
    if (_isProcessing) {
      return _buildMessageCard(
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF6750A4)),
            const SizedBox(height: 20),
            const Text("Processing Payment...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("₦${widget.cost.toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_isSuccess) {
      return _buildMessageCard(
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 10),
            const Text("Ride Paid!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6750A4), shape: const StadiumBorder()),
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Done", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    return Container(
      width: 320,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15), boxShadow: [const BoxShadow(blurRadius: 10, color: Colors.black26)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Ride Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          _buildStatRow(Icons.timer_outlined, "Duration", widget.duration),
          _buildStatRow(Icons.straighten_outlined, "Distance", "${widget.distanceKm.toStringAsFixed(2)} km"),
          _buildStatRow(Icons.payments_outlined, "Cost", "₦${widget.cost.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _buildMessageCard({required Widget child}) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Column(
      children: [
        const Card(
          color: Colors.amber,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text("Please make sure the bike is physically locked before paying.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: const StadiumBorder()),
            onPressed: _handlePayment,
            child: const Text("Confirm Payment", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}