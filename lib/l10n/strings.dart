import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/application.dart';
import '../models/job.dart';
import '../utils/bangla_utils.dart';
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
  String get approveAll => _t('সব অনুমোদন', 'Approve all');
  String get approveAllTitle => _t('সব চাকরি অনুমোদন করবেন?', 'Approve all jobs?');
  String approveAllMessage(int n) => _t(
      '$nটি চাকরি একসাথে অনুমোদিত হবে এবং সবার feed-এ দেখাবে।',
      '$n jobs will be approved at once and appear in everyone\'s feed.');
  String allJobsApproved(int n) => _t('$nটি চাকরি অনুমোদিত হয়েছে', '$n jobs approved');
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

  // ---- Account screen ----
  String get myAccount => _t('আমার অ্যাকাউন্ট', 'My account');
  String get changePassword => _t('পাসওয়ার্ড পরিবর্তন', 'Change password');
  String get currentPassword => _t('বর্তমান পাসওয়ার্ড', 'Current password');
  String get newPassword => _t('নতুন পাসওয়ার্ড', 'New password');
  String get passwordChanged => _t('পাসওয়ার্ড পরিবর্তন হয়েছে', 'Password changed');
  String get language => _t('ভাষা', 'Language');
  String get languageName => _t('বাংলা', 'English');
  String get howItWorks => _t('কীভাবে কাজ করে', 'How it works');
  String get sopTitle => _t('বিস্তারিত নিয়মকানুন (SOP)', 'Detailed guide (SOP)');
  String get deleteAccount => _t('অ্যাকাউন্ট মুছে ফেলুন', 'Delete account');
  String get deleteAccountSubtitle =>
      _t('আপনার প্রোফাইল ও লগইন স্থায়ীভাবে মুছে যাবে', 'Your profile and login will be permanently deleted');
  String get deleteAccountConfirmTitle => _t('অ্যাকাউন্ট মুছে ফেলবেন?', 'Delete your account?');
  String get deleteAccountConfirmMessage => _t(
      'আপনার প্রোফাইল, সংরক্ষিত চাকরি ও আবেদনের তালিকা স্থায়ীভাবে মুছে যাবে। এটি আর ফেরত আনা যাবে না।',
      'Your profile, saved jobs and applications will be permanently deleted. This cannot be undone.');
  String get confirmWithPassword => _t('নিশ্চিত করতে পাসওয়ার্ড দিন', 'Enter your password to confirm');
  String get reloginRequired =>
      _t('নিরাপত্তার জন্য একবার লগআউট করে আবার লগইন করুন, তারপর চেষ্টা করুন।',
          'For security, sign out and sign in again, then retry.');
  String get markApplied => _t('আমার আবেদনে যোগ করুন', 'Add to my applications');
  String get alreadyInApplications => _t('আমার আবেদনে আছে', 'In my applications');
  String get addedToApplications => _t('আমার আবেদনে যোগ হয়েছে', 'Added to my applications');
  String get noJobsFound => _t('কোনো চাকরি পাওয়া যায়নি। নতুন চাকরি দেখতে নিচে টানুন।', 'No jobs found. Pull down to refresh.');
  String get addJob => _t('চাকরি যোগ করুন', 'Add job');
  String get enterValidNumber => _t('সঠিক সংখ্যা দিন', 'Enter a valid number');
  String get requiredField => _t('এই ঘরটি পূরণ করুন', 'This field is required');

  // ---- How it works ----
  List<(String, String)> get howItWorksSteps => [
        (
          _t('চাকরি আসে প্রতি ৩ ঘণ্টায়', 'Jobs arrive every 3 hours'),
          _t('প্রতি ৩ ঘণ্টা পরপর bdjobs ও অ্যাডমিনের যোগ করা ওয়েবসাইট থেকে নতুন চাকরি স্বয়ংক্রিয়ভাবে যোগ হয় এবং সরাসরি তালিকায় দেখায়।',
              'Every 3 hours new jobs are collected from bdjobs and the websites admins added, and appear in the list right away.'),
        ),
        (
          _t('খুঁজুন ও ফিল্টার করুন', 'Search and filter'),
          _t('উপরের সার্চ বক্সে লিখুন, বিভাগের চিপ চাপুন, আর ফিল্টার বাটনে ধরন, এলাকা, অভিজ্ঞতা বা শেষ তারিখ অনুযায়ী বাছাই করুন।',
              'Type in the search box, tap a category chip, and use Filters for job type, location, experience or deadline.'),
        ),
        (
          _t('বিস্তারিত দেখে আবেদন করুন', 'Open a job and apply'),
          _t('চাকরিতে ট্যাপ করলে পূর্ণ বিজ্ঞপ্তি (দায়িত্ব, যোগ্যতা, সুযোগ-সুবিধা) আসবে। "এখনই আবেদন করুন" চাপলে মূল বিজ্ঞপ্তি অ্যাপের ভেতরেই খুলবে।',
              'Tap a job for the full circular (responsibilities, requirements, benefits). "Apply now" opens the original posting inside the app.'),
        ),
        (
          _t('সংরক্ষণ করুন', 'Save jobs'),
          _t('পরে দেখার জন্য চাকরি সংরক্ষণ করুন; সব পাবেন অ্যাকাউন্ট › সংরক্ষিত চাকরি-তে।',
              'Save jobs for later; find them under Account › Saved jobs.'),
        ),
        (
          _t('আবেদনের হিসাব রাখুন', 'Track applications'),
          _t('অ্যাকাউন্ট › আমার আবেদন-এ প্রতিটি আবেদনের অবস্থা (আবেদন করা, সাক্ষাৎকার, নির্বাচিত) হালনাগাদ করুন।',
              'Under Account › My applications, update each application\'s status (applied, interview, selected).'),
        ),
        (
          _t('হাতে যোগ করা চাকরি যাচাই হয়', 'Hand-entered jobs are reviewed'),
          _t('রিক্রুটার বা মডারেটর হাতে চাকরি যোগ করলে অ্যাডমিন/মডারেটর অনুমোদন দেওয়ার পরই সবাই দেখতে পায়।',
              'Jobs added by hand by a recruiter or moderator appear for everyone only after an admin or moderator approves them.'),
        ),
      ];

  // ---- Add job form ----
  String get jobTitleLabel => _t('পদের নাম', 'Job title');
  String get companyLabel => _t('প্রতিষ্ঠান', 'Company');
  String get descriptionLabel => _t('বিবরণ', 'Description');
  String get jobTypeLabelText => _t('চাকরির ধরন', 'Job type');
  String get applyLinkHint => _t('https:// দিয়ে শুরু হওয়া লিংক', 'A link starting with https://');
  String get enterValidLink => _t('সঠিক লিংক দিন (https://...)', 'Enter a valid link (https://...)');
  String get pickDeadline => _t('শেষ তারিখ বেছে নিন', 'Pick a deadline');
  String get salaryLabel => _t('বেতন (ঐচ্ছিক)', 'Salary (optional)');
  String get minExperienceLabel => _t('ন্যূনতম অভিজ্ঞতা (বছর)', 'Min experience (years)');
  String get submitForReview => _t('যাচাইয়ের জন্য জমা দিন', 'Submit for review');
  String get jobSubmittedForReview =>
      _t('চাকরি জমা হয়েছে; অনুমোদনের পর সবাই দেখতে পাবে', 'Job submitted; everyone will see it once approved');

  // ---- Job sources (admin) ----
  String get jobSources => _t('জব সোর্স', 'Job sources');
  String get jobSourcesSubtitle => _t('নতুন ওয়েবসাইট থেকে চাকরি আনুন', 'Collect jobs from more websites');
  String get jobSourcesIntro => _t(
      'চালু থাকা প্রতিটি সোর্স থেকে প্রতি ৩ ঘণ্টায় চাকরি আনা হয়। নতুন সোর্স যোগ করতে + চাপুন, ওয়েবসাইটের লিংক দিন, "খুঁজে দিন" চাপুন, তারপর "পরীক্ষা করুন" দিয়ে দেখে নিন ঠিকমতো চাকরি আসছে কি না।',
      'Jobs are collected from every enabled source every 3 hours. Tap + to add one: enter the site\'s job list link, tap "Detect", then "Test" to check that the right jobs come through.');
  String get noJobSources => _t('এখনো কোনো সোর্স যোগ করা হয়নি', 'No sources added yet');
  String get addJobSource => _t('সোর্স যোগ করুন', 'Add source');
  String get editJobSource => _t('সোর্স সম্পাদনা', 'Edit source');
  String get sourceNameLabel => _t('ওয়েবসাইটের নাম', 'Website name');
  String get sourceListUrlLabel => _t('চাকরির তালিকার লিংক', 'Job list link');
  String get itemSelectorLabel => _t('প্রতিটি চাকরির সিলেক্টর', 'Selector for each job');
  String get itemSelectorHelp =>
      _t('যেমন div.job-card — পাতার প্রতিটি চাকরির বক্স', 'e.g. div.job-card — the box around each job on the page');
  String get optionalSelectors => _t('ঐচ্ছিক সিলেক্টর (বক্সের ভেতরে)', 'Optional selectors (inside the box)');
  String get optionalSelectorsHelp => _t(
      'খালি রাখলে বক্সের প্রথম লিংকটি পদের নাম ও আবেদনের লিংক হিসেবে ধরা হবে।',
      'Left empty, the box\'s first link is used as the job title and apply link.');
  String get titleSelectorLabel => _t('পদের নাম', 'Job title');
  String get companySelectorLabel => _t('প্রতিষ্ঠান', 'Company');
  String get locationSelectorLabel => _t('স্থান', 'Location');
  String get deadlineSelectorLabel => _t('শেষ তারিখ', 'Deadline');
  String get linkSelectorLabel => _t('আবেদনের লিংক', 'Apply link');
  String get sourceEnabled => _t('চালু', 'Enabled');
  String get detectSelector => _t('খুঁজে দিন', 'Detect');
  String get testSource => _t('পরীক্ষা করুন', 'Test');
  String get selectorNotDetected => _t(
      'নিজে থেকে খুঁজে পাওয়া যায়নি; সিলেক্টর হাতে লিখুন', 'Could not detect it; enter the selector yourself');
  String selectorDetected(String selector) => _t('পাওয়া গেছে: $selector', 'Found: $selector');
  String previewCount(int n) => _t('$nটি চাকরি পাওয়া গেছে', '$n jobs found');
  String get previewEmpty => _t(
      'কোনো চাকরি পাওয়া যায়নি। সিলেক্টর ঠিক আছে কি না দেখুন; কিছু সাইট JavaScript দিয়ে তালিকা বানায়, সেগুলো থেকে এভাবে আনা যায় না।',
      'No jobs found. Check the selector; some sites build their list with JavaScript and can\'t be read this way.');
  String previewFailed(String error) => _t('পাতাটি পড়া যায়নি: $error', 'Could not read the page: $error');
  String get testBeforeSaving => _t('সংরক্ষণের আগে "পরীক্ষা করুন" চাপুন', 'Tap "Test" before saving');
  String get sourceSaved => _t('সোর্স সংরক্ষিত হয়েছে; পরের রানে চাকরি আসবে', 'Source saved; jobs arrive on the next run');
  String get deleteSourceTitle => _t('সোর্স মুছবেন?', 'Delete source?');
  String get deleteSourceMessage => _t(
      'এই সোর্স থেকে আর চাকরি আনা হবে না। আগে আনা চাকরিগুলো থেকে যাবে।',
      'No more jobs will be collected from it. Jobs already collected stay.');
  String get notRunYet => _t('এখনো চালানো হয়নি', 'Not run yet');
  String lastRun(String when, int count) => _t('শেষ রান: $when · $countটি চাকরি', 'Last run: $when · $count jobs');

  // ---- Job list filters ----
  String get allCategories => _t('সব', 'All');
  String get filters => _t('ফিল্টার', 'Filters');
  String get searchJobsField => _t('পদ, প্রতিষ্ঠান বা স্থান খুঁজুন', 'Search title, company or place');
  String jobCount(int n) => _t('${number(n)}টি চাকরি', '$n jobs');
  String showJobs(int n) => _t('${number(n)}টি চাকরি দেখুন', 'Show $n jobs');
  String get clearFilters => _t('ফিল্টার মুছুন', 'Clear filters');
  String get sortBy => _t('সাজানো', 'Sort by');
  String get sortNewest => _t('নতুন আগে', 'Newest first');
  String get sortDeadline => _t('শেষ তারিখ আগে', 'Deadline first');
  String get experienceFilter => _t('অভিজ্ঞতা', 'Experience');
  String get anyOption => _t('যেকোনো', 'Any');
  String get fresher => _t('ফ্রেশার', 'Fresher');
  String upToYears(int n) => _t('${number(n)} বছর পর্যন্ত', 'Up to $n years');
  String get postedWithin => _t('প্রকাশিত', 'Posted');
  String get postedToday => _t('আজ', 'Today');
  String lastDays(int n) => _t('গত ${number(n)} দিন', 'Last $n days');
  String get closingSoon => _t('শিগগিরই শেষ (৭ দিনের মধ্যে)', 'Closing soon (within 7 days)');
  String get salaryMentioned => _t('বেতন উল্লেখ আছে', 'Salary mentioned');
  String get showExpired => _t('মেয়াদোত্তীর্ণ চাকরিও দেখান', 'Also show expired jobs');
  String daysLeft(int n) => n <= 0 ? _t('আজ শেষ দিন', 'Last day today') : _t('${number(n)} দিন বাকি', '$n days left');
  String get expired => _t('মেয়াদ শেষ', 'Expired');
  String get noJobsMatchFilters =>
      _t('এই ফিল্টারে কোনো চাকরি নেই। ফিল্টার বদলে দেখুন।', 'No jobs match these filters. Try changing them.');

  /// Digits in the current language.
  String number(int n) => _bn ? BanglaMonths.toBanglaDigits(n) : '$n';

  // ---- Job details ----
  String detailSection(String key) => switch (key) {
        'responsibilities' => _t('কাজের বিবরণ ও দায়িত্ব', 'Job context & responsibilities'),
        'education' => _t('শিক্ষাগত যোগ্যতা', 'Education'),
        'experience' => _t('অভিজ্ঞতা', 'Experience'),
        'requirements' => _t('অন্যান্য যোগ্যতা', 'Additional requirements'),
        'benefits' => _t('সুযোগ-সুবিধা', 'Compensation & benefits'),
        'process' => _t('নিয়োগ প্রক্রিয়া', 'Recruitment process'),
        'company' => _t('প্রতিষ্ঠান সম্পর্কে', 'About the company'),
        _ => key,
      };
  String get vacancies => _t('পদসংখ্যা', 'Vacancies');
  String get workplace => _t('কর্মস্থল', 'Workplace');
  String get companyAddress => _t('ঠিকানা', 'Address');
  String get website => _t('ওয়েবসাইট', 'Website');
  String yearsRange(int? min, int? max) {
    if (min != null && max != null) return _t('${number(min)}–${number(max)} বছর', '$min–$max years');
    if (min != null) return _t('কমপক্ষে ${number(min)} বছর', 'At least $min years');
    return _t('সর্বোচ্চ ${number(max ?? 0)} বছর', 'Up to ${max ?? 0} years');
  }
  String get fullCircularOnSite => _t(
      'এই চাকরির পূর্ণ বিজ্ঞপ্তি এখনো আনা হয়নি। মূল ওয়েবসাইটে দেখুন।',
      'The full circular for this job hasn\'t been fetched yet. See it on the original website.');
  String get viewOriginal => _t('মূল বিজ্ঞপ্তি দেখুন', 'View original circular');
}

