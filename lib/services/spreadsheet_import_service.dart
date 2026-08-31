import 'dart:convert';
import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:intl/intl.dart';

import '../models/job_application.dart';

class SpreadsheetImportException implements Exception {
  final String message;
  const SpreadsheetImportException(this.message);

  @override
  String toString() => message;
}

class SpreadsheetImportResult {
  final List<JobApplication> jobs;
  final int skippedEmpty;
  final int skippedInvalid;
  final List<String> warnings;
  final List<String> recognizedColumns;
  final String sourceName;

  const SpreadsheetImportResult({
    required this.jobs,
    required this.skippedEmpty,
    required this.skippedInvalid,
    required this.warnings,
    required this.recognizedColumns,
    required this.sourceName,
  });

  int get recognizedCount => jobs.length;
}

class SpreadsheetImportService {
  static const maxRows = 1000;

  static const templateHeaders = <String>[
    'Perusahaan',
    'Posisi',
    'Status',
    'Tanggal Lamar',
    'Lokasi',
    'Gaji',
    'Mode Kerja',
    'URL',
    'Sumber',
    'Kontak HR',
    'Deskripsi',
    'Catatan',
    'Prioritas',
  ];

  static const _headerAliases = <String, List<String>>{
    'companyName': [
      'perusahaan',
      'company',
      'nama perusahaan',
      'company name',
      'instansi',
    ],
    'position': [
      'posisi',
      'jabatan',
      'role',
      'job title',
      'title',
      'position',
    ],
    'status': ['status'],
    'appliedDate': [
      'tanggal lamar',
      'tanggal',
      'applied',
      'applied date',
      'date',
      'tgl',
    ],
    'location': ['lokasi', 'kota', 'city', 'location', 'penempatan'],
    'salary': ['gaji', 'salary', 'gaji penawaran', 'compensation'],
    'workType': [
      'mode kerja',
      'tipe kerja',
      'work type',
      'wfh/wfo',
      'worktype',
    ],
    'jobUrl': ['url', 'link', 'tautan', 'job url'],
    'jobSource': ['sumber', 'source', 'portal'],
    'hrContact': ['kontak hr', 'kontak', 'hr', 'email', 'whatsapp', 'wa'],
    'jobDescription': [
      'deskripsi',
      'kualifikasi',
      'description',
      'job description',
    ],
    'notes': ['catatan', 'notes', 'keterangan'],
    'priority': ['prioritas', 'priority'],
  };

  static const _statusAliases = <String, String>{
    'tersimpan': 'Tersimpan',
    'saved': 'Tersimpan',
    'bookmark': 'Tersimpan',
    'draft': 'Draft',
    'dikirim': 'Dikirim',
    'dilamar': 'Dikirim',
    'applied': 'Dikirim',
    'lamar': 'Dikirim',
    'tes': 'Tes / Psikotes',
    'psikotes': 'Tes / Psikotes',
    'tes / psikotes': 'Tes / Psikotes',
    'interview hr': 'Interview HR',
    'hr': 'Interview HR',
    'interview user': 'Interview User',
    'user': 'Interview User',
    'offering': 'Offering',
    'offer': 'Offering',
    'diterima': 'Diterima',
    'accepted': 'Diterima',
    'ditolak': 'Ditolak',
    'rejected': 'Ditolak',
    'dibatalkan': 'Dibatalkan',
    'cancelled': 'Dibatalkan',
  };

  static Uint8List buildTemplateBytes() {
    final excel = Excel.createExcel();
    const sheetName = 'Lamaran';
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];
    sheet.appendRow(
      templateHeaders.map((header) => TextCellValue(header)).toList(),
    );
    sheet.appendRow([
      TextCellValue('PT Contoh Teknologi'),
      TextCellValue('Flutter Developer'),
      TextCellValue('Tersimpan'),
      TextCellValue('2026-08-01'),
      TextCellValue('Jakarta'),
      TextCellValue('Rp 12.000.000 - Rp 15.000.000'),
      TextCellValue('Hybrid'),
      TextCellValue('https://www.jobstreet.co.id/id/job/123'),
      TextCellValue('JobStreet'),
      TextCellValue('rekrutmen@contoh.co.id'),
      TextCellValue('Membangun aplikasi Flutter untuk produk internal.'),
      TextCellValue('Hasil screening awal positif'),
      TextCellValue('Normal'),
    ]);
    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw const SpreadsheetImportException(
        'Template Excel tidak dapat dibuat.',
      );
    }
    return Uint8List.fromList(encoded);
  }

  static SpreadsheetImportResult parse({
    required Uint8List bytes,
    required String fileName,
  }) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv')) {
      return _parseRows(_parseCsv(bytes), sourceName: fileName);
    }
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      return _parseRows(_parseXlsx(bytes), sourceName: fileName);
    }
    throw const SpreadsheetImportException(
      'Format tidak didukung. Gunakan berkas .xlsx atau .csv.',
    );
  }

  static List<List<String>> _parseXlsx(Uint8List bytes) {
    Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (_) {
      throw const SpreadsheetImportException(
        'Berkas Excel rusak atau tidak dapat dibaca.',
      );
    }
    if (excel.tables.isEmpty) {
      throw const SpreadsheetImportException('Berkas Excel tidak berisi sheet.');
    }
    Sheet? sheet;
    for (final name in excel.tables.keys) {
      final candidate = excel.tables[name];
      if (candidate != null && candidate.rows.isNotEmpty) {
        sheet = candidate;
        break;
      }
    }
    sheet ??= excel.tables.values.first;
    return [
      for (final row in sheet.rows)
        [for (final cell in row) _cellToString(cell)],
    ];
  }

  static String _cellToString(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is TextCellValue) return (value.value.text ?? '').trim();
    if (value is IntCellValue) return '${value.value}';
    if (value is DoubleCellValue) {
      final number = value.value;
      return number == number.roundToDouble()
          ? '${number.toInt()}'
          : number.toString();
    }
    if (value is BoolCellValue) return value.value ? 'true' : 'false';
    if (value is DateCellValue) {
      return DateTime(value.year, value.month, value.day).toIso8601String();
    }
    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }
    return value.toString().trim();
  }

  static List<List<String>> _parseCsv(Uint8List bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty) return const [];
    final delimiter = _detectDelimiter(lines.first);
    return [for (final line in lines) _splitCsvLine(line, delimiter)];
  }

  static String _detectDelimiter(String headerLine) {
    final commas = ','.allMatches(headerLine).length;
    final semicolons = ';'.allMatches(headerLine).length;
    return semicolons > commas ? ';' : ',';
  }

  static List<String> _splitCsvLine(String line, String delimiter) {
    final cells = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        cells.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    cells.add(buffer.toString().trim());
    return cells;
  }

  static SpreadsheetImportResult _parseRows(
    List<List<String>> rows, {
    required String sourceName,
  }) {
    if (rows.isEmpty) {
      throw const SpreadsheetImportException('Berkas kosong.');
    }

    final headerIndex = rows.indexWhere(
      (row) => row.any((cell) => cell.trim().isNotEmpty),
    );
    if (headerIndex < 0) {
      throw const SpreadsheetImportException('Header kolom tidak ditemukan.');
    }
    final header = rows[headerIndex]
        .map((cell) => _normalizeHeader(cell))
        .toList();
    final columnMap = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final field = _fieldForHeader(header[i]);
      if (field != null && !columnMap.containsKey(field)) {
        columnMap[field] = i;
      }
    }
    if (!columnMap.containsKey('companyName') ||
        !columnMap.containsKey('position')) {
      throw const SpreadsheetImportException(
        'Kolom Perusahaan dan Posisi wajib ada. Unduh template jika ragu.',
      );
    }

    final jobs = <JobApplication>[];
    final warnings = <String>[];
    var skippedEmpty = 0;
    var skippedInvalid = 0;
    final dataRows = rows.skip(headerIndex + 1).toList();
    if (dataRows.length > maxRows) {
      warnings.add(
        'Hanya $maxRows baris pertama yang diproses dari ${dataRows.length} baris.',
      );
    }

    final limited = dataRows.take(maxRows).toList();
    for (var i = 0; i < limited.length; i++) {
      final row = limited[i];
      final rowNumber = headerIndex + i + 2;
      if (row.every((cell) => cell.trim().isEmpty)) {
        skippedEmpty++;
        continue;
      }
      final company = _cell(row, columnMap['companyName']).trim();
      final position = _cell(row, columnMap['position']).trim();
      if (company.isEmpty && position.isEmpty) {
        skippedEmpty++;
        continue;
      }
      if (company.isEmpty || position.isEmpty) {
        skippedInvalid++;
        warnings.add('Baris $rowNumber dilewati: perusahaan atau posisi kosong.');
        continue;
      }

      final status = _normalizeStatus(_cell(row, columnMap['status']));
      final appliedDate =
          _parseDate(_cell(row, columnMap['appliedDate'])) ?? DateTime.now();
      final now = DateTime.now();
      jobs.add(
        JobApplication(
          id: 'job_xlsx_${now.microsecondsSinceEpoch}_$i',
          companyName: company,
          position: position,
          status: status,
          appliedDate: appliedDate,
          savedAt: status == 'Tersimpan' ? appliedDate : null,
          location: _optional(_cell(row, columnMap['location'])),
          salaryOffered: _optional(_cell(row, columnMap['salary'])),
          workType: JobApplication.normalizeWorkType(
            _cell(row, columnMap['workType']),
          ),
          jobUrl: _optional(_cell(row, columnMap['jobUrl'])),
          jobSource: _optional(_cell(row, columnMap['jobSource'])) ?? 'Lainnya',
          sourcePlatform: 'Excel',
          hrContact: _optional(_cell(row, columnMap['hrContact'])),
          jobDescription: _cell(row, columnMap['jobDescription']),
          notes: _optional(_cell(row, columnMap['notes'])),
          priority: _normalizePriority(_cell(row, columnMap['priority'])),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return SpreadsheetImportResult(
      jobs: jobs,
      skippedEmpty: skippedEmpty,
      skippedInvalid: skippedInvalid,
      warnings: warnings,
      recognizedColumns: columnMap.keys.toList(),
      sourceName: sourceName,
    );
  }

  static String _cell(List<String> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index];
  }

  static String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _normalizeHeader(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('\uFEFF', '')
        .replaceAll(RegExp(r'[\s_]+'), ' ')
        .trim();
  }

  static String? _fieldForHeader(String header) {
    for (final entry in _headerAliases.entries) {
      if (entry.value.contains(header)) return entry.key;
    }
    return null;
  }

  static String _normalizeStatus(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return 'Tersimpan';
    return _statusAliases[key] ??
        _statusAliases.entries
            .firstWhere(
              (entry) => key.contains(entry.key),
              orElse: () => const MapEntry('', 'Tersimpan'),
            )
            .value;
  }

  static String _normalizePriority(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'tinggi':
      case 'high':
        return 'Tinggi';
      case 'rendah':
      case 'low':
        return 'Rendah';
      default:
        return 'Normal';
    }
  }

  static DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    final asNumber = double.tryParse(value.replaceAll(',', '.'));
    if (asNumber != null && asNumber > 20000 && asNumber < 80000) {
      // Excel serial date: days since 1899-12-30.
      return DateTime.utc(1899, 12, 30).add(
        Duration(milliseconds: (asNumber * 86400000).round()),
      );
    }
    const patterns = [
      'd/M/yyyy',
      'dd/MM/yyyy',
      'd-M-yyyy',
      'dd-MM-yyyy',
      'yyyy/M/d',
      'd MMM yyyy',
      'd MMMM yyyy',
    ];
    for (final pattern in patterns) {
      try {
        return DateFormat(pattern, 'id_ID').parseLoose(value);
      } catch (_) {
        try {
          return DateFormat(pattern, 'en_US').parseLoose(value);
        } catch (_) {}
      }
    }
    return null;
  }
}
