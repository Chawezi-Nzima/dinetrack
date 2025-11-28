import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
const db = admin.firestore();

export const onboardEstablishment = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Login required.");

  const role = context.auth.token.role;
  if (!(role === "supervisor" || role === "operator"))
    throw new functions.https.HttpsError("permission-denied", "Not allowed.");

  const { name, type, address, ownerId } = data;

  const doc = db.collection("establishments").doc();
  await doc.set({
    establishmentId: doc.id,
    name,
    type,
    address,
    ownerId,
    dineCoinsBalance: 0,
    supervisorApproved: role === "supervisor",
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { success: true, establishmentId: doc.id };
});
