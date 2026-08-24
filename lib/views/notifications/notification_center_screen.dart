import 'package:flutter/cupertino.dart';
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
  late Future<List<InboxMessage>> _inboxFuture;
  late final DateTime _screenOpenedAt;

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
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      if (mounted) AppToast.error(context, 'Tautan pengumuman tidak valid.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppToast.error(context, 'Tautan belum dapat dibuka.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isDark = AppTheme.isDark(context);
    final notices = _createNotices(state.jobs);
    final txtPri = isDark ? Colors.white : const Color(0xFF151517);
    final txtSec = isDark ? const Color(0xFFA4A4AB) : const Color(0xFF707074);
    final background = isDark
        ? const Color(0xFF111113)
        : const Color(0xFFFAF8F5);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
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
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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
                                    ? const Color(0xFF1E1E24)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2C2C36)
                                      : const Color(0xFFEBE7DF),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.04,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.question_circle_fill,
                                color: Color(0xFF7257D9),
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
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                      child: FutureBuilder<bool>(
                        future: _permissionFuture,
                        builder: (context, snapshot) {
                          final loading =
                              snapshot.connectionState ==
                              ConnectionState.waiting;
                          final enabled = snapshot.data == true;
                          final cardBg = isDark
                              ? const Color(0xFF1E1E24)
                              : Colors.white;
                          final cardBorder = isDark
                              ? const Color(0xFF2C2C36)
                              : const Color(0xFFEBE7DF);
                          final statusColor = enabled
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.16 : 0.03,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
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
                                                    .notifications_none_rounded,
                                          color: statusColor,
                                          size: 20,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loading
                                            ? 'Memeriksa izin notifikasi…'
                                            : enabled
                                            ? 'Pengingat aktif'
                                            : 'Izin notifikasi nonaktif',
                                        style: TextStyle(
                                          color: txtPri,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        loading
                                            ? 'Status izin akan tampil sebentar lagi.'
                                            : enabled
                                            ? _nextReminderText(notices)
                                            : 'Aktifkan agar jadwal seleksi tidak terlewat.',
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
                                  TextButton(
                                    onPressed: _requestPermission,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Aktifkan',
                                      style: TextStyle(
                                        color: Color(0xFF7257D9),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
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
                  if (snapshot.hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _InboxErrorCard(
                          isDark: isDark,
                          onRetry: _refresh,
                        ),
                      ),
                    ),
                  if (inboxMessages.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Column(
                          children: inboxMessages
                              .map(
                                (message) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _InboxMessageCard(
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
                  if (notices.isEmpty && inboxMessages.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 10, 28, 130),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ConfusedEnvelopeMascot(
                              width: 185,
                              height: 145,
                            ),
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
                  else if (notices.isNotEmpty) ...[
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
                                  builder: (_) =>
                                      JobDetailScreen(job: notice.job),
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
            );
          },
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
      final isClosed = job.status == 'Diterima' || job.status == 'Ditolak';
      final schedule = job.interviewDate ?? job.testDate;
      if (!isClosed && schedule != null && schedule.isAfter(now)) {
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
      if (!isClosed && job.needsFollowup) {
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

class _InboxMessageCard extends StatelessWidget {
  final InboxMessage message;
  final bool isDark;
  final VoidCallback? onTap;

  const _InboxMessageCard({
    required this.message,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (message.type) {
      'pro' => const Color(0xFF8B5CF6),
      'reminder' => const Color(0xFFF59E0B),
      'system' => const Color(0xFF0284C7),
      _ => const Color(0xFFEF4444),
    };
    final typeLabel = switch (message.type) {
      'pro' => 'Info PRO',
      'reminder' => 'Pengingat',
      'system' => 'Sistem',
      _ => 'Pengumuman',
    };

    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C2C36) : const Color(0xFFEBE7DF);

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
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
              color: isDark ? Colors.white : const Color(0xFF151517),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.body,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFFA4A4AB)
                  : const Color(0xFF6B6B75),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Buka Tautan',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_outward_rounded, size: 14, color: color),
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

class _InboxErrorCard extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onRetry;

  const _InboxErrorCard({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C36) : const Color(0xFFEBE7DF),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kotak masuk belum dapat dimuat. Periksa koneksi lalu coba lagi.',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF151517),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
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
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C2C36) : const Color(0xFFEBE7DF);

    return AppleBouncyCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: notice.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(notice.icon, color: notice.color, size: 20),
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
                      color: isDark ? Colors.white : const Color(0xFF151517),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notice.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFA4A4AB) : const Color(0xFF707074),
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
