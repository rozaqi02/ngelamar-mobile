import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ngelamar/services/spreadsheet_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpreadsheetImportService', () {
    test('parses CSV with Indonesian headers and skips incomplete rows', () {
      const csv = '''
Perusahaan,Posisi,Status,Lokasi,Gaji,Mode Kerja
PT Alpha,Flutter Developer,Dikirim,Jakarta,Rp 12.000.000,Hybrid
,Tanpa Perusahaan,Dikirim,Bandung,,
PT Beta,Content Creator,Tersimpan,Surabaya,8 juta,WFH
''';
      final result = SpreadsheetImportService.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        fileName: 'lamaran.csv',
      );
      expect(result.jobs.length, equals(2));
      expect(result.jobs.first.companyName, equals('PT Alpha'));
      expect(result.jobs.first.status, equals('Dikirim'));
      expect(result.jobs.last.position, equals('Content Creator'));
      expect(result.jobs.last.workType, equals('WFH'));
      expect(result.skippedInvalid, equals(1));
    });

    test('accepts semicolon CSV used by Indonesian Excel', () {
      const csv =
          'Company;Position;Status\nGojek;Sales Executive;Interview HR\n';
      final result = SpreadsheetImportService.parse(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        fileName: 'export.csv',
      );
      expect(result.jobs, hasLength(1));
      expect(result.jobs.single.companyName, equals('Gojek'));
      expect(result.jobs.single.status, equals('Interview HR'));
    });

    test('builds a readable xlsx template that round-trips', () {
      final bytes = SpreadsheetImportService.buildTemplateBytes();
      expect(bytes.length, greaterThan(100));
      final result = SpreadsheetImportService.parse(
        bytes: bytes,
        fileName: 'template_lamaran_ngelamar.xlsx',
      );
      expect(result.jobs, isNotEmpty);
      expect(result.jobs.first.companyName, contains('Contoh'));
      expect(result.jobs.first.position, contains('Flutter'));
      expect(result.recognizedColumns, contains('companyName'));
      expect(result.recognizedColumns, contains('position'));
    });

    test('rejects files without company and position columns', () {
      const csv = 'Nama,Alamat\nBudi,Jakarta\n';
      expect(
        () => SpreadsheetImportService.parse(
          bytes: Uint8List.fromList(utf8.encode(csv)),
          fileName: 'salah.csv',
        ),
        throwsA(isA<SpreadsheetImportException>()),
      );
    });
  });
}
