class UmrData {
  final String city;
  final double umrAmount;

  const UmrData(this.city, this.umrAmount);
}

class SalaryRangeEvaluationResult {
  final double minGross;
  final double maxGross;
  final bool isRange;
  final double minNetTakeHome;
  final double maxNetTakeHome;
  final double umrAmount;
  final String city;
  final double minUmrRatio;
  final double maxUmrRatio;
  final double estimatedOperationalCost;
  final double minSavings;
  final double maxSavings;

  SalaryRangeEvaluationResult({
    required this.minGross,
    required this.maxGross,
    required this.isRange,
    required this.minNetTakeHome,
    required this.maxNetTakeHome,
    required this.umrAmount,
    required this.city,
    required this.minUmrRatio,
    required this.maxUmrRatio,
    required this.estimatedOperationalCost,
    required this.minSavings,
    required this.maxSavings,
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

  /// Format range Rupiah (misal "Rp 8.000.000 - Rp 12.000.000" atau "Rp 8.000.000")
  static String formatRupiahRange(double min, double max, {bool isRange = true}) {
    if (!isRange || (min - max).abs() < 1) {
      return formatRupiah(min);
    }
    return '${formatRupiah(min)} - ${formatRupiah(max)}';
  }

  static ({double min, double max, bool isRange}) parseSalaryRange(String? input) {
    if (input == null || input.trim().isEmpty) {
      return (min: 0.0, max: 0.0, isRange: false);
    }

    final clean = input
        .toLowerCase()
        .replaceAll('rp', '')
        .replaceAll('idr', '')
        .trim();

    if (clean.contains('-')) {
      final parts = clean.split('-');
      final val1 = _parseSingleSalary(parts[0]);
      final val2 = _parseSingleSalary(parts[1]);
      if (val1 > 0 && val2 > 0) {
        final minVal = val1 < val2 ? val1 : val2;
        final maxVal = val1 > val2 ? val1 : val2;
        return (min: minVal, max: maxVal, isRange: minVal != maxVal);
      } else if (val2 > 0) {
        return (min: val2, max: val2, isRange: false);
      } else {
        return (min: val1, max: val1, isRange: false);
      }
    }

    final val = _parseSingleSalary(clean);
    return (min: val, max: val, isRange: false);
  }

  static double parseSalaryAmount(String? input) {
    final range = parseSalaryRange(input);
    if (range.isRange) {
      return (range.min + range.max) / 2.0;
    }
    return range.min;
  }

  static double _parseSingleSalary(String text) {
    String clean = text.trim();
    if (clean.isEmpty) return 0.0;

    final directParsed = double.tryParse(clean);
    if (directParsed != null) {
      return directParsed;
    }

    if (clean.contains('jt') || clean.contains('juta')) {
      final numStr = clean
          .replaceAll('jt', '')
          .replaceAll('juta', '')
          .replaceAll(',', '.')
          .trim();
      final parsed = double.tryParse(numStr);
      if (parsed != null) return parsed * 1000000;
    }

    clean = clean.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  static SalaryRangeEvaluationResult evaluateSalaryRange({
    required String? rawSalaryInput,
    required String city,
    required String workType,
    bool needsKos = true,
    double? customKosCost,
    double? customUmr,
  }) {
    final range = parseSalaryRange(rawSalaryInput);
    final minGross = range.min;
    final maxGross = range.max;
    final isRange = range.isRange;

    final minNetTHP = minGross * 0.96;
    final maxNetTHP = maxGross * 0.96;

    final umrItem = umrList.firstWhere(
      (element) => element.city.toLowerCase() == city.toLowerCase(),
      orElse: () => const UmrData('Nasional (Rata-rata)', 3500000),
    );

    final effectiveUmr = customUmr != null && customUmr > 0 ? customUmr : umrItem.umrAmount;

    final minUmrRatio = effectiveUmr > 0 ? (minGross / effectiveUmr) : 1.0;
    final maxUmrRatio = effectiveUmr > 0 ? (maxGross / effectiveUmr) : 1.0;

    double operationalCost = 0.0;
    if (customKosCost != null && customKosCost > 0) {
      operationalCost = customKosCost;
    } else if (workType == 'WFH') {
      operationalCost = needsKos ? 2000000 : 1200000;
    } else if (workType == 'Hybrid') {
      operationalCost = needsKos ? 2800000 : 1800000;
    } else {
      operationalCost = needsKos ? 3500000 : 2200000;
    }

    final minSavings = minNetTHP - operationalCost;
    final maxSavings = maxNetTHP - operationalCost;

    return SalaryRangeEvaluationResult(
      minGross: minGross,
      maxGross: maxGross,
      isRange: isRange,
      minNetTakeHome: minNetTHP,
      maxNetTakeHome: maxNetTHP,
      umrAmount: effectiveUmr,
      city: umrItem.city,
      minUmrRatio: minUmrRatio,
      maxUmrRatio: maxUmrRatio,
      estimatedOperationalCost: operationalCost,
      minSavings: minSavings,
      maxSavings: maxSavings,
    );
  }

  static SalaryEvaluationResult evaluateSalary({
    required double grossSalary,
    required String city,
    required String workType,
    bool needsKos = true,
    double? customKosCost,
    double? customUmr,
  }) {
    final res = evaluateSalaryRange(
      rawSalaryInput: grossSalary.toString(),
      city: city,
      workType: workType,
      needsKos: needsKos,
      customKosCost: customKosCost,
      customUmr: customUmr,
    );
    return SalaryEvaluationResult(
      grossSalary: res.minGross,
      estimatedBpjsDeduction: res.minGross * 0.04,
      estimatedNetTakeHomePay: res.minNetTakeHome,
      umrAmount: res.umrAmount,
      city: res.city,
      umrRatio: res.minUmrRatio,
      estimatedOperationalCost: res.estimatedOperationalCost,
      estimatedNetSavings: res.minSavings,
    );
  }
}

class SalaryEvaluationResult {
  final double grossSalary;
  final double estimatedBpjsDeduction;
  final double estimatedNetTakeHomePay;
  final double umrAmount;
  final String city;
  final double umrRatio;
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
