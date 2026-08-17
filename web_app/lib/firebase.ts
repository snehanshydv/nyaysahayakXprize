"use client";

import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import type { Auth } from "firebase/auth";

import { getFirestore } from "firebase/firestore";
import type { Firestore } from "firebase/firestore";
import type { FirebaseApp } from "firebase/app";

const firebaseConfig = {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID
};

const isBrowser = typeof window !== "undefined";
const missingConfigKeys = Object.entries(firebaseConfig)
    .filter(([, value]) => typeof value !== "string" || value.length === 0)
    .map(([key]) => key);

const hasConfig = missingConfigKeys.length === 0;

if (isBrowser && !hasConfig) {
    console.error(
        `[Firebase] Missing NEXT_PUBLIC Firebase config keys: ${missingConfigKeys.join(", ")}. Firebase features are disabled.`
    );
}

const app: FirebaseApp | null = isBrowser && hasConfig
    ? (!getApps().length ? initializeApp(firebaseConfig) : getApp())
    : null;

const auth: Auth | null = app
    ? getAuth(app)
    : null;

const db: Firestore | null = app
    ? getFirestore(app)
    : null;

export { app, auth, db };
