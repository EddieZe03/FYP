import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_scanner_service.dart';
import '../services/api_service.dart';
import '../widgets/analyzing_overlay.dart';
import '../widgets/plexus_background.dart';
import 'result_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

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
      _isProcessing = true;
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
      body: PlexusBackground(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xBF080D3E),
                      border: Border.all(color: const Color(0x38A8C9FF)),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0x2410E6FF),
                            Color(0x00000000),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(color: Color(0x28A8C9FF)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x33FFFFFF)),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF82E6FF)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan QR Code',
                                  style: GoogleFonts.michroma(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF5F8FF),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Point the camera at a QR code or type the URL manually.',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    color: const Color(0xFFADBBE3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFA8C9FF).withValues(alpha: 0.22),
                              ),
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
                          if (_scanStatus != null)
                            Text(
                              _scanStatus!,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: const Color(0xFFA7B3DD),
                              ),
                            ),
                          const SizedBox(height: 24),
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
                            decoration: const InputDecoration(
                              hintText: 'https://example.com',
                              prefixIcon: Icon(Icons.link, color: Color(0xFF82E6FF)),
                            ),
                            style: GoogleFonts.spaceGrotesk(color: const Color(0xFFE7EDFF)),
                          ),
                          const SizedBox(height: 16),
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6978).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFF6978).withValues(alpha: 0.5),
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
                                    ? const Color(0xFF3DA9FF).withValues(alpha: 0.5)
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnalyzingOverlay(
              visible: _isProcessing,
              title: 'ANALYZING QR URL',
              subtitle: 'Extracting QR content and evaluating phishing risk.',
            ),
          ],
        ),
      ),
    );
  }
}
