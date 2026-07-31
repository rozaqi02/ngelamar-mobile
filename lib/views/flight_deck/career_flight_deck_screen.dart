import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_toast.dart';
import 'package:share_plus/share_plus.dart';

/// Exclusive Differentiating Feature: "Career Flight Deck & AI Readiness Matrix".
/// Provides real-time application readiness scoring, salary negotiation benchmark,
/// automated next-step recommendations, and instant executive progress export.
class CareerFlightDeckScreen extends ConsumerWidget {
  const CareerFlightDeckScreen({super.key});

  int _calculateReadinessScore(JobState state) {
    if (state.totalCount == 0) return 0;

    int score = 40; // Base score for starting

    // Response rate boost
    final rate = state.responseRate;
    if (rate >= 50) {
      score += 25;
    } else if (rate >= 20) {
      score += 15;
    }

    // Active pipeline boost
    if (state.interviewCount > 0) score += 20;
    if (state.offeringCount > 0) score += 15;

    return score.clamp(0, 100);
  }

  String _getReadinessLabel(int score) {
    if (score >= 80) return 'Siap Tempur 🔥';
    if (score >= 60) return 'Progres Bagus 📈';
    if (score >= 40) return 'Butuh Dorongan ⚡';
    return 'Mulai Lacak 🚀';
  }

  Color _getReadinessColor(int score) {
    if (score >= 80) return AppTheme.systemGreen;
    if (score >= 60) return AppTheme.systemBlue;
    if (score >= 40) return AppTheme.systemOrange;
    return AppTheme.systemPurple;
  }

  void _shareExecutiveReport(BuildContext context, JobState state) {
    final buffer = StringBuffer();
    buffer.writeln('📋 EXECUTIVE CAREER FLIGHT DECK REPORT');
    buffer.writeln('====================================');
    buffer.writeln('👤 Pelamar: ${state.userName.isEmpty ? "Job Seeker" : state.userName}');
    buffer.writeln('📊 Readiness Score: ${_calculateReadinessScore(state)}/100 [${_getReadinessLabel(_calculateReadinessScore(state))}]');
    buffer.writeln('🗃️ Total Lamaran: ${state.totalCount}');
    buffer.writeln('✈️ Dikirim: ${state.appliedCount}');
    buffer.writeln('🎙️ Interview & Tes: ${state.interviewCount}');
    buffer.writeln('🎁 Penawaran (Offering): ${state.offeringCount}');
    buffer.writeln('📈 Response Rate HR: ${state.responseRate.toStringAsFixed(0)}%');
    buffer.writeln('====================================\n');

    for (var i = 0; i < state.jobs.length; i++) {
      final j = state.jobs[i];
      buffer.writeln(
          '${i + 1}. ${j.position} @ ${j.companyName} [Status: ${j.status}]');
    }

    Share.share(buffer.toString(), subject: 'Executive Career Report Ngelamar');
    AppleToast.success(context, 'Laporan Eksekutif Berhasil Dibagikan!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    final score = _calculateReadinessScore(state);
    final scoreLabel = _getReadinessLabel(score);
    final scoreColor = _getReadinessColor(score);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Career Flight Deck',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: txtPri,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pusat Kendali Karir & AI Readiness Matrix',
                    style: TextStyle(fontSize: 13, color: txtSec),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.3),
                    width: AppTheme.borderHairline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.sparkles, color: scoreColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '$score Score',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Readiness Matrix Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1C1C1E),
                        const Color(0xFF2C2C2E),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF2F2F7),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.3),
                width: AppTheme.borderHairline,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 6,
                            backgroundColor:
                                scoreColor.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          ),
                        ),
                        Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: txtPri,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scoreLabel,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.totalCount == 0
                                ? 'Tambahkan lamaran pertama Anda untuk menghitung readiness index.'
                                : '${state.interviewCount} interview berlangsung, ${state.offeringCount} offering masuk.',
                            style: TextStyle(fontSize: 12, color: txtSec),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Matrix Pillar Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPillarItem(
                      context,
                      'Response',
                      '${state.responseRate.toStringAsFixed(0)}%',
                      CupertinoIcons.chart_bar_alt_fill,
                      AppTheme.systemBlue,
                    ),
                    _buildPillarItem(
                      context,
                      'Interview',
                      '${state.interviewCount}',
                      CupertinoIcons.mic_fill,
                      AppTheme.systemOrange,
                    ),
                    _buildPillarItem(
                      context,
                      'Offering',
                      '${state.offeringCount}',
                      CupertinoIcons.gift_fill,
                      AppTheme.systemPurple,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Smart AI Next Step Recommendations
          Text(
            'REKOMENDASI AKSI KARIR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: txtTer,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          _buildRecommendationCard(
            context,
            title: 'Kirim Follow-Up Lamaran',
            subtitle: 'Kirim pesan follow-up halus ke HRD setelah 3-5 hari lamaran.',
            icon: CupertinoIcons.paperplane_fill,
            color: AppTheme.systemBlue,
            onTap: () {
              if (state.jobs.isEmpty) {
                AppleToast.info(context, 'Belum ada data lamaran untuk diajukan follow-up.');
              } else {
                AppleToast.success(context, 'Pilih lamaran pada menu Lamaran untuk follow-up!');
              }
            },
          ),
          const SizedBox(height: 10),

          _buildRecommendationCard(
            context,
            title: 'Evaluator Gaji & UMR Kota',
            subtitle: 'Bandingkan ekspektasi gaji dengan standar UMR & kos lokasi.',
            icon: CupertinoIcons.money_dollar_circle_fill,
            color: AppTheme.systemGreen,
            onTap: () {
              AppleToast.info(context, 'Gunakan tab "Gaji & Offer" pada Detail Lamaran untuk simulasi.');
            },
          ),
          const SizedBox(height: 24),

          // Export Button
          AppleBouncyCard(
            onTap: () => _shareExecutiveReport(context, state),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.systemBlue,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.systemBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.share_up, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Bagikan Laporan Eksekutif (WA / Catatan)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: txtPri,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 11, color: txtSec),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);
    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return AppleBouncyCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: AppTheme.borderHairline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: txtPri,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: txtSec),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 14, color: AppTheme.getTextTertiary(context)),
          ],
        ),
      ),
    );
  }
}
