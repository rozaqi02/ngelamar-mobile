class UmrData {
  final String city;
  final double umrAmount;

  const UmrData(this.city, this.umrAmount);
}

class SalaryEvaluationResult {
  final double grossSalary;
  final double estimatedBpjsDeduction;
  final double estimatedNetTakeHomePay;
  final double umrAmount;
  final String city;
  final double umrRatio; // Gross / UMR
  final double estimatedOperationalCost;
  final double estimatedNetSavings;

  SalaryEvaluationResult({
    required this.grossSalary,
    required this.estimatedBpjsDeduction,
    required this.estimatedNetTakeHomePay,
    required this.umrAmount,
    required this.city,
    required this.umrRatio,
    required this.estimatedOperationalCost,
    required this.estimatedNetSavings,
  });
}

class SalaryEvaluatorService {
  static const List<UmrData> umrList = [
    UmrData('Jakarta', 5067381),
    UmrData('Surabaya', 4725479),
    UmrData('Tangerang / BSD', 4760000),
    UmrData('Bekasi', 5343430),
    UmrData('Depok', 4878612),
    UmrData('Bogor', 4813988),
    UmrData('Bandung', 4209309),
    UmrData('Semarang', 3243969),
    UmrData('Medan', 3769082),
    UmrData('Yogyakarta / Jogja', 2492997),
    UmrData('Bali (Badung)', 3318628),
    UmrData('Malang', 3309144),
  ];

  /// Formats currency with Indonesian Rupiah dot separators.
  /// Examples:
  ///   5067381 -> "Rp 5.067.381"
  ///   -1500000 -> "-Rp 1.500.000"
  static String formatRupiah(double amount) {
    if (amount.isNaN || amount.isInfinite) return 'Rp 0';
    final isNegative = amount < 0;
    final absAmount = amount.abs().round();

    final numStr = absAmount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < numStr.length; i++) {
      if (i > 0 && (numStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(numStr[i]);
    }

    final formatted = buffer.toString();
    return isNegative ? '-Rp $formatted' : 'Rp $formatted';
  }

  static double parseSalaryAmount(String? input) {
    if (input == null || input.trim().isEmpty) return 0.0;
    String clean = input.toLowerCase().replaceAll('rp', '').replaceAll('idr', '').trim();

    if (clean.contains('-')) {
      clean = clean.split('-').first.trim();
    }

    if (clean.contains('jt') || clean.contains('juta')) {
      final numStr = clean.replaceAll('jt', '').replaceAll('juta', '').replaceAll(',', '.').trim();
      final parsed = double.tryParse(numStr);
      if (parsed != null) return parsed * 1000000;
    }

    clean = clean.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  static SalaryEvaluationResult evaluateSalary({
    required double grossSalary,
    required String city,
    required String workType,
    bool needsKos = true,
  }) {
    final bpjs = grossSalary * 0.04;
    final netTakeHome = grossSalary - bpjs;

    final umrItem = umrList.firstWhere(
      (element) => element.city.toLowerCase() == city.toLowerCase(),
      orElse: () => const UmrData('Nasional (Rata-rata)', 3500000),
    );

    final umrRatio = umrItem.umrAmount > 0 ? (grossSalary / umrItem.umrAmount) : 1.0;

    double operationalCost = 0.0;
    if (workType == 'WFH') {
      operationalCost = needsKos ? 2000000 : 1200000;
    } else if (workType == 'Hybrid') {
      operationalCost = needsKos ? 2800000 : 1800000;
    } else {
      operationalCost = needsKos ? 3500000 : 2200000;
    }

    final savings = netTakeHome - operationalCost;

    return SalaryEvaluationResult(
      grossSalary: grossSalary,
      estimatedBpjsDeduction: bpjs,
      estimatedNetTakeHomePay: netTakeHome,
      umrAmount: umrItem.umrAmount,
      city: umrItem.city,
      umrRatio: umrRatio,
      estimatedOperationalCost: operationalCost,
      estimatedNetSavings: savings,
    );
  }
}
