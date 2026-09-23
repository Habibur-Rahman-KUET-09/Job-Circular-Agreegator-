# Firebase Setup Guide

আপনার Job Circular Aggregator project কে Firebase এর সাথে সংযুক্ত করার জন্য এই গাইডটি অনুসরণ করুন।

## Prerequisites

1. **Google Account** - Firebase project এর জন্য
2. **Firebase CLI** - ইনস্টল করুন:
   ```bash
   npm install -g firebase-tools
   ```
3. **Node.js 14+** - Cloud Functions এর জন্য

## Step 1: Firebase Project তৈরি করুন

### Google Cloud Console এ:

1. [Firebase Console](https://console.firebase.google.com/) এ যান
2. **"Create a project"** ক্লিক করুন
3. Project name লিখুন (e.g., "job-circular-aggregator")
4. Analytics enable করুন
5. **"Create project"** ক্লিক করুন

### ২-৩ মিনিট পর, প্রজেক্ট তৈরি হয়ে যাবে।

## Step 2: Firebase CLI Login করুন

```bash
firebase login
```

এটি আপনার ব্রাউজার খুলবে, সেখানে লগইন করুন।

## Step 3: Project Configure করুন

```bash
cd /path/to/job-circular-aggregator
firebase init
```

প্রশ্ন এভাবে উত্তর দিন:

```
? Are you ready to proceed? (Y/n) → Y
? Which Firebase features do you want to set up for this directory? 
  ✔ Firestore Database
  ✔ Functions
  ✔ Emulators (optional for local testing)
  
? Select a default Firebase project for this directory: 
  → job-circular-aggregator (যা আপনি তৈরি করেছেন)

? What language would you like to use to write Cloud Functions?
  → TypeScript

? Do you want to use ESLint to catch probable bugs and enforce style?
  → Yes

? Do you want to install dependencies now?
  → Yes

? Set up the Realtime Database emulator? (y/N)
  → N

? Set up the Pub/Sub emulator? (y/N)
  → N
```

## Step 4: Firestore Database তৈরি করুন

Firebase Console এ:

1. **Firestore Database** এ যান
2. **"Create database"** ক্লিক করুন
3. **"Start in production mode"** নির্বাচন করুন
4. Region: **asia-south1** (ঢাকা এর কাছাকাছি) নির্বাচন করুন
5. **"Create"** ক্লিক করুন

## Step 5: Firestore Security Rules Deploy করুন

```bash
firebase deploy --only firestore:rules
```

এটি `firestore.rules` ফাইল ডিপ্লয় করবে।

## Step 6: Firestore Indexes তৈরি করুন

```bash
firebase deploy --only firestore:indexes
```

এটি `firestore.indexes.json` এ defined সব composite indexes তৈরি করবে।

## Step 7: Firebase Admin SDK Setup করুন (Python এর জন্য)

1. Firebase Console → **Project Settings** → **Service Accounts**
2. **"Generate new private key"** ক্লিক করুন
3. JSON ফাইল ডাউনলোড করুন
4. আপনার project root এ রাখুন (নাম: `firebase-credentials.json`)
5. `.gitignore` এ যোগ করুন:
   ```
   firebase-credentials.json
   .env
   ```

## Step 8: Environment Setup করুন

```bash
cd scrapers
cp .env.example .env
```

`.env` এ এডিট করুন:

```
FIREBASE_CREDENTIALS_PATH=../firebase-credentials.json
PDF_DIRECTORY=./newspapers
```

## Step 9: Cloud Functions Setup করুন

```bash
cd functions
npm install
```

এটি সব dependencies ইনস্টল করবে।

## Step 10: Local Testing (Optional)

Emulator দিয়ে local এ test করতে:

```bash
firebase emulators:start
```

এটি Firestore, Functions, এবং Pub/Sub emulators চালু করবে।

## Step 11: Deploy Cloud Functions

যখন সবকিছু ready হয়ে যাবে:

```bash
firebase deploy --only functions
```

এটি deploy করবে:
- `sendNotifications` functions
- `runScrapers` functions (scheduled)
- Other notification functions

## Step 12: Deploy সবকিছু

সব একসাথে deploy করতে:

```bash
firebase deploy
```

এটি deploy করবে:
- Firestore Rules
- Indexes
- Cloud Functions

## Enable Required APIs

Firebase Console → APIs & Services এ enable করুন:

1. **Cloud Pub/Sub API** (for scheduled functions)
2. **Cloud Firestore API** (already enabled usually)
3. **Cloud Functions API** (already enabled usually)
4. **Firebase Cloud Messaging API** (for notifications)

## Test Scraper Integration

```bash
cd scrapers
python run_scrapers.py --mode dry-run
```

এটি test করবে:
- Firebase connection
- Job scraping
- Firestore ingestion
- Duplicate detection

## Troubleshooting

### "Project not found" error

```bash
firebase use --add
```

এবং আপনার project select করুন।

### "Permission denied" on Firestore

নিশ্চিত করুন:
1. Firestore Database created আছে
2. Security rules deployed আছে
3. Service account credentials সঠিক আছে

### Functions deploy error

```bash
cd functions
npm install
firebase deploy --only functions --debug
```

### Index creation slow

Composite indexes বড় collection এ creation time লাগতে পারে (কয়েক ঘণ্টা)। Firebase Console এ progress দেখুন।

## Project Structure

```
job-circular-aggregator/
├── firebase.json                 # Firebase CLI config
├── firestore.rules              # Firestore security rules
├── firestore.indexes.json       # Composite indexes
├── .firebaserc                  # Project reference
├── functions/
│   ├── index.ts
│   ├── sendNotifications.ts
│   ├── runScrapers.ts
│   ├── package.json
│   └── tsconfig.json
├── scrapers/
│   ├── requirements.txt
│   ├── base_scraper.py
│   ├── bdjobs_scraper.py
│   ├── newspaper_scraper.py
│   ├── firestore_ingestion.py
│   ├── run_scrapers.py
│   └── firebase-credentials.json (add this, don't commit)
└── lib/
    └── (Flutter app code)
```

## Useful Firebase CLI Commands

```bash
# Firestore management
firebase firestore:delete <collection>  # Delete collection
firebase firestore:indexes              # List all indexes

# Functions
firebase functions:list                 # List deployed functions
firebase functions:delete <name>        # Delete a function
firebase functions:log                  # View function logs

# Emulators
firebase emulators:start                # Start local emulators
firebase emulators:export ./backup      # Export data
firebase emulators:import ./backup      # Import data

# Deployment
firebase deploy --only firestore:rules  # Rules only
firebase deploy --only firestore:indexes # Indexes only
firebase deploy --only functions        # Functions only
firebase deploy --only firestore        # Firestore (rules + indexes)
firebase deploy                         # Everything
```

## Cost Considerations

Free tier এ monthly:
- **Firestore**: 50,000 reads, 20,000 writes, 20,000 deletes
- **Cloud Functions**: 2 million invocations
- **Cloud Pub/Sub**: 10GB messages

Scraper চালু করার সময়:
- ৫০০ jobs × ৭ days = ৩,৫০০ reads/week (~500/day)
- Daily scraper = ~1,000 writes/day
- Notifications = ~50,000 reads/month

Free tier এ comfortable থাকবে। Larger scale এ Blaze plan এ switch করুন।

## Next Steps

1. ✅ Firebase project তৈরি
2. ✅ Firestore database এবং rules
3. ✅ Cloud Functions deployed
4. 🔜 Flutter app Firebase configure করুন
5. 🔜 Python scrapers activate করুন
6. 🔜 Test notifications এবং scheduling

---

**Note**: `.firebaserc` এ `job-circular-aggregator` project ID কে আপনার actual Firebase project ID দিয়ে replace করুন।

Generated with [Claude Code](https://claude.ai/code)
