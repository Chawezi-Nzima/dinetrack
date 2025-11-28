import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const createOperatorProfile = functions.https.onCall(async (data, context) => {
  const { uid, name, phone, email } = data;

  if (!uid) {
    throw new functions.https.HttpsError("invalid-argument", "Missing uid.");
  }

  await admin.firestore().collection("operators").doc(uid).set({
    ownerId: uid,
    name,
    phone,
    email,
    supervisorApproved: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { status: "success", message: "Operator profile created." };
});
