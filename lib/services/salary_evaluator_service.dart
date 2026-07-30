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

  static double parseSalaryAmount(String? input) {
    if (input == null || input.trim().isEmpty) return 0.0;
    String clean = input.toLowerCase().replaceAll('rp', '').replaceAll('idr', '').trim();

    // Handle range e.g., "5 - 8 juta" or "6.000.000 - 8.000.000" -> take first value
    if (clean.contains('-')) {
      clean = clean.split('-').first.trim();
    }

    // Handle "5 jt" or "5.5 juta"
    if (clean.contains('jt') || clean.contains('juta')) {
      final numStr = clean.replaceAll('jt', '').replaceAll('juta', '').replaceAll(',', '.').trim();
      final parsed = double.tryParse(numStr);
      if (parsed != null) return parsed * 1000000;
    }

    // Handle numeric with dots e.g. 6.000.000
    clean = clean.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  static SalaryEvaluationResult evaluateSalary({
    required double grossSalary,
    required String city,
    required String workType, // WFO, WFH, Hybrid
    bool needsKos = true,
  }) {
    // BPJS Ketenagakerjaan + Kesehatan employee share ~ 4%
    final bpjs = grossSalary * 0.04;
    final netTakeHome = grossSalary - bpjs;

    final umrItem = umrList.firstWhere(
      (element) => element.city.toLowerCase() == city.toLowerCase(),
      orElse: () => const UmrData('Nasional (Rata-rata)', 3500000),
    );

    final umrRatio = umrItem.umrAmount > 0 ? (grossSalary / umrItem.umrAmount) : 1.0;

    // Estimate monthly operational cost (Kos + Transport + Meals)
    double operationalCost = 0.0;
    if (workType == 'WFH') {
      // WFH: Electricity/Internet + Meals (No Kos needed unless relocation)
      operationalCost = needsKos ? 2000000 : 1200000;
    } else if (workType == 'Hybrid') {
      // Hybrid: Transport + Kos
      operationalCost = needsKos ? 2800000 : 1800000;
    } else {
      // WFO: Transport + Kos + Daily meals
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
