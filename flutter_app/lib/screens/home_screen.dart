import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'url_scan_screen.dart';
import 'qr_scan_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF010528),
              Color(0xFF030D4F),
              Color(0xFF004B8E),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
                decoration: BoxDecoration(
                  color: const Color(0xBF080D3E),
                  border: Border.all(color: const Color(0x48A8C9FF)),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80010314),
                      blurRadius: 44,
                      offset: Offset(0, 26),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 126,
                      height: 126,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0x52FFFFFF)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'PHISH\nGUARD',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.michroma(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                        color: const Color(0xFFF5F9FF),
                        letterSpacing: 2.2,
                        shadows: const [
                          Shadow(
                            color: Color(0x5882E6FF),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Text(
                        'Phish Guard is a machine learning phishing URL detector that evaluates suspicious links and explains risk with clear confidence and safety recommendations before you click.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          color: const Color(0xFFADBBE3),
                          height: 1.65,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _HomeActionButton(
                            title: 'Scan URL',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const UrlScanScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HomeActionButton(
                            title: 'Scan QR Code',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const QrScanScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        foregroundColor: const Color(0xFF00133A),
        backgroundColor: const Color(0xFF6BD3FF),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        shadowColor: const Color(0x596BD3FF),
        elevation: 8,
      ),
      child: Text(title),
    );
  }
}
