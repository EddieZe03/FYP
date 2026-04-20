import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                          color: const Color(0xC2080D3E),
                          border: Border.all(color: const Color(0x2AA8C9FF)),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55010314),
                              blurRadius: 36,
                              offset: Offset(0, 22),
                            ),
                          ],
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
                                      color: const Color(0x0EFFFFFF),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0x26FFFFFF)),
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
                                            fontSize: 12.8,
                                            color: const Color(0xFFBBC9EF),
                                            height: 1.4,
                                            letterSpacing: 0.04,
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
                                          horizontal: 18, vertical: 10),
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
                                  const SizedBox(height: 22),
                                  Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 132,
                                    ),
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF101850),
                                          Color(0xFF0A0F32),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFFA8C9FF)
                                            .withValues(alpha: 0.25),
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1582E6FF),
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF82E6FF)
                                                            .withValues(
                                                                alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: const Icon(
                                                    Icons.link_rounded,
                                                    size: 14,
                                                    color: Color(0xFF82E6FF),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Analyzed URL',
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFF82E6FF),
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            InkWell(
                                              onTap: () => _copyUrl(
                                                context,
                                                response.normalizedUrl ??
                                                    response.inputUrl ??
                                                    '',
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF82E6FF)
                                                      .withValues(alpha: 0.10),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    999,
                                                  ),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFF82E6FF)
                                                            .withValues(
                                                                alpha: 0.16),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.copy_rounded,
                                                      size: 13,
                                                      color: Color(0xFFBDEBFF),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Copy',
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: const Color(
                                                            0xFFBDEBFF),
                                                        letterSpacing: 0.12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          constraints: const BoxConstraints(
                                            minHeight: 64,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF0E1B44),
                                                Color(0xFF070D27),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(13),
                                            border: Border.all(
                                              color: const Color(0xFF82E6FF)
                                                  .withValues(alpha: 0.18),
                                            ),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              response.normalizedUrl ??
                                                  response.inputUrl ??
                                                  '',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFF4F7FF),
                                                height: 1.54,
                                                letterSpacing: 0.05,
                                              ),
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _buildMetricCard(
                                    label: 'Confidence',
                                    value: result.confidence,
                                    icon: Icons.percent,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildMetricCard(
                                    label: 'Risk Level',
                                    value: result.riskLevel,
                                    icon: Icons.warning_outlined,
                                    color: result.riskColor,
                                  ),
                                  const SizedBox(height: 18),
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
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF82E6FF),
                                              letterSpacing: 0.24,
                                            ),
                                          ),
                                          const SizedBox(height: 9),
                                          Text(
                                            result.explanation!.trim(),
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 13,
                                              color: const Color(0xFFE8EEFF),
                                              height: 1.56,
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
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF82E6FF),
                                              letterSpacing: 0.24,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          ...result.recommendations!.map(
                                            (rec) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 7),
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
                                                            0xFFE8EEFF),
                                                        height: 1.56,
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
                                            vertical: 15),
                                        backgroundColor:
                                            const Color(0xFF3DA9FF),
                                        shadowColor: const Color(0x553DA9FF),
                                        elevation: 3,
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
                                            vertical: 15),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1538),
            Color(0xFF081029),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFA8C9FF).withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F82E6FF),
            blurRadius: 10,
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF82E6FF),
                  letterSpacing: 0.2,
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
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyUrl(BuildContext context, String url) async {
    if (url.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: url));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analyzed URL copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF0A0F32),
      ),
    );
  }
}
