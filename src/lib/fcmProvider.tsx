import { useEffect, useRef, createContext, useContext, type ReactNode } from 'react';
import { supabase } from './supabase';
import { toast } from 'react-hot-toast';

interface FcmContextType {
  getToken: () => Promise<string | null>;
}

const FcmContext = createContext<FcmContextType>({ getToken: async () => null });

export const useFcm = () => useContext(FcmContext);

export const FcmProvider = ({ children }: { children: ReactNode }) => {
  const tokenRef = useRef<string | null>(null);

  const getToken = async (): Promise<string | null> => {
    try {
      // For web, we use the VAPID key approach (Push API)
      // Check if service worker is supported
      if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
        console.log('Push notifications not supported');
        return null;
      }

      // Get the current service worker registration
      const registration = await navigator.serviceWorker.ready;

      // Request permission
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') {
        console.log('Notification permission denied');
        return null;
      }

      // Generate a unique device token for this browser
      // In production, this would come from Firebase Cloud Messaging SDK
      // For now, we generate a unique identifier
      let deviceToken = localStorage.getItem('fcm_device_token');
      if (!deviceToken) {
        deviceToken = `web-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        localStorage.setItem('fcm_device_token', deviceToken);
      }

      tokenRef.current = deviceToken;
      return deviceToken;
    } catch (error) {
      console.error('Error getting FCM token:', error);
      return null;
    }
  };

  const registerToken = async () => {
    try {
      const token = await getToken();
      if (!token) return;

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Store/update token in Supabase
      const { error } = await supabase
        .from('user_fcm_tokens')
        .upsert({
          user_id: user.id,
          token: token,
          device_type: 'web',
        }, { onConflict: 'user_id,token' });

      if (error) {
        // Table might not exist yet or other issue
        console.warn('Could not store FCM token (table may not exist):', error.message);
      }
    } catch (error) {
      console.warn('FCM registration error:', error);
    }
  };

  // Auto-register token on auth state change
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_IN') {
        // Delay to ensure user session is fully established
        setTimeout(registerToken, 1000);
      }
    });

    // Also try on mount if already signed in
    setTimeout(registerToken, 2000);

    return () => subscription.unsubscribe();
  }, []);

  return (
    <FcmContext.Provider value={{ getToken }}>
      {children}
    </FcmContext.Provider>
  );
};

/**
 * Hook to send an FCM notification to a specific user via the edge function.
 * Used by admin panels to notify customers.
 */
export const sendNotification = async (
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
) => {
  try {
    const { error } = await supabase.functions.invoke('send-fcm-notification', {
      body: { userId, title, body, data: data || {} },
    });

    if (error) {
      console.error('Send notification error:', error);
      toast.error('فشل إرسال الإشعار');
      return false;
    }

    return true;
  } catch (error) {
    console.error('Send notification error:', error);
    toast.error('فشل إرسال الإشعار');
    return false;
  }
};
