import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class ProVerificationResult {
  final bool isValid;
  final DateTime? expiresAt;
  final String? plan;
  final String message;

  const ProVerificationResult({
    required this.isValid,
    this.expiresAt,
    this.plan,
    required this.message,
  });
}

class ProEntitlement {
  final bool isActive;
  final DateTime? expiresAt;
  final String plan;

  const ProEntitlement({
    required this.isActive,
    this.expiresAt,
    this.plan = 'monthly',
  });

  static const locked = ProEntitlement(isActive: false);
}

/// Server-authoritative PRO access backed by Supabase Auth, RLS, and RPC.
/// No activation code or entitlement is accepted from local preferences.
class ProVerificationService {
  static Future<ProEntitlement> fetchCurrentEntitlement() async {
    if (!SupabaseService.isInitialized) return ProEntitlement.locked;

    try {
      final user = await SupabaseService.ensureAuthenticated();
      final row = await SupabaseService.client
          .from('pro_entitlements')
          .select('plan, active, expires_at')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null || row['active'] != true) return ProEntitlement.locked;

      final expiresAt = DateTime.tryParse('${row['expires_at']}')?.toLocal();
      if (expiresAt == null || !expiresAt.isAfter(DateTime.now())) {
        return ProEntitlement.locked;
      }
      return ProEntitlement(
        isActive: true,
        expiresAt: expiresAt,
        plan: '${row['plan'] ?? 'monthly'}',
      );
    } on AuthException {
      return ProEntitlement.locked;
    } on PostgrestException {
      return ProEntitlement.locked;
    } catch (_) {
      return ProEntitlement.locked;
    }
  }

  static Future<ProVerificationResult> verify({
    required String code,
    required String plan,
  }) async {
    try {
      await SupabaseService.ensureAuthenticated();
      final response = await SupabaseService.client.rpc(
        'activate_pro',
        params: {'p_code': code.trim(), 'p_requested_plan': plan},
      );
      final row = _firstRow(response);
      if (row == null) {
        return const ProVerificationResult(
          isValid: false,
          message: 'Server tidak mengembalikan hasil aktivasi.',
        );
      }

      final isValid = row['is_valid'] == true;
      final expiresAt = DateTime.tryParse(
        '${row['expires_at'] ?? ''}',
      )?.toLocal();
      return ProVerificationResult(
        isValid: isValid && expiresAt != null,
        expiresAt: expiresAt,
        plan: row['plan']?.toString(),
        message:
            row['message']?.toString() ??
            (isValid ? 'PRO berhasil diaktifkan.' : 'Kode tidak valid.'),
      );
    } on AuthException catch (error) {
      return ProVerificationResult(
        isValid: false,
        message: 'Autentikasi Supabase belum siap: ${error.message}',
      );
    } on PostgrestException catch (error) {
      return ProVerificationResult(
        isValid: false,
        message:
            'Database PRO belum siap. Jalankan migration Supabase terlebih dahulu (${error.code ?? 'database error'}).',
      );
    } catch (_) {
      return const ProVerificationResult(
        isValid: false,
        message: 'Aktivasi belum dapat diverifikasi. Periksa koneksi internet.',
      );
    }
  }

  static Future<void> deactivateCurrentEntitlement() async {
    await SupabaseService.ensureAuthenticated();
    await SupabaseService.client.rpc('deactivate_my_pro');
  }

  static Map<String, dynamic>? _firstRow(dynamic response) {
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    return null;
  }
}
