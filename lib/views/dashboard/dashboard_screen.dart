import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_sheet_window.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/add_edit_job_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jobProvider);
    final name = state.userName.isEmpty ? 'Job Seeker' : state.userName;
    final bg = AppTheme.getBackground(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final surfSec = AppTheme.getSurfaceSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      body: state.isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Apple Large Title Navigation Bar with greeting
                SliverAppBar(
                  backgroundColor: bg,
                  surfaceTintColor: Colors.transparent,
                  pinned: true,
                  expandedHeight: 120,
                  collapsedHeight: 56,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final topPadding = MediaQuery.of(context).padding.top;
                      const collapsedH = 56.0;
                      const expandedH = 120.0;
                      final available = constraints.maxHeight - topPadding;
                      final progress = 1.0 -
                          ((available - collapsedH) /
                              (expandedH - collapsedH))
                              .clamp(0.0, 1.0);

                      return Stack(
                        children: [
                          // Large Title (fades out when collapsed)
                          Positioned(
                            left: 16,
                            bottom: 12,
                            right: 80,
                            child: Opacity(
                              opacity: (1.0 - progress * 2.5).clamp(0.0, 1.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_greeting()},',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: txtSec,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      color: txtPri,
                                      letterSpacing: -0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Small collapsed title (fades in when collapsed)
                          Positioned(
                            left: 16,
                            bottom: 14,
                            child: Opacity(
                              opacity: ((progress - 0.6) * 3.0).clamp(0.0, 1.0),
                              child: Text(
                                'Ngelamar',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: txtPri,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewPadding.bottom + 100,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Response Rate Banner
                      _buildResponseRateBanner(context, state),
                      const SizedBox(height: 28),

                      _sectionTitle(context, 'Ringkasan Lamaran'),
                      const SizedBox(height: 12),
                      _buildMetricsGrid(context, state),
                      const SizedBox(height: 28),

                      _buildSmartPasteCTA(context),
                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionTitle(context, 'Lamaran Terbaru'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: surfSec,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${state.totalCount} Total',
                              style: TextStyle(
                                color: txtSec,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (state.jobs.isEmpty)
                        _buildEmptyState(context)
                      else
                        ...state.jobs
                            .take(5)
                            .map((job) => _buildJobCard(context, job, ref)),
                    ]),
                  ),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 74),
        child: FloatingActionButton.extended(
          heroTag: 'dashboard_fab',
          onPressed: () => AppleSheetWindow.showAppleModalSheet(
            context: context,
            child: const AddEditJobScreen(),
          ),
          backgroundColor: AppTheme.systemBlue,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon:
              const Icon(CupertinoIcons.add, color: Colors.white, size: 18),
          label: const Text(
            'Tambah Loker',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppTheme.getTextPrimary(context),
          letterSpacing: -0.3,
        ),
      );

  Widget _buildResponseRateBanner(BuildContext context, JobState state) {
    final rate = state.responseRate.toStringAsFixed(0);
    final isDark = AppTheme.isDark(context);
    final rateColor = state.responseRate >= 50
        ? (isDark ? AppTheme.systemGreen : AppTheme.lSystemGreen)
        : state.responseRate >= 20
            ? (isDark ? AppTheme.systemOrange : AppTheme.lSystemOrange)
            : AppTheme.getTextSecondary(context);

    final surf = AppTheme.getSurface(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(CupertinoIcons.chart_bar_alt_fill,
                color: rateColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Response Rate HR',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: txtPri,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.jobs.isEmpty
                      ? 'Belum ada lamaran'
                      : '${state.jobs.where((j) => j.status != 'Dikirim').length} dari ${state.totalCount} ditanggapi',
                  style: TextStyle(
                      fontSize: 12, color: txtSec),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$rate%',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: rateColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, JobState state) {
    final isDark = AppTheme.isDark(context);
    final teal   = isDark ? AppTheme.systemTeal   : AppTheme.lSystemTeal;
    final blue   = isDark ? AppTheme.systemBlue   : AppTheme.lSystemBlue;
    final orange = isDark ? AppTheme.systemOrange : AppTheme.lSystemOrange;
    final purple = isDark ? AppTheme.systemPurple : AppTheme.lSystemPurple;

    final items = [
      _MetricItem('Total', state.totalCount, teal,
          CupertinoIcons.tray_fill, 'Semua Lamaran'),
      _MetricItem('Dikirim', state.appliedCount, blue,
          CupertinoIcons.paperplane_fill, 'Menunggu HR'),
      _MetricItem('Interview', state.interviewCount, orange,
          CupertinoIcons.mic_fill, 'Proses Seleksi'),
      _MetricItem('Offering', state.offeringCount, purple,
          CupertinoIcons.gift_fill, 'Penawaran Masuk'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: items.map((item) => _buildMetricCard(context, item)).toList(),
    );
  }

  Widget _buildMetricCard(BuildContext context, _MetricItem item) {
    final surf = AppTheme.getSurface(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return AppleBouncyCard(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bdr, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 15),
                ),
                Text(
                  '${item.count}',
                  style: TextStyle(
                    color: item.color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              style: TextStyle(
                color: txtPri,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              item.subtitle,
              style: TextStyle(
                  color: txtSec, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartPasteCTA(BuildContext context) {
    final surf = AppTheme.getSurface(context);
    final green = AppTheme.isDark(context)
        ? AppTheme.systemGreen
        : AppTheme.lSystemGreen;
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return AppleBouncyCard(
      onTap: () => AppleSheetWindow.showAppleModalSheet(
        context: context,
        child: const AddEditJobScreen(autoFocusPaste: true),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: green.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(CupertinoIcons.bolt_fill,
                  color: green, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Auto-Fill',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: txtPri,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paste teks loker → form terisi otomatis',
                    style: TextStyle(
                        color: txtSec, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                color: AppTheme.getTextTertiary(context), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(
      BuildContext context, JobApplication job, WidgetRef ref) {
    final statusColor = AppTheme.getStatusColor(job.status,
        isDark: AppTheme.isDark(context));
    final daysAgo = DateTime.now().difference(job.appliedDate).inDays;
    final timeStr = daysAgo == 0
        ? 'Hari ini'
        : daysAgo == 1
            ? 'Kemarin'
            : '$daysAgo hr lalu';

    final surf = AppTheme.getSurface(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    return AppleBouncyCard(
      onTap: () => AppleSheetWindow.showAppleModalSheet(
        context: context,
        child: JobDetailScreen(job: job),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bdr, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.position,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: txtPri,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.companyName,
                          style: TextStyle(
                            color: txtSec,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _pillInfo(context, CupertinoIcons.briefcase, job.workType),
                  if (job.location != null) ...[
                    const SizedBox(width: 10),
                    _pillInfo(context, CupertinoIcons.location, job.location!),
                  ],
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        ref.read(jobProvider.notifier).toggleFavorite(job.id),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        job.isFavorite
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.star,
                        color: job.isFavorite
                            ? AppTheme.systemOrange
                            : txtTer,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(timeStr,
                      style: TextStyle(
                          color: txtTer, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillInfo(BuildContext context, IconData icon, String label) {
    final txtTer = AppTheme.getTextTertiary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: txtTer),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: txtTer, fontSize: 11)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final surf = AppTheme.getSurface(context);
    final bdr = AppTheme.getBorder(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.tray, size: 40, color: txtTer),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Lamaran',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: txtPri,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mulai lacak lamaran kerjamu sekarang.',
            textAlign: TextAlign.center,
            style: TextStyle(color: txtSec, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final String subtitle;
  _MetricItem(this.title, this.count, this.color, this.icon, this.subtitle);
}
