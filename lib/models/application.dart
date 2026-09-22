enum ApplicationStatus {
  draft,
  submitted,
  viewed,
  shortlisted,
  interviewScheduled,
  interviewed,
  selected,
  rejected,
  withdrawn,
  onHold
}

class Application {
  final String id;
  final String userId;
  final String jobId;
  final String jobTitle;
  final String company;
  final ApplicationStatus status;
  final DateTime appliedDate;
  final DateTime? lastUpdated;
  final String? notes;
  final String? coverLetter;
  final String? cvUsed;
  final List<String> documents; // URLs to any additional documents
  final String? callbackPhone;
  final String? callbackEmail;
  final String? callbackWebsite;
  final DateTime? interviewDate;
  final String? interviewTime;
  final String? interviewLocation;
  final String? interviewType; // e.g., 'phone', 'video', 'in-person'
  final String? interviewNotes;
  final String? outcome;
  final String? rejectionReason;

  const Application({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.status,
    required this.appliedDate,
    this.lastUpdated,
    this.notes,
    this.coverLetter,
    this.cvUsed,
    this.documents = const [],
    this.callbackPhone,
    this.callbackEmail,
    this.callbackWebsite,
    this.interviewDate,
    this.interviewTime,
    this.interviewLocation,
    this.interviewType,
    this.interviewNotes,
    this.outcome,
    this.rejectionReason,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as String,
      userId: json['userId'] as String,
      jobId: json['jobId'] as String,
      jobTitle: json['jobTitle'] as String,
      company: json['company'] as String,
      status: ApplicationStatus.values.byName(json['status'] as String),
      appliedDate: DateTime.parse(json['appliedDate'] as String),
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated'] as String) : null,
      notes: json['notes'] as String?,
      coverLetter: json['coverLetter'] as String?,
      cvUsed: json['cvUsed'] as String?,
      documents: List<String>.from(json['documents'] as List? ?? []),
      callbackPhone: json['callbackPhone'] as String?,
      callbackEmail: json['callbackEmail'] as String?,
      callbackWebsite: json['callbackWebsite'] as String?,
      interviewDate: json['interviewDate'] != null ? DateTime.parse(json['interviewDate'] as String) : null,
      interviewTime: json['interviewTime'] as String?,
      interviewLocation: json['interviewLocation'] as String?,
      interviewType: json['interviewType'] as String?,
      interviewNotes: json['interviewNotes'] as String?,
      outcome: json['outcome'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'jobId': jobId,
    'jobTitle': jobTitle,
    'company': company,
    'status': status.name,
    'appliedDate': appliedDate.toIso8601String(),
    'lastUpdated': lastUpdated?.toIso8601String(),
    'notes': notes,
    'coverLetter': coverLetter,
    'cvUsed': cvUsed,
    'documents': documents,
    'callbackPhone': callbackPhone,
    'callbackEmail': callbackEmail,
    'callbackWebsite': callbackWebsite,
    'interviewDate': interviewDate?.toIso8601String(),
    'interviewTime': interviewTime,
    'interviewLocation': interviewLocation,
    'interviewType': interviewType,
    'interviewNotes': interviewNotes,
    'outcome': outcome,
    'rejectionReason': rejectionReason,
  };

  Application copyWith({
    String? id,
    String? userId,
    String? jobId,
    String? jobTitle,
    String? company,
    ApplicationStatus? status,
    DateTime? appliedDate,
    DateTime? lastUpdated,
    String? notes,
    String? coverLetter,
    String? cvUsed,
    List<String>? documents,
    String? callbackPhone,
    String? callbackEmail,
    String? callbackWebsite,
    DateTime? interviewDate,
    String? interviewTime,
    String? interviewLocation,
    String? interviewType,
    String? interviewNotes,
    String? outcome,
    String? rejectionReason,
  }) {
    return Application(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
      coverLetter: coverLetter ?? this.coverLetter,
      cvUsed: cvUsed ?? this.cvUsed,
      documents: documents ?? this.documents,
      callbackPhone: callbackPhone ?? this.callbackPhone,
      callbackEmail: callbackEmail ?? this.callbackEmail,
      callbackWebsite: callbackWebsite ?? this.callbackWebsite,
      interviewDate: interviewDate ?? this.interviewDate,
      interviewTime: interviewTime ?? this.interviewTime,
      interviewLocation: interviewLocation ?? this.interviewLocation,
      interviewType: interviewType ?? this.interviewType,
      interviewNotes: interviewNotes ?? this.interviewNotes,
      outcome: outcome ?? this.outcome,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
