import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// This Cloud Function orchestrates job scrapers and ingest results into Firestore
// Deploy with: firebase deploy --only functions

const db = admin.firestore();

// Trigger: Run job scrapers daily at 6:00 AM (Asia/Dhaka)
// This allows jobs to be processed and approved before peak user hours
export const runScrapersDaily = functions.pubsub
  .schedule("every day 06:00")
  .timeZone("Asia/Dhaka")
  .onRun(async (context) => {
    try {
      console.log("Starting scheduled job scraper run");

      // Record scraper run in Firestore for monitoring
      const runRecord = {
        timestamp: admin.firestore.Timestamp.now(),
        status: "running",
        jobsProcessed: 0,
        jobsInserted: 0,
        errorCount: 0,
      };

      const runRef = await db.collection("scraperRuns").add(runRecord);

      try {
        // Call external scraper service or Cloud Task
        // For now, we'll create placeholder logic that can be extended

        // In production, this would:
        // 1. Trigger a Cloud Run service running the Python scrapers
        // 2. Wait for completion
        // 3. Update the database with results

        const scrapedJobs = await triggerScraperService();

        if (scrapedJobs && scrapedJobs.length > 0) {
          // Process and store scraped jobs
          const stats = await processScrapedJobs(scrapedJobs);

          // Update run record
          await runRef.update({
            status: "completed",
            jobsProcessed: scrapedJobs.length,
            jobsInserted: stats.inserted,
            jobsDuplicate: stats.duplicates,
            errorCount: stats.errors,
            completedAt: admin.firestore.Timestamp.now(),
          });

          console.log(
            `Scraper run complete. Inserted: ${stats.inserted}, Duplicates: ${stats.duplicates}`
          );
        } else {
          await runRef.update({
            status: "no_jobs_found",
            completedAt: admin.firestore.Timestamp.now(),
          });
        }
      } catch (error) {
        console.error("Error during scraper run:", error);
        await runRef.update({
          status: "failed",
          errorMessage: String(error),
          failedAt: admin.firestore.Timestamp.now(),
        });
      }

      return null;
    } catch (error) {
      console.error("Error in runScrapersDaily:", error);
      return null;
    }
  });

// Trigger: Auto-approve pending jobs from trusted sources
// Runs 2 hours after scraper (at 08:00 AM)
export const autoApproveTrustedJobs = functions.pubsub
  .schedule("every day 08:00")
  .timeZone("Asia/Dhaka")
  .onRun(async (context) => {
    try {
      console.log("Starting auto-approval of trusted jobs");

      // Define trusted sources (manually added jobs from recruiters)
      const trustedSources = ["internal", "verified_recruiter"];

      // Find pending jobs from trusted sources
      const pendingSnapshot = await db
        .collection("jobs")
        .where("status", "==", "pending")
        .where("source", "in", trustedSources)
        .limit(100)
        .get();

      let approvedCount = 0;

      // Approve each job
      const batch = db.batch();
      for (const doc of pendingSnapshot.docs) {
        batch.update(doc.ref, {
          status: "approved",
          updatedAt: admin.firestore.Timestamp.now(),
        });
        approvedCount++;
      }

      if (approvedCount > 0) {
        await batch.commit();
        console.log(`Auto-approved ${approvedCount} jobs from trusted sources`);
      }

      return null;
    } catch (error) {
      console.error("Error in autoApproveTrustedJobs:", error);
      return null;
    }
  });

// Trigger: Clean up expired job listings weekly
export const cleanupExpiredJobs = functions.pubsub
  .schedule("every sunday 02:00")
  .timeZone("Asia/Dhaka")
  .onRun(async (context) => {
    try {
      console.log("Starting cleanup of expired jobs");

      const ninetyDaysAgo = new Date();
      ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

      // Find jobs past their deadline by 90+ days
      const expiredSnapshot = await db
        .collection("jobs")
        .where("deadline", "<=", ninetyDaysAgo)
        .where("status", "==", "approved")
        .limit(1000)
        .get();

      let deletedCount = 0;

      // Delete each expired job
      const batch = db.batch();
      for (const doc of expiredSnapshot.docs) {
        batch.delete(doc.ref);
        deletedCount++;
      }

      if (deletedCount > 0) {
        await batch.commit();
        console.log(`Deleted ${deletedCount} expired jobs`);
      }

      return null;
    } catch (error) {
      console.error("Error in cleanupExpiredJobs:", error);
      return null;
    }
  });

// Callable function: Trigger scrapers on-demand (admin only)
export const triggerScrapersOnDemand = functions.https.onCall(
  async (data, context) => {
    // Check admin role
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User not authenticated"
      );
    }

    try {
      const userDoc = await db.collection("users").doc(context.auth.uid).get();
      const role = userDoc.data()?.role;

      if (role !== "admin" && role !== "moderator") {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only admins and moderators can trigger scrapers"
        );
      }

      // Create run record
      const runRecord = {
        timestamp: admin.firestore.Timestamp.now(),
        status: "running",
        triggeredBy: context.auth.uid,
        manual: true,
      };

      const runRef = await db.collection("scraperRuns").add(runRecord);

      try {
        const scrapedJobs = await triggerScraperService();

        if (scrapedJobs && scrapedJobs.length > 0) {
          const stats = await processScrapedJobs(scrapedJobs);

          await runRef.update({
            status: "completed",
            jobsProcessed: scrapedJobs.length,
            jobsInserted: stats.inserted,
            jobsDuplicate: stats.duplicates,
            errorCount: stats.errors,
            completedAt: admin.firestore.Timestamp.now(),
          });

          return {
            success: true,
            message: `Scraped and processed ${scrapedJobs.length} jobs`,
            stats: stats,
          };
        } else {
          await runRef.update({
            status: "no_jobs_found",
            completedAt: admin.firestore.Timestamp.now(),
          });

          return {
            success: true,
            message: "No jobs found during scraping",
          };
        }
      } catch (error) {
        await runRef.update({
          status: "failed",
          errorMessage: String(error),
          failedAt: admin.firestore.Timestamp.now(),
        });

        throw new functions.https.HttpsError(
          "internal",
          `Scraper failed: ${String(error)}`
        );
      }
    } catch (error) {
      console.error("Error in triggerScrapersOnDemand:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to trigger scrapers"
      );
    }
  }
);

// Helper function: Trigger external scraper service
async function triggerScraperService(): Promise<any[]> {
  // This is a placeholder that should be implemented to call your scraper service
  // In production, this would:
  // 1. Call a Cloud Run service running the Python scrapers
  // 2. Or invoke a Cloud Task that manages the scraper
  // 3. Or directly import and run scraper modules

  // For now, return empty array (to be implemented)
  console.log("Triggering external scraper service...");
  return [];
}

// Helper function: Process scraped jobs
async function processScrapedJobs(jobs: any[]): Promise<any> {
  const stats = {
    inserted: 0,
    duplicates: 0,
    errors: 0,
  };

  const batch = db.batch();
  let batchCount = 0;

  for (const job of jobs) {
    try {
      // Check for duplicates
      const duplicate = await findDuplicate(job);

      if (duplicate) {
        stats.duplicates++;
      } else {
        // Add new job
        const jobData = {
          ...job,
          status: "pending",
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
        };

        const docRef = db.collection("jobs").doc();
        batch.set(docRef, jobData);
        stats.inserted++;
        batchCount++;

        // Firestore batch limit is 500
        if (batchCount >= 490) {
          await batch.commit();
          batchCount = 0;
        }
      }
    } catch (error) {
      console.error(`Error processing job ${job.title}:`, error);
      stats.errors++;
    }
  }

  // Commit remaining batch
  if (batchCount > 0) {
    await batch.commit();
  }

  return stats;
}

// Helper function: Find duplicate job
async function findDuplicate(job: any): Promise<any> {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const matches = await db
      .collection("jobs")
      .where("source", "==", job.source)
      .where("company", "==", job.company)
      .where("createdAt", ">=", sevenDaysAgo)
      .limit(5)
      .get();

    // Check for similar titles (basic similarity check)
    for (const doc of matches.docs) {
      const existing = doc.data();
      if (calculateSimilarity(job.title, existing.title) > 0.85) {
        return doc;
      }
    }

    return null;
  } catch (error) {
    console.error("Error finding duplicate:", error);
    return null;
  }
}

// Helper function: Calculate string similarity (Levenshtein-like)
function calculateSimilarity(str1: string, str2: string): number {
  const longer = str1.length > str2.length ? str1 : str2;
  const shorter = str1.length > str2.length ? str2 : str1;

  if (longer.length === 0) {
    return 1.0;
  }

  const editDistance = levenshteinDistance(longer, shorter);
  return (longer.length - editDistance) / longer.length;
}

// Helper function: Calculate Levenshtein distance
function levenshteinDistance(str1: string, str2: string): number {
  const matrix: number[][] = [];

  for (let i = 0; i <= str2.length; i++) {
    matrix[i] = [i];
  }

  for (let j = 0; j <= str1.length; j++) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= str2.length; i++) {
    for (let j = 1; j <= str1.length; j++) {
      if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j] + 1
        );
      }
    }
  }

  return matrix[str2.length][str1.length];
}
