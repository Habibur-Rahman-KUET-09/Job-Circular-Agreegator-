import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();

// This Cloud Function sends notifications for job deadlines and application updates
// Deploy with: firebase deploy --only functions

const db = admin.firestore();
const messaging = admin.messaging();

// Trigger: Send deadline reminders for jobs expiring in 7 days
export const sendDeadlineReminders = functions.pubsub
  .schedule("every day 09:00")
  .timeZone("Asia/Dhaka")
  .onRun(async (context) => {
    const now = new Date();
    const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const oneDayFromNow = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);

    try {
      const jobsSnapshot = await db
        .collection("jobs")
        .where("deadline", ">=", oneDayFromNow)
        .where("deadline", "<=", sevenDaysFromNow)
        .where("status", "==", "approved")
        .get();

      for (const jobDoc of jobsSnapshot.docs) {
        const job = jobDoc.data();
        const daysLeft = Math.ceil(
          (new Date(job.deadline).getTime() - now.getTime()) /
            (1000 * 60 * 60 * 24)
        );

        // Send to all users
        const usersSnapshot = await db
          .collection("users")
          .where("notificationsEnabled", "==", true)
          .get();

        const userTokens = [];
        for (const userDoc of usersSnapshot.docs) {
          if (userDoc.data().fcmToken) {
            userTokens.push(userDoc.data().fcmToken);
          }
        }

        if (userTokens.length > 0) {
          const message = {
            notification: {
              title: `${daysLeft} days left to apply`,
              body: `${job.title} at ${job.company}`,
            },
            data: {
              type: "job_deadline",
              jobId: jobDoc.id,
              company: job.company,
              deadline: job.deadline,
            },
            tokens: userTokens,
          };

          try {
            await messaging.sendMulticast(message);
            console.log(`Sent deadline reminder for job: ${jobDoc.id}`);
          } catch (error) {
            console.error(`Error sending reminder for job ${jobDoc.id}:`, error);
          }
        }
      }

      return null;
    } catch (error) {
      console.error("Error in sendDeadlineReminders:", error);
      return null;
    }
  });

// Trigger: Send application status updates
export const sendApplicationStatusUpdate = functions.firestore
  .document("users/{userId}/applications/{applicationId}")
  .onUpdate(async (change, context) => {
    const oldStatus = change.before.data().status;
    const newStatus = change.after.data().status;

    if (oldStatus === newStatus) {
      return null;
    }

    const userId = context.params.userId;
    const application = change.after.data();

    try {
      const userDoc = await db.collection("users").doc(userId).get();
      const userToken = userDoc.data()?.fcmToken;

      if (!userToken) {
        console.log(`No FCM token for user ${userId}`);
        return null;
      }

      const statusMessages: { [key: string]: string } = {
        applied: "Your application has been submitted",
        interviewed: "You have been invited for an interview",
        selected: "Congratulations! You have been selected",
        rejected: "Thank you for your interest",
      };

      const message = {
        notification: {
          title: "Application Status Update",
          body: `${statusMessages[newStatus] || "Status updated"} for ${
            application.jobTitle
          } at ${application.company}`,
        },
        data: {
          type: "application_update",
          jobId: application.jobId,
          status: newStatus,
          applicationId: context.params.applicationId,
        },
        token: userToken,
      };

      await messaging.send(message);
      console.log(`Sent status update for application: ${
        context.params.applicationId
      }`);

      return null;
    } catch (error) {
      console.error("Error in sendApplicationStatusUpdate:", error);
      return null;
    }
  });

// Trigger: Send job match notifications
export const sendJobMatches = functions.pubsub
  .schedule("every 12 hours")
  .timeZone("Asia/Dhaka")
  .onRun(async (context) => {
    try {
      const usersSnapshot = await db
        .collection("users")
        .where("notificationsEnabled", "==", true)
        .get();

      for (const userDoc of usersSnapshot.docs) {
        const user = userDoc.data();
        if (!user.fcmToken) continue;

        // Get user skills and preferences
        const skills = user.skills || [];
        const preferredLocations = user.preferredLocations || [];
        const preferredCategories = user.preferredIndustries || [];

        // Query matching jobs
        let query: FirebaseFirestore.Query = db
          .collection("jobs")
          .where("status", "==", "approved");

        if (preferredLocations.length > 0) {
          query = query.where("location", "in", preferredLocations);
        }

        if (preferredCategories.length > 0) {
          query = query.where("category", "in", preferredCategories);
        }

        const matchingJobs = await query.limit(3).get();

        if (matchingJobs.docs.length > 0) {
          const jobTitles = matchingJobs.docs
            .map((doc) => doc.data().title)
            .join(", ");

          const message = {
            notification: {
              title: "New Job Matches",
              body: `We found ${matchingJobs.docs.length} new jobs that match your profile`,
            },
            data: {
              type: "job_match",
              jobCount: matchingJobs.docs.length.toString(),
            },
            token: user.fcmToken,
          };

          try {
            await messaging.send(message);
            console.log(`Sent job matches to user: ${userDoc.id}`);
          } catch (error) {
            console.error(`Error sending matches to user ${userDoc.id}:`, error);
          }
        }
      }

      return null;
    } catch (error) {
      console.error("Error in sendJobMatches:", error);
      return null;
    }
  });

// Trigger: Clean up FCM tokens for users who uninstall the app
export const cleanupInvalidTokens = functions.firestore
  .document("users/{userId}")
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;
    console.log(`User ${userId} deleted, cleanup complete`);
    return null;
  });

// Helper function to handle failed FCM tokens
export const handleInvalidTokens = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User not authenticated"
      );
    }

    const { invalidTokens } = data;

    if (!Array.isArray(invalidTokens)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invalidTokens must be an array"
      );
    }

    try {
      await db
        .collection("users")
        .doc(context.auth.uid)
        .update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });

      console.log(
        `Deleted invalid FCM tokens for user: ${context.auth.uid}`
      );
      return { success: true };
    } catch (error) {
      console.error("Error handling invalid tokens:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to handle invalid tokens"
      );
    }
  }
);
