import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class FeedbackSubmissionException implements Exception {
  const FeedbackSubmissionException(this.message);

  final String message;
}

class FeedbackService {
  static Future<void> submit({
    required String category,
    required String message,
    required String appVersion,
  }) async {
    const allowedCategories = {'feedback', 'bug', 'feature_request', 'support'};
    final cleanMessage = message.trim();
    if (!allowedCategories.contains(category) ||
        cleanMessage.length < 5 ||
        cleanMessage.length > 3000) {
      throw const FeedbackSubmissionException(
        'Tulis masukan minimal 5 karakter sebelum mengirim.',
      );
    }
    try {
      final user = await SupabaseService.ensureAuthenticated();
      await SupabaseService.client.from('user_feedback').insert({
        'user_id': user.id,
        'category': category,
        'message': cleanMessage,
        'app_version': appVersion,
        'device_context': {
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        },
      });
    } on SocketException {
      throw const FeedbackSubmissionException(
        'Tidak ada koneksi internet. Masukan belum terkirim.',
      );
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        throw const FeedbackSubmissionException(
          'Server belum mengizinkan pengiriman masukan. Coba lagi sebentar.',
        );
      }
      if (error.code == '42P01') {
        throw const FeedbackSubmissionException(
          'Fitur masukan di server belum selesai disiapkan.',
        );
      }
      throw const FeedbackSubmissionException(
        'Masukan belum dapat dikirim. Silakan coba lagi.',
      );
    }
  }
}
