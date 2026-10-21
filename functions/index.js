// Push notifications for Paw Sitters.
//
// Each user's device tokens live in fcmTokens/{uid}.tokens (written by the app).
// These triggers send a notification when someone receives a message, an
// application (or a decision on theirs), or a review, and drop tokens that
// Firebase Cloud Messaging reports as no longer valid.

const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
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
