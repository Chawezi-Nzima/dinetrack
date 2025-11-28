import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Login required.");

  const callerRole = context.auth.token.role;
  if (callerRole !== "supervisor")
    throw new functions.https.HttpsError("permission-denied", "Supervisor only.");

  const { uid, role } = data;
  const allowed = ["supervisor", "operator", "kitchen", "staff", "customer"];
  if (!allowed.includes(role))
    throw new functions.https.HttpsError("invalid-argument", "Invalid role.");

  await admin.auth().setCustomUserClaims(uid, { role });

  await db.collection("users").doc(uid).update({ role });

  return { success: true };
});
