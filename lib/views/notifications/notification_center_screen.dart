import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/notification_service.dart';
import '../../services/inbox_service.dart';
import '../../services/remote_config_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/confused_envelope_mascot.dart';
import '../../widgets/company_logo_badge.dart';
import '../../widgets/app_motion.dart';
import '../../widgets/app_layout_metrics.dart';
import '../../widgets/app_tour_overlay.dart';
import '../../widgets/header_help_button.dart';
import '../jobs/job_detail_screen.dart';

/// Screen 4: Notification Center, aligned with the Home dashboard design.
/// Membedakan secara visual dan filter antara:
/// 1. Notif Lamaran (Interview, Psikotes, Offering, Follow-up)
/// 2. Kotak Masuk (Pengumuman, Pesan, Info PRO)
/// 3. Notif Sistem (Status Izin & Pengingat Lokal)
class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  late Future<bool> _permissionFuture;
  late Future<List<InboxMessage>> _inboxFuture;
  bool _showTour = false;
  late final DateTime _screenOpenedAt;
  int _selectedCategoryIndex = 0;

  final List<String> _categories = const [
    'Semua',
    'Lamaran',
    'Kotak Masuk',
    'Sistem',
  ];

  @override
  void initState() {
    super.initState();
    _screenOpenedAt = DateTime.now();
    _permissionFuture = NotificationService.areNotificationsEnabled();
    _inboxFuture = InboxService.fetch();
  }

  Future<void> _refresh() async {
    final permission = NotificationService.areNotificationsEnabled();
    final inbox = InboxService.fetch();
    setState(() {
      _permissionFuture = permission;
      _inboxFuture = inbox;
    });
    await Future.wait<void>([
      permission.then<void>((_) {}),
      inbox.then<void>((_) {}).catchError((_) {}),
    ]);
  }

  Future<void> _openInboxLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      if (mounted) AppToast.error(context, 'Tautan pengumuman tidak valid.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppToast.error(context, 'Tautan belum dapat dibuka.');
    }
  }

  Future<void> _requestPermission() async {
    await NotificationService.promptPermissionIfNeeded(context);
    if (!mounted) return;
    setState(() {
      _permissionFuture = NotificationService.areNotificationsEnabled();
    });
  }

  Widget _buildHomeHeader({
    required bool isDark,
    required Color textColor,
    required int totalCount,
  }) {
    return TourAnchor(
      id: 'notif_header',
      child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        AppLayoutMetrics.headerTopInsideSafeArea(context, extra: 12),
        20,
        10,
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (Navigator.canPop(context)) ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242428) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF383842)
                          : AppTheme.warmBorder,
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.20 : 0.04,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTIFIKASI\nKAMU',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 34,
                      height: 0.96,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.6,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    totalCount == 0
                        ? 'Semua kabar kariermu akan tampil di sini.'
                        : '$totalCount kabar terbaru untuk perjalanan kariermu.',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFA0A0A8)
                          : AppTheme.textMuted,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            HeaderHelpButton(
              onTap: () => setState(() => _showTour = true),
              semanticLabel: 'Buka tutorial Notifikasi',
              size: 44,
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final notices = _createNotices(state.jobs);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final background = AppTheme.getBackground(context);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          SafeArea(
        bottom: false,
        child: FutureBuilder<List<InboxMessage>>(
          future: _inboxFuture,
          builder: (context, snapshot) {
            final remoteAnnouncement = RemoteConfigService.announcement;
            final inboxMessages = [
              if (remoteAnnouncement != null)
                InboxMessage(
                  id: 'remote_announcement',
                  title: remoteAnnouncement.title,
                  body: remoteAnnouncement.message,
                  type: 'announcement',
                  actionUrl: remoteAnnouncement.actionUrl,
                  createdAt: _screenOpenedAt,
                ),
              ...(snapshot.data ?? const <InboxMessage>[]),
            ];

            final showJobNotices =
                _selectedCategoryIndex == 0 || _selectedCategoryIndex == 1;
            final showInbox =
                _selectedCategoryIndex == 0 || _selectedCategoryIndex == 2;
            final showSystem =
                _selectedCategoryIndex == 0 || _selectedCategoryIndex == 3;

            final totalNoticesCount = notices.length + inboxMessages.length;
            final actionNeeded = notices
                .where(_needsActionSoon)
                .toList(growable: false);
            final upcoming = notices
                .where((notice) => !_needsActionSoon(notice))
                .toList(growable: false);

            return TourAnchor(
              id: 'notif_list',
              child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHomeHeader(
                      isDark: isDark,
                      textColor: txtPri,
                      totalCount: totalNoticesCount,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Row(
                        children: List.generate(_categories.length, (idx) {
                          final isSelected = _selectedCategoryIndex == idx;
                          final label = _categories[idx];
                          final count = idx == 1
                              ? notices.length
                              : (idx == 2 ? inboxMessages.length : 0);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              showCheckmark: false,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(label),
                                  if (count > 0 && !isSelected) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.getSurfaceSecondary(
                                          context,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF45454A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              labelStyle: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? (isDark
                                          ? const Color(0xFF141416)
                                          : Colors.white)
                                    : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF4B4B50)),
                              ),
                              selectedColor: isDark
                                  ? const Color(0xFF5C44E4)
                                  : const Color(0xFF19191B),
                              backgroundColor: AppTheme.getSurface(context),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppTheme.getBorder(context),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategoryIndex = idx);
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (showSystem)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                        child: FutureBuilder<bool>(
                          future: _permissionFuture,
                          builder: (context, snapshot) {
                            final loading =
                                snapshot.connectionState ==
                                ConnectionState.waiting;
                            final enabled = snapshot.data == true;
                            final statusColor = enabled
                                ? const Color(0xFF15803D)
                                : const Color(0xFFD97706);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                // The notification system is intentionally a
                                // neutral surface. Status remains in the icon
                                // and badge rather than tinting an entire card.
                                color: isDark
                                    ? const Color(0xFF2A2824)
                                    : const Color(0xFFE7DED0),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusCard,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: loading
                                        ? const Padding(
                                            padding: EdgeInsets.all(11),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                            ),
                                          )
                                        : Icon(
                                            enabled
                                                ? Icons
                                                      .notifications_active_rounded
                                                : Icons
                                                      .notifications_off_outlined,
                                            color: statusColor,
                                            size: 21,
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              loading
                                                  ? 'Memeriksa Izin...'
                                                  : (enabled
                                                        ? 'Pengingat Sistem Aktif'
                                                        : 'Izin Notifikasi Nonaktif'),
                                              style: TextStyle(
                                                color: txtPri,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Sistem',
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          loading
                                              ? 'Status izin akan segera tampil.'
                                              : (enabled
                                                    ? _nextReminderText(notices)
                                                    : 'Aktifkan agar jadwal interview tidak terlewat.'),
                                          style: TextStyle(
                                            color: txtSec,
                                            fontSize: 11.5,
                                            height: 1.3,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!loading && !enabled)
                                    ElevatedButton(
                                      onPressed: _requestPermission,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF15803D,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Aktifkan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (showInbox && inboxMessages.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 6, 22, 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.all_inbox_rounded,
                              size: 15,
                              color: Color(0xFF6750A4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'KOTAK MASUK & PENGUMUMAN (${inboxMessages.length})',
                              style: TextStyle(
                                color: txtSec,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: Column(
                          children: inboxMessages
                              .map(
                                (message) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _MaterialInboxCard(
                                    message: message,
                                    isDark: isDark,
                                    onTap:
                                        message.actionUrl == null ||
                                            message.actionUrl!.trim().isEmpty
                                        ? null
                                        : () => _openInboxLink(
                                            message.actionUrl!.trim(),
                                          ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ],
                  if (showJobNotices && actionNeeded.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 6, 22, 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.priority_high_rounded,
                              size: 15,
                              color: Color(0xFFB45309),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PERLU DITINDAKLANJUTI (${actionNeeded.length})',
                              style: TextStyle(
                                color: txtSec,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        AppLayoutMetrics.contentBottomClearance(context),
                      ),
                      sliver: SliverList.separated(
                        itemCount: actionNeeded.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notice = actionNeeded[index];
                          return StaggeredReveal(
                            index: index,
                            child: _MaterialJobNoticeCard(
                              notice: notice,
                              isDark: isDark,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.push(
                                  context,
                                  AppMotion.detailDockRoute(
                                    builder: (_) =>
                                        JobDetailScreen(job: notice.job),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (showJobNotices && upcoming.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: txtSec,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              actionNeeded.isEmpty
                                  ? 'JADWAL MENDATANG (${upcoming.length})'
                                  : 'BERIKUTNYA (${upcoming.length})',
                              style: TextStyle(
                                color: txtSec,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        AppLayoutMetrics.contentBottomClearance(context),
                      ),
                      sliver: SliverList.separated(
                        itemCount: upcoming.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notice = upcoming[index];
                          return StaggeredReveal(
                            index: index + actionNeeded.length,
                            child: _MaterialJobNoticeCard(
                              notice: notice,
                              isDark: isDark,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.push(
                                  context,
                                  AppMotion.detailDockRoute(
                                    builder: (_) =>
                                        JobDetailScreen(job: notice.job),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (totalNoticesCount == 0 ||
                      (showJobNotices && !showInbox && notices.isEmpty) ||
                      (showInbox && !showJobNotices && inboxMessages.isEmpty))
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          28,
                          20,
                          28,
                          AppLayoutMetrics.contentBottomClearance(context),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const ConfusedEnvelopeMascot(
                              width: 185,
                              height: 145,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Semua Rapi & Terpantau',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: txtPri,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Jadwal wawancara, tes psikotes, dan follow-up lamaran kerjamu akan otomatis terangkum di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: txtSec,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            );
          },
        ),
      ),
          if (_showTour)
            AppTourOverlay(
              tabIndex: 6,
              onFinish: () {
                if (mounted) setState(() => _showTour = false);
              },
            ),
        ],
      ),
    );
  }

  String _nextReminderText(List<_CareerNotice> notices) {
    final dated = notices.where((notice) => notice.date != null).toList();
    if (dated.isEmpty) return 'Semua jadwal lamaranmu sedang aman.';
    dated.sort((a, b) => a.date!.compareTo(b.date!));
    return 'Jadwal terdekat: ${DateFormat('dd MMM, HH:mm', 'id_ID').format(dated.first.date!)}';
  }

  bool _needsActionSoon(_CareerNotice notice) {
    if (notice.title.startsWith('Waktunya Follow-Up') ||
        notice.title.startsWith('Tawaran Gaji')) {
      return true;
    }
    final date = notice.date;
    if (date == null) return false;
    return !date.isAfter(DateTime.now().add(const Duration(days: 2)));
  }

  List<_CareerNotice> _createNotices(List<JobApplication> jobs) {
    final now = DateTime.now();
    final notices = <_CareerNotice>[];
    for (final job in jobs) {
      final isClosed = job.status == 'Diterima' || job.status == 'Ditolak';
      final schedule = job.interviewDate ?? job.testDate;
      if (!isClosed && schedule != null && schedule.isAfter(now)) {
        notices.add(
          _CareerNotice(
            job: job,
            title: job.interviewDate != null
                ? 'Jadwal Interview: ${job.companyName}'
                : 'Jadwal Tes: ${job.companyName}',
            subtitle:
                '${job.position} • ${DateFormat('EEEE, dd MMM • HH:mm', 'id_ID').format(schedule)}',
            icon: job.interviewDate != null
                ? Icons.record_voice_over_rounded
                : Icons.fact_check_rounded,
            color: const Color(0xFF1D4ED8),
            date: schedule,
          ),
        );
      }
      if (!isClosed && job.needsFollowup) {
        notices.add(
          _CareerNotice(
            job: job,
            title: 'Waktunya Follow-Up Lamaran',
            subtitle:
                'Posisi ${job.position} di ${job.companyName} belum ada pembaruan > 7 hari.',
            icon: Icons.outgoing_mail,
            color: const Color(0xFFB45309),
            date: job.appliedDate.add(const Duration(days: 7)),
          ),
        );
      }
      if (job.status == 'Offering') {
        notices.add(
          _CareerNotice(
            job: job,
            title: 'Tawaran Gaji (Offering)',
            subtitle:
                'Selamat! Periksa kembali detail offering dari ${job.companyName}.',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF15803D),
          ),
        );
      }
    }
    notices.sort((a, b) {
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });
    return notices;
  }
}

class _CareerNotice {
  final JobApplication job;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime? date;

  const _CareerNotice({
    required this.job,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.date,
  });
}

/// Home-style job selection notice card.
class _MaterialJobNoticeCard extends StatelessWidget {
  final _CareerNotice notice;
  final bool isDark;
  final VoidCallback onTap;

  const _MaterialJobNoticeCard({
    required this.notice,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return AppleBouncyCard(
      onTap: onTap,
      semanticLabel: 'Buka ${notice.title}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2824) : const Color(0xFFE7DED0),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'company_logo_${notice.job.id}',
              child: CompanyLogoBadge(
                companyName: notice.job.companyName,
                customImagePath: notice.job.companyLogoPath,
                size: 44,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: notice.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Lamaran',
                          style: TextStyle(
                            color: notice.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (notice.date != null)
                        Text(
                          DateFormat('dd MMM', 'id_ID').format(notice.date!),
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notice.title,
                    style: TextStyle(
                      color: txtPri,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notice.subtitle,
                    style: TextStyle(color: txtSec, fontSize: 12, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home-style inbox and announcement message card.
class _MaterialInboxCard extends StatelessWidget {
  final InboxMessage message;
  final bool isDark;
  final VoidCallback? onTap;

  const _MaterialInboxCard({
    required this.message,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (message.type) {
      'pro' => const Color(0xFF6750A4),
      'reminder' => const Color(0xFFB45309),
      'system' => const Color(0xFF0284C7),
      _ => const Color(0xFFBA1A1A),
    };
    final typeLabel = switch (message.type) {
      'pro' => 'Info PRO',
      'reminder' => 'Pengingat',
      'system' => 'Sistem',
      _ => 'Pengumuman',
    };

    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2824) : const Color(0xFFE7DED0),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat(
                  'd MMM, HH:mm',
                  'id_ID',
                ).format(message.createdAt.toLocal()),
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.title,
            style: TextStyle(
              color: txtPri,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.body,
            style: TextStyle(color: txtSec, fontSize: 12.5, height: 1.4),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Buka Tautan',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_outward_rounded, size: 14, color: color),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return AppleBouncyCard(
      onTap: onTap,
      semanticLabel: 'Buka ${message.title}',
      child: card,
    );
  }
}
