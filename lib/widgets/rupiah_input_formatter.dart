import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric input into Indonesian Rupiah currency format with dot thousand separators.
/// Example: "15000000" -> "Rp 15.000.000"
class RupiahInputFormatter extends TextInputFormatter {
  final bool includeSymbol;

  RupiahInputFormatter({this.includeSymbol = true});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Keep only digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###', 'id_ID');
    final formattedNumber = formatter.format(number).replaceAll(',', '.');
    final newText = includeSymbol ? 'Rp $formattedNumber' : formattedNumber;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  /// Helper to format raw integer / double / string to Indonesian Rupiah
  static String format(num? value, {bool includeSymbol = true}) {
    if (value == null) return '';
    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(value).replaceAll(',', '.');
    return includeSymbol ? 'Rp $formatted' : formatted;
  }
}
