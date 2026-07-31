import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/job_application.dart';

class FollowupTemplate {
  final String title;
  final String content;
  final String language; // 'ID' or 'EN'

  FollowupTemplate({
    required this.title,
    required this.content,
    required this.language,
  });
}

class FollowupService {
  static List<FollowupTemplate> generateTemplates(JobApplication job) {
    final dateStr = DateFormat('dd MMMM yyyy').format(job.appliedDate);
    final company = job.companyName;
    final position = job.position;
    final hrName = job.hrContact != null && job.hrContact!.isNotEmpty
        ? job.hrContact
        : 'Bapak/Ibu HRD';

    return [
      FollowupTemplate(
        title: 'Follow-Up Santun WA (Bahasa Indonesia)',
        language: 'ID',
        content:
            'Selamat pagi/siang $hrName,\n\nPerkenalkan saya [Nama Anda]. Saya sebelumnya telah melamar untuk posisi * $position * di * $company * pada tanggal $dateStr.\n\nSaya ingin menanyakan terkait perkembangan proses seleksi untuk posisi tersebut. Saya sangat tertarik untuk berkontribusi di $company.\n\nTerima kasih banyak atas waktu dan perhatikannya. Semoga $hrName sehat selalu.',
      ),
      FollowupTemplate(
        title: 'Follow-Up Formal Email (Bahasa Indonesia)',
        language: 'ID',
        content:
            'Yth. Tim Rekrutmen / $hrName $company,\n\nSemoga pesan ini menemui Anda dalam keadaan baik.\n\nPerkenalkan saya [Nama Anda]. Saya telah mengajukan lamaran pekerjaan untuk posisi $position pada tanggal $dateStr melalui [Sumber Loker].\n\nMelalui email ini, saya ingin menanyakan kabar terbaru mengenai proses seleksi lamaran saya. Saya tetap memiliki ketertarikan yang tinggi untuk bisa bergabung dan memberikan dampak positif bagi $company.\n\nApabila ada dokumen atau informasi tambahan yang diperlukan, dengan senang hati saya akan menyediakannya.\n\nTerima kasih atas waktu dan kesempatan yang diberikan.\n\nHormat saya,\n[Nama Anda]\n[Nomor HP/WA]',
      ),
      FollowupTemplate(
        title: 'Follow-Up English WhatsApp',
        language: 'EN',
        content:
            'Dear $hrName,\n\nHope you are doing well!\n\nMy name is [Your Name]. I applied for the *$position* role at *$company* on $dateStr.\n\nI am following up to kindly check if there are any updates regarding my application. I remain very enthusiastic about the opportunity to join your team.\n\nThank you for your time and consideration!',
      ),
      FollowupTemplate(
        title: 'Follow-Up English Email',
        language: 'EN',
        content:
            'Dear Hiring Team / $hrName at $company,\n\nI hope this email finds you well.\n\nMy name is [Your Name], and I submitted my application for the $position role on $dateStr.\n\nI am writing to express my continued interest in the position and to respectfully inquire about the timeline for the next steps in the hiring process.\n\nPlease let me know if you require any additional information or documents from my side.\n\nThank you very much for your time and consideration.\n\nBest regards,\n[Your Name]\n[Your Phone]',
      ),
    ];
  }

  static Future<bool> launchWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> launchEmail(
    String email,
    String subject,
    String body,
  ) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
