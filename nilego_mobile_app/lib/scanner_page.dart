import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Bike QR')),
      body: MobileScanner(
        // The controller manages the camera (flash, front/back)
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String code = barcode.rawValue ?? "Unknown";
            
            // For your defense: This is where the IoT logic begins
            debugPrint('Bike ID Scanned: $code');
            
            // Automatically close scanner and go back with the ID
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}