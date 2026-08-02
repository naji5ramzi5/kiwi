// Supabase Edge Function URL for FCM notifications
export const FCM_FUNCTION_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/send-notification`;

// Supabase
export const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
export const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;
