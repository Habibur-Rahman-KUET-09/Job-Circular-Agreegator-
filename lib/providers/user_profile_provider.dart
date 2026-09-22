import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/index.dart';

class UserProfileProvider extends ChangeNotifier {
  final UserProfileService _userProfileService;
  final String userId;

  UserProfileProvider(this._userProfileService, this.userId);

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProfileComplete =>
      _profile != null &&
      _profile!.email != null &&
      _profile!.yearsOfExperience != null &&
      _profile!.skills.isNotEmpty;

  // Fetch profile
  Future<void> fetchProfile() async {
    _setLoading(true);
    _setError(null);
    try {
      _profile = await _userProfileService.getProfile(userId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create profile
  Future<bool> createProfile(String fullName, String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userProfileService.createProfile(userId, fullName, email);
      await fetchProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update basic info
  Future<bool> updateBasicInfo({
    String? fullName,
    String? phone,
    String? bio,
    String? profilePhotoUrl,
    String? currentPosition,
    int? yearsOfExperience,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userProfileService.updateBasicInfo(
        userId: userId,
        fullName: fullName,
        phone: phone,
        bio: bio,
        profilePhotoUrl: profilePhotoUrl,
        currentPosition: currentPosition,
        yearsOfExperience: yearsOfExperience,
      );
      await fetchProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update skills
  Future<bool> updateSkills(List<String> skills) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userProfileService.updateSkills(userId, skills);
      await fetchProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update job preferences
  Future<bool> updateJobPreferences({
    List<String>? preferredLocations,
    List<String>? preferredJobTypes,
    List<String>? preferredIndustries,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userProfileService.updateJobPreferences(
        userId: userId,
        preferredLocations: preferredLocations,
        preferredJobTypes: preferredJobTypes,
        preferredIndustries: preferredIndustries,
      );
      await fetchProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update resume
  Future<bool> updateResumeUrl(String resumeUrl) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userProfileService.updateResumeUrl(userId, resumeUrl);
      await fetchProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update cover letter template
  Future<bool> updateCoverLetterTemplate(String template) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userProfileService.updateCoverLetterTemplate(userId, template);
      await fetchProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update social links
  Future<bool> updateSocialLinks({
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userProfileService.updateSocialLinks(
        userId: userId,
        linkedinUrl: linkedinUrl,
        githubUrl: githubUrl,
        portfolioUrl: portfolioUrl,
      );
      await fetchProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update notification preference
  Future<bool> updateNotificationPreference(bool enabled) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userProfileService.updateNotificationPreference(userId, enabled);
      await fetchProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update language preference
  Future<bool> updateLanguagePreference(String language) async {
    _setLoading(true);
    _setError(null);
    try {
      await _userProfileService.updateLanguagePreference(userId, language);
      await fetchProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? error) {
    _error = error;
  }
}
