// Firebase Cloud Messaging Service Worker
// يجب أن يكون في مجلد public ليعمل من الـ root

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js')
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js')

firebase.initializeApp({
  apiKey:            'AIzaSyCE4WX7pdUsiqghBpDz9jfc0mLCbsfcGZI',
  authDomain:        'fresh-enterprise.firebaseapp.com',
  projectId:         'fresh-enterprise',
  storageBucket:     'fresh-enterprise.firebasestorage.app',
  messagingSenderId: '214305510491',
  appId:             '1:214305510491:web:fe1e3ce1100ea92bec5b7e',
})

const messaging = firebase.messaging()

// معالجة الإشعارات في الخلفية (Background)
messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Background message received:', payload)

  const { title = 'Fresh System', body = '', icon = '/logo.png' } = payload.notification || {}

  self.registration.showNotification(title, {
    body,
    icon,
    badge: '/logo.png',
    tag: payload.data?.orderId || 'fresh-notification',
    data: payload.data,
    actions: payload.data?.orderId
      ? [{ action: 'view', title: 'عرض الطلب' }]
      : [],
    requireInteraction: payload.data?.priority === 'high',
    dir: 'rtl',
    lang: 'ar',
  })
})

// فتح التطبيق عند الضغط على الإشعار
self.addEventListener('notificationclick', (event) => {
  event.notification.close()

  const orderId = event.notification.data?.orderId
  const url = orderId ? `/orders?id=${orderId}` : '/'

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus()
          client.postMessage({ type: 'NAVIGATE', url })
          return
        }
      }
      clients.openWindow(url)
    })
  )
})
