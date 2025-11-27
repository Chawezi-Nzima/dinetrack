// functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * onAuthUserCreate
 * - Triggered when a new Firebase Auth user is created
 * - Bootstraps users/{uid} doc (role default: 'customer' unless provided via other flow)
 * - Keeps minimal profile to match ERD: userId, name, email, phone, role, createdAt, dineCoinsBalance
 */
export const onAuthUserCreate = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const now = admin.firestore.FieldValue.serverTimestamp();

  const userDoc = {
    userId: uid,
    displayName: user.displayName || null,
    email: user.email || null,
    phone: user.phoneNumber || null,
    role: "customer", // default role
    dineCoinsBalance: 0,
    createdAt: now,
    // optional profile fields
  };

  await db.collection("users").doc(uid).set(userDoc, { merge: true });
  console.log(`Created users/${uid} doc`);
});

/**
 * setUserRole (callable)
 * - Only callable by a user that has the 'supervisor' custom claim
 * - Sets Firebase custom claims for target user and updates users/{uid}.role
 *
 * payload: { uid: string, role: "supervisor"|"operator"|"kitchen"|"staff"|"customer" }
 */
export const setUserRole = functions.https.onCall(async (data, context) => {
  // Security: must be authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Request had no auth context.");
  }

  const callerUid = context.auth.uid;
  // Check caller has supervisor claim
  const callerToken = context.auth.token || {};
  if (!callerToken.role || callerToken.role !== "supervisor") {
    throw new functions.https.HttpsError("permission-denied", "Only supervisors may set roles.");
  }

  const { uid, role } = data as { uid?: string; role?: string };
  if (!uid || !role) {
    throw new functions.https.HttpsError("invalid-argument", "Missing uid or role.");
  }

  const allowedRoles = ["supervisor", "operator", "kitchen", "staff", "customer"];
  if (!allowedRoles.includes(role)) {
    throw new functions.https.HttpsError("invalid-argument", "Role not allowed.");
  }

  // Set custom claims
  await admin.auth().setCustomUserClaims(uid, { role });

  // Update Firestore users doc as canonical role record too
  await db.collection("users").doc(uid).set({ role }, { merge: true });

  return { success: true, uid, role };
});

/**
 * onboardEstablishment (callable)
 * - Supervisor or Operator can create an establishment record.
 * - If created by operator, operator must be in 'operator' role.
 *
 * payload: {
 *  name, type, address, ownerId (operator uid)
 * }
 *
 * Result: creates establishments/{estId}, creates establishments/{estId}/meta and returns estId
 */
export const onboardEstablishment = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required.");
  const callerRole = context.auth.token.role || null;
  if (!callerRole || !(callerRole === "supervisor" || callerRole === "operator")) {
    throw new functions.https.HttpsError("permission-denied", "Only supervisor or operator can onboard.");
  }

  const { name, type, address, ownerId } = data as {
    name?: string;
    type?: string;
    address?: string;
    ownerId?: string;
  };

  if (!name || !type || !ownerId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
  }

  // Optionally check ownerId exists
  const ownerDoc = await db.collection("users").doc(ownerId).get();
  if (!ownerDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Owner user not found.");
  }

  // Create establishment doc
  const estRef = db.collection("establishments").doc();
  const estData = {
    establishmentId: estRef.id,
    name,
    type,
    address: address || null,
    ownerId,
    dineCoinsBalance: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    supervisorApproved: callerRole === "supervisor" ? true : false,
  };

  await estRef.set(estData);

  // Add a basic tables, menuCategory collections placeholder (optional)
  // Example: create empty collections or default category
  await estRef.collection("menuCategories").doc("default").set({
    categoryId: "default",
    name: "Main",
    description: "Default category",
    establishmentId: estRef.id,
  });

  return { success: true, establishmentId: estRef.id };
});

/**
 * creditDineCoins (callable)
 * - Supervisor-only operation to credit/debit DineCoins to users or establishments
 * - Atomic transaction: writes to dinecoin_ledger and updates user's or establishment's balance
 *
 * payload: {
 *   targetType: 'user' | 'establishment',
 *   targetId: string,
 *   amount: number, // positive credit, negative debit
 *   reason?: string
 * }
 */
export const creditDineCoins = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required.");
  const callerRole = context.auth.token.role || null;
  if (!callerRole || callerRole !== "supervisor") {
    throw new functions.https.HttpsError("permission-denied", "Only supervisors can modify DineCoins.");
  }

  const { targetType, targetId, amount, reason } = data as {
    targetType?: string;
    targetId?: string;
    amount?: number;
    reason?: string;
  };

  if (!targetType || !targetId || typeof amount !== "number") {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
  }
  if (!["user", "establishment"].includes(targetType)) {
    throw new functions.https.HttpsError("invalid-argument", "targetType must be user|establishment");
  }

  const ledgerRef = db.collection("dinecoin_ledger").doc();
  const ledgerDoc = {
    ledgerId: ledgerRef.id,
    targetType,
    targetId,
    amount,
    reason: reason || null,
    type: amount >= 0 ? "credit" : "debit",
    supervisorId: context.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Atomic: update balance on target and write ledger entry
  await db.runTransaction(async (tx) => {
    tx.set(ledgerRef, ledgerDoc);

    if (targetType === "user") {
      const userRef = db.collection("users").doc(targetId);
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw new functions.https.HttpsError("not-found", "User not found");
      const prev = userSnap.data()?.dineCoinsBalance || 0;
      const updated = prev + amount;
      tx.update(userRef, { dineCoinsBalance: updated });
    } else {
      const estRef = db.collection("establishments").doc(targetId);
      const estSnap = await tx.get(estRef);
      if (!estSnap.exists) throw new functions.https.HttpsError("not-found", "Establishment not found");
      const prev = estSnap.data()?.dineCoinsBalance || 0;
      const updated = prev + amount;
      tx.update(estRef, { dineCoinsBalance: updated });
    }
  });

  return { success: true, ledgerId: ledgerRef.id };
});

/**
 * Optional helper: markUserAsOperator - convenience wrapper to create operator profile and set role
 * - callable by supervisor
 * payload: { uid, profile: { name, phone, email } }
 */
export const createOperatorProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required.");
  if ((context.auth.token.role || "") !== "supervisor") {
    throw new functions.https.HttpsError("permission-denied", "Only supervisors can create operator profiles.");
  }

  const { uid, profile } = data as { uid?: string; profile?: Record<string, any> };
  if (!uid || !profile) {
    throw new functions.https.HttpsError("invalid-argument", "uid and profile required.");
  }

  // set claims
  await admin.auth().setCustomUserClaims(uid, { role: "operator" });

  // create operator doc in 'operators' collection and ensure users/uid role updated
  await db.collection("users").doc(uid).set({ role: "operator", ...profile }, { merge: true });
  // mirror to operators collection (optional)
  await db.collection("operators").doc(uid).set({
    ownerId: uid,
    name: profile.name || null,
    email: profile.email || null,
    phone: profile.phone || null,
    supervisorApproved: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, uid };
});
