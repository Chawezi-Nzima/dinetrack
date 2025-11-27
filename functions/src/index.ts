// functions/src/index.ts

/* === TRIGGERS === */
export { onAuthUserCreate } from "./triggers/onAuthUserCreate";

/* === ROLE / USER MANAGEMENT === */
export { setUserRole } from "./utils/roleUtils";

/* === ONBOARDING === */
export { onboardEstablishment } from "./onboarding/onboardEstablishment";
export { createOperatorProfile } from "./onboarding/createOperatorProfile";

/* === DINECOINS === */
export { creditDineCoins } from "./dinecoins/creditDineCoins";

/* === PAYMENTS (OPTIONAL) === */
export * from "./payments/paymentHandlers";
