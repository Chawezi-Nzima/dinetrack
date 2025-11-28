import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const creditDineCoins = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError("unauthenticated", "Login required.");

  if (context.auth.token.role !== "supervisor")
    throw new functions.https.HttpsError("permission-denied", "Supervisor only.");

  const { targetType, targetId, amount } = data;

  const ledgerRef = db.collection("dinecoin_ledger").doc();
  const entry = {
    ledgerId: ledgerRef.id,
    targetType,
    targetId,
    amount,
    type: amount >= 0 ? "credit" : "debit",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    supervisorId: context.auth.uid
  };

  await db.runTransaction(async (tx) => {
    tx.set(ledgerRef, entry);

    const collection = targetType === "user" ? "users" : "establishments";
    const docRef = db.collection(collection).doc(targetId);
    const docSnap = await tx.get(docRef);

    if (!docSnap.exists)
      throw new functions.https.HttpsError("not-found", "Target not found.");

    const prev = docSnap.data()?.dineCoinsBalance || 0;
    tx.update(docRef, { dineCoinsBalance: prev + amount });
  });

  return { success: true };
});
