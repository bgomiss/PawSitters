// Push notifications for Paw Sitters.
//
// Each user's device tokens live in fcmTokens/{uid}.tokens (written by the app).
// These triggers send a notification when someone receives a message, an
// application (or a decision on theirs), or a review, and drop tokens that
// Firebase Cloud Messaging reports as no longer valid.

const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 5 });

const db = admin.firestore();

async function notifyUser(uid, title, body, data = {}) {
  if (!uid) return;
  const ref = db.collection("fcmTokens").doc(uid);
  const snapshot = await ref.get();
  const tokens = (snapshot.exists && snapshot.get("tokens")) || [];
  if (tokens.length === 0) return;

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    apns: { payload: { aps: { sound: "default" } } },
  });

  const invalid = [];
  response.responses.forEach((result, index) => {
    const code = result.error && result.error.code;
    if (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-registration-token") {
      invalid.push(tokens[index]);
    }
  });
  if (invalid.length > 0) {
    await ref.update({ tokens: admin.firestore.FieldValue.arrayRemove(...invalid) });
  }
  logger.info(`Notified ${uid}: ${response.successCount} sent, ${invalid.length} stale tokens removed`);
}

function preview(text, max = 120) {
  if (!text) return "";
  return text.length > max ? `${text.slice(0, max - 1)}…` : text;
}

// Messages are stored twice (messages/{sender}/{receiver} and messages/{receiver}/{sender});
// only the receiver's copy triggers a notification.
exports.onNewMessage = onDocumentCreated("messages/{ownerId}/{otherId}/{messageId}", async (event) => {
  const message = event.data && event.data.data();
  if (!message || event.params.ownerId !== message.receiverId) return;
  const body = message.messageType === "image" ? "📷 Photo" : preview(message.content);
  await notifyUser(message.receiverId, message.senderName || "New message", body, {
    type: "message",
    senderId: message.senderId || "",
  });
});

exports.onApplicationWritten = onDocumentWritten("applications/{applicationId}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  if (!after || (before && before.status === after.status)) return;
  const data = { type: "application", applicationId: event.params.applicationId };

  if (after.status === "pending") {
    // New application, or re-applying after withdrawing: tell the listing owner.
    await notifyUser(after.listingOwnerId, "New application",
      `${after.applicantName || "Someone"} applied to “${after.listingTitle}”`, data);
  } else if (after.status === "accepted" || after.status === "declined") {
    // The owner decided: tell the applicant.
    const accepted = after.status === "accepted";
    await notifyUser(after.applicantId, accepted ? "Application accepted 🎉" : "Application declined",
      `${after.listingOwnerName || "The owner"} ${accepted ? "accepted" : "declined"} your application for “${after.listingTitle}”`,
      data);
  }
});

exports.onNewReview = onDocumentCreated("reviews/{reviewId}", async (event) => {
  const review = event.data && event.data.data();
  if (!review) return;
  await notifyUser(review.revieweeId, "You got a new review",
    `${review.reviewerName || "Someone"} rated you ${"★".repeat(review.rating || 0)}`, { type: "review" });
});

// MARK: - Moderation
//
// New reports notify the moderators listed in config/moderation.adminUids,
// so objectionable content can be handled within 24 hours.

exports.onNewReport = onDocumentCreated("reports/{reportId}", async (event) => {
  const report = event.data && event.data.data();
  if (!report) return;
  logger.warn(`New report ${event.params.reportId}: ${report.targetType} ${report.targetId} (${report.reason})`);
  const config = await db.collection("config").doc("moderation").get();
  const admins = (config.exists && config.get("adminUids")) || [];
  await Promise.all(admins.map((uid) => notifyUser(uid, "New report to review",
    `${report.reason} – ${report.targetType}`, { type: "report", reportId: event.params.reportId })));
});

// MARK: - Account deletion
//
// Called by the app's "Delete account" button with the user's ID token.
// Removes everything that belongs to the user, then the Auth account itself.

const BUCKET_PATH = /\/o\/([^?]+)/;

/** Storage object path for a Firebase download URL, or null for other URLs. */
function storagePath(url) {
  const match = typeof url === "string" && url.includes("firebasestorage") ? url.match(BUCKET_PATH) : null;
  return match ? decodeURIComponent(match[1]) : null;
}

async function deleteQuery(query) {
  const snapshot = await query.get();
  await Promise.all(snapshot.docs.map((doc) => doc.ref.delete()));
  return snapshot.docs;
}

exports.deleteAccount = onRequest({ cors: false }, async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send({ error: "Use POST" });
    return;
  }
  const header = req.get("Authorization") || "";
  let uid;
  try {
    uid = (await admin.auth().verifyIdToken(header.replace(/^Bearer /, ""))).uid;
  } catch (error) {
    res.status(401).send({ error: "Not signed in" });
    return;
  }

  const bucket = admin.storage().bucket();
  const files = new Set([`profile_images/${uid}.jpg`]);

  // Profile (stored under the user's role collection).
  for (const collection of ["sitters", "owners"]) {
    const ref = db.collection(collection).doc(uid);
    const snapshot = await ref.get();
    if (snapshot.exists) {
      const imagePath = storagePath(snapshot.get("profileImageUrl"));
      if (imagePath) files.add(imagePath);
      await ref.delete();
    }
  }

  // Listings and their photos.
  for (const collection of ["ownersListings", "sittersListings"]) {
    const listings = await deleteQuery(db.collection(collection).where("ownerId", "==", uid));
    for (const listing of listings) {
      for (const url of listing.get("imageUrls") || []) {
        const path = storagePath(url);
        if (path) files.add(path);
      }
    }
  }

  // Applications, reviews, favorites and push tokens.
  await deleteQuery(db.collection("applications").where("applicantId", "==", uid));
  await deleteQuery(db.collection("applications").where("listingOwnerId", "==", uid));
  await deleteQuery(db.collection("reviews").where("reviewerId", "==", uid));
  await deleteQuery(db.collection("reviews").where("revieweeId", "==", uid));
  await db.collection("favorites").doc(uid).delete();
  await db.collection("blocks").doc(uid).delete();
  await db.collection("fcmTokens").doc(uid).delete();

  // Conversations: the user's own copy and the other people's copies of them.
  const userMessagesRef = db.collection("messages").doc(uid);
  for (const conversation of await userMessagesRef.listCollections()) {
    const messages = await deleteQuery(conversation);
    for (const message of messages) {
      if (message.get("messageType") === "image" && message.get("senderId") === uid) {
        const path = storagePath(message.get("content"));
        if (path) files.add(path);
      }
    }
    await deleteQuery(db.collection("messages").doc(conversation.id).collection(uid));
    await db.collection("recent_messages").doc(conversation.id).collection("messages").doc(uid).delete();
  }
  await userMessagesRef.delete();
  await deleteQuery(db.collection("recent_messages").doc(uid).collection("messages"));
  await db.collection("recent_messages").doc(uid).delete();

  await Promise.all([...files].map((path) => bucket.file(path).delete({ ignoreNotFound: true })));
  await admin.auth().deleteUser(uid);
  logger.info(`Deleted account ${uid} and ${files.size} storage files`);
  res.status(200).send({ deleted: true });
});
