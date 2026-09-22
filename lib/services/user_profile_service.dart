import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

class UserProfileService {
  final FirebaseFirestore _firestore;

  UserProfileService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Create or update user profile
  Future<void> saveProfile(UserProfile profile) async {
    try {
      await _usersCollection.doc(profile.userId).set(
        profile.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  // Get user profile
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Create new user profile (on registration)
  Future<void> createProfile(String userId, String fullName, String email) async {
    try {
      final profile = UserProfile(
        userId: userId,
        fullName: fullName,
        email: email,
        createdAt: DateTime.now(),
      );
      await saveProfile(profile);
    } catch (e) {
      throw Exception('Failed to create profile: $e');
    }
  }

  // Update profile name and basic info
  Future<void> updateBasicInfo({
    required String userId,
    String? fullName,
    String? phone,
    String? bio,
    String? profilePhotoUrl,
    String? currentPosition,
    int? yearsOfExperience,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (fullName != null) updates['fullName'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;
      if (profilePhotoUrl != null) updates['profilePhotoUrl'] = profilePhotoUrl;
      if (currentPosition != null) updates['currentPosition'] = currentPosition;
      if (yearsOfExperience != null) updates['yearsOfExperience'] = yearsOfExperience;

      await _usersCollection.doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update basic info: $e');
    }
  }

  // Update skills
  Future<void> updateSkills(String userId, List<String> skills) async {
    try {
      await _usersCollection.doc(userId).update({
        'skills': skills,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update skills: $e');
    }
  }

  // Update job preferences
  Future<void> updateJobPreferences({
    required String userId,
    List<String>? preferredLocations,
    List<String>? preferredJobTypes,
    List<String>? preferredIndustries,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (preferredLocations != null) updates['preferredLocations'] = preferredLocations;
      if (preferredJobTypes != null) updates['preferredJobTypes'] = preferredJobTypes;
      if (preferredIndustries != null) updates['preferredIndustries'] = preferredIndustries;

      await _usersCollection.doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update job preferences: $e');
    }
  }

  // Update resume URL
  Future<void> updateResumeUrl(String userId, String resumeUrl) async {
    try {
      await _usersCollection.doc(userId).update({
        'resumeUrl': resumeUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update resume: $e');
    }
  }

  // Update cover letter template
  Future<void> updateCoverLetterTemplate(String userId, String template) async {
    try {
      await _usersCollection.doc(userId).update({
        'coverLetterTemplate': template,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update cover letter template: $e');
    }
  }

  // Update social links
  Future<void> updateSocialLinks({
    required String userId,
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (linkedinUrl != null) updates['linkedinUrl'] = linkedinUrl;
      if (githubUrl != null) updates['githubUrl'] = githubUrl;
      if (portfolioUrl != null) updates['portfolioUrl'] = portfolioUrl;

      await _usersCollection.doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update social links: $e');
    }
  }

  // Update notification preference
  Future<void> updateNotificationPreference(String userId, bool enabled) async {
    try {
      await _usersCollection.doc(userId).update({
        'notificationsEnabled': enabled,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update notification preference: $e');
    }
  }

  // Update language preference
  Future<void> updateLanguagePreference(String userId, String language) async {
    try {
      await _usersCollection.doc(userId).update({
        'preferredLanguage': language,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update language preference: $e');
    }
  }

  // Update application statistics (called when application status changes)
  Future<void> updateApplicationStats(
    String userId,
    int totalApplications,
    int successCount,
  ) async {
    try {
      await _usersCollection.doc(userId).update({
        'totalApplications': totalApplications,
        'successCount': successCount,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update application statistics: $e');
    }
  }

  // Watch user profile in real-time
  Stream<UserProfile?> watchProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // Delete user profile
  Future<void> deleteProfile(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}
