import 'job_application.dart';

class CareerContext {
  final String jobId;
  final String companyName;
  final String position;
  final String status;
  final String? salary;
  final DateTime? nextEventAt;

  const CareerContext({
    required this.jobId,
    required this.companyName,
    required this.position,
    required this.status,
    this.salary,
    this.nextEventAt,
  });

  factory CareerContext.fromJob(JobApplication job) => CareerContext(
    jobId: job.id,
    companyName: job.companyName,
    position: job.position,
    status: job.status,
    salary: job.salaryOffered,
    nextEventAt: job.nextDueAt,
  );

  String get practiceTitle => 'Latihan untuk $position di $companyName';
}
