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
                      child: const Icon(
                        Icons.shield_rounded,
                        size: 64,
                        color: Color(0xFF82E6FF),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Phish Guard',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.michroma(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F9FF),
                        letterSpacing: 0.14 * 16,
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
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _HomeActionButton(
                          title: 'Scan URL',
                          icon: Icons.travel_explore,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UrlScanScreen(),
                              ),
                            );
                          },
                        ),
                        _HomeActionButton(
                          title: 'Scan QR Code',
                          icon: Icons.qr_code_scanner_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const QrScanScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Ensemble Learning Model',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: const Color(0xFF95A5D7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'soft_voting_ensemble v1.0',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F9FF),
                      ),
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
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          foregroundColor: const Color(0xFF00133A),
          backgroundColor: const Color(0xFF6BD3FF),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          shadowColor: const Color(0x596BD3FF),
          elevation: 8,
        ),
      ),
    );
  }
}
