importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyB0d9fRqVZ5e0f6b5c4a3d2e1f0a9b8c7d6e5f4",
  authDomain: "fresh-enterprise.firebaseapp.com",
  projectId: "fresh-enterprise",
  messagingSenderId: "112645303767989129446",
  appId: "1:112645303767989129446:web:abc123def456"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title || 'Fresh';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/fresh-icon.png',
    badge: '/fresh-badge.png',
    vibrate: [200, 100, 200],
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const urlToOpen = event.notification.data?.url || '/';
  event.waitUntil(clients.openWindow(urlToOpen));
});
