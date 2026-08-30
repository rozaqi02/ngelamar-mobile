import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/job_application.dart';
import '../../models/calendar_event.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_layout_metrics.dart';
import '../../widgets/app_motion.dart';
import '../../widgets/calendar_planner_mascot.dart';
import '../../widgets/company_logo_badge.dart';
import '../jobs/job_detail_screen.dart';

/// Kalender kerja modern dan minimalis yang memusatkan seluruh jadwal seleksi,
/// tindak lanjut, dan tenggat lamaran dalam satu tampilan.
class CalendarScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenCareerHub;

  const CalendarScreen({super.key, this.onOpenCareerHub});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _visibleMonth = DateTime(today.year, today.month);
    _selectedDate = today;
  }

  void _moveMonth(int offset) {
    HapticFeedback.selectionClick();
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    final maxDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    setState(() {
      _visibleMonth = nextMonth;
      _selectedDate = DateTime(
        nextMonth.year,
        nextMonth.month,
        _selectedDate.day.clamp(1, maxDay),
      );
    });
  }

  void _goToToday() {
    HapticFeedback.mediumImpact();
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _visibleMonth = DateTime(today.year, today.month);
      _selectedDate = today;
    });
  }

  List<CalendarEvent> _collectEvents(List<JobApplication> jobs) =>
      CalendarEventAdapter.fromJobs(jobs);

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final surfaceColor = AppTheme.getSurface(context);
    final borderColor = AppTheme.getBorder(context);

    final events = _collectEvents(ref.watch(jobProvider).jobs);
    final selectedEvents = events
        .where((event) => _sameDay(event.date, _selectedDate))
        .toList();
    final today = DateUtils.dateOnly(DateTime.now());
    final isViewingToday = _sameDay(_selectedDate, today);

    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final leadingDays = firstDay.weekday % 7;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final calendarCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

    // Monthly Analytics
    final eventsThisMonth = events
        .where(
          (event) =>
              event.date.year == _visibleMonth.year &&
              event.date.month == _visibleMonth.month,
        )
        .toList();
    final selectionCountThisMonth = eventsThisMonth
        .where((e) => e.legendKind == 'interview')
        .length;
    final otherCountThisMonth =
        eventsThisMonth.length - selectionCountThisMonth;

    // Nearest upcoming agenda
    final upcomingEvents = events
        .where((e) => !DateUtils.dateOnly(e.date).isBefore(today))
        .toList();
    final nearestEvent = upcomingEvents.isNotEmpty
        ? upcomingEvents.first
        : null;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            AppLayoutMetrics.headerTopInsideSafeArea(context, extra: 12),
            20,
            AppLayoutMetrics.contentBottomClearance(context),
          ),
          children: [
            // 1. Header Bar: Title + Subtitle + Fast Shortcuts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KALENDER',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          height: 0.98,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Jadwal seleksi dan agenda lamaranmu.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (!isViewingToday ||
                        _visibleMonth.year != today.year ||
                        _visibleMonth.month != today.month)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _goToToday,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF27272A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: borderColor.withValues(
                                    alpha: isDark ? 0.3 : 0.6,
                                  ),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.today_rounded,
                                    color: const Color(0xFF5C44E4),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Hari Ini',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.onOpenCareerHub != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onOpenCareerHub,
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF27272A)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderColor.withValues(
                                  alpha: isDark ? 0.3 : 0.6,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_mosaic_rounded,
                              color: Color(0xFF5C44E4),
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Minimal Bento Metrics (Borderless Tonal Cards)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(
                        color: borderColor.withValues(
                          alpha: isDark ? 0.25 : 0.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.15 : 0.03,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat(
                                  'MMM y',
                                  'id_ID',
                                ).format(_visibleMonth).toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF5C44E4),
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${eventsThisMonth.length} Agenda',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$selectionCountThisMonth seleksi / $otherCountThisMonth lainnya',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(
                        color: borderColor.withValues(
                          alpha: isDark ? 0.25 : 0.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.15 : 0.03,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'AGENDA TERDEKAT',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFFD97706),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: Color(0xFFD97706),
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nearestEvent != null
                              ? _formatRelativeDay(nearestEvent.date, today)
                              : 'Semua Aman',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nearestEvent != null
                              ? '${nearestEvent.job.companyName} / ${_formatEventTime(nearestEvent.date)}'
                              : 'Belum ada agenda seleksi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Calendar Month Card
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
                border: Border.all(
                  color: borderColor.withValues(alpha: isDark ? 0.25 : 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month Navigator Row
                  Row(
                    children: [
                      _MonthNavButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Bulan sebelumnya',
                        onTap: () => _moveMonth(-1),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat('MMMM y', 'id_ID').format(_visibleMonth),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      _MonthNavButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Bulan berikutnya',
                        onTap: () => _moveMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Weekday Header Labels (Clean Typography)
                  Row(
                    children:
                        const ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB']
                            .map(
                              (day) => Expanded(
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textSecondary.withValues(alpha: 0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Day grid with compact multi-category event markers.
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: calendarCells,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                    itemBuilder: (context, index) {
                      final dayNumber = index - leadingDays + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      final date = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month,
                        dayNumber,
                      );
                      final isSelected = _sameDay(date, _selectedDate);
                      final isToday = _sameDay(date, today);
                      final dayEvents = events
                          .where((event) => _sameDay(event.date, date))
                          .toList();
                      final hasEvents = dayEvents.isNotEmpty;
                      final markerColors = <Color>[];
                      for (final event in dayEvents) {
                        final color = _calendarEventColor(
                          event.legendKind,
                          isDark,
                        );
                        if (!markerColors.contains(color)) {
                          markerColors.add(color);
                        }
                      }

                      Color cellBg;
                      Color cellTextColor;

                      if (isSelected) {
                        cellBg = isDark
                            ? const Color(0xFFE5DDFF)
                            : const Color(0xFF19191B);
                        cellTextColor = isDark
                            ? const Color(0xFF19191B)
                            : Colors.white;
                      } else if (hasEvents) {
                        cellBg = isDark
                            ? const Color(0xFF242429)
                            : const Color(0xFFF7F4EE);
                        cellTextColor = textPrimary;
                      } else {
                        cellBg = Colors.transparent;
                        cellTextColor = textPrimary;
                      }

                      return Semantics(
                        button: true,
                        selected: isSelected,
                        label:
                            '${DateFormat('d MMMM y', 'id_ID').format(date)}, ${dayEvents.length} kegiatan',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedDate = date);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            decoration: BoxDecoration(
                              color: cellBg,
                              shape: BoxShape.circle,
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: const Color(0xFF5C44E4),
                                      width: 1.4,
                                    )
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.translate(
                                  offset: Offset(
                                    0,
                                    markerColors.isNotEmpty ? -3 : 0,
                                  ),
                                  child: Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      color: cellTextColor,
                                      fontSize: 13,
                                      fontWeight:
                                          isSelected || hasEvents || isToday
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (markerColors.isNotEmpty)
                                  Positioned(
                                    bottom: 5,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: markerColors
                                          .take(4)
                                          .map(
                                            (color) => Container(
                                              width: 4.5,
                                              height: 4.5,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Four event categories used by the markers above.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF27272A).withValues(alpha: 0.5)
                          : const Color(0xFFF9F7F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _CalendarLegendItem(
                          color: _calendarEventColor('application', isDark),
                          label: 'Lamaran',
                        ),
                        _CalendarLegendItem(
                          color: _calendarEventColor('interview', isDark),
                          label: 'Seleksi',
                        ),
                        _CalendarLegendItem(
                          color: _calendarEventColor('next_action', isDark),
                          label: 'Tindak Lanjut',
                        ),
                        _CalendarLegendItem(
                          color: _calendarEventColor('deadline', isDark),
                          label: 'Tenggat',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Selected Day Agenda Section
            Row(
              children: [
                Expanded(
                  child: Text(
                    isViewingToday
                        ? 'HARI INI'
                        : DateFormat(
                            'EEEE, d MMMM y',
                            'id_ID',
                          ).format(_selectedDate).toUpperCase(),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFEFECE6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedEvents.isEmpty
                        ? 'KOSONG'
                        : '${selectedEvents.length} JADWAL',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 5. Selected Day Events List or Clean Empty State
            if (selectedEvents.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(
                    color: borderColor.withValues(alpha: isDark ? 0.25 : 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFF4F2EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tidak ada jadwal kegiatan',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih tanggal lain atau tambahkan jadwal pada lamaranmu.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...selectedEvents.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CalendarEventCard(event: event),
                ),
              ),

            const SizedBox(height: 6),

            // 6. Friendly planner mascot resting at the bottom of the screen
            Center(
              child: Opacity(
                opacity: isDark ? 0.85 : 1.0,
                child: const CalendarPlannerMascot(width: 190, height: 158),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRelativeDay(DateTime date, DateTime today) {
    final diff = DateUtils.dateOnly(date).difference(today).inDays;
    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Besok';
    if (diff == 2) return 'Lusa';
    return DateFormat('d MMM', 'id_ID').format(date);
  }

  static String _formatEventTime(DateTime date) {
    if (date.hour == 0 && date.minute == 0) return 'Seharian';
    return '${DateFormat('HH:mm').format(date)} WIB';
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MonthNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F2EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.getTextPrimary(context),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;

  const _CalendarEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = _calendarEventColor(event.legendKind, isDark);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final surfaceColor = AppTheme.getSurface(context);
    final borderColor = AppTheme.getBorder(context);

    final timeStr = event.date.hour == 0 && event.date.minute == 0
        ? 'Seharian'
        : '${DateFormat('HH:mm').format(event.date)} WIB';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: () => Navigator.of(context).push(
          AppMotion.detailDockRoute(
            builder: (_) => JobDetailScreen(
              job: event.job,
              companyLogoHeroTag: event.companyHeroTag,
            ),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: borderColor.withValues(alpha: isDark ? 0.25 : 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 42,
                child: Hero(
                  tag: event.companyHeroTag,
                  createRectTween: companyLogoRectTween,
                  flightShuttleBuilder: companyLogoFlightShuttle,
                  placeholderBuilder: companyLogoHeroPlaceholder,
                  child: CompanyLogoBadge(
                    companyName: event.job.companyName,
                    size: 42,
                    customImagePath: event.job.companyLogoPath,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: isDark ? 0.22 : 0.14,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.title.toUpperCase(),
                            style: TextStyle(
                              color: accent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.job.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${event.job.position} / ${event.job.workType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _calendarEventColor(String kind, bool isDark) {
  switch (kind) {
    case 'application':
      return isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
    case 'interview':
    case 'test':
      return isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706);
    case 'deadline':
      return isDark ? const Color(0xFFFCA5A5) : const Color(0xFFE11D48);
    default:
      return isDark ? const Color(0xFF86EFAC) : const Color(0xFF059669);
  }
}

class _CalendarLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _CalendarLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(width: 4.5),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
