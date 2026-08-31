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
  final double confidenceScore;
  final Map<String, bool> fieldConfidence;

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
    this.confidenceScore = 1.0,
    Map<String, bool>? fieldConfidence,
  }) : fieldConfidence = fieldConfidence ?? const {};

  bool get hasUsableCompany =>
      companyName.trim().isNotEmpty &&
      !TextParserService.isPlaceholderCompany(companyName);

  bool get hasUsablePosition =>
      position.trim().isNotEmpty &&
      !TextParserService.isPlaceholderPosition(position);
}

class TextParserService {
  static const placeholderCompany = 'Perusahaan Baru';
  static const placeholderPosition = 'Posisi Lowongan';

  static const _supportedJobHosts = <String>[
    'linkedin.com',
    'jobstreet.com',
    'jobstreet.co',
    'glints.com',
    'indeed.com',
    'kalibrr.com',
    'kitalulus.com',
    'karir.com',
  ];

  static bool isPlaceholderCompany(String name) {
    final n = name.trim().toLowerCase();
    return n.isEmpty ||
        n == placeholderCompany.toLowerCase() ||
        n == 'perusahaan' ||
        n == 'company';
  }

  static bool isPlaceholderPosition(String name) {
    final n = name.trim().toLowerCase();
    return n.isEmpty ||
        n == placeholderPosition.toLowerCase() ||
        n == 'posisi' ||
        n == 'position' ||
        n == 'lowongan';
  }

  /// Ekstraksi otomatis dari URL (LinkedIn, JobStreet, Glints, Indeed, dll.) atau Teks Bebas.
  static Future<ParsedJobData> extractFromUrlOrText(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ParsedJobData(
        companyName: '',
        position: '',
        workType: '',
        rawDescription: '',
        extractedSkills: [],
        confidenceScore: 0.0,
      );
    }

    final normalized = _ensureUrlProtocol(trimmed);

    final urlReg = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final urlMatch = urlReg.firstMatch(normalized);

    if (urlMatch != null) {
      final detectedUrl = urlMatch.group(0)!;
      final urlParsed = await _extractFromUrl(detectedUrl, normalized);
      if (urlParsed != null) return urlParsed;
    }

    final parsed = parseJobText(normalized);
    if (urlMatch != null && (parsed.jobUrl == null || parsed.jobUrl!.isEmpty)) {
      return ParsedJobData(
        companyName: parsed.companyName,
        position: parsed.position,
        workType: parsed.workType,
        salary: parsed.salary,
        location: parsed.location,
        rawDescription: parsed.rawDescription,
        extractedSkills: parsed.extractedSkills,
        jobUrl: urlMatch.group(0)!,
        hrContact: parsed.hrContact,
        sourcePlatform: parsed.sourcePlatform,
        confidenceScore: parsed.confidenceScore,
        fieldConfidence: parsed.fieldConfidence,
      );
    }
    return parsed;
  }

  static String _ensureUrlProtocol(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'(^|[\s])((?:www\.)?(?:linkedin|jobstreet|glints|indeed|kalibrr|kitalulus|karir)\.[\w./?&=%-]+)',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}https://${m.group(2)}',
    );
  }

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
        sourcePlatform: parsed.sourcePlatform,
        confidenceScore: parsed.confidenceScore,
        fieldConfidence: parsed.fieldConfidence,
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
    } else if (lowerUrl.contains('kitalulus.com')) {
      platform = 'KitaLulus';
    } else if (lowerUrl.contains('karir.com')) {
      platform = 'Karir.com';
    }

    String position = '';
    String company = '';
    String description = originalInput;

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

    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(milliseconds: 2500));
      if (res.statusCode == 200) {
        final html = res.body;

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

    final resolvedCompany = company.isNotEmpty
        ? company
        : parsedFromText.companyName;
    final resolvedPosition = position.isNotEmpty
        ? position
        : parsedFromText.position;

    final isCompanyConfident = resolvedCompany.isNotEmpty;
    final isPositionConfident = resolvedPosition.isNotEmpty;
    double confidence =
        (isCompanyConfident ? 0.5 : 0.0) + (isPositionConfident ? 0.5 : 0.0);

    return ParsedJobData(
      companyName: resolvedCompany,
      position: resolvedPosition,
      workType: parsedFromText.workType,
      salary: parsedFromText.salary,
      location: parsedFromText.location,
      rawDescription: description,
      extractedSkills: parsedFromText.extractedSkills,
      jobUrl: url,
      hrContact: parsedFromText.hrContact,
      sourcePlatform: platform,
      confidenceScore: confidence,
      fieldConfidence: {
        'company': isCompanyConfident,
        'position': isPositionConfident,
        'salary': parsedFromText.salary != null,
        'location': parsedFromText.location != null,
      },
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
            r'^(we are hiring|hiring|lowongan kerja|lowongan|loker)\s*[:\-–]?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\b(lowongan kerja|loker)\b', caseSensitive: false),
          ' ',
        )
        .trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return '';
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
          RegExp(r'\b(careers?|karir|official|loker)\b', caseSensitive: false),
          ' ',
        )
        .trim();
    c = c.replaceAll(RegExp(r'\s+'), ' ');
    if (c.isEmpty) return '';
    return c;
  }

  static ParsedJobData parseJobText(String text) {
    if (text.trim().isEmpty) {
      return ParsedJobData(
        companyName: '',
        position: '',
        workType: '',
        rawDescription: '',
        extractedSkills: [],
        confidenceScore: 0.0,
      );
    }

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String companyName = '';
    String position = '';
    String workType = '';
    String? salary;
    String? location;
    String? hrContact;

    final lowerText = text.toLowerCase();

    final hasWfh =
        lowerText.contains('wfh') ||
        lowerText.contains('work from home') ||
        lowerText.contains('remote') ||
        lowerText.contains('kerja dari rumah');
    final hasWfo =
        lowerText.contains('wfo') ||
        lowerText.contains('work from office') ||
        lowerText.contains('on-site') ||
        lowerText.contains('onsite') ||
        lowerText.contains('on site') ||
        lowerText.contains('kerja di kantor');
    final hasHybrid =
        lowerText.contains('hybrid') || lowerText.contains('fleksibel');
    if (hasHybrid || (hasWfh && hasWfo)) {
      workType = 'Hybrid';
    } else if (hasWfh) {
      workType = 'WFH';
    } else if (hasWfo) {
      workType = 'WFO';
    }

    final emailReg = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      caseSensitive: false,
    );
    final emailMatch = emailReg.firstMatch(text);
    if (emailMatch != null) {
      hrContact = emailMatch.group(0);
    } else {
      final phoneReg = RegExp(r'(\+?62|0)8\d{7,12}');
      final phoneMatch = phoneReg.firstMatch(text.replaceAll(RegExp(r'[\s-]'), ''));
      if (phoneMatch != null) {
        hrContact = phoneMatch.group(0);
      }
    }

    companyName = _extractLabeled(
      text,
      const ['perusahaan', 'company', 'nama perusahaan', 'instansi'],
    );
    if (companyName.isEmpty) {
      final ptReg = RegExp(
        r'(pt\.?\s+[a-zA-Z0-9\.\-][a-zA-Z0-9\.\-\s]{1,40}|cv\.?\s+[a-zA-Z0-9\.\-][a-zA-Z0-9\.\-\s]{1,40}|bank\s+[a-zA-Z0-9\.\-\s]{2,30}|[a-zA-Z0-9\.\-\s]{2,30}\s+tbk\.?|[a-zA-Z0-9\.\-\s]{2,30}\s+inc\.?)',
        caseSensitive: false,
      );
      final ptMatch = ptReg.firstMatch(text);
      if (ptMatch != null) {
        companyName = ptMatch.group(0)!.split('\n').first.trim();
      } else {
        final diReg = RegExp(
          r'(?:di|at)\s+([A-Z][A-Za-z0-9&.\-][A-Za-z0-9&.\-\s]{1,40})',
        );
        final diMatch = diReg.firstMatch(text);
        if (diMatch != null) {
          companyName = diMatch.group(1)!.split('\n').first.trim();
        }
      }
    }
    companyName = companyName
        .replaceAll(RegExp(r'[.,;:]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    position = _extractLabeled(
      text,
      const [
        'posisi',
        'jabatan',
        'role',
        'job title',
        'title',
        'sebagai',
        'dibutuhkan',
        'looking for',
        'hiring',
      ],
    );
    if (position.isEmpty) {
      const roleKeywords =
          r'(developer|engineer|designer|specialist|staff|officer|intern|internship|manager|admin|analyst|associate|lead|programmer|consultant|supervisor|creator|executive|associate|accountant|secretary|receptionist|copywriter|marketer|recruiter|hrd|perawat|guru|dosen|barista|kasir|sales|driver|teknisi|mekanik|farmasi|bidan|gudang|operasional|security|chef|waiter|videographer|photographer|illustrator|researcher)';
      final posReg = RegExp(
        r'\b((?:[a-zA-Z][a-zA-Z/\s]{0,35})?' + roleKeywords + r')\b',
        caseSensitive: false,
      );
      final posMatch = posReg.firstMatch(text);
      if (posMatch != null) {
        position = posMatch.group(0)!.split('\n').first.trim();
      } else if (lines.isNotEmpty) {
        final firstLine = lines.first;
        if (firstLine.length <= 55 &&
            !firstLine.toLowerCase().contains('http') &&
            !RegExp(r'^we are hiring', caseSensitive: false).hasMatch(firstLine)) {
          position = firstLine;
        }
      }
    }
    position = _cleanTitle(position);

    final salaryReg = RegExp(
      r'(?:rp\.?\s*|idr\s*|usd\s*|\$)\s*[\d\.\,]+(?:\s*(?:jt|juta|mio|rb|ribu|k))?(?:\s*[-–—]\s*(?:rp\.?\s*|idr\s*|usd\s*|\$)?\s*[\d\.\,]+(?:\s*(?:jt|juta|mio|rb|ribu|k))?)?(?:\s*(?:/\s*)?(?:bln|bulan|month))?'
      r'|[\d\.\,]+\s*(?:jt|juta)\s*[-–—]\s*[\d\.\,]+\s*(?:jt|juta)',
      caseSensitive: false,
    );
    final salaryMatch = salaryReg.firstMatch(text);
    if (salaryMatch != null) {
      salary = salaryMatch.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    final cities = [
      'Jakarta Selatan',
      'Jakarta Barat',
      'Jakarta Pusat',
      'Jakarta Timur',
      'Jakarta Utara',
      'South Jakarta',
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
      'Denpasar',
      'Bali',
      'Malang',
      'Solo',
      'Batam',
      'Makassar',
      'Palembang',
      'Balikpapan',
      'Samarinda',
      'Pontianak',
      'Manado',
      'Padang',
      'Pekanbaru',
      'Bandar Lampung',
      'Cikarang',
      'Karawang',
      'Sidoarjo',
      'Gresik',
      'Cirebon',
      'Purwokerto',
    ];
    for (var city in cities) {
      if (lowerText.contains(city.toLowerCase())) {
        location = city == 'South Jakarta' ? 'Jakarta Selatan' : city;
        break;
      }
    }
    if (location == null &&
        (lowerText.contains('remote indonesia') ||
            lowerText.contains('remote, indonesia'))) {
      location = 'Remote';
    }

    const skillKeywords = [
      'Flutter',
      'Dart',
      'React',
      'Node.js',
      'Python',
      'Golang',
      'Kotlin',
      'Swift',
      'Laravel',
      'PostgreSQL',
      'Figma',
      'SEO',
      'Copywriting',
      'Canva',
      'UI/UX',
    ];
    final extractedSkills = <String>[];
    for (final skill in skillKeywords) {
      if (_hasSkillToken(lowerText, skill.toLowerCase())) {
        extractedSkills.add(skill);
      }
    }
    if (_hasSkillToken(lowerText, 'excel')) {
      extractedSkills.add('Excel');
    }
    if (_hasSkillToken(lowerText, 'java') &&
        !lowerText.contains('javascript')) {
      extractedSkills.add('Java');
    } else if (_hasSkillToken(lowerText, 'javascript')) {
      extractedSkills.add('JavaScript');
    }
    if (_hasSkillToken(lowerText, 'php')) {
      extractedSkills.add('PHP');
    }
    if (_hasSkillToken(lowerText, 'sql')) {
      extractedSkills.add('SQL');
    }
    if (_hasSkillToken(lowerText, 'git')) {
      extractedSkills.add('Git');
    }

    final usableCompany = isPlaceholderCompany(companyName) ? '' : companyName;
    final usablePosition = isPlaceholderPosition(position) ? '' : position;

    return ParsedJobData(
      companyName: usableCompany,
      position: usablePosition,
      workType: workType,
      salary: salary,
      location: location,
      rawDescription: text,
      extractedSkills: extractedSkills,
      hrContact: hrContact,
      sourcePlatform: 'Manual',
      confidenceScore:
          (usableCompany.isNotEmpty ? 0.5 : 0.0) +
          (usablePosition.isNotEmpty ? 0.5 : 0.0),
      fieldConfidence: {
        'company': usableCompany.isNotEmpty,
        'position': usablePosition.isNotEmpty,
        'salary': salary != null,
        'location': location != null,
      },
    );
  }

  static String _extractLabeled(String text, List<String> labels) {
    final joined = labels.map(RegExp.escape).join('|');
    final reg = RegExp(
      '(?:$joined)\\s*[:\\-]\\s*([^\\n,]{2,60})',
      caseSensitive: false,
    );
    final match = reg.firstMatch(text);
    if (match == null) return '';
    return match.group(1)!.trim();
  }

  static bool _hasSkillToken(String lowerText, String skill) {
    final escaped = RegExp.escape(skill);
    return RegExp(
      '(^|[^a-z0-9+])$escaped([^a-z0-9+]|\$)',
      caseSensitive: false,
    ).hasMatch(lowerText);
  }
}
