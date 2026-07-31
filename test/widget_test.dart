import 'package:flutter_test/flutter_test.dart';
import 'package:ngelamar/services/text_parser_service.dart';
import 'package:ngelamar/services/salary_evaluator_service.dart';

void main() {
  group('TextParserService Tests', () {
    test('Should parse company, position, workType, and salary from job text', () {
      const sampleText = '''
We are hiring Flutter Developer at PT Tech Innovations.
Work Location: Jakarta (WFH available).
Salary: Rp 12.000.000 - Rp 15.000.000.
Requirements: Flutter, Dart, Riverpod, Firebase.
''';

      final result = TextParserService.parseJobText(sampleText);
      expect(result.position, contains('Flutter Developer'));
      expect(result.companyName, contains('PT Tech Innovations'));
      expect(result.workType, equals('WFH'));
      expect(result.salary, equals('Rp 12.000.000'));
    });
  });

  group('SalaryEvaluatorService Tests', () {
    test('Should format Rupiah currency correctly', () {
      expect(SalaryEvaluatorService.formatRupiah(10000000), equals('Rp 10.000.000'));
      expect(SalaryEvaluatorService.formatRupiah(-500000), equals('-Rp 500.000'));
      expect(SalaryEvaluatorService.formatRupiah(0), equals('Rp 0'));
    });

    test('Should parse salary amount string correctly', () {
      expect(SalaryEvaluatorService.parseSalaryAmount('Rp 12.000.000'), equals(12000000.0));
      expect(SalaryEvaluatorService.parseSalaryAmount('15 jt'), equals(15000000.0));
      expect(SalaryEvaluatorService.parseSalaryAmount(''), equals(0.0));
    });

    test('Should evaluate salary against UMR correctly', () {
      final eval = SalaryEvaluatorService.evaluateSalary(
        grossSalary: 10000000,
        city: 'Jakarta',
        workType: 'WFO',
        needsKos: true,
      );
      expect(eval.grossSalary, equals(10000000.0));
      expect(eval.city, equals('Jakarta'));
      expect(eval.estimatedNetTakeHomePay, greaterThan(0));
    });
  });
}
