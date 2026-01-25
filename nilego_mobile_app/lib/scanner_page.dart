import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

enum ScanStatus { scanning, connecting, connected }

class _ScannerPageState extends State<ScannerPage> {
  // Controller to handle Flashlight and Camera
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  ScanStatus _status = ScanStatus.scanning;
  String? _scannedCode;

  // The Logic to handle the 3-step flow
  void _handleDetection(BarcodeCapture capture) async {
    // Only proceed if we are currently in 'scanning' mode
    if (_status != ScanStatus.scanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      _scannedCode = barcode.rawValue;
      if (_scannedCode != null) {
        // 1. STOP SCANNING & START CONNECTING
        setState(() {
          _status = ScanStatus.connecting;
        });
        
        // Simulate Bluetooth Handshake (2 seconds)
        await Future.delayed(const Duration(seconds: 2));

        // 2. SHOW SUCCESS STATE
        if (mounted) {
          setState(() {
            _status = ScanStatus.connected;
          });
        }

        // Simulate Success Message (1.5 seconds)
        await Future.delayed(const Duration(milliseconds: 1500));

        // 3. EXIT
        if (mounted) {
          Navigator.pop(context, _scannedCode);
        }
        break; // Stop loop
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. THE CAMERA FEED
          MobileScanner(
            controller: controller,
            onDetect: _handleDetection,
          ),

          // 2. THE DARK OVERLAY WITH CUTOUT
          CustomPaint(
            painter: ScannerOverlayPainter(
              borderColor: Colors.white,
              borderRadius: 12,
              borderLength: 30,
              borderWidth: 5,
              cutoutSize: 280, 
            ),
            child: Container(),
          ),

          // 3. UI LAYERS (Flashlight, Text, and Animations)
          SafeArea(
            child: Column(
              children: [
                // TOP HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Scan QR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 28), 
                    ],
                  ),
                ),

                const Spacer(),

                // FLASHLIGHT (Only show when scanning)
                if (_status == ScanStatus.scanning)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), 
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: ValueListenableBuilder(
                          valueListenable: controller, 
                          builder: (context, state, child) {
                            return Icon(
                              state.torchState == TorchState.on 
                                  ? Icons.flash_on 
                                  : Icons.flash_off,
                              color: Colors.white,
                              size: 28,
                            );
                          },
                        ),
                        onPressed: () => controller.toggleTorch(),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 68), // Spacer to keep layout stable

                // CENTER CONTENT (The Icons inside the Box)
                SizedBox(
                  height: 280,
                  child: Center(
                    child: _buildCenterIcon(),
                  ),
                ),

                // BOTTOM TEXT (Dynamic based on state)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: _buildStatusText(),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to switch the icon inside the square
  Widget _buildCenterIcon() {
    switch (_status) {
      case ScanStatus.scanning:
        return const SizedBox(); // Empty when scanning
      
      case ScanStatus.connecting:
        return Stack(
          alignment: Alignment.center,
          children: const [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                strokeWidth: 8,
                color: Color(0xFF6750A4), // Deep Purple
                backgroundColor: Color(0xFFE8DEF8), // Light Purple
              ),
            ),
            Icon(Icons.bluetooth, color: Colors.black, size: 50),
          ],
        );

      case ScanStatus.connected:
        return const Icon(
          Icons.check, 
          color: Colors.green, 
          size: 100, // Big Green Check
        );
    }
  }

  // Helper to switch the text below
// inside scanner_page.dart

  Widget _buildStatusText() {
    switch (_status) {
      case ScanStatus.scanning:
        return const Text(
          "Align QR code within frame\nto unlock",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
        );

      case ScanStatus.connecting:
        return const Text(
          "Connecting to Bicycle System...",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.yellow, 
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        );

      case ScanStatus.connected:
        // ✨ UPDATED TEXT HERE
        return const Text(
          "Bicycle Unlocked Successfully!\nSafe Ride.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.green, 
            fontSize: 18, 
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }
  }

// 🎨 CUSTOM PAINTER (Standard Overlay)
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutoutSize;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutoutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final Rect screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Rect cutoutRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: cutoutSize,
      height: cutoutSize,
    );

    final Path backgroundPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(screenRect),
      Path()..addRRect(RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius))),
    );

    canvas.drawPath(backgroundPath, backgroundPaint);

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left, cutoutRect.top + borderLength)
        ..lineTo(cutoutRect.left, cutoutRect.top)
        ..lineTo(cutoutRect.left + borderLength, cutoutRect.top),
      borderPaint,
    );
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - borderLength, cutoutRect.top)
        ..lineTo(cutoutRect.right, cutoutRect.top)
        ..lineTo(cutoutRect.right, cutoutRect.top + borderLength),
      borderPaint,
    );
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left, cutoutRect.bottom - borderLength)
        ..lineTo(cutoutRect.left, cutoutRect.bottom)
        ..lineTo(cutoutRect.left + borderLength, cutoutRect.bottom),
      borderPaint,
    );
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - borderLength, cutoutRect.bottom)
        ..lineTo(cutoutRect.right, cutoutRect.bottom)
        ..lineTo(cutoutRect.right, cutoutRect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}