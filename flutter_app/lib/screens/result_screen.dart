import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prediction_model.dart';
import '../widgets/plexus_background.dart';

enum ScanFlowSource { url, qr }

enum ResultScreenAction { scanAgain, backHome }

class ResultScreen extends StatelessWidget {
  final PredictionResponse response;
  final ScanFlowSource source;

  const ResultScreen({
    super.key,
    required this.response,
    required this.source,
  });

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

    final hasDecisionNotes = (result.explanation ?? '').trim().isNotEmpty;

    return Scaffold(
      body: PlexusBackground(
        child: SafeArea(
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
                          border: Border.all(color: const Color(0x38A8C9FF)),
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
                                      border: Border.all(
                                          color: const Color(0x33FFFFFF)),
                                    ),
                                    child: Icon(
                                      result.isPhishing
                                          ? Icons.warning_rounded
                                          : Icons.shield_rounded,
                                      color: result.isPhishing
                                          ? const Color(0xFFFFA0B0)
                                          : const Color(0xFF82E6FF),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Detection Result',
                                          maxLines: 2,
                                          style: GoogleFonts.michroma(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFF5F8FF),
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'The model has evaluated the submitted URL and produced the result below.',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 12.5,
                                            color: const Color(0xFFADBBE3),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 9),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: result.isPhishing
                                              ? [
                                                  const Color(0xFFFF9FB0),
                                                  const Color(0xFFFF6E85)
                                                ]
                                              : [
                                                  const Color(0xFF9FFFD4),
                                                  const Color(0xFF63F0A3)
                                                ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        result.label.toUpperCase(),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: result.isPhishing
                                              ? const Color(0xFF2A0610)
                                              : const Color(0xFF002211),
                                          letterSpacing: 0.35,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A0F32),
                                      border: Border.all(
                                        color: const Color(0xFFA8C9FF)
                                            .withValues(alpha: 0.25),
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1282E6FF),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Analyzed URL',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF82E6FF),
                                            letterSpacing: 0.15,
                                          ),
                                        ),
                                        const SizedBox(height: 9),
                                        Text(
                                          response.normalizedUrl ??
                                              response.inputUrl ??
                                              '',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFFF0F4FF),
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
                                  if (hasDecisionNotes)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A0F32),
                                        border: Border.all(
                                          color: const Color(0xFF82E6FF)
                                              .withValues(alpha: 0.35),
                                          style: BorderStyle.solid,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x1282E6FF),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Decision Notes',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF82E6FF),
                                              letterSpacing: 0.15,
                                            ),
                                          ),
                                          const SizedBox(height: 9),
                                          Text(
                                            result.explanation!.trim(),
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 13,
                                              color: const Color(0xFFE2E8FF),
                                              height: 1.5,
                                              fontWeight: FontWeight.w400,
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
                                        color: const Color(0xFF0A0F32),
                                        border: Border.all(
                                          color: const Color(0xFFA8C9FF)
                                              .withValues(alpha: 0.25),
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x1282E6FF),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Safety Recommendations',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF82E6FF),
                                              letterSpacing: 0.15,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          ...result.recommendations!.map(
                                            (rec) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(2),
                                                    child: const Icon(
                                                      Icons.check_circle,
                                                      size: 18,
                                                      color: Color(0xFF63F0A3),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 11),
                                                  Expanded(
                                                    child: Text(
                                                      rec,
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        fontSize: 13,
                                                        color: const Color(
                                                            0xFFE2E8FF),
                                                        height: 1.5,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(ResultScreenAction.scanAgain),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        backgroundColor:
                                            const Color(0xFF3DA9FF),
                                        shadowColor: const Color(0x663DA9FF),
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        source == ScanFlowSource.url
                                            ? 'Scan URL Again'
                                            : 'Scan QR Code Again',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(ResultScreenAction.backHome),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        side: const BorderSide(
                                            color: Color(0xFF82E6FF),
                                            width: 1.5),
                                        foregroundColor:
                                            const Color(0xFFBDEBFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Back to Home',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
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
              );
            },
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F32),
        border: Border.all(
          color: const Color(0xFFA8C9FF).withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1282E6FF),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF82E6FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: const Color(0xFF82E6FF),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF82E6FF),
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color ?? const Color(0xFFF0F4FF),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
