import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'url_scan_screen.dart';
import 'qr_scan_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo placeholder
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: const Color(0xFF82E6FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFF82E6FF).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 64,
                      color: Color(0xFF82E6FF),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Title
                  Text(
                    'PHISH GUARD',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.michroma(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5F8FF),
                      letterSpacing: 0.12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'Phishing URL Detection using Machine Learning',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: const Color(0xFFADBBE3),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Scan URL button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UrlScanScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Scan URL'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF3DA9FF),
                        foregroundColor: const Color(0xFF00133A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Scan QR button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const QrScanScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Scan QR Code'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF66D0FF),
                        foregroundColor: const Color(0xFF00133A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Footer
                  Text(
                    'Ensemble Learning Model\nsoft_voting_ensemble v1.0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const Color(0xFF95A5D7),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
