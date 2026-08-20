import '../models/job_application.dart';

/// Service mesin pencari agregator lowongan kerja dari Glints, JobStreet, dan LinkedIn Indonesia.
class JobSearchService {
  static final List<JobApplication> _masterCatalog = [
    JobApplication(
      id: 'glints_goto_flutter',
      companyName: 'PT GoTo Gojek Tokopedia Tbk',
      position: 'Senior Flutter Engineer (Core App)',
      status: 'Tersedia',
      appliedDate: DateTime.now().subtract(const Duration(hours: 2)),
      salaryOffered: 'Rp 22.000.000 - Rp 30.000.000 / bln',
      minSalary: 22000000,
      maxSalary: 30000000,
      workType: 'Hybrid',
      location: 'Jakarta Selatan (Hybrid)',
      jobSource: 'Glints',
      sourcePlatform: 'Glints',
      jobUrl: 'https://glints.com/id/opportunities/jobs/senior-flutter-engineer',
      jobDescription:
          '• Mengembangkan fitur mobile skala besar dengan jutaan pengguna harian.\n• Menerapkan Clean Architecture, Bloc/Riverpod, dan automated testing.\n• Kolaborasi erat dengan tim Core Framework & Platform Infrastructure.',
      isFavorite: false,
    ),
    JobApplication(
      id: 'jobstreet_bca_mobile',
      companyName: 'PT Bank Central Asia Tbk',
      position: 'Mobile Application Specialist (myBCA)',
      status: 'Tersedia',
      appliedDate: DateTime.now().subtract(const Duration(hours: 5)),
      salaryOffered: 'Rp 18.000.000 - Rp 24.000.000 / bln',
      minSalary: 18000000,
      maxSalary: 24000000,
      workType: 'On-Site',
      location: 'Jakarta Barat (WFO)',
      jobSource: 'JobStreet',
      sourcePlatform: 'JobStreet',
      jobUrl: 'https://www.jobstreet.co.id/job/bca-mobile-developer',
      jobDescription:
          '• Mengembangkan aplikasi perbankan digital generasi terbaru.\n• Memahami security standard transaksi perbankan, SSL Pinning, dan biometrik.\n• Memiliki pengalaman dengan Flutter, Kotlin, atau Swift.',
      isFavorite: false,
    ),
    JobApplication(
      id: 'glints_shopee_backend',
      companyName: 'PT Shopee International Indonesia',
      position: 'Software Engineer - Backend (Golang)',
      status: 'Tersedia',
      appliedDate: DateTime.now().subtract(const Duration(hours: 8)),
      salaryOffered: 'Rp 20.000.000 - Rp 28.000.000 / bln',
      minSalary: 20000000,
      maxSalary: 28000000,
      workType: 'WFH',
      location: 'Jakarta Pusat & Remote',
      jobSource: 'Glints',
      sourcePlatform: 'Glints',
      jobUrl: 'https://glints.com/id/opportunities/jobs/software-engineer-golang',
      jobDescription:
          '• Merancang dan mengoptimalkan high-throughput backend services.\n• Menguasai Golang, Python, Kafka, Redis, dan PostgreSQL.\n• Berpengalaman dalam microservices dan distributed system architecture.',
      isFavorite: false,
    ),
    JobApplication(
      id: 'jobstreet_telkom_architect',
      companyName: 'PT Telkom Indonesia Tbk',
      position: 'Lead Mobile Solution Architect',
      status: 'Tersedia',
      appliedDate: DateTime.now().subtract(const Duration(hours: 12)),
      salaryOffered: 'Rp 26.000.000 - Rp 35.000.000 / bln',
      minSalary: 26000000,
      maxSalary: 35000000,
      workType: 'Hybrid',
      location: 'Jakarta / Bandung',
      jobSource: 'JobStreet',
      sourcePlatform: 'JobStreet',
      jobUrl: 'https://www.jobstreet.co.id/job/telkom-lead-architect',
      jobDescription:
          '• Merancang arsitektur sistem digital B2B dan enterprise nasional.\n• Mendorong standarisasi UI/UX, CI/CD pipeline, dan code review.\n• Pengalaman 5+ tahun dalam rekayasa perangkat lunak enterprise.',
      isFavorite: false,
    ),
    JobApplication(
      id: 'glints_traveloka_product',
      companyName: 'PT Traveloka Indonesia',
      position: 'Product Designer (UI/UX - Mobile)',
      status: 'Tersedia',
      appliedDate: DateTime.now().subtract(const Duration(days: 1)),
      salaryOffered: 'Rp 16.000.000 - Rp 23.000.000 / bln',
      minSalary: 16000000,
      maxSalary: 23000000,
      workType: 'Hybrid',
      location: 'Tangerang Selatan / WFH',
      jobSource: 'Glints',
      sourcePlatform: 'Glints',
      jobUrl: 'https://glints.com/id/opportunities/jobs/product-designer-traveloka',
      jobDescription:
          '• Merancang user flow, wireframe, dan prototype interaktif dengan Figma.\n• Melakukan usability testing dan user research kualitatif & kuantitatif.\n• Kolaborasi erat dengan PM dan Mobile Engineer.',
      isFavorite: false,
    ),
    JobApplication(
      id: 'jobstreet_bukalapak_flutter',
      companyName: 'PT Bukalapak.com Tbk',
      position: 'Mobile Developer (Flutter & Android)',
      status: 'Tersedia',
      appliedDate: DateTime.now().subtract(const Duration(days: 1)),
      salaryOffered: 'Rp 17.000.000 - Rp 24.000.000 / bln',
      minSalary: 17000000,
      maxSalary: 24000000,
      workType: 'WFH',
      location: 'Jakarta Selatan (Remote)',
      jobSource: 'JobStreet',
      sourcePlatform: 'JobStreet',
      jobUrl: 'https://www.jobstreet.co.id/job/bukalapak-mobile-dev',
      jobDescription:
          '• Mengembangkan modul aplikasi Mitra Bukalapak dengan Flutter.\n• Menerapkan clean architecture, dependency injection, dan unit testing.\n• Memastikan performa aplikasi tetap lancar di perangkat low-end.',
      isFavorite: false,
    ),
    JobApplication(
      id: 'glints_dana_qa',
      companyName: 'PT Espay Debit Indonesia Koe (DANA)',
      position: 'QA Automation Engineer (Mobile)',
      status: 'Tersedia',
      appliedDate: DateTime.now().subtract(const Duration(days: 2)),
      salaryOffered: 'Rp 15.000.000 - Rp 21.000.000 / bln',
      minSalary: 15000000,
      maxSalary: 21000000,
      workType: 'Hybrid',
      location: 'Jakarta Selatan (WFO & WFH)',
      jobSource: 'Glints',
      sourcePlatform: 'Glints',
      jobUrl: 'https://glints.com/id/opportunities/jobs/dana-qa-automation',
      jobDescription:
          '• Membangun test automation script untuk aplikasi mobile (Appium / Flutter Driver).\n• Melakukan stress testing, integration testing, dan security testing.\n• Bekerja dalam sprint agile bersama scrum team.',
      isFavorite: false,
    ),
    JobApplication(
      id: 'jobstreet_tiket_data',
      companyName: 'PT Global Tiket Network (tiket.com)',
      position: 'Data Analyst & Business Intelligence',
      status: 'Tersedia',
      appliedDate: DateTime.now().subtract(const Duration(days: 2)),
      salaryOffered: 'Rp 16.000.000 - Rp 22.000.000 / bln',
      minSalary: 16000000,
      maxSalary: 22000000,
      workType: 'Hybrid',
      location: 'Jakarta Barat (Hybrid)',
      jobSource: 'JobStreet',
      sourcePlatform: 'JobStreet',
      jobUrl: 'https://www.jobstreet.co.id/job/tiket-data-analyst',
      jobDescription:
          '• Menganalisis metrik funnel konversi pengguna dan performa promosi.\n• Membuat dashboard analitik dengan Tableau, SQL, dan Python.\n• Memberikan rekomendasi berbasis data kepada manajemen.',
      isFavorite: false,
    ),
  ];

  /// Mencari lowongan berdasarkan kata kunci, filter kota, dan platform sumber.
  static Future<List<JobApplication>> searchJobs({
    String query = '',
    String cityFilter = 'Semua Kota',
    String platformFilter = 'Semua',
    String workTypeFilter = 'Semua',
  }) async {
    // Simulasi delay respons jaringan
    await Future.delayed(const Duration(milliseconds: 300));

    final q = query.trim().toLowerCase();

    return _masterCatalog.where((job) {
      // 1. Filter Platform (Glints / JobStreet)
      if (platformFilter != 'Semua' &&
          job.sourcePlatform.toLowerCase() != platformFilter.toLowerCase()) {
        return false;
      }

      // 2. Filter Kota
      if (cityFilter != 'Semua Kota') {
        final loc = (job.location ?? '').toLowerCase();
        if (cityFilter == 'Remote / WFH') {
          if (job.workType != 'WFH' && !loc.contains('remote') && !loc.contains('wfh')) {
            return false;
          }
        } else if (!loc.contains(cityFilter.toLowerCase())) {
          return false;
        }
      }

      // 3. Filter Tipe Kerja (WFH/WFO/Hybrid)
      if (workTypeFilter != 'Semua' &&
          job.workType.toLowerCase() != workTypeFilter.toLowerCase()) {
        return false;
      }

      // 4. Filter Kata Kunci
      if (q.isNotEmpty) {
        final matchPos = job.position.toLowerCase().contains(q);
        final matchComp = job.companyName.toLowerCase().contains(q);
        final matchDesc = job.jobDescription.toLowerCase().contains(q);
        final matchLoc = (job.location ?? '').toLowerCase().contains(q);
        if (!matchPos && !matchComp && !matchDesc && !matchLoc) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
