import { useState, useEffect, useCallback, useRef } from 'react'
import { requestNotificationPermission, onForegroundMessage } from './firebase'
import { supabase } from './supabase'

export interface AppNotification {
  id: string
  title: string
  body: string
  type: 'order' | 'driver' | 'inventory' | 'system'
  orderId?: string
  time: Date
  read: boolean
}

// ── Store FCM token in Supabase for this device ──
export async function saveFcmToken(token: string, userId?: string) {
  // نخزن الـ token في Supabase لنستخدمه لاحقاً لإرسال الإشعارات
  const { error } = await supabase
    .from('fcm_tokens')
    .upsert({
      token,
      user_id: userId || null,
      platform: 'web',
      updated_at: new Date().toISOString(),
    }, { onConflict: 'token' })

  if (error) console.warn('[FCM] Could not save token:', error.message)
  else console.log('[FCM] Token saved to Supabase')
}

// ── Main Notifications Hook ──
export function useNotifications() {
  const [notifications, setNotifications] = useState<AppNotification[]>([])
  const [permission, setPermission] = useState<NotificationPermission>('default')
  const [fcmToken, setFcmToken] = useState<string | null>(null)
  const unsubRef = useRef<(() => void) | null>(null)

  const unreadCount = notifications.filter(n => !n.read).length

  const addNotification = useCallback((notif: Omit<AppNotification, 'id' | 'time' | 'read'>) => {
    setNotifications(prev => [{
      ...notif,
      id: crypto.randomUUID(),
      time: new Date(),
      read: false,
    }, ...prev].slice(0, 50)) // احتفظ بآخر 50 إشعار
  }, [])

  const markAllRead = useCallback(() => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })))
  }, [])

  const markRead = useCallback((id: string) => {
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n))
  }, [])

  const clearAll = useCallback(() => setNotifications([]), [])

  // Request FCM permission & setup foreground listener
  const initFCM = useCallback(async () => {
    if (!('Notification' in window)) return
    setPermission(Notification.permission)

    if (Notification.permission === 'granted') {
      const token = await requestNotificationPermission()
      if (token) {
        setFcmToken(token)
        await saveFcmToken(token)
      }

      // Listen to foreground messages
      unsubRef.current = onForegroundMessage((payload) => {
        const title = payload.notification?.title || 'Fresh System'
        const body = payload.notification?.body || ''
        const type = (payload.data?.type as AppNotification['type']) || 'system'

        addNotification({ title, body, type, orderId: payload.data?.orderId })

        // Show browser notification if tab is not focused
        if (document.visibilityState !== 'visible') {
          new Notification(title, { body, icon: '/logo.png', dir: 'rtl' })
        }
      })
    }
  }, [addNotification])

  // Setup Supabase Realtime → trigger notifications for new orders
  useEffect(() => {
    const channel = supabase
      .channel('notifications-orders')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'orders',
      }, (payload) => {
        addNotification({
          title: '🛒 طلب جديد!',
          body: `طلب جديد وصل — ${(payload.new as { delivery_address?: string }).delivery_address || 'عنوان غير محدد'}`,
          type: 'order',
          orderId: (payload.new as { id: string }).id,
        })
      })
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'orders',
      }, (payload) => {
        const newStatus = (payload.new as { status: string }).status
        const criticalStatuses = ['ملغي', 'مكتمل']
        if (criticalStatuses.includes(newStatus)) {
          addNotification({
            title: newStatus === 'ملغي' ? '❌ طلب ملغي' : '✅ طلب مكتمل',
            body: `تم تغيير حالة الطلب إلى: ${newStatus}`,
            type: 'order',
            orderId: (payload.new as { id: string }).id,
          })
        }
      })
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'inventory',
      }, (payload) => {
        const qty = (payload.new as { stock_quantity: number }).stock_quantity
        const min = (payload.new as { min_stock_level: number }).min_stock_level
        if (qty < min) {
          addNotification({
            title: '⚠️ مخزون منخفض',
            body: 'أحد المنتجات وصل إلى الحد الأدنى للمخزون',
            type: 'inventory',
          })
        }
      })
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [addNotification])

  useEffect(() => {
    initFCM()
    return () => { unsubRef.current?.() }
  }, [initFCM])

  return {
    notifications,
    unreadCount,
    permission,
    fcmToken,
    markRead,
    markAllRead,
    clearAll,
    requestPermission: initFCM,
  }
}
