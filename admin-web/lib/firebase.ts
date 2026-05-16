import { initializeApp, getApps } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyAEyipri8FOQ9KojuAhqAhU8Aaie1LH5Po',
  authDomain: 'eacademia-app.firebaseapp.com',
  projectId: 'eacademia-app',
  storageBucket: 'eacademia-app.firebasestorage.app',
  messagingSenderId: '893780722918',
  appId: '1:893780722918:web:e6f718bf82f5b05c046727',
};

const app = getApps().length ? getApps()[0] : initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
