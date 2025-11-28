import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

export const onAuthUserCreate = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const now = admin.firestore.FieldValue.serverTimestamp();

  await db.collection("users").doc(uid).set({
    userId: uid,
    email: user.email,
    phone: user.phoneNumber,
    displayName: user.displayName,
    role: "customer",
    dineCoinsBalance: 0,
    createdAt: now
  }, { merge: true });
});
