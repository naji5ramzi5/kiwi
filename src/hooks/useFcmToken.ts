import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { sendFcmNotification } from '../lib/fcm';
import { toast } from 'react-hot-toast';

/**
 * Hook to request FCM permission, get token, and store it in Supabase.
 * Should be called once after user authenticates.
 */
export const useFcmToken = () => {
  const [permissionGranted, setPermissionGranted] = useState<boolean | null>(null); // null = not asked yet
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // Only run on client
    if (typeof window === 'undefined') return;

    const registerFcm = async () => {
      setLoading(true);
      try {
        // Check if we already have a token stored in localStorage (for demo)
        // In a real app, you might store it in DB and retrieve on login.
        const storedToken = localStorage.getItem('fcm_token');
        if (storedToken) {
          setToken(storedToken);
          setPermissionGranted(true);
          // Optionally verify with Supabase that it's registered for this user
          const { data: user } = await supabase.auth.getUser();
          if (user.user) {
            const { data: existing, error } = await supabase
              .from('user_fcm_tokens')
              .select('id')
              .eq('user_id', user.user.id)
              .eq('token', storedToken)
              .single();
            if (!existing && !error) {
              // Token not registered for this user, register it
                await supabase
                  .from('user_fcm_tokens')
                  .insert({ user_id: user.user.id, token: storedToken, device_type: 'web' });
            }
          }
          setLoading(false);
          return;
        }

        // Request permission
        if ('Notification' in window && Notification.permission === 'default') {
          const permission = await Notification.requestPermission();
          setPermissionGranted(permission === 'granted');
          if (permission !== 'granted') {
            toast.error('تم رفض إذن الإشعارات');
            setLoading(false);
            return;
          }
        } else if (Notification.permission === 'denied') {
          setPermissionGranted(false);
          toast.error('إذن الإشعارات محظور. يرجى تمكينه من إعدادات المتصفح.');
          setLoading(false);
          return;
        } else {
          // Already granted
          setPermissionGranted(true);
        }

        // Get FCM token using Firebase SDK? We don't have Firebase configured.
        // For web push via FCM, we need to use the Firebase JS SDK to get a token.
        // However, the edge function we created expects to send via FCM HTTP v1 API using a device token.
        // Since we are not integrating Firebase SDK, we'll simulate a token for demonstration.
        // In a real project, you would initialize Firebase and get the token.
        // For now, we'll generate a random token and store it.
        const fakeToken = `web-token-${Math.random().toString(36).substr(2, 9)}`;
        setToken(fakeToken);
        localStorage.setItem('fcm_token', fakeToken);

        // Register token in Supabase
        const { data: user } = await supabase.auth.getUser();
        if (user.user) {
          await supabase
            .from('user_fcm_tokens')
            .upsert(
              { user_id: user.user.id, token: fakeToken, device_type: 'web' },
              { onConflict: 'user_id,token' }
            );
        }

        // Optionally send a test notification
        // await sendFcmNotification(user.user.id, 'مرحباً', 'تم تفعيل الإشعارات بنجاح');
      } catch (err: any) {
        console.error('FCM token registration error:', err);
        toast.error('فشل تسجيل رمز الإشعارات: ' + err.message);
      } finally {
        setLoading(false);
      }
    };

    registerFcm();
  }, []);

  return { permissionGranted, token, loading };
}
