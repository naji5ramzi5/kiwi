import { supabase } from './supabase'

/**
 * Sends a FCM notification to a user via the edge function.
 * @param userId The user's ID (from auth.users)
 * @param title Notification title
 * @param body Notification body
 * @param data Optional data payload
 */
export const sendFcmNotification = async (
  userId: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
) => {
  try {
    // Call the edge function
    const { data: responseData, error } = await supabase.functions.invoke(
      'send-fcm-notification',
      {
        body: { userId, title, body, data },
      }
    )

    if (error) {
      throw error
    }

    return responseData
  } catch (err) {
    console.error('Failed to send FCM notification:', err)
    throw err
  }
}