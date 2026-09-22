import 'package:uuid/uuid.dart';

enum JobType { fullTime, partTime, contract, temporary, internship, freelance }

enum JobCategory {
  it,
  finance,
  healthcare,
  education,
  sales,
  marketing,
  operations,
  hr,
  construction,
  manufacturing,
  service,
  other
}

class Job {
  final String id;
  final String title;
  final String company;
  final String description;
  final String location;
  final JobType jobType;
  final JobCategory category;
  final List<String> requiredSkills;
  final int? minYearsExperience;
  final int? maxYearsExperience;
  final String? salaryMin;
  final String? salaryMax;
  final String? salaryCurrency;
  final String source; // URL to original job posting
  final String platform; // e.g., 'linkedin', 'bdjobs', 'govt', etc.
  final DateTime postedDate;
  final DateTime? deadline;
  final DateTime createdAt;
  final int viewCount;
  final int applicationCount;
  final bool isActive;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.jobType,
    required this.category,
    required this.requiredSkills,
    this.minYearsExperience,
    this.maxYearsExperience,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'BDT',
    required this.source,
    required this.platform,
    required this.postedDate,
    this.deadline,
    required this.createdAt,
    this.viewCount = 0,
    this.applicationCount = 0,
    this.isActive = true,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      jobType: JobType.values.byName(json['jobType'] as String),
      category: JobCategory.values.byName(json['category'] as String),
      requiredSkills: List<String>.from(json['requiredSkills'] as List),
      minYearsExperience: json['minYearsExperience'] as int?,
      maxYearsExperience: json['maxYearsExperience'] as int?,
      salaryMin: json['salaryMin'] as String?,
      salaryMax: json['salaryMax'] as String?,
      salaryCurrency: json['salaryCurrency'] as String? ?? 'BDT',
      source: json['source'] as String,
      platform: json['platform'] as String,
      postedDate: DateTime.parse(json['postedDate'] as String),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      viewCount: json['viewCount'] as int? ?? 0,
      applicationCount: json['applicationCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'company': company,
    'description': description,
    'location': location,
    'jobType': jobType.name,
    'category': category.name,
    'requiredSkills': requiredSkills,
    'minYearsExperience': minYearsExperience,
    'maxYearsExperience': maxYearsExperience,
    'salaryMin': salaryMin,
    'salaryMax': salaryMax,
    'salaryCurrency': salaryCurrency,
    'source': source,
    'platform': platform,
    'postedDate': postedDate.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'viewCount': viewCount,
    'applicationCount': applicationCount,
    'isActive': isActive,
  };

  Job copyWith({
    String? id,
    String? title,
    String? company,
    String? description,
    String? location,
    JobType? jobType,
    JobCategory? category,
    List<String>? requiredSkills,
    int? minYearsExperience,
    int? maxYearsExperience,
    String? salaryMin,
    String? salaryMax,
    String? salaryCurrency,
    String? source,
    String? platform,
    DateTime? postedDate,
    DateTime? deadline,
    DateTime? createdAt,
    int? viewCount,
    int? applicationCount,
    bool? isActive,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      description: description ?? this.description,
      location: location ?? this.location,
      jobType: jobType ?? this.jobType,
      category: category ?? this.category,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      minYearsExperience: minYearsExperience ?? this.minYearsExperience,
      maxYearsExperience: maxYearsExperience ?? this.maxYearsExperience,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      source: source ?? this.source,
      platform: platform ?? this.platform,
      postedDate: postedDate ?? this.postedDate,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
