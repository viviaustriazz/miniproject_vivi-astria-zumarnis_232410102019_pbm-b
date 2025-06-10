// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'hasil_scan_qr.dart';
import 'storage_services.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  bool isFrontCamera = false;
  bool hasScanned = false;
  String? previewUrl;
  bool isValidUrl = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin kamera diperlukan untuk scan QR Code')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.pink[300],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: Icon(isFrontCamera ? Icons.camera_front : Icons.camera_rear, color: Colors.white),
            onPressed: _flipCamera,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: cameraController,
              onDetect: _handleBarcode,
            ),
          ),
          if (previewUrl != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: isValidUrl
                        ? InkWell(
                            onTap: () => _launchUrl(previewUrl!),
                            child: Text(
                              previewUrl!,
                              style: const TextStyle(
                                color: Colors.pink,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        : Text(previewUrl!),
                  ),
                  if (isValidUrl)
                    IconButton(
                      icon: const Icon(Icons.launch, color: Colors.pink),
                      onPressed: () => _launchUrl(previewUrl!),
                    ),
                ],
              ),
            ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Arahkan kamera ke QR Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'QR Code akan otomatis ter-scan',
                    style: TextStyle(fontSize: 14, color: Colors.pink[300]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBarcode(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null) {
        setState(() {
          previewUrl = code;
          isValidUrl = code.startsWith('http://') || code.startsWith('https://');
        });

        if (!hasScanned) {
          hasScanned = true;
          _handleScanResult(code);
        }
      }
    }
  }

  Future<void> _handleScanResult(String code) async {
    final result = ScanResult(
      data: code,
      timestamp: DateTime.now(),
      type: _getDataType(code),
    );

    await StorageService.saveScanResult(result);
    if (!mounted) return;
    _showResultDialog(result);
  }

  String _getDataType(String data) {
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return 'URL';
    } else if (data.contains('@') && data.contains('.')) {
      return 'Email';
    } else if (RegExp(r'^\d+$').hasMatch(data)) {
      return 'Number';
    } else {
      return 'Text';
    }
  }

  void _showResultDialog(ScanResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.qr_code, color: Colors.pink),
              SizedBox(width: 10),
              Text('Scan Berhasil!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipe: ${result.displayType}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Data:'),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.data,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => hasScanned = false);
              },
              child: const Text('Scan Lagi'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[300],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Selesai'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka URL';
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka URL')),
      );
    }
  }

  Future<void> _toggleFlash() async {
    await cameraController.toggleTorch();
    if (!mounted) return;
    setState(() => isFlashOn = !isFlashOn);
  }

  Future<void> _flipCamera() async {
    await cameraController.switchCamera();
    if (!mounted) return;
    setState(() => isFrontCamera = !isFrontCamera);
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
