class ParsedJobData {
  final String companyName;
  final String position;
  final String workType;
  final String? salary;
  final String? location;
  final String rawDescription;
  final List<String> extractedSkills;

  ParsedJobData({
    required this.companyName,
    required this.position,
    required this.workType,
    this.salary,
    this.location,
    required this.rawDescription,
    required this.extractedSkills,
  });
}

class TextParserService {
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

    // Detect Work Type accurately
    final lowerText = text.toLowerCase();
    if (lowerText.contains('hybrid') ||
        lowerText.contains('hybridd') ||
        lowerText.contains('fleksibel') ||
        (lowerText.contains('wfh') && lowerText.contains('wfo'))) {
      workType = 'Hybrid';
    } else if (lowerText.contains('wfh') ||
        lowerText.contains('work from home') ||
        lowerText.contains('remote') ||
        lowerText.contains('kerja dari rumah') ||
        lowerText.contains('telecommute')) {
      workType = 'WFH';
    } else {
      workType = 'WFO';
    }

    // Detect Company Name Patterns
    final ptReg = RegExp(
      r'(pt\.?\s+[a-zA-Z0-9\.\-\s]{2,30}|cv\.?\s+[a-zA-Z0-9\.\-\s]{2,30}|[a-zA-Z0-9\.\-\s]{2,30}\s+inc\.?|[a-zA-Z0-9\.\-\s]{2,30}\s+ltd\.?)',
      caseSensitive: false,
    );
    final ptMatch = ptReg.firstMatch(text);
    if (ptMatch != null) {
      companyName = ptMatch.group(0)!.trim();
      if (companyName.contains('\n')) {
        companyName = companyName.split('\n').first.trim();
      }
    }

    // Detect Position Patterns
    final posReg = RegExp(
      r'([a-zA-Z\s]{2,35}(developer|engineer|designer|specialist|staff|officer|intern|internship|manager|admin|analyst|associate|lead))',
      caseSensitive: false,
    );
    final posMatch = posReg.firstMatch(text);
    if (posMatch != null) {
      position = posMatch.group(0)!.trim();
      if (position.contains('\n')) {
        position = position.split('\n').first.trim();
      }
    } else if (lines.isNotEmpty) {
      position = lines.first;
      if (position.length > 40) {
        position = position.substring(0, 40).trim();
      }
    }

    // Detect Salary Patterns
    final salaryReg = RegExp(
      r'(rp\.?\s*[\d\.\,]+(\s*-\s*[\d\.\,]+)?|[\d\.\,]+\s*(jt|juta|mio|milli?on)|idr\s*[\d\.\,]+)',
      caseSensitive: false,
    );
    final salaryMatch = salaryReg.firstMatch(text);
    if (salaryMatch != null) {
      salary = salaryMatch.group(0)!.trim();
    }

    // Detect Major Cities for Location
    final cities = [
      'Jakarta',
      'Surabaya',
      'Bandung',
      'Medan',
      'Semarang',
      'Yogyakarta',
      'Jogja',
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

    // Extract Key Skills
    final skillKeywords = [
      'Flutter',
      'Dart',
      'React',
      'Node.js',
      'Python',
      'Java',
      'Kotlin',
      'Swift',
      'PHP',
      'Laravel',
      'SQL',
      'MySQL',
      'PostgreSQL',
      'Figma',
      'Excel',
      'Photoshop',
      'SEO',
      'Copywriting',
      'Canva',
      'Git',
      'Communication',
      'English',
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
    );
  }
}
