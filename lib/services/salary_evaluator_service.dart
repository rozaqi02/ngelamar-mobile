class UmrData {
  final String city;
  final double umrAmount;
  final String effectiveYear;
  final String source;

  const UmrData(
    this.city,
    this.umrAmount, {
    this.effectiveYear = '2025/2026',
    this.source = 'Kemenaker & Kepgub Pemda',
  });
}

class SalaryRangeEvaluationResult {
  final double minGross;
  final double maxGross;
  final bool isRange;
  final double minNetTakeHome;
  final double maxNetTakeHome;
  final double minBpjsDeduction;
  final double maxBpjsDeduction;
  final double minPph21Deduction;
  final double maxPph21Deduction;
  final double umrAmount;
  final String city;
  final String effectiveYear;
  final String source;
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
    required this.minBpjsDeduction,
    required this.maxBpjsDeduction,
    required this.minPph21Deduction,
    required this.maxPph21Deduction,
    required this.umrAmount,
    required this.city,
    this.effectiveYear = '2025/2026',
    this.source = 'Kemenaker & Kepgub Pemda',
    required this.minUmrRatio,
    required this.maxUmrRatio,
    required this.estimatedOperationalCost,
    required this.minSavings,
    required this.maxSavings,
  });
}

class SalaryEvaluatorService {
  static const String currentDatasetYear = '2025/2026';
  static const String datasetSourceUrl = 'https://satudata.kemnaker.go.id';
  static const String datasetDisclaimer =
      'Referensi 2025/2026. Nilai dapat berubah; verifikasi keputusan terbaru pemerintah daerah.';

  static const List<UmrData> umrList = [
    UmrData(
      'Jakarta',
      5396761,
      effectiveYear: '2025/2026',
      source: 'Kepgub DKI Jakarta',
    ),
    UmrData(
      'Bekasi',
      5698540,
      effectiveYear: '2025/2026',
      source: 'Kepgub Jawa Barat',
    ),
    UmrData(
      'Depok',
      5195000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Jawa Barat',
    ),
    UmrData(
      'Bogor',
      5132000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Jawa Barat',
    ),
    UmrData(
      'Tangerang / BSD',
      5065000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Banten',
    ),
    UmrData(
      'Surabaya',
      5035000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Jawa Timur',
    ),
    UmrData(
      'Batam',
      4950000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Kepri',
    ),
    UmrData(
      'Bandung',
      4492000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Jawa Barat',
    ),
    UmrData(
      'Medan',
      4020000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Sumut',
    ),
    UmrData(
      'Bali (Badung)',
      3520000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Bali',
    ),
    UmrData(
      'Malang',
      3525000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Jawa Timur',
    ),
    UmrData(
      'Semarang',
      3460000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Jawa Tengah',
    ),
    UmrData(
      'Yogyakarta / Jogja',
      2650000,
      effectiveYear: '2025/2026',
      source: 'Kepgub DIY',
    ),
    UmrData(
      'Solo (Surakarta)',
      2450000,
      effectiveYear: '2025/2026',
      source: 'Kepgub Jawa Tengah',
    ),
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
  static String formatRupiahRange(
    double min,
    double max, {
    bool isRange = true,
  }) {
    if (!isRange || (min - max).abs() < 1) {
      return formatRupiah(min);
    }
    return '${formatRupiah(min)} - ${formatRupiah(max)}';
  }

  static ({double min, double max, bool isRange}) parseSalaryRange(
    String? input,
  ) {
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
          .replaceAll(' ', '')
          .replaceAll(',', '.')
          .trim();
      final parsed = double.tryParse(numStr);
      if (parsed != null) return parsed * 1000000;
    }

    if (clean.contains('rb') ||
        clean.contains('ribu') ||
        RegExp(r'\d+k\b').hasMatch(clean)) {
      final numStr = clean
          .replaceAll('rb', '')
          .replaceAll('ribu', '')
          .replaceAll('k', '')
          .replaceAll(' ', '')
          .replaceAll(',', '.')
          .trim();
      final parsed = double.tryParse(numStr);
      if (parsed != null) return parsed * 1000;
    }

    clean = clean.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  static double estimatePph21(double gross) {
    if (gross <= 4500000) return 0.0;
    if (gross <= 8000000) return gross * 0.015;
    if (gross <= 15000000) return gross * 0.05;
    if (gross <= 25000000) return gross * 0.09;
    return gross * 0.15;
  }

  static SalaryRangeEvaluationResult evaluateSalaryRange({
    required String? rawSalaryInput,
    required String city,
    required String workType,
    bool needsKos = true,
    double? customKosCost,
    double? customUmr,
    double bpjsPercent = 4.0,
    bool includePph21 = false,
  }) {
    final range = parseSalaryRange(rawSalaryInput);
    final minGross = range.min;
    final maxGross = range.max;
    final isRange = range.isRange;

    final minBpjs = minGross * (bpjsPercent / 100.0);
    final maxBpjs = maxGross * (bpjsPercent / 100.0);

    final minPph21 = includePph21 ? estimatePph21(minGross) : 0.0;
    final maxPph21 = includePph21 ? estimatePph21(maxGross) : 0.0;

    final minNetTHP = (minGross - minBpjs - minPph21).clamp(
      0.0,
      double.infinity,
    );
    final maxNetTHP = (maxGross - maxBpjs - maxPph21).clamp(
      0.0,
      double.infinity,
    );

    final umrItem = umrList.firstWhere(
      (element) => element.city.toLowerCase() == city.toLowerCase(),
      orElse: () => const UmrData('Nasional (Rata-rata)', 3500000),
    );

    final effectiveUmr = customUmr != null && customUmr > 0
        ? customUmr
        : umrItem.umrAmount;

    final minUmrRatio = effectiveUmr > 0 ? (minGross / effectiveUmr) : 1.0;
    final maxUmrRatio = effectiveUmr > 0 ? (maxGross / effectiveUmr) : 1.0;

    double operationalCost = 0.0;
    if (customKosCost != null) {
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
      minBpjsDeduction: minBpjs,
      maxBpjsDeduction: maxBpjs,
      minPph21Deduction: minPph21,
      maxPph21Deduction: maxPph21,
      umrAmount: effectiveUmr,
      city: umrItem.city,
      effectiveYear: umrItem.effectiveYear,
      source: umrItem.source,
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
    double bpjsPercent = 4.0,
    bool includePph21 = false,
  }) {
    final res = evaluateSalaryRange(
      rawSalaryInput: grossSalary.toString(),
      city: city,
      workType: workType,
      needsKos: needsKos,
      customKosCost: customKosCost,
      customUmr: customUmr,
      bpjsPercent: bpjsPercent,
      includePph21: includePph21,
    );
    return SalaryEvaluationResult(
      grossSalary: res.minGross,
      estimatedBpjsDeduction: res.minBpjsDeduction,
      estimatedPph21Deduction: res.minPph21Deduction,
      estimatedNetTakeHomePay: res.minNetTakeHome,
      umrAmount: res.umrAmount,
      city: res.city,
      effectiveYear: res.effectiveYear,
      source: res.source,
      umrRatio: res.minUmrRatio,
      estimatedOperationalCost: res.estimatedOperationalCost,
      estimatedNetSavings: res.minSavings,
    );
  }
}

class SalaryEvaluationResult {
  final double grossSalary;
  final double estimatedBpjsDeduction;
  final double estimatedPph21Deduction;
  final double estimatedNetTakeHomePay;
  final double umrAmount;
  final String city;
  final String effectiveYear;
  final String source;
  final double umrRatio;
  final double estimatedOperationalCost;
  final double estimatedNetSavings;

  SalaryEvaluationResult({
    required this.grossSalary,
    required this.estimatedBpjsDeduction,
    this.estimatedPph21Deduction = 0.0,
    required this.estimatedNetTakeHomePay,
    required this.umrAmount,
    required this.city,
    this.effectiveYear = '2025/2026',
    this.source = 'Kemenaker & Kepgub Pemda',
    required this.umrRatio,
    required this.estimatedOperationalCost,
    required this.estimatedNetSavings,
  });
}
