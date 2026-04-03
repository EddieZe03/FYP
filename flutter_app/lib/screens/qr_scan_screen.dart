import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_scanner_service.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import 'result_screen.dart';
import 'url_scan_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({Key? key}) : super(key: key);

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final TextEditingController _urlController = TextEditingController();
  MobileScannerController? _cameraController;
  bool _isProcessing = false;
  String? _error;
  String? _scanStatus = 'Ready to scan';

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodes) async {
    if (_isProcessing) return;

    final barcode = barcodes.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _isProcessing = true;

    final scannedValue = barcode!.rawValue!;
    final url = QrScannerService.normalizeUrl(scannedValue);

    setState(() {
      _urlController.text = url;
      _scanStatus = 'QR detected: $url';
    });

    // Auto-submit after brief delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      await _submitUrl(url);
    }
  }

  Future<void> _submitUrl(String url) async {
    if (url.isEmpty) {
      setState(() {
        _error = 'Please provide a URL';
        _isProcessing = false;
      });
      return;
    }

    setState(() {
      _error = null;
    });

    final response = await ApiService.predictUrl(url);

    if (!mounted) return;

    if (response.ok && response.result != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultScreen(response: response),
        ),
      );
    } else {
      setState(() {
        _error = response.error ?? 'Prediction failed';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.michroma(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF010528),
              const Color(0xFF030D4F),
              const Color(0xFF004B8E),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Camera Scanner
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFA8C9FF).withOpacity(0.22),
                    ),
                    overflow: Overflow.hidden,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    height: 280,
                    child: MobileScanner(
                      controller: _cameraController,
                      onDetect: _handleBarcode,
                      errorBuilder: (context, error, child) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  size: 40, color: Color(0xFF82E6FF)),
                              const SizedBox(height: 12),
                              Text(
                                'Camera access required',
                                style: GoogleFonts.spaceGrotesk(
                                  color: const Color(0xFFE7EDFF),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status
                if (_scanStatus != null)
                  Text(
                    _scanStatus!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const Color(0xFFA7B3DD),
                    ),
                  ),
                const SizedBox(height: 24),

                // Manual URL input
                Text(
                  'Or enter URL manually:',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD8E5FF),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  enabled: !_isProcessing,
                  decoration: InputDecoration(
                    hintText: 'https://example.com',
                    prefixIcon: const Icon(Icons.link, color: Color(0xFF82E6FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFFE7EDFF)),
                ),
                const SizedBox(height: 16),

                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6978).withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFF6978).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFFFD6DC)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFFFD6DC)),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _submitUrl(_urlController.text),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _isProcessing
                          ? const Color(0xFF3DA9FF).withOpacity(0.5)
                          : const Color(0xFF3DA9FF),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00133A),
                              ),
                            ),
                          )
                        : const Text('Scan QR Code'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
