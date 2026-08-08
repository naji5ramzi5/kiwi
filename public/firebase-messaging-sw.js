importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCE4WX7pdUsiqghBpDz9jfc0mLCbsfcGZI",
  authDomain: "fresh-enterprise.firebaseapp.com",
  projectId: "fresh-enterprise",
  storageBucket: "fresh-enterprise.firebasestorage.app",
  messagingSenderId: "214305510491",
  appId: "1:214305510491:web:fe1e3ce1100ea92bec5b7e"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title || 'Fresh';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/kiwi-logo.jpg',
    badge: '/kiwi-logo.jpg',
    vibrate: [200, 100, 200],
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const urlToOpen = event.notification.data?.url || '/';
  event.waitUntil(clients.openWindow(urlToOpen));
});
