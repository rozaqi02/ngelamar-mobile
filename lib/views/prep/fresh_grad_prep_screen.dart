import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/salary_evaluator_service.dart';
import '../../widgets/apple_toast.dart';

/// Halaman Persiapan Karir - Apple HIG iOS 18 Style.
/// CupertinoSlidingSegmentedControl, Grouped List View, Large Title collapse.
class FreshGradPrepScreen extends StatefulWidget {
  const FreshGradPrepScreen({super.key});

  @override
  State<FreshGradPrepScreen> createState() => _FreshGradPrepScreenState();
}

class _FreshGradPrepScreenState extends State<FreshGradPrepScreen> {
  // Segmented control index
  int _selectedSegment = 0;

  // --- Checklist Berkas ---
  final List<Map<String, dynamic>> _docs = [
    {'title': 'CV Format ATS (PDF, maks. 2 halaman)', 'checked': true},
    {'title': 'Portofolio / Project Showcase', 'checked': false},
    {'title': 'Surat Lamaran (Cover Letter)', 'checked': true},
    {'title': 'Ijazah / Surat Keterangan Lulus (SKL)', 'checked': true},
    {'title': 'Transkrip Nilai Legalisir', 'checked': true},
    {'title': 'Pasfoto Formal (Background Polos)', 'checked': false},
    {'title': 'Sertifikat Pelatihan / Organisasi', 'checked': false},
  ];

  // --- Salary Calculator ---
  double _grossSalary = 5500000;
  String _selectedCity = 'Jakarta';
  bool _needsKos = true;

  int get _checkedCount => _docs.where((d) => d['checked'] == true).length;
  double get _readinessPercent =>
      _docs.isEmpty ? 0 : _checkedCount / _docs.length;

  // --- Interview Q&A ---
  final _qaItems = const [
    {
      'q': 'Ceritakan tentang diri Anda',
      'sub': 'Elevator Pitch 60 Detik',
      'a': 'Sebutkan latar belakang pendidikan, posisi yang diminati, 2-3 keahlian utama, serta pengalaman proyek kuliah atau magang yang relevan secara ringkas dan percaya diri.',
    },
    {
      'q': 'Mengapa melamar posisi ini tanpa pengalaman kerja?',
      'sub': 'Motivasi & Nilai',
      'a': 'Hubungkan ilmu kuliah dan proyek Anda dengan deskripsi kerja. Tunjukkan antusiasme untuk belajar cepat dan kontribusi nyata yang dapat Anda berikan sejak hari pertama.',
    },
    {
      'q': 'Berapa ekspektasi gaji Anda?',
      'sub': 'Negosiasi',
      'a': 'Sampaikan rentang gaji yang sesuai standar UMR kota tersebut. Contoh: "Berdasarkan riset UMR dan standar fresh graduate di kota ini, ekspektasi saya Rp X - Rp Y, namun saya terbuka menyesuaikan dengan benefit perusahaan."',
    },
    {
      'q': 'Apa kelebihan dan kekurangan terbesar Anda?',
      'sub': 'Self-Awareness',
      'a': 'Kelebihan: Pilih 1 soft skill atau hard skill dengan contoh proyek nyata. Kekurangan: Sebutkan kelemahan yang sedang aktif Anda perbaiki, misal "Saya sedang belajar manajemen waktu dengan to-do list harian."',
    },
    {
      'q': 'Di mana Anda melihat diri Anda dalam 3-5 tahun ke depan?',
      'sub': 'Ambisi & Komitmen',
      'a': 'Jawab dengan jujur dan realistis. Tunjukkan bahwa Anda ingin tumbuh bersama perusahaan ini, bukan sekadar batu loncatan. Sebutkan keterampilan spesifik yang ingin Anda kuasai.',
    },
  ];

  // --- Templat Pesan ---
  final _templates = const [
    {
      'title': 'Email Melamar Kerja (Formal)',
      'category': 'Email',
      'icon': CupertinoIcons.envelope_fill,
      'color': 0xFF007AFF,
      'text':
          'Yth. HRD [Nama Perusahaan],\n\nPerkenalkan nama saya [Nama Anda], lulusan [Jurusan] dari [Universitas]. Berdasarkan informasi posisi [Nama Posisi], saya bermaksud mengajukan diri untuk bergabung dengan perusahaan Bapak/Ibu.\n\nTerlampir CV dan Portofolio saya sebagai bahan pertimbangan. Saya siap dihubungi kapan saja untuk proses seleksi lebih lanjut.\n\nTerima kasih,\n[Nama Anda]\n[Nomor HP]',
    },
    {
      'title': 'Follow-Up Status Lamaran',
      'category': 'WhatsApp',
      'icon': CupertinoIcons.chat_bubble_fill,
      'color': 0xFF34C759,
      'text':
          'Selamat pagi/siang Bapak/Ibu HRD [Nama Perusahaan], perkenalkan saya [Nama Anda] yang melamar posisi [Nama Posisi] pada [Tanggal]. Saya ingin menanyakan perkembangan proses seleksi berkas saya. Terima kasih banyak atas waktunya.',
    },
    {
      'title': 'Konfirmasi Jadwal Interview',
      'category': 'WhatsApp',
      'icon': CupertinoIcons.calendar_badge_plus,
      'color': 0xFFFF9500,
      'text':
          'Selamat pagi/siang Bapak/Ibu, terima kasih atas undangan interview untuk posisi [Nama Posisi]. Saya mengonfirmasi kehadiran pada [Hari/Tanggal] pukul [Waktu] di [Lokasi]. Terima kasih.',
    },
    {
      'title': 'Ucapan Terima Kasih Pasca Interview',
      'category': 'Email',
      'icon': CupertinoIcons.star_fill,
      'color': 0xFF5E5CE6,
      'text':
          'Yth. [Nama Interviewer],\n\nTerima kasih atas waktu dan kesempatan wawancara hari ini. Saya semakin antusias dengan kesempatan untuk bergabung di [Nama Perusahaan] setelah mendengar penjelasan Bapak/Ibu mengenai peran dan tim yang ada.\n\nSaya berharap dapat segera berkontribusi di tim Anda.\n\nHormat saya,\n[Nama Anda]',
    },
  ];

  final _segments = ['Berkas', 'Gaji', 'Interview', 'Templat'];

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.getBackground(context);
    final txtPri = AppTheme.getTextPrimary(context);


    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Apple Large Title App Bar
          CupertinoSliverNavigationBar(
            backgroundColor: bg.withValues(alpha: 0.85),
            border: null,
            largeTitle: Text(
              'Persiapan Karir',
              style: TextStyle(
                color: txtPri,
                fontWeight: FontWeight.bold,
              ),
            ),
            middle: Text(
              'Persiapan Karir',
              style: TextStyle(
                color: txtPri,
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
            stretch: true,
          ),

          // Segmented Control - sticky di bawah nav bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SegmentedHeaderDelegate(
              segments: _segments,
              selectedIndex: _selectedSegment,
              isDark: isDark,
              onChanged: (i) => setState(() => _selectedSegment = i),
            ),
          ),

          // Content berdasarkan tab aktif
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedSegment),
                child: _buildContent(context, isDark),
              ),
            ),
          ),

          // Bottom safe area
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    switch (_selectedSegment) {
      case 0:
        return _buildChecklistContent(context, isDark);
      case 1:
        return _buildSalaryContent(context, isDark);
      case 2:
        return _buildInterviewContent(context, isDark);
      case 3:
        return _buildTemplatesContent(context, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 1. Checklist Berkas ──────────────────────────────────────────────────────

  Widget _buildChecklistContent(BuildContext context, bool isDark) {
    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final bdr = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);
    final percent = _readinessPercent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Progress Card
          _AppleCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kesiapan Berkas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: txtPri,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _progressColor(percent).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(_checkedCount)}/${_docs.length} berkas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _progressColor(percent),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 10,
                    backgroundColor:
                        AppTheme.getSurfaceSecondary(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _progressColor(percent)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  percent < 1.0
                      ? 'Lengkapi ${_docs.length - _checkedCount} berkas lagi agar siap melamar'
                      : 'Semua berkas sudah siap - selamat melamar!',
                  style: TextStyle(
                    fontSize: 13,
                    color: txtSec,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section Header gaya Apple
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'DAFTAR PERIKSA BERKAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: txtSec,
                letterSpacing: 0.4,
              ),
            ),
          ),

          // Grouped Checklist - Apple Settings style
          Container(
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: bdr, width: AppTheme.borderHairline),
            ),
            child: Column(
              children: List.generate(_docs.length, (i) {
                final doc = _docs[i];
                final isChecked = doc['checked'] as bool;
                final isLast = i == _docs.length - 1;

                return Column(
                  children: [
                    _ChecklistRow(
                      title: doc['title'] as String,
                      isChecked: isChecked,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _docs[i]['checked'] = !isChecked;
                        });
                      },
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 52,
                        endIndent: 0,
                        color: bdr,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _progressColor(double percent) {
    if (percent < 0.5) return AppTheme.systemRed;
    if (percent < 0.8) return AppTheme.systemOrange;
    return AppTheme.systemGreen;
  }

  // ── 2. Estimator Gaji ────────────────────────────────────────────────────────

  Widget _buildSalaryContent(BuildContext context, bool isDark) {
    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final bdr = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);
    final blue = isDark ? AppTheme.systemBlue : AppTheme.lSystemBlue;

    final eval = SalaryEvaluatorService.evaluateSalary(
      grossSalary: _grossSalary,
      city: _selectedCity,
      workType: 'WFO',
      needsKos: _needsKos,
    );
    final isPositive = eval.estimatedNetSavings >= 0;
    final resultColor = isPositive ? AppTheme.systemGreen : AppTheme.systemRed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Input Card
          _AppleCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimator Gaji Pertama',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: txtPri,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hitung estimasi sisa gaji bersih setelah potongan dan biaya hidup.',
                  style: TextStyle(
                      fontSize: 13, color: txtSec, letterSpacing: -0.1),
                ),
                const SizedBox(height: 20),

                // Gaji slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tawaran Gaji Kotor',
                        style: TextStyle(
                            fontSize: 14,
                            color: txtSec,
                            letterSpacing: -0.2)),
                    Text(
                      SalaryEvaluatorService.formatRupiah(_grossSalary),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: txtPri,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: blue,
                    inactiveTrackColor:
                        AppTheme.getSurfaceSecondary(context),
                    thumbColor: isDark ? Colors.white : Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 11),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 20),
                    overlayColor: blue.withValues(alpha: 0.12),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: _grossSalary,
                    min: 2000000,
                    max: 15000000,
                    divisions: 130,
                    onChanged: (v) => setState(() => _grossSalary = v),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rp 2 Jt',
                        style: TextStyle(fontSize: 11, color: txtSec)),
                    Text('Rp 15 Jt',
                        style: TextStyle(fontSize: 11, color: txtSec)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // City + Kos Card - Apple Grouped style
          Container(
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: bdr, width: AppTheme.borderHairline),
            ),
            child: Column(
              children: [
                // Kota dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.location_fill,
                          size: 18, color: AppTheme.systemRed),
                      const SizedBox(width: 10),
                      Text(
                        'Kota Tujuan Kerja',
                        style: TextStyle(
                          fontSize: 15,
                          color: txtPri,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _showCityPicker(context),
                        child: Row(
                          children: [
                            Text(
                              _selectedCity,
                              style: TextStyle(
                                fontSize: 15,
                                color: txtSec,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(CupertinoIcons.chevron_right,
                                size: 14, color: txtSec),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, indent: 44, color: bdr),
                // Perlu Kos switch
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.house_fill,
                          size: 18, color: AppTheme.systemOrange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Perlu Sewa Kos',
                              style: TextStyle(
                                fontSize: 15,
                                color: txtPri,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Estimasi kos ±Rp 1.500.000/bulan',
                              style: TextStyle(
                                fontSize: 12,
                                color: txtSec,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _needsKos,
                        activeTrackColor: blue,
                        onChanged: (v) => setState(() => _needsKos = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Result card
          Container(
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(
                color: resultColor.withValues(alpha: 0.25),
                width: AppTheme.borderHairline,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPositive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.exclamationmark_circle_fill,
                      size: 18,
                      color: resultColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPositive
                          ? 'Gaji ini cukup untuk hidup mandiri'
                          : 'Gaji ini kurang untuk hidup mandiri',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: resultColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SalaryRow(
                  label: 'Gaji Kotor',
                  value: SalaryEvaluatorService.formatRupiah(eval.grossSalary),
                  color: txtPri,
                ),
                const SizedBox(height: 6),
                _SalaryRow(
                  label: 'Potongan BPJS (-4%)',
                  value: '- ${SalaryEvaluatorService.formatRupiah(eval.estimatedBpjsDeduction)}',
                  color: AppTheme.systemRed,
                ),
                const SizedBox(height: 6),
                _SalaryRow(
                  label: 'Biaya Hidup & Kos',
                  value: '- ${SalaryEvaluatorService.formatRupiah(eval.estimatedOperationalCost)}',
                  color: AppTheme.systemRed,
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: resultColor.withValues(alpha: 0.20)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimasi Sisa / Tabungan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: txtPri,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      SalaryEvaluatorService.formatRupiah(
                          eval.estimatedNetSavings),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: resultColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    final cities = SalaryEvaluatorService.umrList;
    int tempIndex = cities.indexWhere((u) => u.city == _selectedCity);
    if (tempIndex < 0) tempIndex = 0;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: AppTheme.getSurface(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  child: const Text(
                    'Pilih',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedCity = cities[tempIndex].city;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                    initialItem: tempIndex),
                itemExtent: 40,
                onSelectedItemChanged: (i) => tempIndex = i,
                children: cities
                    .map((u) => Text(
                          '${u.city} (${SalaryEvaluatorService.formatRupiah(u.umrAmount)})',
                          style: TextStyle(
                            color: AppTheme.getTextPrimary(context),
                            fontSize: 15,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Interview Q&A ─────────────────────────────────────────────────────────

  Widget _buildInterviewContent(BuildContext context, bool isDark) {
    final surf = AppTheme.getSurface(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final bdr = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Tips banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.systemBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(
                color: AppTheme.systemBlue.withValues(alpha: 0.25),
                width: AppTheme.borderHairline,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.lightbulb_fill,
                    size: 18, color: AppTheme.systemBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pelajari pertanyaan-pertanyaan umum ini sebelum interview. '
                    'Jawaban terbaik selalu yang tulus, spesifik, dan disertai contoh nyata.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.systemBlue,
                      height: 1.4,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Q&A list - Apple Grouped Style dengan ExpansionTile
          Container(
            decoration: BoxDecoration(
              color: surf,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: bdr, width: AppTheme.borderHairline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: Column(
                children: List.generate(_qaItems.length, (i) {
                  final item = _qaItems[i];
                  final isLast = i == _qaItems.length - 1;

                  return Column(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.start,
                          childrenPadding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 14),
                          leading: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.systemBlue
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.systemBlue,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            item['q']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: txtPri,
                              letterSpacing: -0.2,
                            ),
                          ),
                          subtitle: Text(
                            item['sub']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: txtSec,
                              letterSpacing: -0.1,
                            ),
                          ),
                          iconColor: txtSec,
                          collapsedIconColor: txtSec,
                          children: [
                            Text(
                              item['a']!,
                              style: TextStyle(
                                fontSize: 13,
                                color: txtSec,
                                height: 1.5,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(height: 1, indent: 62, color: bdr),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Templat Pesan ─────────────────────────────────────────────────────────

  Widget _buildTemplatesContent(BuildContext context, bool isDark) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ...List.generate(_templates.length, (i) {
            final t = _templates[i];
            final color = Color(t['color'] as int);
            final icon = t['icon'] as IconData;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AppleCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(icon, size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['title'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: txtPri,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                t['category'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: t['text'] as String));
                            AppleToast.success(
                                context, 'Templat berhasil disalin!');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE5E5EA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.doc_on_doc,
                                    size: 13,
                                    color: AppTheme.systemBlue),
                                const SizedBox(width: 4),
                                Text(
                                  'Salin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.systemBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t['text'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: txtSec,
                          height: 1.5,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Segmented Header Delegate ──────────────────────────────────────────────────

class _SegmentedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> segments;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _SegmentedHeaderDelegate({
    required this.segments,
    required this.selectedIndex,
    required this.isDark,
    required this.onChanged,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg = AppTheme.getBackground(context);

    return Container(
      color: bg.withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: selectedIndex,
        thumbColor: isDark ? const Color(0xFF3A3A3C) : Colors.white,
        backgroundColor: isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFE5E5EA),
        children: {
          for (int i = 0; i < segments.length; i++)
            i: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                segments[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextPrimary(context),
                  letterSpacing: -0.2,
                ),
              ),
            ),
        },
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_SegmentedHeaderDelegate old) =>
      old.selectedIndex != selectedIndex ||
      old.isDark != isDark;
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _AppleCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _AppleCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surf = AppTheme.getSurface(context);
    final bdr = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: bdr, width: AppTheme.borderHairline),
      ),
      child: child,
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String title;
  final bool isChecked;
  final bool isDark;
  final VoidCallback onTap;

  const _ChecklistRow({
    required this.title,
    required this.isChecked,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isChecked
                    ? AppTheme.systemBlue
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isChecked
                    ? null
                    : Border.all(
                        color: isDark
                            ? const Color(0xFF48484A)
                            : const Color(0xFFC6C6C8),
                        width: 1.5,
                      ),
              ),
              child: isChecked
                  ? const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isChecked ? FontWeight.w500 : FontWeight.w400,
                  color: isChecked ? txtPri : txtSec,
                  decoration:
                      isChecked ? TextDecoration.lineThrough : null,
                  decorationColor: txtSec,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SalaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final txtSec = AppTheme.getTextSecondary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: txtSec,
            letterSpacing: -0.1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
