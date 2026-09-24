import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/application.dart';
import '../models/job.dart';
import 'locale_provider.dart';

/// Every user-facing string in the app, in Bangla and English. Screens read
/// via `Strings.of(context)` (rebuilds on language change through
/// [LocaleProvider]) and pick a getter per piece of text — no ARB/codegen,
/// just a plain class, so adding a string is "add a getter here".
class Strings {
  final AppLanguage lang;
  const Strings(this.lang);

  static Strings of(BuildContext context) {
    final language = context.watch<LocaleProvider>().language;
    return Strings(language);
  }

  /// For event handlers and async callbacks, where [of]'s watch isn't allowed.
  static Strings read(BuildContext context) {
    return Strings(context.read<LocaleProvider>().language);
  }

  bool get _bn => lang == AppLanguage.bn;
  String _t(String bn, String en) => _bn ? bn : en;

  // ---- Common / shared ----
  String get appTitle => _t('সন্ধান', 'Shondhan');
  String get cancel => _t('বাতিল', 'Cancel');
  String get save => _t('সংরক্ষণ করুন', 'Save');
  String get delete => _t('মুছে ফেলুন', 'Delete');
  String get name => _t('নাম', 'Name');
  String get retry => _t('আবার চেষ্টা করুন', 'Retry');
  // ---- Login / sign up (auth/login_screen.dart) ----
  String get loginSignUpTitle => _t('নতুন অ্যাকাউন্ট তৈরি করুন', 'Create a new account');
  String get loginSignInTitle => _t('লগইন করুন', 'Sign in');
  String get loginEmail => _t('ইমেইল', 'Email');
  String get loginPassword => _t('পাসওয়ার্ড', 'Password');
  String get loginConfirmPassword => _t('পাসওয়ার্ড নিশ্চিত করুন', 'Confirm password');
  String get loginForgotPassword => _t('পাসওয়ার্ড ভুলে গেছেন?', 'Forgot password?');
  String get loginSignUpButton => _t('নিবন্ধন করুন', 'Sign up');
  String get loginSignInButton => _t('লগইন', 'Sign in');
  String get loginHaveAccount => _t('আগে থেকেই অ্যাকাউন্ট আছে? লগইন করুন', 'Already have an account? Sign in');
  String get loginNewHere => _t('নতুন এখানে? অ্যাকাউন্ট তৈরি করুন', 'New here? Create an account');
  String get loginOr => _t('অথবা', 'or');
  String get loginWithGoogle => _t('Google দিয়ে চালিয়ে যান', 'Continue with Google');
  String get loginEmailRequired => _t('ইমেইল আবশ্যক', 'Email is required');
  String get loginEmailInvalid => _t('সঠিক ইমেইল দিন', 'Enter a valid email');
  String get loginPasswordRequired => _t('পাসওয়ার্ড আবশ্যক', 'Password is required');
  String get loginPasswordTooShort => _t('কমপক্ষে ৮ অক্ষর দিন', 'Enter at least 8 characters');
  String get loginPasswordNeedsDigit => _t('অন্তত একটি সংখ্যা দিন', 'Include at least one digit');
  String get loginPasswordMismatch => _t('পাসওয়ার্ড মিলছে না', 'Passwords do not match');
  String get loginEnterEmailFirst => _t('আগে ইমেইল ঠিকানা লিখুন', 'Enter your email address first');
  String get loginResetLinkSent => _t('যদি এই ইমেইলে অ্যাকাউন্ট থাকে তাহলে পাসওয়ার্ড রিসেট লিংক পাঠানো হবে', 'If an account exists with this email, a password reset link will be sent');
  String get loginErrorInvalidEmail => _t('ইমেইল ঠিকানাটি সঠিক নয়।', 'That email address is invalid.');
  String get loginErrorUserDisabled => _t('এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে।', 'This account has been disabled.');
  String get loginErrorUserNotFound =>
      _t('এই ইমেইল/পাসওয়ার্ডে কোনো অ্যাকাউন্ট পাওয়া যায়নি।', 'No account found with this email/password.');
  String get loginErrorWrongPassword => _t('পাসওয়ার্ড সঠিক নয়।', 'Incorrect password.');
  String get loginErrorEmailInUse =>
      _t('এই ইমেইল দিয়ে আগে থেকেই একটি অ্যাকাউন্ট আছে।', 'An account already exists with this email.');
  String get loginErrorWeakPassword =>
      _t('পাসওয়ার্ড খুবই দুর্বল — কমপক্ষে ৬ অক্ষর দিন।', 'Password is too weak — use at least 6 characters.');
  String get loginErrorNetwork => _t('ইন্টারনেট সংযোগ পরীক্ষা করুন।', 'Check your internet connection.');
  String get loginErrorTooManyRequests =>
      _t('অনেকবার চেষ্টা করা হয়েছে — একটু পর আবার চেষ্টা করুন।', 'Too many attempts — try again shortly.');
  String get loginErrorGeneric => _t('একটি সমস্যা হয়েছে, আবার চেষ্টা করুন।', 'Something went wrong — try again.');
  String get loginTooManyAttempts =>
      _t('অনেক পাসওয়ার্ড ভুল দেওয়া হয়েছে। অ্যাকাউন্ট ১৫ মিনিটের জন্য লক করা হয়েছে।', 'Too many failed attempts. Account locked for 15 minutes.');
  String loginAccountLockedOut(int minutes) =>
      _t('অ্যাকাউন্ট লক করা আছে। $minutes মিনিট পর আবার চেষ্টা করুন।', 'Account is locked. Try again in $minutes minutes.');
  String loginGoogleSignInFailed(String error) =>
      _t('Google সাইন-ইন ব্যর্থ হয়েছে: $error', 'Google sign-in failed: $error');
  String get loginErrorMissingGoogleToken =>
      _t('Google থেকে আইডি টোকেন পাওয়া যায়নি।', 'Did not receive an ID token from Google.');
  String get loginErrorNoCurrentUser => _t('সাইন-ইন করা নেই।', 'Not signed in.');
  String get loginErrorMissingPassword => _t('পাসওয়ার্ড আবশ্যক।', 'Password is required.');

  // ---- Job Circular Aggregator specific strings ----
  String get filterJobs => _t('চাকরি ফিল্টার করুন', 'Filter Jobs');
  String get searchJobsHint => _t('শিরোনাম, কোম্পানি...', 'Title, company...');
  String get locationHint => _t('শহর বা অঞ্চল', 'City or region');
  String get jobDetails => _t('চাকরির বিবরণ', 'Job Details');
  String get description => _t('বিবরণ', 'Description');
  String get requiredSkills => _t('প্রয়োজনীয় দক্ষতা', 'Required Skills');
  String get source => _t('উৎস', 'Source');
  String get applyLink => _t('আবেদন লিঙ্ক', 'Apply Link');
  String get applyNow => _t('এখনই আবেদন করুন', 'Apply Now');
  String get saveJob => _t('চাকরি সংরক্ষণ করুন', 'Save Job');
  String get jobSaved => _t('চাকরি সংরক্ষিত হয়েছে', 'Job saved');
  String get couldNotLaunchUrl => _t('লিঙ্কটি খোলা যায় না', 'Could not launch URL');
  String get myProfile => _t('আমার প্রোফাইল', 'My Profile');
  String get savedJobs => _t('সংরক্ষিত চাকরি', 'Saved Jobs');
  String get myApplications => _t('আমার আবেদন', 'My Applications');
  String get logout => _t('লগআউট', 'Logout');
  String get confirmLogout => _t('লগআউট নিশ্চিত করুন', 'Confirm Logout');
  String get logoutConfirmation => _t('আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান?', 'Are you sure you want to logout?');
  String postedTime(int daysAgo) => _t('$daysAgo দিন আগে', '$daysAgo days ago');
  String deadline(String date) => _t('সময়সীমা: $date', 'Deadline: $date');
  String get postedDate => _t('পোস্টের তারিখ', 'Posted Date');
  String get experience => _t('অভিজ্ঞতা', 'Experience');
  String get salary => _t('বেতন', 'Salary');
  String get category => _t('বিভাগ', 'Category');
  String get search => _t('অনুসন্ধান', 'Search');
  String get location => _t('অবস্থান', 'Location');
  String get apply => _t('প্রয়োগ করুন', 'Apply');
  String get loginAccount => _t('অ্যাকাউন্ট', 'Account');
  String get errorOccurred => _t('একটি ত্রুটি ঘটেছে', 'An error occurred');
  String get noSavedJobs => _t('কোনো সংরক্ষিত চাকরি নেই', 'No saved jobs');
  String get jobRemoved => _t('চাকরি সরানো হয়েছে', 'Job removed');
  String get noApplications => _t('কোনো আবেদন নেই', 'No applications');
  String get noApplicationsInStatus => _t('এই স্ট্যাটাসে কোনো আবেদন নেই', 'No applications in this status');
  String get fullName => _t('সম্পূর্ণ নাম', 'Full Name');
  String get phone => _t('ফোন', 'Phone');
  String get bio => _t('জীবনী', 'Bio');
  String get currentPosition => _t('বর্তমান পদ', 'Current Position');
  String get yearsOfExperience => _t('অভিজ্ঞতার বছর', 'Years of Experience');
  String get basicInfo => _t('মৌলিক তথ্য', 'Basic Info');
  String get noName => _t('নাম নেই', 'No Name');
  String get noProfileData => _t('কোনো প্রোফাইল ডেটা নেই', 'No profile data');
  String get profileUpdated => _t('প্রোফাইল আপডেট হয়েছে', 'Profile updated');
  String get skillsHint => _t('দক্ষতা যোগ করুন', 'Add skills');
  String get skillsHintExample => _t('উদাহরণ: ফ্লাটার, ডার্ট, ফায়ারবেস', 'Example: Flutter, Dart, Firebase');
  String get notes => _t('নোট', 'Notes');
  String get remove => _t('সরান', 'Remove');
  String savedOn(String date) => _t('সংরক্ষিত: $date', 'Saved: $date');
  String get viewDetails => _t('বিস্তারিত দেখুন', 'View Details');
  String appliedOn(String date) => _t('আবেদন করা হয়েছে: $date', 'Applied: $date');
  String get interviewScheduled => _t('সাক্ষাৎকার নির্ধারিত', 'Interview Scheduled');
  String get updateStatus => _t('স্থিতি আপডেট করুন', 'Update Status');

  // ---- Notification Strings ----
  String get notifications => _t('বিজ্ঞপ্তি', 'Notifications');
  String get notificationSettings => _t('বিজ্ঞপ্তি সেটিংস', 'Notification Settings');
  String get noNotifications => _t('কোনো বিজ্ঞপ্তি নেই', 'No notifications');
  String get markAllAsRead => _t('সবকিছু পড়া হিসেবে চিহ্নিত করুন', 'Mark all as read');
  String get clearAll => _t('সব মুছে ফেলুন', 'Clear all');
  String get clearNotifications => _t('বিজ্ঞপ্তি মুছে ফেলুন', 'Clear Notifications');
  String get clearNotificationsConfirm => _t('আপনি কি নিশ্চিত যে আপনি সমস্ত বিজ্ঞপ্তি মুছে ফেলতে চান?', 'Are you sure you want to clear all notifications?');
  String get enableNotifications => _t('বিজ্ঞপ্তি সক্ষম করুন', 'Enable Notifications');
  String get notificationDesc => _t('চাকরি, আবেদন এবং সময়সীমা সম্পর্কে আপডেট পান', 'Get updates about jobs, applications, and deadlines');
  String get notificationType => _t('বিজ্ঞপ্তি ধরন', 'Notification Type');
  String get jobDeadlineReminders => _t('চাকরির সময়সীমা অনুস্মারক', 'Job Deadline Reminders');
  String get jobDeadlineRemindersDesc => _t('আসন্ন আবেদনের সময়সীমা সম্পর্কে অবহিত থাকুন', 'Stay informed about upcoming application deadlines');
  String get applicationUpdates => _t('আবেদন আপডেট', 'Application Updates');
  String get applicationUpdatesDesc => _t('আপনার আবেদনের অগ্রগতি সম্পর্কে অবহিত থাকুন', 'Get notified about your application progress');
  String get jobMatches => _t('চাকরি ম্যাচ', 'Job Matches');
  String get jobMatchesDesc => _t('আপনার দক্ষতার সাথে নতুন চাকরি পান', 'Get new jobs that match your skills');
  String get dailyDigest => _t('দৈনিক সংক্ষিপ্তসার', 'Daily Digest');
  String get dailyDigestDesc => _t('প্রতিদিন একটি বিজ্ঞপ্তিতে সমস্ত আপডেট পান', 'Get all updates in one notification daily');
  String get notificationTiming => _t('বিজ্ঞপ্তি সময়', 'Notification Timing');
  String get quietHours => _t('নিরব সময়', 'Quiet Hours');
  String get from => _t('থেকে', 'From');
  String get to => _t('পর্যন্ত', 'To');
  String get startTime => _t('শুরুর সময়', 'Start Time');
  String get endTime => _t('শেষ সময়', 'End Time');
  String get notificationsDisabled => _t('বিজ্ঞপ্তি নিষ্ক্রিয় করা হয়েছে। সেগুলি সক্ষম করতে উপরে টগল করুন।', 'Notifications are disabled. Toggle above to enable them.');
  String get tip => _t('টিপ', 'Tip');
  String get notificationTip => _t('নিরব সময়ের বাইরে গুরুত্বপূর্ণ বিজ্ঞপ্তি সর্বদা প্রদর্শিত হয়।', 'Important notifications are always shown outside quiet hours.');

  // ---- Job review (admin/moderator) ----
  String get reviewJobs => _t('চাকরি যাচাই', 'Review jobs');
  String get noPendingJobs => _t('যাচাইয়ের জন্য কোনো চাকরি নেই', 'No jobs waiting for review');
  String get approve => _t('অনুমোদন', 'Approve');
  String get reject => _t('প্রত্যাখ্যান', 'Reject');
  String get jobApproved => _t('চাকরি অনুমোদিত হয়েছে', 'Job approved');
  String get jobRejected => _t('চাকরি বাতিল করা হয়েছে', 'Job rejected');
  String sourceLabel(String source) => _t('উৎস: $source', 'Source: $source');

  // ---- Enum labels ----
  String categoryLabel(JobCategory category) => switch (category) {
        JobCategory.govt => _t('সরকারি', 'Government'),
        JobCategory.bank => _t('ব্যাংক', 'Bank'),
        JobCategory.ngo => _t('এনজিও', 'NGO'),
        JobCategory.it => _t('আইটি', 'IT'),
        JobCategory.private => _t('বেসরকারি', 'Private'),
        JobCategory.finance => _t('অর্থ ও হিসাব', 'Finance'),
        JobCategory.healthcare => _t('স্বাস্থ্যসেবা', 'Healthcare'),
        JobCategory.education => _t('শিক্ষা', 'Education'),
        JobCategory.sales => _t('বিক্রয়', 'Sales'),
        JobCategory.marketing => _t('মার্কেটিং', 'Marketing'),
        JobCategory.operations => _t('অপারেশনস', 'Operations'),
        JobCategory.hr => _t('মানবসম্পদ', 'HR'),
        JobCategory.other => _t('অন্যান্য', 'Other'),
      };

  String jobTypeLabel(JobType type) => switch (type) {
        JobType.fullTime => _t('পূর্ণকালীন', 'Full-time'),
        JobType.partTime => _t('খণ্ডকালীন', 'Part-time'),
        JobType.contract => _t('চুক্তিভিত্তিক', 'Contract'),
        JobType.temporary => _t('অস্থায়ী', 'Temporary'),
        JobType.internship => _t('ইন্টার্নশিপ', 'Internship'),
        JobType.freelance => _t('ফ্রিল্যান্স', 'Freelance'),
      };

  String applicationStatusLabel(ApplicationStatus status) => switch (status) {
        ApplicationStatus.draft => _t('খসড়া', 'Draft'),
        ApplicationStatus.submitted => _t('আবেদন করা হয়েছে', 'Applied'),
        ApplicationStatus.viewed => _t('দেখা হয়েছে', 'Viewed'),
        ApplicationStatus.shortlisted => _t('সংক্ষিপ্ত তালিকায়', 'Shortlisted'),
        ApplicationStatus.interviewScheduled => _t('সাক্ষাৎকার নির্ধারিত', 'Interview scheduled'),
        ApplicationStatus.interviewed => _t('সাক্ষাৎকার হয়েছে', 'Interviewed'),
        ApplicationStatus.selected => _t('নির্বাচিত', 'Selected'),
        ApplicationStatus.rejected => _t('প্রত্যাখ্যাত', 'Rejected'),
        ApplicationStatus.withdrawn => _t('প্রত্যাহার করা হয়েছে', 'Withdrawn'),
        ApplicationStatus.onHold => _t('স্থগিত', 'On hold'),
      };

  String get allApplications => _t('সব', 'All');
  String interviewAt(String date, String? time) =>
      time == null || time.isEmpty ? date : _t('$date, $time', '$date at $time');

  // ---- Relative time ----
  String get justNow => _t('এইমাত্র', 'Just now');
  String minutesAgo(int n) => _t('$n মিনিট আগে', '${n}m ago');
  String hoursAgo(int n) => _t('$n ঘণ্টা আগে', '${n}h ago');
  String daysAgo(int n) => _t('$n দিন আগে', '${n}d ago');

  // ---- Quiet hours dialog ----
  String get quietHoursStartTitle => _t('নিরব সময় শুরু', 'Quiet hours start');
  String get quietHoursEndTitle => _t('নিরব সময় শেষ', 'Quiet hours end');
  String get done => _t('সম্পন্ন', 'Done');
}
