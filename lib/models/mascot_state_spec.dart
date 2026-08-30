import 'package:flutter/material.dart';

enum MascotPose {
  saved,
  applied,
  testing,
  interviewHr,
  interviewUser,
  offering,
  accepted,
  rejected,
}

@immutable
class MascotStateSpec {
  final MascotPose pose;
  final String label;
  final IconData prop;
  final bool hasTears;
  final bool hasConfetti;
  final Color accent;

  const MascotStateSpec({
    required this.pose,
    required this.label,
    required this.prop,
    required this.accent,
    this.hasTears = false,
    this.hasConfetti = false,
  });

  factory MascotStateSpec.forStatus(String status) => switch (status) {
    'Tersimpan' || 'Draft' => const MascotStateSpec(
      pose: MascotPose.saved,
      label: 'Rencana tersimpan',
      prop: Icons.bookmark_rounded,
      accent: Color(0xFF64748B),
    ),
    'Tes / Psikotes' => const MascotStateSpec(
      pose: MascotPose.testing,
      label: 'Saatnya fokus',
      prop: Icons.psychology_rounded,
      accent: Color(0xFFF59E0B),
    ),
    'Interview HR' => const MascotStateSpec(
      pose: MascotPose.interviewHr,
      label: 'Kenalan dengan HR',
      prop: Icons.record_voice_over_rounded,
      accent: Color(0xFF635BFF),
    ),
    'Interview User' => const MascotStateSpec(
      pose: MascotPose.interviewUser,
      label: 'Tunjukkan kemampuanmu',
      prop: Icons.groups_rounded,
      accent: Color(0xFF8B5CF6),
    ),
    'Offering' => const MascotStateSpec(
      pose: MascotPose.offering,
      label: 'Penawaran datang',
      prop: Icons.card_giftcard_rounded,
      accent: Color(0xFFEC4899),
      hasConfetti: true,
    ),
    'Diterima' => const MascotStateSpec(
      pose: MascotPose.accepted,
      label: 'Kamu berhasil!',
      prop: Icons.celebration_rounded,
      accent: Color(0xFF10B981),
      hasConfetti: true,
    ),
    'Ditolak' => const MascotStateSpec(
      pose: MascotPose.rejected,
      label: 'Pelan-pelan, coba lagi',
      prop: Icons.water_drop_rounded,
      accent: Color(0xFFDE4B3E),
      hasTears: true,
    ),
    _ => const MascotStateSpec(
      pose: MascotPose.applied,
      label: 'Lamaran terkirim',
      prop: Icons.send_rounded,
      accent: Color(0xFF475569),
    ),
  };
}
