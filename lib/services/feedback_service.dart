import 'dart:io';

import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

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
      throw ArgumentError('Masukan belum valid.');
    }
    final user = await SupabaseService.ensureAuthenticated();
    await SupabaseService.client.from('user_feedback').insert({
      'user_id': user.id,
      'category': category,
      'message': cleanMessage,
      'app_version': appVersion,
      'device_context': {'platform': kIsWeb ? 'web' : Platform.operatingSystem},
    });
  }
}
