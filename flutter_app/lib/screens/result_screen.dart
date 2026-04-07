import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prediction_model.dart';
import '../widgets/plexus_background.dart';

class ResultScreen extends StatelessWidget {
  final PredictionResponse response;

  const ResultScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final result = response.result;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(response.error ?? 'Unknown error'),
        ),
      );
    }

    return Scaffold(
      body: PlexusBackground(
        child: Center(
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
                            child: Icon(
                              result.isPhishing ? Icons.warning_rounded : Icons.shield_rounded,
                              color: result.isPhishing
                                  ? const Color(0xFFFFA0B0)
                                  : const Color(0xFF82E6FF),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detection Result',
                                  style: GoogleFonts.michroma(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF5F8FF),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'The model has evaluated the submitted URL and produced the result below.',
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
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: result.isPhishing
                                      ? [const Color(0xFFFF9FB0), const Color(0xFFFF6E85)]
                                      : [const Color(0xFF9FFFD4), const Color(0xFF63F0A3)],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                result.label.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: result.isPhishing
                                      ? const Color(0xFF2A0610)
                                      : const Color(0xFF002211),
                                  letterSpacing: 0.06,
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
                                color: const Color(0xFFA8C9FF).withValues(alpha: 0.22),
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Analyzed URL',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFA7B3DD),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  response.normalizedUrl ?? response.inputUrl ?? '',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    color: const Color(0xFFE7EDFF),
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  label: 'Confidence',
                                  value: result.confidence,
                                  icon: Icons.percent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  label: 'Risk Level',
                                  value: result.riskLevel,
                                  icon: Icons.warning_outlined,
                                  color: result.riskColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (result.explanation != null)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF82E6FF).withValues(alpha: 0.34),
                                  style: BorderStyle.solid,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Decision Notes',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFA7B3DD),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    result.explanation!,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      color: const Color(0xFFD7E2FF),
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          if (result.recommendations != null &&
                              result.recommendations!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF040828),
                                border: Border.all(
                                  color: const Color(0xFFA8C9FF).withValues(alpha: 0.22),
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Safety Recommendations',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFA7B3DD),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...result.recommendations!
                                      .map((rec) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  size: 18,
                                                  color: Color(0xFF63F0A3),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    rec,
                                                    style: GoogleFonts.spaceGrotesk(
                                                      fontSize: 13,
                                                      color: const Color(0xFFCFDDFF),
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      ,
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF3DA9FF),
                              ),
                              child: Text(
                                'Back',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF040828),
        border: Border.all(
          color: const Color(0xFFA8C9FF).withValues(alpha: 0.22),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFA7B3DD),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? const Color(0xFFF3F6FF),
            ),
          ),
        ],
      ),
    );
  }
}
