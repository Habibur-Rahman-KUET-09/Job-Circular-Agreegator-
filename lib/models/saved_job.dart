class SavedJob {
  final String id;
  final String userId;
  final String jobId;
  final String jobTitle;
  final String company;
  final String location;
  final DateTime savedAt;
  final String? notes;

  const SavedJob({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.savedAt,
    this.notes,
  });

  factory SavedJob.fromJson(Map<String, dynamic> json) {
    return SavedJob(
      id: json['id'] as String,
      userId: json['userId'] as String,
      jobId: json['jobId'] as String,
      jobTitle: json['jobTitle'] as String,
      company: json['company'] as String,
      location: json['location'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'jobId': jobId,
    'jobTitle': jobTitle,
    'company': company,
    'location': location,
    'savedAt': savedAt.toIso8601String(),
    'notes': notes,
  };

  SavedJob copyWith({
    String? id,
    String? userId,
    String? jobId,
    String? jobTitle,
    String? company,
    String? location,
    DateTime? savedAt,
    String? notes,
  }) {
    return SavedJob(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      location: location ?? this.location,
      savedAt: savedAt ?? this.savedAt,
      notes: notes ?? this.notes,
    );
  }
}
