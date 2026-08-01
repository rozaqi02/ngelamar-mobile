import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_sheet_window.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/apple_inline_badge.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/add_edit_job_screen.dart';
import '../prep/fresh_grad_prep_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _openAddJob(
    BuildContext context, {
    bool autoFocusPaste = false,
  }) async {
    final result = await AppleSheetWindow.showAppleModalSheet<JobApplication>(
      context: context,
      child: AddEditJobScreen(autoFocusPaste: autoFocusPaste),
    );

    if (result != null && context.mounted) {
      AppleToast.success(
        context,
        'Lamaran tersimpan!',
        subtitle: '${result.position} di ${result.companyName}',
        actionLabel: 'Lihat',
        onAction: () {
          AppleSheetWindow.showAppleModalSheet(
            context: context,
            child: JobDetailScreen(job: result),
          );
        },
      );
    }
  }

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
    final isDark = AppTheme.isDark(context);
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
                // Apple Large Title Navigation Bar with greeting + Add button
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
                      final progress =
                          1.0 -
                          ((available - collapsedH) / (expandedH - collapsedH))
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
                                      fontWeight: FontWeight.w700,
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
                                  fontWeight: FontWeight.w600,
                                  color: txtPri,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),

                          // Add button (top-right, always visible)
                          Positioned(
                            right: 16,
                            bottom: 12,
                            child: GestureDetector(
                              onTap: () => _openAddJob(context),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? AppTheme.systemBlue
                                              : AppTheme.lSystemBlue)
                                          .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.plus,
                                  size: 18,
                                  color: isDark
                                      ? AppTheme.systemBlue
                                      : AppTheme.lSystemBlue,
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
                      const SizedBox(height: 14),

                      // Fresh Grad Prep Hub CTA
                      _buildPrepHubCTA(context),
                      const SizedBox(height: 28),

                      _sectionTitle(context, 'Ringkasan Lamaran'),
                      const SizedBox(height: 12),
                      _buildMetricsGrid(context, state),
                      const SizedBox(height: 28),

                      _buildSmartPasteCTA(context),
                      const SizedBox(height: 28),

                      Row(
                        children: [
                          Expanded(
                            child: _sectionTitle(context, 'Lamaran Terbaru'),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
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
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(
    title,
    style: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
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
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Icon(
              CupertinoIcons.chart_bar_alt_fill,
              color: rateColor,
              size: 20,
            ),
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
                  style: TextStyle(fontSize: 12, color: txtSec),
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
              fontWeight: FontWeight.w700,
              color: rateColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepHubCTA(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final blue = isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue;

    return AppleBouncyCard(
      onTap: () => AppleSheetWindow.showAppleModalSheet(
        context: context,
        child: const FreshGradPrepScreen(),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: blue.withValues(alpha: 0.35),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
              child: Icon(
                CupertinoIcons.doc_checkmark_fill,
                color: blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Persiapan Karir Fresh Grad',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: txtPri,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PANDUAN',
                          style: TextStyle(
                            color: blue,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Checklist berkas, estimator gaji UMR & panduan interview',
                    style: TextStyle(color: txtSec, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppTheme.getTextTertiary(context),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, JobState state) {
    final isDark = AppTheme.isDark(context);
    final teal = isDark ? AppTheme.systemTeal : AppTheme.lSystemTeal;
    final blue = isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue;
    final orange = isDark ? AppTheme.systemOrange : AppTheme.lSystemOrange;
    final purple = isDark ? AppTheme.systemPurple : AppTheme.lSystemPurple;

    final items = [
      _MetricItem(
        'Total',
        state.totalCount,
        teal,
        CupertinoIcons.tray_fill,
        'Semua Lamaran',
      ),
      _MetricItem(
        'Dikirim',
        state.appliedCount,
        blue,
        CupertinoIcons.paperplane_fill,
        'Menunggu HR',
      ),
      _MetricItem(
        'Interview',
        state.interviewCount,
        orange,
        CupertinoIcons.mic_fill,
        'Proses Seleksi',
      ),
      _MetricItem(
        'Offering',
        state.offeringCount,
        purple,
        CupertinoIcons.gift_fill,
        'Penawaran Masuk',
      ),
    ];

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: textScale > 1.3 ? 0.95 : 1.25,
      children: items.map((item) => _buildMetricCard(context, item)).toList(),
    );
  }

  Widget _buildMetricCard(BuildContext context, _MetricItem item) {
    final isDark = AppTheme.isDark(context);
    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, color: item.color, size: 15),
              ),
              Text(
                '${item.count}',
                style: TextStyle(
                  color: item.color,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
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
            style: TextStyle(color: txtSec, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSmartPasteCTA(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final surf = AppTheme.getSurface(context);
    final green = isDark ? AppTheme.systemGreen : AppTheme.lSystemGreen;
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return AppleBouncyCard(
      onTap: () => _openAddJob(context, autoFocusPaste: true),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: green.withValues(alpha: 0.3),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
              child: Icon(CupertinoIcons.bolt_fill, color: green, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Isi Otomatis',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: txtPri,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paste teks loker, form terisi otomatis',
                    style: TextStyle(color: txtSec, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppTheme.getTextTertiary(context),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    JobApplication job,
    WidgetRef ref,
  ) {
    final isDark = AppTheme.isDark(context);
    final statusColor = AppTheme.getStatusColor(job.status, isDark: isDark);
    final diffDays = DateTime.now().difference(job.appliedDate).inDays;
    final daysAgo = diffDays < 0 ? 0 : diffDays;
    final timeStr = daysAgo == 0
        ? 'Hari ini'
        : daysAgo == 1
        ? 'Kemarin'
        : '$daysAgo hr lalu';

    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    return RepaintBoundary(
      child: AppleBouncyCard(
        onTap: () => AppleSheetWindow.showAppleModalSheet(
          context: context,
          child: JobDetailScreen(job: job),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: surf,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                            style: TextStyle(color: txtSec, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          AppleInlineBadge(
                            icon: CupertinoIcons.briefcase,
                            label: job.workType,
                          ),
                          if (job.location != null)
                            AppleInlineBadge(
                              icon: CupertinoIcons.location,
                              label: job.location!,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    Text(
                      timeStr,
                      style: TextStyle(color: txtTer, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final txtTer = AppTheme.getTextTertiary(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
