import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/prediction_model.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.0.12:5000'; // Change to your Flask server IP

  // For testing on device, use your machine's IP: http://192.168.x.x:5000
  static String get baseUrl => _baseUrl;

  static Future<PredictionResponse> predictUrl(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return PredictionResponse.fromJson(jsonDecode(response.body));
      } else {
        return PredictionResponse(
          ok: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PredictionResponse(
        ok: false,
        error: 'Network error: $e',
      );
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static void setBaseUrl(String newUrl) {
    // Allow runtime configuration of API URL
    // Usage: ApiService.setBaseUrl('http://192.168.1.100:5000');
  }
}
