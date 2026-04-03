import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/prediction_model.dart';
import 'result_screen.dart';

class UrlScanScreen extends StatefulWidget {
  const UrlScanScreen({Key? key}) : super(key: key);

  @override
  State<UrlScanScreen> createState() => _UrlScanScreenState();
}

class _UrlScanScreenState extends State<UrlScanScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _submit() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.predictUrl(url);

    if (!mounted) return;

    if (response.ok && response.result != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(response: response),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _error = response.error ?? 'Prediction failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan URL',
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
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Website URL',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD8E5FF),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  enabled: !_isLoading,
                  inputFormatters: [],
                  decoration: InputDecoration(
                    hintText: 'https://example.com',
                    prefixIcon: const Icon(Icons.link, color: Color(0xFF82E6FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFFE7EDFF)),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _isLoading
                          ? const Color(0xFF3DA9FF).withOpacity(0.5)
                          : const Color(0xFF3DA9FF),
                      disabledBackgroundColor: const Color(0xFF3DA9FF).withOpacity(0.5),
                    ),
                    child: _isLoading
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
                        : Text(
                            'Scan URL',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF040828),
                    border: Border.all(
                      color: const Color(0xFFA8C9FF).withOpacity(0.22),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips for safer browsing:',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE7EDFF),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...['Always check the domain name carefully',
                          'Look for HTTPS in the address bar',
                          'Avoid clicking suspicious links'].map(
                        (tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '• $tip',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: const Color(0xFFCFDDFF),
                            ),
                          ),
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
    );
  }
}
