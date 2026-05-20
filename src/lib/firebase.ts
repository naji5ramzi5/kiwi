import { initializeApp, getApps } from 'firebase/app'
import { getMessaging, getToken, onMessage, type Messaging } from 'firebase/messaging'
import { getAnalytics } from 'firebase/analytics'

const firebaseConfig = {
  apiKey:            import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain:        import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId:         import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket:     import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId:             import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId:     import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
}

// Avoid duplicate initialization in HMR
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0]

// Analytics (web only)
export const analytics = typeof window !== 'undefined' ? getAnalytics(app) : null

// Messaging (web only, requires HTTPS or localhost)
let messaging: Messaging | null = null
try {
  messaging = getMessaging(app)
} catch {
  console.warn('[Firebase] Messaging not available in this environment')
}
export { messaging }

// ── Request Permission & Get FCM Token ──
export async function requestNotificationPermission(): Promise<string | null> {
  if (!messaging) return null

  try {
    const permission = await Notification.requestPermission()
    if (permission !== 'granted') {
      console.warn('[FCM] Notification permission denied')
      return null
    }

    const token = await getToken(messaging, {
      vapidKey: import.meta.env.VITE_FIREBASE_VAPID_KEY,
    })

    console.log('[FCM] Token:', token)
    return token
  } catch (err) {
    console.error('[FCM] Error getting token:', err)
    return null
  }
}

// ── Listen to foreground messages ──
export function onForegroundMessage(callback: (payload: {
  notification?: { title?: string; body?: string; icon?: string }
  data?: Record<string, string>
}) => void) {
  if (!messaging) return () => {}
  return onMessage(messaging, callback)
}

export default app
