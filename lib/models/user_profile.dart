class UserProfile {
  final String userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? bio;
  final String? currentPosition;
  final int? yearsOfExperience;
  final List<String> skills;
  final List<String> preferredLocations;
  final List<String> preferredJobTypes; // fullTime, partTime, etc
  final List<String> preferredIndustries;
  final String? resumeUrl;
  final String? coverLetterTemplate;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final bool notificationsEnabled;
  final String preferredLanguage; // 'bn' or 'en'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int totalApplications;
  final int successCount; // interviews or selections

  const UserProfile({
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    this.profilePhotoUrl,
    this.bio,
    this.currentPosition,
    this.yearsOfExperience,
    this.skills = const [],
    this.preferredLocations = const [],
    this.preferredJobTypes = const [],
    this.preferredIndustries = const [],
    this.resumeUrl,
    this.coverLetterTemplate,
    this.linkedinUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.notificationsEnabled = true,
    this.preferredLanguage = 'bn',
    required this.createdAt,
    this.updatedAt,
    this.totalApplications = 0,
    this.successCount = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      bio: json['bio'] as String?,
      currentPosition: json['currentPosition'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      skills: List<String>.from(json['skills'] as List? ?? []),
      preferredLocations: List<String>.from(json['preferredLocations'] as List? ?? []),
      preferredJobTypes: List<String>.from(json['preferredJobTypes'] as List? ?? []),
      preferredIndustries: List<String>.from(json['preferredIndustries'] as List? ?? []),
      resumeUrl: json['resumeUrl'] as String?,
      coverLetterTemplate: json['coverLetterTemplate'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      githubUrl: json['githubUrl'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'bn',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      totalApplications: json['totalApplications'] as int? ?? 0,
      successCount: json['successCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'profilePhotoUrl': profilePhotoUrl,
    'bio': bio,
    'currentPosition': currentPosition,
    'yearsOfExperience': yearsOfExperience,
    'skills': skills,
    'preferredLocations': preferredLocations,
    'preferredJobTypes': preferredJobTypes,
    'preferredIndustries': preferredIndustries,
    'resumeUrl': resumeUrl,
    'coverLetterTemplate': coverLetterTemplate,
    'linkedinUrl': linkedinUrl,
    'githubUrl': githubUrl,
    'portfolioUrl': portfolioUrl,
    'notificationsEnabled': notificationsEnabled,
    'preferredLanguage': preferredLanguage,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'totalApplications': totalApplications,
    'successCount': successCount,
  };

  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? profilePhotoUrl,
    String? bio,
    String? currentPosition,
    int? yearsOfExperience,
    List<String>? skills,
    List<String>? preferredLocations,
    List<String>? preferredJobTypes,
    List<String>? preferredIndustries,
    String? resumeUrl,
    String? coverLetterTemplate,
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
    bool? notificationsEnabled,
    String? preferredLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalApplications,
    int? successCount,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      bio: bio ?? this.bio,
      currentPosition: currentPosition ?? this.currentPosition,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      skills: skills ?? this.skills,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      preferredJobTypes: preferredJobTypes ?? this.preferredJobTypes,
      preferredIndustries: preferredIndustries ?? this.preferredIndustries,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      coverLetterTemplate: coverLetterTemplate ?? this.coverLetterTemplate,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalApplications: totalApplications ?? this.totalApplications,
      successCount: successCount ?? this.successCount,
    );
  }
}
