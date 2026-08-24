import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/job_provider.dart';
import '../../services/pro_verification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pro_envelope_mascot.dart';

/// Screen: Langganan Ngelamar PRO via WhatsApp Resmi (083136049987).
/// Dilengkapi maskot menyatu tanpa border, tabel perbandingan Free vs PRO,
/// serta navigasi instan ke WhatsApp Admin.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  static const bool _proActivationAvailable = true;
  String _selectedPlan = 'monthly'; // 'monthly' | 'yearly'
  static const String _adminWhatsAppNumber = '6283136049987';
  final TextEditingController _codeController = TextEditingController();
  bool _isActivating = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestAdminCodeViaWhatsApp() async {
    HapticFeedback.selectionClick();
    final planName = _selectedPlan == 'monthly'
        ? 'Paket Bulanan (Rp 10.000 / bln)'
        : 'Paket Tahunan (Rp 99.000 / thn)';
    final message =
        'Halo Admin Ngelamar, saya telah melakukan pembayaran untuk *Ngelamar PRO* ($planName). Mohon kirimkan kode aktivasi saya untuk diverifikasi sistem. Terima kasih!';
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$_adminWhatsAppNumber?text=$encoded';
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        await Clipboard.setData(const ClipboardData(text: '083136049987'));
        if (mounted) {
          AppToast.info(
            context,
            'Nomor Admin (0831-3604-9987) disalin ke clipboard',
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: '083136049987'));
      if (mounted) {
        AppToast.info(
          context,
          'Nomor Admin (0831-3604-9987) disalin ke clipboard',
        );
      }
    }
  }

  Future<void> _activateWithCode() async {
    final input = _codeController.text.trim();
    if (input.isEmpty) {
      HapticFeedback.lightImpact();
      AppToast.warning(context, 'Masukkan 10 digit kode aktivasi dari Admin');
      return;
    }

    setState(() => _isActivating = true);
    final result = await ProVerificationService.verify(
      code: input,
      plan: _selectedPlan,
    );

    if (!mounted) return;
    if (result.isValid && result.expiresAt != null) {
      HapticFeedback.heavyImpact();
      await ref
          .read(jobProvider.notifier)
          .activateProSubscription(
            plan: _selectedPlan,
            verifiedExpiry: result.expiresAt!,
          );
      setState(() => _isActivating = false);
      _codeController.clear();
      if (mounted) {
        AppDialog.show(
          context: context,
          icon: Icons.stars_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Selamat! PRO Aktif',
          content:
              'Langganan Anda telah diverifikasi. Seluruh fitur Ngelamar PRO yang tersedia kini terbuka penuh.',
          primaryLabel: 'Mulai Gunakan',
          onPrimary: () => Navigator.pop(context),
        );
      }
    } else {
      HapticFeedback.vibrate();
      setState(() => _isActivating = false);
      if (mounted) {
        AppDialog.show(
          context: context,
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFE53935),
          title: 'Aktivasi Belum Berhasil',
          content: result.message,
          secondaryLabel: 'Coba Lagi',
          primaryLabel: 'Chat Admin WA',
          onPrimary: () {
            Navigator.pop(context);
            _requestAdminCodeViaWhatsApp();
          },
        );
      }
    }
  }

  final List<Map<String, dynamic>> _comparisonRows = [
    {
      'feature': 'Pencatatan Lamaran',
      'free': 'Pencatatan dasar',
      'pro': 'Unlimited (Tanpa Batas)',
      'isProOnly': false,
    },
    {
      'feature': 'Alarm Pengingat Seleksi',
      'free': 'Otomatis saat jadwal dibuat',
      'pro': 'Otomatis saat jadwal dibuat',
      'isProOnly': false,
    },
    {
      'feature': 'Simulasi Interview STAR',
      'free': '3 Topik Dasar',
      'pro': '15+ Topik Lengkap & Acak',
      'isProOnly': false,
    },
    {
      'feature': 'Template Chat & Email HR',
      'free': '2 Template Standar',
      'pro': 'Semua Template Lengkap',
      'isProOnly': false,
    },
    {
      'feature': 'Standar Gaji & Analisis UMR',
      'free': 'Terbatas',
      'pro': 'Akses Seluruh Kota di Indonesia',
      'isProOnly': false,
    },
    {
      'feature': 'Backup Data JSON',
      'free': 'Bagikan backup data',
      'pro': 'Bagikan backup data',
      'isProOnly': false,
    },
    {
      'feature': 'Mode Gelap (Dark Mode)',
      'free': 'Khusus Member PRO',
      'pro': 'Tersedia Lengkap',
      'isProOnly': true,
    },
    {
      'feature': 'Badge Profil & Status Eksklusif',
      'free': 'Standar',
      'pro': 'Badge Mahkota Emas King',
      'isProOnly': true,
    },
    {
      'feature': 'Dukungan Prioritas WhatsApp',
      'free': 'Email Biasa',
      'pro': 'Konsultasi WhatsApp Prioritas',
      'isProOnly': true,
    },
  ];

  Future<void> _subscribeViaWhatsApp() async {
    HapticFeedback.heavyImpact();
    final planName = _selectedPlan == 'monthly'
        ? 'Paket Bulanan (Rp 10.000 / bln)'
        : 'Paket Tahunan (Rp 99.000 / thn)';

    final message =
        'Halo Admin Ngelamar, saya ingin berlangganan *Ngelamar PRO* dengan pilihan *$planName*. Mohon panduan pembayarannya. Terima kasih!';
    final encodedMessage = Uri.encodeComponent(message);
    final waUrl = 'https://wa.me/$_adminWhatsAppNumber?text=$encodedMessage';

    try {
      final uri = Uri.parse(waUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        await Clipboard.setData(const ClipboardData(text: '083136049987'));
        if (mounted) {
          AppToast.info(
            context,
            'Nomor Admin (+62 831-3604-9987) disalin ke clipboard',
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(const ClipboardData(text: '083136049987'));
      if (mounted) {
        AppToast.info(
          context,
          'Nomor Admin (+62 831-3604-9987) disalin ke clipboard',
        );
      }
    }
  }

  void _confirmCancelSubscription() {
    HapticFeedback.selectionClick();
    AppDialog.show(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFE53935),
      title: 'Nonaktifkan akses PRO?',
      content:
          'Aplikasi ini akan kembali ke versi Free. Tindakan ini tidak membatalkan atau mengembalikan pembayaran yang sudah dilakukan melalui WhatsApp.',
      secondaryLabel: 'Pertahankan PRO',
      primaryLabel: 'Nonaktifkan',
      isDestructive: true,
      onPrimary: () async {
        Navigator.pop(context);
        try {
          await ref.read(jobProvider.notifier).cancelProSubscription();
          if (mounted) {
            AppToast.warning(context, 'Langganan PRO telah dinonaktifkan');
          }
        } catch (_) {
          if (mounted) {
            AppToast.error(
              context,
              'Pembatalan belum tersimpan. Periksa koneksi internet.',
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isPro = state.isProUser;
    final isDark = AppTheme.isDark(context);
    final txtPri = AppTheme.getTextPrimary(context);
    final txtSec = AppTheme.getTextSecondary(context);
    final bg = AppTheme.getBackground(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final expiryStr = state.proExpiryDate != null
        ? DateFormat(
            'dd MMMM yyyy, HH:mm',
            'id_ID',
          ).format(state.proExpiryDate!)
        : 'Aktif';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── TOP NAV BAR ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FluidBounceButton(
                    onTap: () => Navigator.pop(context),
                    semanticLabel: 'Kembali',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF242428) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF38383E)
                              : const Color(0xFFE5E0D5),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: txtPri,
                        size: 20,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF19191B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 14,
                          color: Color(0xFFFFD54F),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'NGELAMAR PRO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balanced spacer
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 6, 20, 110 + bottomInset),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ── MASCOT SEAMLESS ON BACKGROUND CANVAS (NO BOX / NO BORDER) ──
                    const Center(
                      child: ProKingEnvelopeMascot(width: 175, height: 130),
                    ),

                    const SizedBox(height: 12),

                    // Heading Title
                    Text(
                      'Akselerasi Karir Impianmu\nDengan Ngelamar PRO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: txtPri,
                        letterSpacing: -0.7,
                        height: 1.18,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Dapatkan pencatatan tanpa batas, alarm pengingat otomatis di HP, dan bank soal interview lengkap.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: txtSec,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── ACTIVE PRO STATUS BANNER (IF SUBSCRIBED) ──
                    if (isPro) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF19191B),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Status Langganan Aktif',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Aktif hingga: $expiryStr',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: _confirmCancelSubscription,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade200,
                                side: BorderSide(
                                  color: Colors.red.shade400.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Nonaktifkan PRO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      // ── PLAN SELECTOR CARDS ──
                      Row(
                        children: [
                          Expanded(
                            child: _buildPlanSelectorCard(
                              id: 'monthly',
                              title: 'Paket Bulanan',
                              price: 'Rp 10.000',
                              period: ' / bulan',
                              badge: 'PALING POPULER',
                              isSelected: _selectedPlan == 'monthly',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPlanSelectorCard(
                              id: 'yearly',
                              title: 'Paket Tahunan',
                              price: 'Rp 99.000',
                              period: ' / tahun',
                              badge: 'HEMAT 17%',
                              isSelected: _selectedPlan == 'yearly',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                    ],

                    // ── TABEL PERBANDINGAN PRO VS FREE ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF383842)
                              : const Color(0xFFE5E0D5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.compare_arrows_rounded,
                                size: 18,
                                color: txtPri,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Perbandingan Free vs PRO',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: txtPri,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF29292F)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'Fitur',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: txtSec,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Free',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: txtSec,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'PRO',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: txtPri,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Table Rows
                          ..._comparisonRows.map((row) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      row['feature'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: txtPri,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      row['free'] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: txtSec,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF132E1D)
                                            : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        row['pro'] as String,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? const Color(0xFF4ADE80)
                                              : const Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── KARTU AKTIVASI 10 DIGIT KODE AKSES PRO ──
                    if (!isPro && _proActivationAvailable) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E24)
                              : const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF19191B),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5C44E4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.key_rounded,
                                    color: Colors.white,
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
                                        'Aktivasi Kode Akses PRO',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: txtPri,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Text(
                                        'Masukkan 10 digit kode yang diberikan Admin',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: txtSec,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Panduan 3 Langkah
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF29292F)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF3B3B42)
                                      : const Color(0xFFE5E0D5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildActivationStep(
                                    step: '1',
                                    title: 'Lakukan Pembayaran',
                                    desc:
                                        'Pilih paket lalu transfer via WhatsApp Admin resmi.',
                                  ),
                                  const Divider(height: 14, thickness: 0.8),
                                  _buildActivationStep(
                                    step: '2',
                                    title: 'Minta Kode Aktivasi',
                                    desc:
                                        'Kirim bukti bayar ke Admin untuk menerima 10 digit kode.',
                                  ),
                                  const Divider(height: 14, thickness: 0.8),
                                  _buildActivationStep(
                                    step: '3',
                                    title: 'Input & Akses Fitur',
                                    desc:
                                        'Ketik 10 digit kode di bawah lalu tekan tombol Aktifkan.',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Input Box Kode 10 Digit
                            TextField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.0,
                                color: txtPri,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ketik 10 digit kode aktivasi...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF29292F)
                                    : Colors.white,
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF19191B),
                                    width: 1.4,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF19191B),
                                    width: 1.4,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF5C44E4),
                                    width: 2.2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Tombol Submit Kode
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isActivating
                                    ? null
                                    : _activateWithCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5C44E4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isActivating
                                    ? const CupertinoActivityIndicator(
                                        color: Colors.white,
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Aktifkan PRO sekarang',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Tombol Minta Kode ke Admin
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _requestAdminCodeViaWhatsApp,
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF25D366),
                                ),
                                label: Text(
                                  'Minta / Konfirmasi Kode ke Admin (WhatsApp)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: txtPri,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // WhatsApp Contact Direct Notice
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF25D366).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_rounded,
                            color: Color(0xFF25D366),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aktivasi Dilindungi Supabase',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: txtPri,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kode diverifikasi oleh database dan hanya dapat digunakan sesuai paket serta masa aktifnya.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: txtSec,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BOTTOM FLOATING CTA (WHATSAPP REDIRECTION) ──
            if (!isPro && _proActivationAvailable)
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  bottomInset > 0 ? bottomInset + 12 : 20,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _subscribeViaWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedPlan == 'monthly'
                              ? 'Beli via WhatsApp — Rp 10.000 / bln'
                              : 'Beli via WhatsApp — Rp 99.000 / thn',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSelectorCard({
    required String id,
    required String title,
    required String price,
    required String period,
    required String badge,
    required bool isSelected,
  }) {
    final isDark = AppTheme.isDark(context);
    final muted = isDark ? const Color(0xFFB1B1B8) : const Color(0xFF555558);
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $price$period',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPlan = id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF19191B)
                : (isDark ? const Color(0xFF242429) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF19191B)
                  : (isDark
                        ? const Color(0xFF3B3B42)
                        : const Color(0xFFE5E0D5)),
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? const Color(0xFF121214)
                        : const Color(0xFF5C44E4),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.grey.shade300 : muted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF121214)),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    period,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
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

  Widget _buildActivationStep({
    required String step,
    required String title,
    required String desc,
  }) {
    final isDark = AppTheme.isDark(context);
    final primary = isDark ? Colors.white : const Color(0xFF121214);
    final secondary = isDark
        ? const Color(0xFFB1B1B8)
        : const Color(0xFF555558);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF19191B),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: TextStyle(fontSize: 11, color: secondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
