import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/job_provider.dart';
import '../../services/prefs_service.dart';
import '../../services/salary_evaluator_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_toast.dart';
import '../../widgets/rupiah_input_formatter.dart';
import '../subscription/subscription_screen.dart';
import 'career_prep_welcome_screen.dart';

class FreshGradPrepScreen extends ConsumerStatefulWidget {
  const FreshGradPrepScreen({super.key});

  @override
  ConsumerState<FreshGradPrepScreen> createState() => _FreshGradPrepScreenState();
}

class _FreshGradPrepScreenState extends ConsumerState<FreshGradPrepScreen> {
  int _selectedSegment = 0;
  int _expandedQaIndex = 0;

  final List<Map<String, dynamic>> _docs = [
    {'title': 'CV Format ATS (PDF, maks. 2 halaman)', 'checked': false},
    {'title': 'Portofolio / Project Showcase', 'checked': false},
    {'title': 'Surat Lamaran (Cover Letter)', 'checked': false},
    {'title': 'Ijazah / Surat Keterangan Lulus (SKL)', 'checked': false},
    {'title': 'Transkrip Nilai Legalisir', 'checked': false},
    {'title': 'Pasfoto Formal (Background Polos)', 'checked': false},
    {'title': 'Sertifikat Pelatihan / Organisasi', 'checked': false},
  ];

  double _grossSalary = 6500000;
  String _selectedCity = 'Jakarta';
  bool _needsKos = true;
  double _customRentCost = 1500000;
  bool _useCustomUmr = false;
  double _customUmrInput = 5067381;

  late TextEditingController _salaryController;
  late TextEditingController _umrController;
  late TextEditingController _kosController;

  int get _checkedCount => _docs.where((d) => d['checked'] == true).length;
  double get _readinessPercent => _docs.isEmpty ? 0 : _checkedCount / _docs.length;

  @override
  void initState() {
    super.initState();
    _activeQaItems = _allQaPool.take(5).toList();
    _salaryController = TextEditingController(
      text: RupiahInputFormatter.format(_grossSalary, includeSymbol: false),
    );
    _umrController = TextEditingController(
      text: RupiahInputFormatter.format(_customUmrInput, includeSymbol: false),
    );
    _kosController = TextEditingController(
      text: RupiahInputFormatter.format(_customRentCost, includeSymbol: false),
    );
    _loadSavedChecklist();
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _umrController.dispose();
    _kosController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedChecklist() async {
    final savedCheckedTitles = await PrefsService.getChecklistDocs();
    if (savedCheckedTitles != null && mounted) {
      setState(() {
        for (var doc in _docs) {
          doc['checked'] = savedCheckedTitles.contains(doc['title']);
        }
      });
    }
  }

  Future<void> _toggleDoc(int index) async {
    HapticFeedback.selectionClick();
    setState(() {
      _docs[index]['checked'] = !(_docs[index]['checked'] as bool);
    });

    final checkedTitles = _docs
        .where((d) => d['checked'] == true)
        .map((d) => d['title'] as String)
        .toList();
    await PrefsService.setChecklistDocs(checkedTitles);
  }

  void _shareChecklist() {
    HapticFeedback.selectionClick();
    final items = _docs.map((d) => '${(d['checked'] as bool) ? '✅' : '⬜'} ${d['title']}').join('\n');
    final text = '📋 *Kesiapan Berkas Lamaran Saya - Ngelamar App*\n'
        'Progress: $_checkedCount/${_docs.length} (${(_readinessPercent * 100).toInt()}%)\n\n'
        '$items\n\n'
        'Dicatat via Ngelamar App';
    Share.share(text, subject: 'Kesiapan Berkas Lamaran Kerja');
  }

  String _populateTemplate(String templateText, String userName, String? defaultCompany, String? defaultPosition) {
    var result = templateText;
    final name = userName.isNotEmpty ? userName : 'Pencari Kerja';
    result = result.replaceAll('[Nama Anda]', name);
    result = result.replaceAll('[Nama Lengkap]', name);
    if (defaultCompany != null && defaultCompany.isNotEmpty) {
      result = result.replaceAll('[Nama Perusahaan]', defaultCompany);
    }
    if (defaultPosition != null && defaultPosition.isNotEmpty) {
      result = result.replaceAll('[Nama Posisi]', defaultPosition);
      result = result.replaceAll('[Posisi]', defaultPosition);
    }
    final now = DateTime.now();
    result = result.replaceAll('[Tanggal]', '${now.day}/${now.month}/${now.year}');
    result = result.replaceAll('[Hari/Tanggal]', '${now.day}/${now.month}/${now.year}');
    result = result.replaceAll('[Waktu]', '10:00 WIB');
    result = result.replaceAll('[Lokasi]', 'Google Meet / Kantor');
    return result;
  }

  final List<Map<String, String>> _allQaPool = const [
    {
      'q': 'Ceritakan tentang diri Anda',
      'sub': 'Elevator Pitch 60 Detik',
      'a':
          'Sebutkan latar belakang pendidikan, posisi yang diminati, 2-3 keahlian utama, serta pengalaman proyek kuliah atau magang yang relevan secara ringkas, percaya diri, dan terstruktur.',
    },
    {
      'q': 'Mengapa melamar posisi ini tanpa pengalaman kerja?',
      'sub': 'Motivasi & Nilai Tambah',
      'a':
          'Hubungkan ilmu kuliah dan proyek mandiri Anda dengan deskripsi kerja. Tunjukkan antusiasme untuk belajar cepat dan kontribusi nyata yang dapat Anda berikan sejak hari pertama.',
    },
    {
      'q': 'Berapa ekspektasi gaji Anda?',
      'sub': 'Taktik Negosiasi Fresh Grad',
      'a':
          'Sampaikan rentang gaji yang sesuai standar UMR kota tersebut. Contoh: "Berdasarkan riset UMR dan standar fresh graduate di kota ini, ekspektasi saya Rp X - Rp Y, namun saya terbuka menyesuaikan dengan benefit perusahaan."',
    },
    {
      'q': 'Apa kelebihan dan kekurangan terbesar Anda?',
      'sub': 'Self-Awareness & Growth Mindset',
      'a':
          'Kelebihan: Pilih 1 keahlian utama disertai contoh nyata. Kekurangan: Sebutkan kelemahan yang sedang aktif Anda perbaiki, misal manajemen waktu dengan bantuan tools to-do list.',
    },
    {
      'q': 'Ceritakan saat Anda menghadapi masalah sulit dan solusinya',
      'sub': 'Metode STAR (Situation, Task, Action, Result)',
      'a':
          'Gunakan rumus STAR: Jelaskan situasinya (S), tugas Anda (T), tindakan solutif yang Anda ambil (A), dan hasil positif terukur yang dicapai (R).',
    },
    {
      'q': 'Mengapa Anda tertarik bergabung dengan perusahaan kami?',
      'sub': 'Riset Budaya & Nilai Perusahaan',
      'a':
          'Tunjukkan pemahaman Anda tentang produk, visi, atau inovasi terbaru perusahaan. Jelaskan bagaimana nilai perusahaan selaras dengan tujuan karir jangka panjang Anda.',
    },
    {
      'q': 'Bagaimana cara Anda memprioritaskan pekerjaan saat deadline mepet?',
      'sub': 'Time Management & Prioritas',
      'a':
          'Jelaskan penggunaan matriks Eisenhower (mendesak vs penting), komunikasi proaktif dengan tim, dan fokus menyelesaikan blocker kritis terlebih dahulu.',
    },
    {
      'q': 'Di mana Anda melihat diri Anda dalam 3 hingga 5 tahun ke depan?',
      'sub': 'Ambisi & Komitmen Karir',
      'a':
          'Fokus pada penguasaan keahlian mendalam, kontribusi nyata terhadap pertumbuhan tim, dan kesiapan mengambil tanggung jawab lebih besar di perusahaan ini.',
    },
    {
      'q': 'Bagaimana respon Anda jika berbeda pendapat dengan rekan kerja?',
      'sub': 'Komunikasi & Resolusi Konflik',
      'a':
          'Dengarkan sudut pandang rekan secara objektif, fokus pada data dan tujuan bersama tim, serta diskusikan solusi kompromi yang paling menguntungkan project.',
    },
    {
      'q': 'Apa yang Anda lakukan jika mendapat tugas yang belum pernah Anda pelajari?',
      'sub': 'Resourcefulness & Belajar Mandiri',
      'a':
          'Lakukan riset mandiri dari dokumentasi resmi/studi kasus, buat prototype sederhana, dan tanyakan feedback terarah kepada mentor/senior dengan pertanyaan spesifik.',
    },
    {
      'q': 'Apakah ada pertanyaan yang ingin Anda tanyakan kepada kami?',
      'sub': 'Pertanyaan Balik ke Pewawancara',
      'a':
          'Tanyakan hal substantif, misal: "Apa tantangan terbesar yang sedang dihadapi tim posisi ini dalam 6 bulan ke depan?" atau "Seperti apa kriteria sukses di 3 bulan pertama?".',
    },
    {
      'q': 'Ceritakan kegagalan terbesar Anda dan pelajaran yang didapat',
      'sub': 'Resiliensi & Refleksi Diri',
      'a':
          'Pilih kegagalan nyata di masa kuliah/proyek, akui tanggung jawab Anda tanpa menyalahkan orang lain, dan tekankan sistem baru yang Anda buat agar kesalahan itu tidak terulang.',
    },
  ];

  late List<Map<String, String>> _activeQaItems;

  final List<Map<String, dynamic>> _interviewTopics = const [
    {
      'title': 'Metode STAR dalam Menjawab',
      'category': 'Teknik Jawaban',
      'icon': Icons.star_rounded,
      'color': Color(0xFF5C44E4),
      'summary': 'Formula emas untuk menjawab pertanyaan situasional: Situation (Situasi), Task (Tugas), Action (Aksi), dan Result (Hasil terukur).',
    },
    {
      'title': 'Taktik Negosiasi Gaji Pertama',
      'category': 'Kompensasi',
      'icon': Icons.payments_rounded,
      'color': Color(0xFF1E8E3E),
      'summary': 'Ketahui standar UMR, pisahkan gaji pokok dengan tunjangan, dan hitung benefit asuransi serta fasilitas kerja.',
    },
    {
      'title': 'Kelemahan Tanpa Menjatuhkan Diri',
      'category': 'Self-Awareness',
      'icon': Icons.psychology_rounded,
      'color': Color(0xFFD97706),
      'summary': 'Sebutkan kelemahan yang bukan core requirements pekerjaan, dan tunjukkan langkah nyata yang sedang aktif Anda jalankan.',
    },
    {
      'title': '5 Pertanyaan Balik Paling Cerdas',
      'category': 'Reverse Q&A',
      'icon': Icons.help_outline_rounded,
      'color': Color(0xFF0288D1),
      'summary': 'Tanyakan tentang ekspektasi 90 hari pertama, kultur tim, dan kesempatan pengembangan skill untuk meninggalkan impresi positif.',
    },
    {
      'title': 'Menghadapi Pertanyaan Sulit / Blank',
      'category': 'Ketenangan',
      'icon': Icons.lightbulb_outline_rounded,
      'color': Color(0xFFE53935),
      'summary': 'Minta izin jeda 5 detik untuk berpikir, atau minta klarifikasi dengan sopan daripada mengarang jawaban yang tidak akurat.',
    },
    {
      'title': 'Body Language & Artikulasi Percaya Diri',
      'category': 'Etika & Sikap',
      'icon': Icons.record_voice_over_rounded,
      'color': Color(0xFF7B1FA2),
      'summary': 'Jaga kontak mata wajar, duduk tegak rileks, hindari kata filler berlebih, dan gunakan intonasi yang antusias.',
    },
  ];

  void _randomizeQaItems() {
    HapticFeedback.mediumImpact();
    final copy = List<Map<String, String>>.from(_allQaPool)..shuffle();
    setState(() {
      _activeQaItems = copy.take(5).toList();
      _expandedQaIndex = 0;
    });
    AppleToast.success(context, '5 Pertanyaan interview baru telah diacak!');
  }

  final _templates = const [
    {
      'title': 'Email Melamar Kerja (Formal)',
      'category': 'Email',
      'isPro': false,
      'color': AppTheme.cardPurple,
      'text':
          'Yth. HRD [Nama Perusahaan],\n\nPerkenalkan nama saya [Nama Anda], lulusan [Jurusan] dari [Universitas]. Berdasarkan informasi posisi [Nama Posisi], saya bermaksud mengajukan diri untuk bergabung dengan perusahaan Bapak/Ibu.\n\nTerlampir CV dan Portofolio saya sebagai bahan pertimbangan. Saya siap dihubungi kapan saja untuk proses seleksi lebih lanjut.\n\nTerima kasih,\n[Nama Anda]\n[Nomor HP]',
    },
    {
      'title': 'Follow-Up Status Lamaran (H+7)',
      'category': 'WhatsApp',
      'isPro': false,
      'color': AppTheme.cardGreen,
      'text':
          'Selamat pagi/siang Bapak/Ibu HRD [Nama Perusahaan], perkenalkan saya [Nama Anda] yang melamar posisi [Nama Posisi] pada [Tanggal]. Saya ingin menanyakan perkembangan proses seleksi berkas saya. Terima kasih banyak atas waktunya.',
    },
    {
      'title': 'Konfirmasi Jadwal Interview',
      'category': 'WhatsApp',
      'isPro': false,
      'color': AppTheme.cardYellow,
      'text':
          'Selamat pagi/siang Bapak/Ibu, terima kasih atas undangan interview untuk posisi [Nama Posisi]. Saya mengonfirmasi kehadiran pada [Hari/Tanggal] pukul [Waktu] di [Lokasi]. Terima kasih.',
    },
    {
      'title': 'Ucapan Terima Kasih Pasca Interview',
      'category': 'Email',
      'isPro': false,
      'color': AppTheme.cardCoral,
      'text':
          'Yth. [Nama Interviewer],\n\nTerima kasih atas waktu dan kesempatan wawancara hari ini. Saya semakin antusias dengan kesempatan untuk bergabung di [Nama Perusahaan].\n\nHormat saya,\n[Nama Anda]',
    },
    {
      'title': 'Negosiasi Gaji Tahap Offering (PRO)',
      'category': 'Email',
      'isPro': true,
      'color': Color(0xFF5C44E4),
      'text':
          'Yth. Tim HR [Nama Perusahaan],\n\nTerima kasih banyak atas penawaran kerja untuk posisi [Nama Posisi]. Saya sangat antusias untuk berkontribusi.\n\nBerdasarkan riset standar industri serta keahlian [Keahlian Utama] yang saya miliki, apakah terdapat fleksibilitas pada kompensasi pokok di angka [Rp Target]? Saya sangat terbuka mendiskusikan paket benefit lainnya.\n\nSalam hormat,\n[Nama Anda]',
    },
    {
      'title': 'Minta Waktu Pertimbangan Offering (PRO)',
      'category': 'WhatsApp / Email',
      'isPro': true,
      'color': Color(0xFF1E8E3E),
      'text':
          'Yth. Bapak/Ibu [Nama HR], terima kasih atas surat penawaran (Offering Letter) yang dikirimkan. Saya mohon izin untuk mempelajari rincian kontrak dan benefit ini secara seksama. Saya akan memberikan konfirmasi final paling lambat pada [Hari/Tanggal]. Terima kasih atas pengertiannya.',
    },
    {
      'title': 'Menolak Tawaran Kerja secara Sopan (PRO)',
      'category': 'Email',
      'isPro': true,
      'color': Color(0xFFD97706),
      'text':
          'Yth. Tim Rekrutmen [Nama Perusahaan],\n\nTerima kasih sebesar-besarnya atas kepercayaan Bapak/Ibu menawarkan posisi [Nama Posisi]. Setelah pertimbangan matang dan diskusi keluarga, dengan berat hati saya belum dapat menerima tawaran ini karena saya telah memutuskan mengambil peluang yang lebih selaras dengan fokus jangka pendek saya saat ini.\n\nSemoga [Nama Perusahaan] terus sukses, dan saya berharap dapat tetap terhubung secara profesional di masa depan.\n\nSalam hangat,\n[Nama Anda]',
    },
    {
      'title': 'Follow-Up Hasil Interview User H+3 (PRO)',
      'category': 'WhatsApp',
      'isPro': true,
      'color': Color(0xFF0288D1),
      'text':
          'Selamat pagi Bapak/Ibu [Nama HR], perkenalkan saya [Nama Anda]. Saya ingin mengucapkan terima kasih atas sesi interview user bersama [Nama User/Manager] pada hari [Hari]. Diskusi kemarin sangat menginspirasi saya mengenai target tim kedepan. Mohon info apakah ada berkas tambahan yang perlu saya lengkapi untuk proses selanjutnya? Terima kasih banyak.',
    },
  ];

  final _segments = ['Berkas', 'Gaji UMR', 'Interview', 'Templat'];

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final bg = AppTheme.getBackground(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => const CareerPrepWelcomeScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5E0D5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(CupertinoIcons.question_circle_fill, size: 18, color: Color(0xFF5C44E4)),
                          ),
                        ),
                      ],
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

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: List.generate(_segments.length, (i) {
                    final isSel = _selectedSegment == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < _segments.length - 1 ? 6 : 0),
                        child: FluidBounceButton(
                          onTap: () {
                            setState(() => _selectedSegment = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.fastOutSlowIn,
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
                              boxShadow: isSel
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
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

            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                _selectedSegment == 2 ? 0 : 20,
                0,
                _selectedSegment == 2 ? 0 : 20,
                120 + (bottomInset > 0 ? bottomInset : 0),
              ),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _buildSelectedTabContent(context, isDark),
                ),
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
      key: const ValueKey('tab_checklist'),
      children: [
        Hero(
          tag: 'prep_checklist_card_hero',
          flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
            return Material(
              type: MaterialType.transparency,
              child: toHeroContext.widget,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF19191B),
              borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
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
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_checkedCount / ${_docs.length}',
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, val, _) => LinearProgressIndicator(
                    value: val,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                percent < 1.0
                    ? 'Centang berkas yang sudah Anda siapkan untuk memantau kesiapan.'
                    : 'Seluruh berkas persiapan karir Anda sudah lengkap!',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
              ),
            ],
          ),
        ),
      ),

        const SizedBox(height: 18),

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
                      onTap: () => _toggleDoc(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isChecked ? AppTheme.cardPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isChecked ? AppTheme.cardPurple : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: isChecked
                            ? const Icon(CupertinoIcons.checkmark_alt, size: 17, color: Colors.white)
                            : null,
                      ),
                    ),
                    title: Text(
                      doc['title'] as String,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? Colors.grey : const Color(0xFF121214),
                      ),
                    ),
                    onTap: () => _toggleDoc(i),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 54),
                ],
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        // Share Checklist Readiness Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _shareChecklist,
            icon: const Icon(Icons.share_outlined, size: 17, color: Color(0xFF19191B)),
            label: const Text(
              'Bagikan Ringkasan Kesiapan Berkas',
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF19191B), fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFDCD8CE), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
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
      customKosCost: _needsKos ? _customRentCost : 0,
      customUmr: _useCustomUmr ? _customUmrInput : null,
    );
    final cardBg = isDark ? const Color(0xFF1E1E22) : Colors.white;

    final targetUmr = _useCustomUmr
        ? _customUmrInput
        : (SalaryEvaluatorService.umrList
            .firstWhere((u) => u.city.toLowerCase() == _selectedCity.toLowerCase(),
                orElse: () => const UmrData('Nasional', 3500000))
            .umrAmount);

    return Column(
      key: const ValueKey('tab_salary'),
      children: [
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
              const Text(
                'Tawaran Gaji Pokok (Input Manual)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  RupiahInputFormatter(includeSymbol: false),
                ],
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF19191B)),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF19191B)),
                  fillColor: isDark ? const Color(0xFF2C2C30) : const Color(0xFFF7F5EE),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E0D5))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E0D5))),
                ),
                onChanged: (val) {
                  setState(() {
                    _grossSalary = SalaryEvaluatorService.parseSalaryAmount(val);
                  });
                },
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
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCity = val;
                          final found = SalaryEvaluatorService.umrList.firstWhere((u) => u.city == val);
                          _customUmrInput = found.umrAmount;
                          _umrController.text = RupiahInputFormatter.format(found.umrAmount, includeSymbol: false);
                        });
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total UMR Daerah Dituju', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        _useCustomUmr ? 'Input Manual Aktif' : 'Standar Resmi 2024',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(
                    SalaryEvaluatorService.formatRupiah(targetUmr),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF5C44E4)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sesuaikan Nilai UMR Manual', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  CupertinoSwitch(
                    value: _useCustomUmr,
                    activeTrackColor: const Color(0xFF19191B),
                    onChanged: (v) => setState(() => _useCustomUmr = v),
                  ),
                ],
              ),

              if (_useCustomUmr) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _umrController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(includeSymbol: false),
                  ],
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF5C44E4)),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF5C44E4)),
                    hintText: 'Masukkan UMR manual...',
                    fillColor: isDark ? const Color(0xFF2C2C30) : const Color(0xFFF7F5EE),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E0D5))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E0D5))),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _customUmrInput = SalaryEvaluatorService.parseSalaryAmount(val);
                    });
                  },
                ),
              ],

              const Divider(height: 24),

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

              if (_needsKos) ...[
                const SizedBox(height: 10),
                const Text('Biaya Sewa Kos / bln (Input Manual)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _kosController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(includeSymbol: false),
                  ],
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF19191B)),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF19191B)),
                    fillColor: isDark ? const Color(0xFF2C2C30) : const Color(0xFFF7F5EE),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E0D5))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E0D5))),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _customRentCost = SalaryEvaluatorService.parseSalaryAmount(val);
                    });
                  },
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

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
                    ? 'Gaji Cukup untuk Hidup Mandiri'
                    : 'Gaji Berpotensi Defisit',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF19191B)),
              ),
              const SizedBox(height: 12),
              _buildEvalRow('Gaji Kotor', SalaryEvaluatorService.formatRupiah(eval.grossSalary)),
              _buildEvalRow('Standar UMR Daerah', SalaryEvaluatorService.formatRupiah(targetUmr)),
              _buildEvalRow('BPJS Ketenagakerjaan (4%)', '- ${SalaryEvaluatorService.formatRupiah(eval.estimatedBpjsDeduction)}'),
              if (_needsKos)
                _buildEvalRow('Biaya Sewa Kos (Input User)', '- ${SalaryEvaluatorService.formatRupiah(_customRentCost)}'),
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

  void _showTopicDetailModal(BuildContext context, Map<String, dynamic> topic) {
    HapticFeedback.selectionClick();
    final color = topic['color'] as Color;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(topic['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          topic['category'] as String,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topic['title'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF121214)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              topic['summary'] as String,
              style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF555558)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19191B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewTab(BuildContext context, bool isDark) {
    final cardColors = [
      AppTheme.cardPurple,
      AppTheme.cardYellow,
      AppTheme.cardCoral,
      AppTheme.cardGreen,
      AppTheme.cardDark,
    ];

    return Column(
      key: const ValueKey('tab_interview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section with 5 Count Badge & Acak Soal Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    '5 Pertanyaan Wawancara',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF121214),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              FluidBounceButton(
                onTap: _randomizeQaItems,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF19191B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shuffle_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Acak Soal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── OVERLAPPING STACKED DECK CARDS (EDGE-TO-EDGE NO HORIZONTAL MARGIN) ──
        ...List.generate(_activeQaItems.length, (idx) {
          final qa = _activeQaItems[idx];
          final isExpanded = _expandedQaIndex == idx;
          final cardColor = cardColors[idx % cardColors.length];
          final isDarkText = cardColor == AppTheme.cardYellow || cardColor == AppTheme.cardGreen;
          final titleColor = isDarkText ? const Color(0xFF121214) : Colors.white;
          final descColor = isDarkText ? const Color(0xFF333336) : Colors.white.withValues(alpha: 0.90);
          final topMargin = idx == 0 ? 0.0 : -22.0;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _expandedQaIndex = isExpanded ? -1 : idx;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.fastOutSlowIn,
              width: double.infinity,
              margin: EdgeInsets.only(top: topMargin),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(28),
                  bottom: idx == _activeQaItems.length - 1 || isExpanded
                      ? const Radius.circular(28)
                      : const Radius.circular(0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Tag Pill & Expand Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDarkText
                                  ? const Color(0xFF19191B).withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'SOAL 0${idx + 1}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDarkText
                                  ? const Color(0xFF19191B)
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                              size: 14,
                              color: isDarkText ? Colors.white : cardColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Focus Subtitle
                      Text(
                        qa['sub']!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: descColor,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Question Title
                      Text(
                        qa['q']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),

                      // Expanded Answer & Strategy Box
                      if (isExpanded) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkText
                                ? Colors.white.withValues(alpha: 0.95)
                                : Colors.black.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '💡 Rekomendasi Jawaban & STAR Tips:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: isDarkText ? const Color(0xFF121214) : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                qa['a']!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkText ? const Color(0xFF222224) : Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        // ── TOPIC OVERVIEW SECTION ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
              border: Border.all(color: const Color(0xFFE5E0D5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 18, color: Color(0xFF5C44E4)),
                  SizedBox(width: 8),
                  Text(
                    'Bank Topik & Strategi Wawancara',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF121214),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ketuk topik di bawah ini untuk melihat strategi jawaban:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interviewTopics.map((t) {
                  final color = t['color'] as Color;
                  return GestureDetector(
                    onTap: () => _showTopicDetailModal(context, t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E0D5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t['icon'] as IconData, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            t['title'] as String,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF121214),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildTemplatesTab(BuildContext context, bool isDark) {
    final state = ref.watch(jobProvider);
    final isPro = state.isProUser;

    return Column(
      key: const ValueKey('tab_templates'),
      children: _templates.map((tpl) {
        final color = tpl['color'] as Color;
        final isItemPro = tpl['isPro'] == true;
        final isLocked = isItemPro && !isPro;

        final isDarkText = color == AppTheme.cardYellow || color == AppTheme.cardGreen;
        final titleColor = isDarkText ? const Color(0xFF111113) : Colors.white;
        final subColor = isDarkText ? const Color(0xCC111113) : const Color(0xCCFFFFFF);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            tpl['title'] as String,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (isItemPro) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDarkText ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isLocked ? Icons.lock_rounded : Icons.workspace_premium_rounded, size: 11, color: titleColor),
                                const SizedBox(width: 3),
                                Text(
                                  isLocked ? 'PRO' : 'UNLOCKED',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: titleColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (isLocked) {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (_) => const SubscriptionScreen()),
                        );
                        AppleToast.info(context, 'Buka Ngelamar PRO untuk menyalin templat ini!');
                      } else {
                        Clipboard.setData(ClipboardData(text: tpl['text'] as String));
                        AppleToast.success(context, 'Templat disalin ke clipboard');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_outline_rounded : CupertinoIcons.doc_on_doc,
                        color: titleColor,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tpl['text'] as String,
                style: TextStyle(fontSize: 12.5, color: subColor, height: 1.45),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (isLocked) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (_) => const SubscriptionScreen()),
                          );
                          AppleToast.info(context, 'Buka Ngelamar PRO untuk membuka templat ini!');
                        } else {
                          final firstJob = state.jobs.isNotEmpty ? state.jobs.first : null;
                          final filled = _populateTemplate(
                            tpl['text'] as String,
                            state.userName,
                            firstJob?.companyName,
                            firstJob?.position,
                          );
                          Clipboard.setData(ClipboardData(text: filled));
                          AppleToast.success(
                            context,
                            'Templat Terisi Otomatis!',
                            subtitle: 'Disalin dengan nama ${state.userName.isNotEmpty ? state.userName : "Anda"}',
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDarkText ? Colors.black.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkText ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_fix_high_rounded, size: 13, color: titleColor),
                            const SizedBox(width: 4),
                            Text(
                              'Isi Data Saya',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: titleColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (isLocked) {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (_) => const SubscriptionScreen()),
                        );
                        AppleToast.info(context, 'Buka Ngelamar PRO untuk membagikan templat ini!');
                      } else {
                        final firstJob = state.jobs.isNotEmpty ? state.jobs.first : null;
                        final filled = _populateTemplate(
                          tpl['text'] as String,
                          state.userName,
                          firstJob?.companyName,
                          firstJob?.position,
                        );
                        Share.share(filled, subject: tpl['title'] as String);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkText ? Colors.black.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkText ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(Icons.share_outlined, size: 15, color: titleColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
