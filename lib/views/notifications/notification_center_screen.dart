import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/job_application.dart';
import '../../providers/job_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/confused_envelope_mascot.dart';
import '../../widgets/welcome_screen_route.dart';
import '../jobs/job_detail_screen.dart';
import 'notification_welcome_screen.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  late Future<bool> _permissionFuture;

  @override
  void initState() {
    super.initState();
    _permissionFuture = NotificationService.areNotificationsEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final notices = _createNotices(state.jobs);
    final txtPri = isDark ? Colors.white : const Color(0xFF151517);
    final txtSec = isDark ? const Color(0xFFA4A4AB) : const Color(0xFF66666B);
    final background = isDark
        ? const Color(0xFF151315)
        : const Color(0xFFF8EEE9);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'KABAR\nUNTUKMU',
                        style: TextStyle(
                          color: txtPri,
                          fontSize: 31,
                          height: 0.98,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.25,
                        ),
                      ),
                    ),
                    FluidBounceButton(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          WelcomeScreenRoute(
                            child: const NotificationWelcomeScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252327)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3B383E)
                                : const Color(0xFFE7DAD4),
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.question_circle_fill,
                          color: Color(0xFFFF6B5F),
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
                child: FutureBuilder<bool>(
                  future: _permissionFuture,
                  builder: (context, snapshot) {
                    final enabled = snapshot.data ?? false;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: enabled
                            ? const Color(0xFFCDF0D2)
                            : const Color(0xFFFFD2CB),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.72),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              enabled
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_off_outlined,
                              color: enabled
                                  ? const Color(0xFF1E7C36)
                                  : const Color(0xFFC43A31),
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  enabled
                                      ? 'Pengingat aktif'
                                      : 'Izin belum aktif',
                                  style: const TextStyle(
                                    color: Color(0xFF1D1B1B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  enabled
                                      ? _nextReminderText(notices)
                                      : 'Aktifkan agar jadwal seleksi tidak terlewat.',
                                  style: const TextStyle(
                                    color: Color(0xFF575052),
                                    fontSize: 11.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!enabled)
                            TextButton(
                              onPressed: _requestPermission,
                              child: const Text(
                                'Perbaiki',
                                style: TextStyle(
                                  color: Color(0xFFC43A31),
                                  fontWeight: FontWeight.w900,
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
            if (notices.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 10, 28, 130),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ConfusedEnvelopeMascot(width: 185, height: 145),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada kabar baru',
                        style: TextStyle(
                          color: txtPri,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Jadwal seleksi dan waktu follow-up lamaranmu akan muncul di sini.',
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
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                  child: Text(
                    '${notices.length} HAL PERLU PERHATIAN',
                    style: TextStyle(
                      color: txtSec,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  125 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverList.separated(
                  itemCount: notices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    return _NoticeCard(
                      notice: notice,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => JobDetailScreen(job: notice.job),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermission() async {
    await NotificationService.promptPermissionIfNeeded(context);
    if (!mounted) return;
    setState(() {
      _permissionFuture = NotificationService.areNotificationsEnabled();
    });
  }

  String _nextReminderText(List<_CareerNotice> notices) {
    final dated = notices.where((notice) => notice.date != null).toList();
    if (dated.isEmpty) return 'Semua jadwal lamaranmu sedang aman.';
    dated.sort((a, b) => a.date!.compareTo(b.date!));
    return 'Berikutnya ${DateFormat('dd MMM, HH:mm', 'id_ID').format(dated.first.date!)}';
  }

  List<_CareerNotice> _createNotices(List<JobApplication> jobs) {
    final now = DateTime.now();
    final notices = <_CareerNotice>[];
    for (final job in jobs) {
      final schedule = job.interviewDate ?? job.testDate;
      if (schedule != null && schedule.isAfter(now)) {
        notices.add(
          _CareerNotice(
            job: job,
            title: job.interviewDate != null
                ? 'Interview ${job.companyName}'
                : 'Tes ${job.companyName}',
            subtitle:
                '${job.position} • ${DateFormat('EEEE, dd MMM • HH:mm', 'id_ID').format(schedule)}',
            icon: job.interviewDate != null
                ? Icons.record_voice_over_rounded
                : Icons.fact_check_rounded,
            color: const Color(0xFF5C44E4),
            date: schedule,
          ),
        );
      }
      if (job.needsFollowup) {
        notices.add(
          _CareerNotice(
            job: job,
            title: 'Waktunya follow-up',
            subtitle:
                '${job.position} di ${job.companyName} belum mendapat pembaruan.',
            icon: Icons.outgoing_mail,
            color: const Color(0xFFF2A62B),
            date: job.appliedDate.add(const Duration(days: 7)),
          ),
        );
      }
      if (job.status == 'Offering') {
        notices.add(
          _CareerNotice(
            job: job,
            title: 'Tawaran menunggumu',
            subtitle:
                'Periksa kembali detail offering dari ${job.companyName}.',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF1E8E3E),
          ),
        );
      }
    }
    notices.sort((a, b) {
      if (a.date == null) return -1;
      if (b.date == null) return 1;
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

class _NoticeCard extends StatelessWidget {
  final _CareerNotice notice;
  final bool isDark;
  final VoidCallback onTap;

  const _NoticeCard({
    required this.notice,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppleBouncyCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222024) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF37343A) : const Color(0xFFE8DDD8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: notice.color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(notice.icon, color: notice.color, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF19191B),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notice.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF66666B),
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_outward_rounded,
              color: isDark ? Colors.white54 : const Color(0xFF777178),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
