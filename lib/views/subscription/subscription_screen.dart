import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/job_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/apple_animations.dart';
import '../../widgets/apple_toast.dart';
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
  String _selectedPlan = 'monthly'; // 'monthly' | 'yearly'
  static const String _adminWhatsAppNumber = '6283136049987';

  final List<Map<String, dynamic>> _comparisonRows = [
    {
      'feature': 'Pencatatan Lamaran',
      'free': 'Maks. 10 Lamaran',
      'pro': 'Unlimited (Tanpa Batas)',
      'isProOnly': false,
    },
    {
      'feature': 'Alarm Pengingat Seleksi',
      'free': 'Manual',
      'pro': 'Otomatis Real-Time di HP',
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
      'feature': 'Impor & Ekspor Data Excel (.xlsx)',
      'free': 'Tidak Tersedia',
      'pro': 'Penuh Tanpa Batas 📊',
      'isProOnly': true,
    },
    {
      'feature': 'Mode Gelap Eksklusif (Dark Mode OLED)',
      'free': 'Standar',
      'pro': 'Tersedia Premium 🌙',
      'isProOnly': true,
    },
    {
      'feature': 'Badge Profil & Status Eksklusif',
      'free': 'Standar',
      'pro': 'Badge Mahkota Emas King 👑',
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

    final message = 'Halo Admin Ngelamar, saya ingin berlangganan *Ngelamar PRO* dengan pilihan *$planName*. Mohon panduan pembayarannya. Terima kasih!';
    final encodedMessage = Uri.encodeComponent(message);
    final waUrl = 'https://wa.me/$_adminWhatsAppNumber?text=$encodedMessage';

    try {
      final uri = Uri.parse(waUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        AppleToast.warning(context, 'Tidak dapat membuka WhatsApp. Silakan simpan nomor 083136049987');
      }
    } catch (e) {
      if (mounted) {
        AppleToast.error(context, 'Gagal membuka WhatsApp: $e');
      }
    }
  }

  void _confirmCancelSubscription() {
    HapticFeedback.selectionClick();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Batalkan Langganan PRO?'),
        content: const Text('Akses fitur eksklusif PRO Anda akan dinonaktifkan kembali ke versi Free.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tetap Berlangganan'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(jobProvider.notifier).cancelProSubscription();
              if (mounted) {
                AppleToast.warning(context, 'Langganan PRO telah dinonaktifkan');
              }
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobProvider);
    final isPro = state.isProUser;
    final txtPri = AppTheme.getTextPrimary(context);
    final bg = AppTheme.getBackground(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final expiryStr = state.proExpiryDate != null
        ? DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(state.proExpiryDate!)
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
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E0D5)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF121214), size: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF19191B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFFFFD54F)),
                        SizedBox(width: 5),
                        Text(
                          'NGELAMAR PRO',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 38), // Balanced spacer
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
                      child: ProKingEnvelopeMascot(
                        width: 175,
                        height: 130,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Heading Title
                    Text(
                      'Akselerasi Karir Impianmu\nDengan Ngelamar PRO ✨',
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
                          color: Colors.grey.shade700,
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
                                Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Status Langganan Aktif',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Aktif hingga: $expiryStr',
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 12.5),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: _confirmCancelSubscription,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade200,
                                side: BorderSide(color: Colors.red.shade400.withValues(alpha: 0.6)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Batalkan Langganan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E0D5), width: 1.2),
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
                          const Row(
                            children: [
                              Icon(Icons.compare_arrows_rounded, size: 18, color: Color(0xFF121214)),
                              SizedBox(width: 8),
                              Text(
                                'Perbandingan Free vs PRO',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF121214),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text('Fitur', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text('Free', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text('PRO 👑', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Table Rows
                          ..._comparisonRows.map((row) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      row['feature'] as String,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      row['free'] as String,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        row['pro'] as String,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
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

                    // WhatsApp Contact Direct Notice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aktivasi Langsung via WhatsApp',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF121214)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Nomor Resmi: 0831-3604-9987. Pembayaran via QRIS, Transfer Bank, atau E-Wallet.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF555558), height: 1.3),
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
            if (!isPro)
              Container(
                padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset > 0 ? bottomInset + 12 : 20),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedPlan == 'monthly'
                              ? 'Beli via WhatsApp — Rp 10.000 / bln'
                              : 'Beli via WhatsApp — Rp 99.000 / thn',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, letterSpacing: -0.2),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPlan = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF19191B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF19191B) : const Color(0xFFE5E0D5),
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
                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFF121214) : const Color(0xFF5C44E4),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.grey.shade300 : const Color(0xFF555558),
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
                    color: isSelected ? Colors.white : const Color(0xFF121214),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
