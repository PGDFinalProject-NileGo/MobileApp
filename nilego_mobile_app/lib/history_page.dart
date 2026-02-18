import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('ride_history')
            .where('user_id', isEqualTo: user?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}")); 
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return const Center(child: Text("No rides yet!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index].data() as Map<String, dynamic>;

              // --- 1. LOGIC FOR DURATION ---
              final dynamic durationData = ride['duration_seconds'] ?? ride['duration'];
              String durationDisplay;

              if (durationData is int) {
                // Formats old numeric seconds to MM:SS
                durationDisplay = "${(durationData ~/ 60).toString().padLeft(2, '0')}:${(durationData % 60).toString().padLeft(2, '0')}";
              } else {
                // Uses the string "05:22" from newer data
                durationDisplay = durationData?.toString() ?? "00:00";
              }

              // --- 2. LOGIC FOR DISTANCE & DATE ---
              final double distance = (ride['distance_km'] ?? 0.0).toDouble();
              final Timestamp? ts = ride['timestamp'];
              final dateStr = ts != null 
                  ? DateFormat('MMM d, yyyy . h:mm a').format(ts.toDate()) 
                  : "Just now";

              // --- 3. YOUR ORIGINAL UI DESIGN ---
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.pedal_bike, size: 40, color: Colors.black),
                    const SizedBox(height: 10),
                    Text(
                      dateStr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Displays real GPS distance and formatted time
                        Text("$durationDisplay mins . ${distance.toStringAsFixed(1)}km"),
                        Text(
                          "₦${(ride['cost'] ?? 0).toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}