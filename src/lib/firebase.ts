import { initializeApp, getApps } from 'firebase/app'
import { getMessaging, getToken, onMessage, type Messaging } from 'firebase/messaging'
import { getAnalytics } from 'firebase/analytics'

const firebaseConfig = {
  apiKey:            'AIzaSyCE4WX7pdUsiqghBpDz9jfc0mLCbsfcGZI',
  authDomain:        'fresh-enterprise.firebaseapp.com',
  projectId:         'fresh-enterprise',
  storageBucket:     'fresh-enterprise.firebasestorage.app',
  messagingSenderId: '214305510491',
  appId:             '1:214305510491:web:fe1e3ce1100ea92bec5b7e',
  measurementId:     'G-7SW1QB3GS7',
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
      vapidKey: 'BF7wkvaSEINXTN-SsV_3tcRMZVmsk0_JZdlYXzJXhiDTcagcid0pRQUAktchrsJy7hi5oKd-DwljxeYN-3GGaOc',
    })

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
