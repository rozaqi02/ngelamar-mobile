import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/salary_evaluator_service.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/apple_animations.dart';

class FreshGradPrepScreen extends StatefulWidget {
  const FreshGradPrepScreen({super.key});

  @override
  State<FreshGradPrepScreen> createState() => _FreshGradPrepScreenState();
}

class _FreshGradPrepScreenState extends State<FreshGradPrepScreen> {
  int _selectedSegment = 0;

  final List<Map<String, dynamic>> _docs = [
    {'title': 'CV Format ATS (PDF, maks. 2 halaman)', 'checked': true},
    {'title': 'Portofolio / Project GitHub Showcase', 'checked': false},
    {'title': 'Surat Lamaran (Cover Letter)', 'checked': true},
    {'title': 'Ijazah / Surat Keterangan Lulus (SKL)', 'checked': true},
    {'title': 'Transkrip Nilai Legalisir', 'checked': true},
    {'title': 'Pasfoto Formal (Background Polos)', 'checked': false},
    {'title': 'Sertifikat Pelatihan / Organisasi', 'checked': false},
  ];

  double _grossSalary = 6500000;
  String _selectedCity = 'Jakarta';
  bool _needsKos = true;

  int get _checkedCount => _docs.where((d) => d['checked'] == true).length;
  double get _readinessPercent => _docs.isEmpty ? 0 : _checkedCount / _docs.length;

  final _qaItems = const [
    {
      'q': 'Ceritakan tentang diri Anda',
      'sub': 'Elevator Pitch 60 Detik',
      'a':
          'Sebutkan latar belakang pendidikan, posisi yang diminati, 2-3 keahlian utama, serta pengalaman proyek kuliah atau magang yang relevan secara ringkas dan percaya diri.',
    },
    {
      'q': 'Mengapa melamar posisi ini tanpa pengalaman kerja?',
      'sub': 'Motivasi & Nilai',
      'a':
          'Hubungkan ilmu kuliah dan proyek Anda dengan deskripsi kerja. Tunjukkan antusiasme untuk belajar cepat dan kontribusi nyata yang dapat Anda berikan sejak hari pertama.',
    },
    {
      'q': 'Berapa ekspektasi gaji Anda?',
      'sub': 'Negosiasi',
      'a':
          'Sampaikan rentang gaji yang sesuai standar UMR kota tersebut. Contoh: "Berdasarkan riset UMR dan standar fresh graduate di kota ini, ekspektasi saya Rp X - Rp Y, namun saya terbuka menyesuaikan dengan benefit perusahaan."',
    },
    {
      'q': 'Apa kelebihan dan kekurangan terbesar Anda?',
      'sub': 'Self-Awareness',
      'a':
          'Kelebihan: Pilih 1 soft skill atau hard skill dengan contoh proyek nyata. Kekurangan: Sebutkan kelemahan yang sedang aktif Anda perbaiki, misal manajemen waktu dengan to-do list.',
    },
  ];

  final _templates = const [
    {
      'title': 'Email Melamar Kerja (Formal)',
      'category': 'Email',
      'color': AppTheme.cardPurple,
      'text':
          'Yth. HRD [Nama Perusahaan],\n\nPerkenalkan nama saya [Nama Anda], lulusan [Jurusan] dari [Universitas]. Berdasarkan informasi posisi [Nama Posisi], saya bermaksud mengajukan diri untuk bergabung dengan perusahaan Bapak/Ibu.\n\nTerlampir CV dan Portofolio saya sebagai bahan pertimbangan. Saya siap dihubungi kapan saja untuk proses seleksi lebih lanjut.\n\nTerima kasih,\n[Nama Anda]\n[Nomor HP]',
    },
    {
      'title': 'Follow-Up Status Lamaran',
      'category': 'WhatsApp',
      'color': AppTheme.cardGreen,
      'text':
          'Selamat pagi/siang Bapak/Ibu HRD [Nama Perusahaan], perkenalkan saya [Nama Anda] yang melamar posisi [Nama Posisi] pada [Tanggal]. Saya ingin menanyakan perkembangan proses seleksi berkas saya. Terima kasih banyak atas waktunya.',
    },
    {
      'title': 'Konfirmasi Jadwal Interview',
      'category': 'WhatsApp',
      'color': AppTheme.cardYellow,
      'text':
          'Selamat pagi/siang Bapak/Ibu, terima kasih atas undangan interview untuk posisi [Nama Posisi]. Saya mengonfirmasi kehadiran pada [Hari/Tanggal] pukul [Waktu] di [Lokasi]. Terima kasih.',
    },
    {
      'title': 'Ucapan Terima Kasih Pasca Interview',
      'category': 'Email',
      'color': AppTheme.cardCoral,
      'text':
          'Yth. [Nama Interviewer],\n\nTerima kasih atas waktu dan kesempatan wawancara hari ini. Saya semakin antusias dengan kesempatan untuk bergabung di [Nama Perusahaan].\n\nHormat saya,\n[Nama Anda]',
    },
  ];

  final _segments = ['Berkas', 'Gaji UMR', 'Interview', 'Templat'];

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.getBackground(context);
    final txtPri = AppTheme.getTextPrimary(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERSIAPAN\nKARIR',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: txtPri,
                        letterSpacing: -1.2,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Checklist berkas, simulasi gaji UMR, cheat-sheet interview & templat',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

            // Segmented Filter Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: List.generate(_segments.length, (i) {
                    final isSel = _selectedSegment == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < _segments.length - 1 ? 6 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSegment = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF19191B)
                                  : (isDark ? const Color(0xFF242428) : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF19191B)
                                    : const Color(0xFFE6E3D8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _segments[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF333333)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Tab Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverToBoxAdapter(
                child: _buildSelectedTabContent(context, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(BuildContext context, bool isDark) {
    switch (_selectedSegment) {
      case 0:
        return _buildChecklistTab(context, isDark);
      case 1:
        return _buildSalaryTab(context, isDark);
      case 2:
        return _buildInterviewTab(context, isDark);
      case 3:
        return _buildTemplatesTab(context, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChecklistTab(BuildContext context, bool isDark) {
    final percent = _readinessPercent;
    final cardBg = isDark ? const Color(0xFF1E1E22) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Readiness Hero Card (Purple Card)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardPurple,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cardPurple.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kesiapan Berkas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_checkedCount)}/${_docs.length} Siap',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                percent < 1.0
                    ? 'Lengkapi ${_docs.length - _checkedCount} berkas lagi agar persiapan lamaran optimal.'
                    : 'Luar biasa! Seluruh berkas karir sudah lengkap.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Checklist Items
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: const Color(0xFFE6E3D8)),
          ),
          child: Column(
            children: List.generate(_docs.length, (i) {
              final doc = _docs[i];
              final isChecked = doc['checked'] as bool;
              final isLast = i == _docs.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: GestureDetector(
                      onTap: () => setState(() => _docs[i]['checked'] = !isChecked),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isChecked ? AppTheme.cardPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isChecked ? AppTheme.cardPurple : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: isChecked
                            ? const Icon(CupertinoIcons.checkmark_alt, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    title: Text(
                      doc['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? Colors.grey : null,
                      ),
                    ),
                    onTap: () => setState(() => _docs[i]['checked'] = !isChecked),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 54),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryTab(BuildContext context, bool isDark) {
    final eval = SalaryEvaluatorService.evaluateSalary(
      grossSalary: _grossSalary,
      city: _selectedCity,
      workType: 'WFO',
      needsKos: _needsKos,
    );
    final cardBg = isDark ? const Color(0xFF1E1E22) : Colors.white;

    return Column(
      children: [
        // Salary Input Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: const Color(0xFFE6E3D8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tawaran Gaji Pokok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    SalaryEvaluatorService.formatRupiah(_grossSalary),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF19191B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Slider(
                value: _grossSalary,
                min: 2000000,
                max: 20000000,
                divisions: 180,
                activeColor: const Color(0xFF19191B),
                onChanged: (v) => setState(() => _grossSalary = v),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kota Tujuan Kerja', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  DropdownButton<String>(
                    value: _selectedCity,
                    underline: const SizedBox.shrink(),
                    items: SalaryEvaluatorService.umrList
                        .map((u) => DropdownMenuItem(value: u.city, child: Text(u.city, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCity = val!),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Perlu Sewa Kos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  CupertinoSwitch(
                    value: _needsKos,
                    activeTrackColor: const Color(0xFF19191B),
                    onChanged: (v) => setState(() => _needsKos = v),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Result Card (Green / Coral Card)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: eval.estimatedNetSavings >= 0 ? AppTheme.cardGreen : AppTheme.cardCoral,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eval.estimatedNetSavings >= 0
                    ? '✓ Gaji Cukup untuk Hidup Mandiri'
                    : '⚠ Gaji Berpotensi Defisit',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF19191B)),
              ),
              const SizedBox(height: 12),
              _buildEvalRow('Gaji Kotor', SalaryEvaluatorService.formatRupiah(eval.grossSalary)),
              _buildEvalRow('BPJS Ketenagakerjaan (4%)', '- ${SalaryEvaluatorService.formatRupiah(eval.estimatedBpjsDeduction)}'),
              _buildEvalRow('Biaya Kos & Operasional', '- ${SalaryEvaluatorService.formatRupiah(eval.estimatedOperationalCost)}'),
              const Divider(height: 16, color: Colors.black26),
              _buildEvalRow(
                'Estimasi Tabungan Bersih',
                SalaryEvaluatorService.formatRupiah(eval.estimatedNetSavings),
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInterviewTab(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E22) : Colors.white;

    return Column(
      children: _qaItems.map((qa) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: const Color(0xFFE6E3D8)),
          ),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
            title: Text(qa['q']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(qa['sub']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  qa['a']!,
                  style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF333333)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemplatesTab(BuildContext context, bool isDark) {
    return Column(
      children: _templates.map((tpl) {
        final color = tpl['color'] as Color;
        final isDarkText = color == AppTheme.cardYellow || color == AppTheme.cardGreen;
        final titleColor = isDarkText ? const Color(0xFF111113) : Colors.white;
        final subColor = isDarkText ? const Color(0xCC111113) : const Color(0xCCFFFFFF);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tpl['title'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.doc_on_doc, color: titleColor, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tpl['text'] as String));
                      AppleToast.success(context, 'Templat disalin ke clipboard');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tpl['text'] as String,
                style: TextStyle(fontSize: 12, color: subColor, height: 1.4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
