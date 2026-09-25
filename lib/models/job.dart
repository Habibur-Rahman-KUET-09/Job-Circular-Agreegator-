
enum JobType { fullTime, partTime, contract, temporary, internship, freelance }

enum JobCategory {
  govt,
  bank,
  ngo,
  it,
  private,
  finance,
  healthcare,
  education,
  sales,
  marketing,
  operations,
  hr,
  other
}

enum JobSourceType { scraped, manual }

enum JobStatus { pending, approved, rejected }

class Job {
  final String id;
  final String title;
  final String company;
  final String description;
  final String location;
  final JobCategory category;
  final JobType? jobType;
  final List<String>? requiredSkills;
  final int? minYearsExperience;
  final int? maxYearsExperience;
  final String? salaryMin;
  final String? salaryMax;

  // Full circular, when the source provides it: section key
  // (responsibilities, education, experience, requirements, benefits,
  // process, company) -> text with one paragraph or "• item" per line.
  final Map<String, String> details;
  final String? vacancies;
  final String? workplace;
  final String? locationDetail;
  final String? companyAddress;
  final String? companyWebsite;

  // Source info
  final String source; // 'bdjobs', 'chakri.com', 'newspaper:prothomalo', 'manual'
  final JobSourceType sourceType;
  final String? applyLink; // Direct link to apply/original post

  // Temporal info
  final DateTime postedDate;
  final DateTime? deadline;
  final DateTime? scrapedAt; // When app collected it (scraped only)

  // Admin/moderation
  final String? postedBy; // Firebase Auth UID (manual only)
  final JobStatus status; // pending/approved/rejected

  // Metadata
  final DateTime createdAt;
  final int viewCount;
  final int applicationCount;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.category,
    required this.source,
    required this.sourceType,
    required this.postedDate,
    required this.status,
    required this.createdAt,
    this.jobType,
    this.requiredSkills,
    this.minYearsExperience,
    this.maxYearsExperience,
    this.salaryMin,
    this.salaryMax,
    this.details = const {},
    this.vacancies,
    this.workplace,
    this.locationDetail,
    this.companyAddress,
    this.companyWebsite,
    this.applyLink,
    this.deadline,
    this.scrapedAt,
    this.postedBy,
    this.viewCount = 0,
    this.applicationCount = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      category: JobCategory.values.byName(json['category'] as String),
      source: json['source'] as String,
      sourceType: JobSourceType.values.byName(json['sourceType'] as String),
      postedDate: DateTime.parse(json['postedDate'] as String),
      status: JobStatus.values.byName(json['status'] as String? ?? 'approved'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      jobType: JobType.values.asNameMap()[json['jobType']],
      requiredSkills: json['requiredSkills'] != null
          ? List<String>.from(json['requiredSkills'] as List)
          : null,
      minYearsExperience: json['minYearsExperience'] as int?,
      maxYearsExperience: json['maxYearsExperience'] as int?,
      salaryMin: json['salaryMin'] as String?,
      salaryMax: json['salaryMax'] as String?,
      details: {
        for (final e in ((json['details'] as Map?) ?? const {}).entries)
          if (e.value is String && (e.value as String).trim().isNotEmpty) '${e.key}': e.value as String,
      },
      vacancies: json['vacancies'] as String?,
      workplace: json['workplace'] as String?,
      locationDetail: json['jobLocationDetail'] as String?,
      companyAddress: json['companyAddress'] as String?,
      companyWebsite: json['companyWebsite'] as String?,
      applyLink: json['applyLink'] as String?,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      scrapedAt: json['scrapedAt'] != null ? DateTime.parse(json['scrapedAt'] as String) : null,
      postedBy: json['postedBy'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      applicationCount: json['applicationCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'company': company,
    'description': description,
    'location': location,
    'category': category.name,
    'source': source,
    'sourceType': sourceType.name,
    'postedDate': postedDate.toIso8601String(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    if (jobType != null) 'jobType': jobType!.name,
    if (requiredSkills != null) 'requiredSkills': requiredSkills,
    'minYearsExperience': minYearsExperience,
    'maxYearsExperience': maxYearsExperience,
    'salaryMin': salaryMin,
    'salaryMax': salaryMax,
    if (details.isNotEmpty) 'details': details,
    if (vacancies != null) 'vacancies': vacancies,
    if (workplace != null) 'workplace': workplace,
    if (locationDetail != null) 'jobLocationDetail': locationDetail,
    if (companyAddress != null) 'companyAddress': companyAddress,
    if (companyWebsite != null) 'companyWebsite': companyWebsite,
    'applyLink': applyLink,
    'deadline': deadline?.toIso8601String(),
    'scrapedAt': scrapedAt?.toIso8601String(),
    'postedBy': postedBy,
    'viewCount': viewCount,
    'applicationCount': applicationCount,
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
    String? source,
    JobSourceType? sourceType,
    String? applyLink,
    DateTime? postedDate,
    DateTime? deadline,
    DateTime? scrapedAt,
    String? postedBy,
    JobStatus? status,
    DateTime? createdAt,
    int? viewCount,
    int? applicationCount,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      source: source ?? this.source,
      sourceType: sourceType ?? this.sourceType,
      postedDate: postedDate ?? this.postedDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      jobType: jobType ?? this.jobType,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      minYearsExperience: minYearsExperience ?? this.minYearsExperience,
      maxYearsExperience: maxYearsExperience ?? this.maxYearsExperience,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      details: details,
      vacancies: vacancies,
      workplace: workplace,
      locationDetail: locationDetail,
      companyAddress: companyAddress,
      companyWebsite: companyWebsite,
      applyLink: applyLink ?? this.applyLink,
      deadline: deadline ?? this.deadline,
      scrapedAt: scrapedAt ?? this.scrapedAt,
      postedBy: postedBy ?? this.postedBy,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
    );
  }
}
