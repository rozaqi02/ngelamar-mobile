import 'package:http/http.dart' as http;

class ParsedJobData {
  final String companyName;
  final String position;
  final String workType;
  final String? salary;
  final String? location;
  final String rawDescription;
  final List<String> extractedSkills;
  final String? jobUrl;
  final String? hrContact;
  final String sourcePlatform;

  ParsedJobData({
    required this.companyName,
    required this.position,
    required this.workType,
    this.salary,
    this.location,
    required this.rawDescription,
    required this.extractedSkills,
    this.jobUrl,
    this.hrContact,
    this.sourcePlatform = 'Manual',
  });
}

class TextParserService {
  static const _supportedJobHosts = <String>[
    'linkedin.com',
    'jobstreet.com',
    'jobstreet.co',
    'glints.com',
    'indeed.com',
    'kalibrr.com',
  ];

  /// Ekstraksi otomatis dari URL (LinkedIn, JobStreet, Glints, Indeed, dll.) atau Teks Bebas.
  static Future<ParsedJobData> extractFromUrlOrText(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ParsedJobData(
        companyName: '',
        position: '',
        workType: 'WFO',
        rawDescription: '',
        extractedSkills: [],
      );
    }

    // 1. Cek apakah input mengandung URL
    final urlReg = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final urlMatch = urlReg.firstMatch(trimmed);

    if (urlMatch != null) {
      final detectedUrl = urlMatch.group(0)!;
      final urlParsed = await _extractFromUrl(detectedUrl, trimmed);
      if (urlParsed != null) return urlParsed;
    }

    // 2. Jika bukan URL atau URL offline, parse sebagai teks postingan
    return parseJobText(trimmed);
  }

  /// Ekstraksi cerdas dari URL lowongan
  static Future<ParsedJobData?> _extractFromUrl(
    String url,
    String originalInput,
  ) async {
    final uri = Uri.tryParse(url);
    if (!_isSupportedHttpsJobUrl(uri)) {
      final parsed = parseJobText(originalInput);
      return ParsedJobData(
        companyName: parsed.companyName,
        position: parsed.position,
        workType: parsed.workType,
        salary: parsed.salary,
        location: parsed.location,
        rawDescription: originalInput,
        extractedSkills: parsed.extractedSkills,
        jobUrl: url,
        hrContact: parsed.hrContact,
      );
    }
    final safeUri = uri!;

    final lowerUrl = url.toLowerCase();
    String platform = 'Lainnya';
    if (lowerUrl.contains('linkedin.com')) {
      platform = 'LinkedIn';
    } else if (lowerUrl.contains('jobstreet.co')) {
      platform = 'JobStreet';
    } else if (lowerUrl.contains('glints.com')) {
      platform = 'Glints';
    } else if (lowerUrl.contains('indeed.com')) {
      platform = 'Indeed';
    } else if (lowerUrl.contains('kalibrr.com')) {
      platform = 'Kalibrr';
    }

    String position = '';
    String company = '';
    String description = originalInput;

    // A. Analisis Path / Slug URL
    try {
      final pathSegments = safeUri.pathSegments
          .where((s) => s.isNotEmpty)
          .toList();

      for (var seg in pathSegments) {
        final decoded = Uri.decodeComponent(
          seg,
        ).replaceAll(RegExp(r'[-_]'), ' ');
        if (decoded.contains(' at ') || decoded.contains(' di ')) {
          final parts = decoded.contains(' at ')
              ? decoded.split(' at ')
              : decoded.split(' di ');
          if (parts.length >= 2) {
            position = _cleanTitle(parts[0]);
            company = _cleanCompany(parts[1]);
          }
        } else if (seg.length > 5 &&
            !RegExp(r'^\d+$').hasMatch(seg) &&
            !['job', 'jobs', 'view', 'opportunities', 'id'].contains(seg)) {
          if (position.isEmpty) {
            position = _cleanTitle(decoded);
          }
        }
      }
    } catch (_) {}

    // B. Coba fetch metadata HTML jika memungkinkan (timeout 2.5s)
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(milliseconds: 2500));
      if (res.statusCode == 200) {
        final html = res.body;

        // Cari <title>
        final titleMatch = RegExp(
          r'<title[^>]*>(.*?)</title>',
          caseSensitive: false,
          dotAll: true,
        ).firstMatch(html);
        if (titleMatch != null) {
          final rawTitle = titleMatch.group(1)!.trim();
          final parts = rawTitle.split(RegExp(r'[|\-–•]'));
          if (parts.isNotEmpty && position.isEmpty) {
            position = _cleanTitle(parts[0]);
          }
          if (parts.length > 1 && company.isEmpty) {
            company = _cleanCompany(parts[1]);
          }
        }

        // Cari OpenGraph og:title & og:description
        final ogTitleMatch =
            RegExp(
              r'<meta[^>]*property="og:title"[^>]*content="(.*?)"',
              caseSensitive: false,
            ).firstMatch(html) ??
            RegExp(
              r"<meta[^>]*property='og:title'[^>]*content='(.*?)'",
              caseSensitive: false,
            ).firstMatch(html);
        if (ogTitleMatch != null) {
          final ogTitle = ogTitleMatch.group(1)!.trim();
          final parts = ogTitle.split(RegExp(r'[|\-–•]'));
          if (parts.isNotEmpty) position = _cleanTitle(parts[0]);
          if (parts.length > 1) company = _cleanCompany(parts[1]);
        }

        final ogDescMatch =
            RegExp(
              r'<meta[^>]*property="og:description"[^>]*content="(.*?)"',
              caseSensitive: false,
            ).firstMatch(html) ??
            RegExp(
              r"<meta[^>]*property='og:description'[^>]*content='(.*?)'",
              caseSensitive: false,
            ).firstMatch(html);
        if (ogDescMatch != null) {
          description = '$originalInput\n\n${ogDescMatch.group(1)!.trim()}';
        }
      }
    } catch (_) {}

    final parsedFromText = parseJobText(description);

    return ParsedJobData(
      companyName: company.isNotEmpty
          ? company
          : (parsedFromText.companyName.isNotEmpty
                ? parsedFromText.companyName
                : 'Perusahaan Lowongan'),
      position: position.isNotEmpty
          ? position
          : (parsedFromText.position.isNotEmpty
                ? parsedFromText.position
                : 'Posisi Lowongan'),
      workType: parsedFromText.workType,
      salary: parsedFromText.salary,
      location: parsedFromText.location,
      rawDescription: description,
      extractedSkills: parsedFromText.extractedSkills,
      jobUrl: url,
      hrContact: parsedFromText.hrContact,
      sourcePlatform: platform,
    );
  }

  static bool _isSupportedHttpsJobUrl(Uri? uri) {
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }
    final host = uri.host.toLowerCase();
    return _supportedJobHosts.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  }

  static String _cleanTitle(String text) {
    var t = text
        .replaceAll(
          RegExp(
            r'(\d+|job|lowongan|kerja|hiring|recruitment|rekrutmen)',
            caseSensitive: false,
          ),
          ' ',
        )
        .trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return 'Posisi Lowongan';
    return t
        .split(' ')
        .map(
          (w) => w.isNotEmpty
              ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  static String _cleanCompany(String text) {
    var c = text
        .replaceAll(
          RegExp(r'(\d+|careers?|karir|official|loker)', caseSensitive: false),
          ' ',
        )
        .trim();
    c = c.replaceAll(RegExp(r'\s+'), ' ');
    if (c.isEmpty) return 'Perusahaan Baru';
    return c;
  }

  static ParsedJobData parseJobText(String text) {
    if (text.trim().isEmpty) {
      return ParsedJobData(
        companyName: '',
        position: '',
        workType: 'WFO',
        rawDescription: '',
        extractedSkills: [],
      );
    }

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String companyName = '';
    String position = '';
    String workType = 'WFO';
    String? salary;
    String? location;
    String? hrContact;

    final lowerText = text.toLowerCase();

    // 1. Tipe Kerja
    if (lowerText.contains('hybrid') ||
        lowerText.contains('fleksibel') ||
        (lowerText.contains('wfh') && lowerText.contains('wfo'))) {
      workType = 'Hybrid';
    } else if (lowerText.contains('wfh') ||
        lowerText.contains('work from home') ||
        lowerText.contains('remote') ||
        lowerText.contains('kerja dari rumah')) {
      workType = 'WFH';
    } else {
      workType = 'WFO';
    }

    // 2. Kontak HR (Email / WA)
    final emailReg = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      caseSensitive: false,
    );
    final emailMatch = emailReg.firstMatch(text);
    if (emailMatch != null) {
      hrContact = emailMatch.group(0);
    } else {
      final phoneReg = RegExp(r'(08\d{8,12}|\+62\d{8,12})');
      final phoneMatch = phoneReg.firstMatch(text);
      if (phoneMatch != null) {
        hrContact = phoneMatch.group(0);
      }
    }

    // 3. Nama Perusahaan (PT / CV / Tbk / Bank / Di / At)
    final ptReg = RegExp(
      r'(pt\.?\s+[a-zA-Z0-9\.\-\s]{2,35}|cv\.?\s+[a-zA-Z0-9\.\-\s]{2,35}|bank\s+[a-zA-Z0-9\.\-\s]{2,30}|[a-zA-Z0-9\.\-\s]{2,30}\s+tbk\.?|[a-zA-Z0-9\.\-\s]{2,30}\s+inc\.?)',
      caseSensitive: false,
    );
    final ptMatch = ptReg.firstMatch(text);
    if (ptMatch != null) {
      companyName = ptMatch.group(0)!.trim();
      if (companyName.contains('\n')) {
        companyName = companyName.split('\n').first.trim();
      }
    } else {
      final diReg = RegExp(
        r'(di\s+([A-Z][a-zA-Z0-9\.\-\s]{2,30})|at\s+([A-Z][a-zA-Z0-9\.\-\s]{2,30}))',
      );
      final diMatch = diReg.firstMatch(text);
      if (diMatch != null) {
        final raw = diMatch
            .group(0)!
            .replaceAll(RegExp(r'^(di|at)\s+', caseSensitive: false), '')
            .trim();
        companyName = raw.split('\n').first.trim();
      }
    }

    // 4. Posisi / Role
    final posReg = RegExp(
      r'([a-zA-Z\s]{2,35}(developer|engineer|designer|specialist|staff|officer|intern|internship|manager|admin|analyst|associate|lead|programmer|consultant|supervisor))',
      caseSensitive: false,
    );
    final posMatch = posReg.firstMatch(text);
    if (posMatch != null) {
      position = posMatch.group(0)!.trim();
      if (position.contains('\n')) {
        position = position.split('\n').first.trim();
      }
    } else if (lines.isNotEmpty) {
      final firstLine = lines.first;
      if (firstLine.length <= 45 && !firstLine.toLowerCase().contains('http')) {
        position = firstLine;
      }
    }

    // 5. Gaji (Format Rp)
    final salaryReg = RegExp(
      r'(rp\.?\s*[\d\.\,]+(\s*-\s*[\d\.\,]+)?(\s*(jt|juta|mio|rb|ribu|bln|bulan))?|[\d\.\,]+\s*(jt|juta)\s*-\s*[\d\.\,]+\s*(jt|juta)|idr\s*[\d\.\,]+)',
      caseSensitive: false,
    );
    final salaryMatch = salaryReg.firstMatch(text);
    if (salaryMatch != null) {
      salary = salaryMatch.group(0)!.trim();
    }

    // 6. Lokasi Kota
    final cities = [
      'Jakarta Selatan',
      'Jakarta Barat',
      'Jakarta Pusat',
      'Jakarta Timur',
      'Jakarta Utara',
      'Jakarta',
      'Surabaya',
      'Bandung',
      'Medan',
      'Semarang',
      'Yogyakarta',
      'Jogja',
      'Tangerang Selatan',
      'Tangerang',
      'BSD',
      'Bekasi',
      'Depok',
      'Bogor',
      'Bali',
      'Malang',
      'Solo',
      'Batam',
    ];
    for (var city in cities) {
      if (lowerText.contains(city.toLowerCase())) {
        location = city;
        break;
      }
    }

    // 7. Skill Keywords
    final skillKeywords = [
      'Flutter',
      'Dart',
      'React',
      'Node.js',
      'Python',
      'Golang',
      'Java',
      'Kotlin',
      'Swift',
      'PHP',
      'Laravel',
      'SQL',
      'PostgreSQL',
      'Figma',
      'Excel',
      'SEO',
      'Copywriting',
      'Canva',
      'Git',
      'UI/UX',
    ];

    List<String> extractedSkills = [];
    for (var skill in skillKeywords) {
      if (lowerText.contains(skill.toLowerCase())) {
        extractedSkills.add(skill);
      }
    }

    return ParsedJobData(
      companyName: companyName.isEmpty ? 'Perusahaan Baru' : companyName,
      position: position.isEmpty ? 'Posisi Lowongan' : position,
      workType: workType,
      salary: salary,
      location: location,
      rawDescription: text,
      extractedSkills: extractedSkills,
      hrContact: hrContact,
      sourcePlatform: 'Manual',
    );
  }
}
