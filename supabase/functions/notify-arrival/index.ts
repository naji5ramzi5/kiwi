import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    const { order_id } = await req.json();

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 1. Get Order and Customer ID
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('*, profiles(fcm_token)')
      .eq('id', order_id)
      .single();

    if (orderError || !order) throw new Error('Order not found');

    // 2. Prepare Notification
    const fcmToken = order.profiles?.fcm_token;
    
    if (fcmToken) {
      // In a real production app, we would call Firebase FCM API here
      console.log(`Sending ARRIVAL notification to token: ${fcmToken}`);
      
      // We can also insert into our internal notifications table
      await supabase.from('notifications').insert({
        user_id: order.customer_id,
        title: 'لقد وصل المندوب! 🚴',
        body: 'المندوب متواجد الآن عند موقعك، يرجى الاستلام.',
        type: 'arrival',
        data: { order_id }
      });
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Arrival notification sent' }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    )
  }
})
