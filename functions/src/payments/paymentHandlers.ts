import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const creditDineCoins = functions.https.onCall(async (data, context) => {
  const { targetType, targetId, amount, reason } = data;

  if (!context.auth?.token?.role || context.auth.token.role !== "supervisor") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only supervisors may credit dine coins."
    );
  }

  const ref =
    targetType === "user"
      ? admin.firestore().collection("users").doc(targetId)
      : admin.firestore().collection("establishments").doc(targetId);

  await ref.update({
    dineCoinsBalance: admin.firestore.FieldValue.increment(amount),
  });

  await admin.firestore().collection("dinecoin_ledger").add({
    targetType,
    targetId,
    amount,
    type: "credit",
    reason,
    supervisorId: context.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { status: "success" };
});
