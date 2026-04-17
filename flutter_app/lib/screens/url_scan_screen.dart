import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/analyzing_overlay.dart';
import '../widgets/plexus_background.dart';
import 'result_screen.dart';

class UrlScanScreen extends StatefulWidget {
  const UrlScanScreen({super.key});

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
      body: PlexusBackground(
        child: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xBF080D3E),
                              border:
                                  Border.all(color: const Color(0x38A8C9FF)),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 22),
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
                                      bottom:
                                          BorderSide(color: Color(0x28A8C9FF)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: const Color(0x14FFFFFF),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: const Color(0x33FFFFFF)),
                                        ),
                                        child: const Icon(Icons.travel_explore,
                                            color: Color(0xFF82E6FF)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Scan URL',
                                              style: GoogleFonts.michroma(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFF5F8FF),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Enter a URL and the model will evaluate its risk.',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        decoration: const InputDecoration(
                                          hintText: 'https://example.com',
                                          prefixIcon: Icon(Icons.link,
                                              color: Color(0xFF82E6FF)),
                                        ),
                                        style: GoogleFonts.spaceGrotesk(
                                            color: const Color(0xFFE7EDFF)),
                                        onSubmitted: (_) => _submit(),
                                      ),
                                      const SizedBox(height: 20),
                                      if (_error != null)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6978)
                                                .withValues(alpha: 0.16),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: const Color(0xFFFF6978)
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.error_outline,
                                                  color: Color(0xFFFFD6DC)),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _error!,
                                                  style: const TextStyle(
                                                      color: Color(0xFFFFD6DC)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed:
                                              _isLoading ? null : _submit,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            backgroundColor: _isLoading
                                                ? const Color(0xFF3DA9FF)
                                                    .withValues(alpha: 0.5)
                                                : const Color(0xFF3DA9FF),
                                            disabledBackgroundColor:
                                                const Color(0xFF3DA9FF)
                                                    .withValues(alpha: 0.5),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      Color(0xFF00133A),
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  'Scan URL',
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
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
                                            color: const Color(0xFFA8C9FF)
                                                .withValues(alpha: 0.22),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tips for safer browsing:',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFE7EDFF),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...[
                                              'Always check the domain name carefully',
                                              'Look for HTTPS in the address bar',
                                              'Avoid clicking suspicious links'
                                            ].map(
                                              (tip) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                child: Text(
                                                  '• $tip',
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    fontSize: 13,
                                                    color:
                                                        const Color(0xFFCFDDFF),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            AnalyzingOverlay(visible: _isLoading),
          ],
        ),
      ),
    );
  }
}
