import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerService {
  static Future<String?> scanQr() async {
    // This will be called from the QR scan screen
    // mobile_scanner package handles the camera access
    return null;
  }

  static bool isValidUrl(String text) {
    try {
      Uri.parse(text);
      return text.startsWith('http://') || text.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  static String normalizeUrl(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'http://$trimmed';
    }
    return trimmed;
  }
}
