# Job Circular Aggregator (জব সার্কুলার এগ্রিগেটর)

একই জায়গায় সব চাকরির খোঁজ — স্থানীয় নিয়োগ, বিভিন্ন এজেন্সি, প্রতিষ্ঠান সবার চাকরির খোঁজ ট্র্যাক করার অ্যাপ। আবেদন ট্র্যাকিং, বিজ্ঞপ্তি, এবং ক্যারিয়ার ডেভেলপমেন্ট সাপোর্ট। Flutter + Firebase (Auth, Firestore, Storage, Cloud Messaging, Cloud Functions)।

## মূল ফিচার (প্রাথমিক পরিকল্পনা)

### 1. Job Search & Browse
- বিভিন্ন সোর্স থেকে জব সার্কুলার একত্রিত (একাধিক প্ল্যাটফর্ম, এজেন্সি, সরকারি চাকরি)
- ফিল্টার ও সার্চ: দক্ষতা, অভিজ্ঞতা, বেতন, অবস্থান, চাকরির ধরন
- সেভ/বুকমার্ক পছন্দের চাকরি
- রিয়েল-টাইম নোটিফিকেশন ম্যাচিং সার্চ ফিল্টার

### 2. Application Tracking
- কোন কোন চাকরিতে আবেদন করেছেন ট্র্যাক করুন
- আবেদনের স্ট্যাটাস: প্রেরিত, ইন্টারভিউ কল, ইন্টারভিউ সম্পন্ন, নির্বাচিত, অস্বীকৃত
- ইন্টারভিউ তারিখ এবং সময় রিমাইন্ডার
- কলব্যাক নম্বর, ইমেইল, সাইটস সংরক্ষণ
- ইন্টারভিউ প্রস্তুতি নোটস

### 3. User Profile & Preferences
- সিভি/রেজিউমে আপলোড (সাধারণ কভার লেটার টেমপ্লেট)
- পছন্দের খাত, অভিজ্ঞতা, দক্ষতা ট্যাগ
- কর্মজীবনের লক্ষ্য এবং পছন্দের অবস্থান
- অটোমেটিক ম্যাচিং: আপনার প্রোফাইলের সাথে মানানসই চাকরি নোটিফিকেশন

### 4. Interview Preparation
- কমন ইন্টারভিউ প্রশ্ন লাইব্রেরি
- স্যালারি নেগোশিয়েশন টিপস
- চাকরি-নির্দিষ্ট প্রস্তুতি গাইড
- কমিউনিটি অভিজ্ঞতা শেয়ারিং (নির্দিষ্ট কোম্পানির ইন্টারভিউ অভিজ্ঞতা)

### 5. Career Tools
- স্যালারি রেঞ্জ ক্যালকুলেটর
- ক্যারিয়ার পাথ ম্যাপার
- স্কিল এসেসমেন্ট

### 6. Analytics & Reports
- আপনার আবেদন পরিসংখ্যান
- সাফল্যের হার ট্র্যাকিং
- চাকরির ট্রেন্ড (সবচেয়ে বেশি খোঁজা দক্ষতা, জনপ্রিয় অবস্থান)

### 7. Notifications & Reminders
- নতুন চাকরি তাৎক্ষণিক সতর্কতা (ফিল্টার অনুযায়ী)
- ইন্টারভিউ রিমাইন্ডার
- আবেদনের শেষ মেয়াদ নোটিফিকেশন (ডেডলাইনের ২৪ ঘণ্টা আগে)
- নতুন প্রতিষ্ঠানের চাকরি নোটিফিকেশন

## Authentication

- ইমেইল/পাসওয়ার্ড
- ফোন নম্বর (OTP)
- গুগল সাইন-ইন
- লিঙ্কডইন সাইন-ইন (পরবর্তী)

## Data Model

```
users/
  {userId}
    profile: { name, email, phone, resume, skills, experience, preferences }
    settings: { language, notifications, filters }

jobs/
  {jobId}
    title, description, company, location, salary, skills_required
    source: { platform, url, posted_date, deadline }
    category, job_type (full-time, part-time, contract, etc)
    metadata: { view_count, application_count, created_at }

applications/
  {userId}/
    {jobId}
      status, applied_date, last_updated
      interview_details: { date, time, location, type, notes }
      callback: { phone, email, website }
      outcome: { selected, rejected, on_hold }

saved_jobs/
  {userId}/
    {jobId}: { saved_at, notes }

job_sources/
  {sourceId}
    name, url, category, last_sync
```

## Project Structure

```
lib/
  models/          Job, Application, User, SavedJob, Interview
  services/        JobService, ApplicationService, UserService, NotificationService
  providers/       State management (Provider/ChangeNotifier)
  screens/
    - auth/        Login, Register, Password Reset
    - home/        Job feed, search, filter
    - job_details/ Job details, application button, saved jobs
    - applications/ Application tracking, status updates
    - profile/     User profile, preferences, resume upload
    - interview/   Interview prep, resources
  widgets/         Reusable UI components
  l10n/            Bangla/English localization
  utils/           Helpers, formatters
```

## Development Phases

- **Phase 1**: Auth + Job listing + Basic filtering + Application tracking
- **Phase 2**: Interview prep tools + Community features + Analytics
- **Phase 3**: CV builder + Advanced matching + Cloud Functions for scraping/aggregation

## Firebase Setup

Similar to other projects — requires:
- Authentication (Email, Phone, Google)
- Firestore (job listings, applications, user profiles)
- Storage (CV/resume uploads)
- Cloud Messaging (notifications)
- Cloud Functions (scheduled job aggregation, notification triggers)

See baytulmal-collection-tracker README for detailed Firebase setup steps.

## Build & Run

```bash
# Ensure pubspec.lock is generated (from the copied template)
flutter pub get

# Run the app
flutter run

# Build APK
flutter build apk --release
```

## Notes

- Copied structure from baytulmal-collection-tracker as template
- Firebase credentials need to be configured via `flutterfire configure`
- Firestore rules and Cloud Functions for job aggregation to be implemented
