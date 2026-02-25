import 'dart:async';
import 'dart:io'; // Needed for Platform check
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'active_ride_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

enum ScanStatus { scanning, connecting, connected, error }

class _ScannerPageState extends State<ScannerPage> {
  // Controller to handle Flashlight and Camera
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  ScanStatus _status = ScanStatus.scanning;
  String? _scannedCode;
  StreamSubscription? _scanSubscription;

  // 1. HANDLE QR DETECTION
  void _handleDetection(BarcodeCapture capture) async {
    // Only scan if we are in 'scanning' mode
    if (_status != ScanStatus.scanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      _scannedCode = barcode.rawValue;
      
      if (_scannedCode != null) {
        // Stop the camera scanning immediately
        controller.stop(); 

        setState(() {
          _status = ScanStatus.connecting;
        });

        debugPrint("QR Code Found: $_scannedCode");

        // --- 🔍 NEW: CHECK BLUETOOTH STATUS FIRST ---
        try {
          // Check if Bluetooth is ON
          if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
            debugPrint("Bluetooth is OFF. Attempting to turn on...");
            
            // For Android, we can try to turn it on
            if (Platform.isAndroid) {
              await FlutterBluePlus.turnOn();
            } else {
              // iOS doesn't allow auto-turn on, show error
              throw "Please turn on Bluetooth manually.";
            }

            // Wait a moment for it to actually turn on
            await Future.delayed(const Duration(seconds: 2));
            
            // Check again
            if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
               throw "Bluetooth is still OFF. Cannot connect.";
            }
          }

          debugPrint("Bluetooth is ON. Starting Scan...");
          
          BluetoothDevice? targetDevice;

          // Start scanning for devices (4 second timeout)
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

          // Listen to scan results
          _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
            for (ScanResult r in results) {
              if (r.device.platformName == _scannedCode) {
                targetDevice = r.device;
                FlutterBluePlus.stopScan(); // Found it!
                _connectToDevice(targetDevice!); 
                break; 
              }
            }
          });

          // Wait for scan to finish (4 seconds)
          await Future.delayed(const Duration(seconds: 4));
          
          // If we didn't find it...
          if (targetDevice == null) {
            throw "Bike not found nearby. Move closer!";
          }

        } catch (e) {
          debugPrint("Scan Error: $e");
          _handleError(e.toString());
        }
        break; // Exit the loop
      }
    }
  }

  // 2. CONNECT TO DEVICE
  void _connectToDevice(BluetoothDevice device) async {
    try {
      // Cancel scan listener just in case
      _scanSubscription?.cancel();

      await device.connect();
      debugPrint("Connected to ${device.platformName}");

      if (mounted) {
        setState(() { _status = ScanStatus.connected; });
        
        // Wait 1 second for visual feedback (Green Checkmark)
        await Future.delayed(const Duration(seconds: 1));

        // NAVIGATE TO ACTIVE RIDE PAGE
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveRidePage(
              bikeId: _scannedCode!,      
              connectedDevice: device, 
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Connection failed: $e");
      _handleError("Connection Failed. Try again.");
    }
  }

  // 3. ERROR HANDLER
  void _handleError(String message) {
    if (mounted) {
      setState(() { _status = ScanStatus.error; });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        )
      );

      // Restart scanning after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() { _status = ScanStatus.scanning; });
          controller.start();
        }
      });
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    controller.dispose();
    super.dispose();
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

          // 2. THE DARK OVERLAY
          CustomPaint(
            painter: ScannerOverlayPainter(
              borderColor: _status == ScanStatus.error ? Colors.red : Colors.white,
              borderRadius: 12,
              borderLength: 30,
              borderWidth: 5,
              cutoutSize: 280, 
            ),
            child: Container(),
          ),

          // 3. UI LAYERS
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text("Scan QR", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 28), 
                    ],
                  ),
                ),

                const Spacer(),

                // Flashlight
                if (_status == ScanStatus.scanning)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: IconButton(
                        icon: ValueListenableBuilder(
                          valueListenable: controller, 
                          builder: (context, state, child) {
                            return Icon(state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 28);
                          },
                        ),
                        onPressed: () => controller.toggleTorch(),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 68),

                // Center Icon
                SizedBox(
                  height: 280,
                  child: Center(child: _buildCenterIcon()),
                ),

                // Bottom Text
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

  Widget _buildCenterIcon() {
    switch (_status) {
      case ScanStatus.scanning: return const SizedBox();
      case ScanStatus.connecting:
        return Stack(
          alignment: Alignment.center,
          children: const [
            SizedBox(
              width: 100, height: 100,
              child: CircularProgressIndicator(strokeWidth: 8, color: Color(0xFF6750A4), backgroundColor: Color(0xFFE8DEF8)),
            ),
            Icon(Icons.bluetooth, color: Colors.white, size: 50), // Changed to white for better visibility
          ],
        );
      case ScanStatus.connected: return const Icon(Icons.check, color: Colors.green, size: 100);
      case ScanStatus.error: return const Icon(Icons.error_outline, color: Colors.red, size: 100);
    }
  }

  Widget _buildStatusText() {
    switch (_status) {
      case ScanStatus.scanning:
        return const Text("Align QR code within frame\nto unlock", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16));
      case ScanStatus.connecting:
        return const Text("Searching for Bike...", textAlign: TextAlign.center, style: TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold));
      case ScanStatus.connected:
        return const Text("Connected!", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold));
      case ScanStatus.error:
        return const Text("Error Connecting", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold));
    }
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutoutSize;

  ScannerOverlayPainter({required this.borderColor, required this.borderRadius, required this.borderLength, required this.borderWidth, required this.cutoutSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Paint backgroundPaint = Paint()..color = Colors.black.withOpacity(0.6)..style = PaintingStyle.fill;
    final Rect screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Rect cutoutRect = Rect.fromCenter(center: Offset(centerX, centerY), width: cutoutSize, height: cutoutSize);
    final Path backgroundPath = Path.combine(PathOperation.difference, Path()..addRect(screenRect), Path()..addRRect(RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius))));
    canvas.drawPath(backgroundPath, backgroundPaint);
    final Paint borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = borderWidth..strokeCap = StrokeCap.round;

    canvas.drawPath(Path()..moveTo(cutoutRect.left, cutoutRect.top + borderLength)..lineTo(cutoutRect.left, cutoutRect.top)..lineTo(cutoutRect.left + borderLength, cutoutRect.top), borderPaint);
    canvas.drawPath(Path()..moveTo(cutoutRect.right - borderLength, cutoutRect.top)..lineTo(cutoutRect.right, cutoutRect.top)..lineTo(cutoutRect.right, cutoutRect.top + borderLength), borderPaint);
    canvas.drawPath(Path()..moveTo(cutoutRect.left, cutoutRect.bottom - borderLength)..lineTo(cutoutRect.left, cutoutRect.bottom)..lineTo(cutoutRect.left + borderLength, cutoutRect.bottom), borderPaint);
    canvas.drawPath(Path()..moveTo(cutoutRect.right - borderLength, cutoutRect.bottom)..lineTo(cutoutRect.right, cutoutRect.bottom)..lineTo(cutoutRect.right, cutoutRect.bottom - borderLength), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}