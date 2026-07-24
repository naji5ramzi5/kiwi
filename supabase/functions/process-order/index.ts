import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { orderId, action } = await req.json()

    if (!orderId || !action) {
      throw new Error('Missing orderId or action')
    }

    // Get the order
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('*, profiles(*)')
      .eq('id', orderId)
      .single()

    if (orderError) throw orderError

    switch (action) {
      case 'accept': {
        const { error: updateError } = await supabase.from('orders').update({ status: 'preparing' }).eq('id', orderId)
        if (updateError) throw updateError
        
        // Notify customer
        if (order.customer_id) {
          await supabase.from('notifications').insert({
            user_id: order.customer_id,
            title: 'تم قبول طلبك',
            body: `طلبك #${orderId.toString().substring(0, 5)} قيد التحضير الآن`,
            type: 'order_update',
            order_id: orderId,
          })
        }
        break
      }

      case 'reject': {
        const { error: updateError } = await supabase.from('orders').update({ status: 'rejected' }).eq('id', orderId)
        if (updateError) throw updateError
        
        if (order.customer_id) {
          await supabase.from('notifications').insert({
            user_id: order.customer_id,
            title: 'تم رفض طلبك',
            body: `نعتذر، طلبك #${orderId.toString().substring(0, 5)} تم رفضه`,
            type: 'order_update',
            order_id: orderId,
          })
        }
        break
      }

      case 'ship': {
        const { error: updateError } = await supabase.from('orders').update({ status: 'shipped' }).eq('id', orderId)
        if (updateError) throw updateError
        
        if (order.customer_id) {
          await supabase.from('notifications').insert({
            user_id: order.customer_id,
            title: 'طلبك في الطريق إليك',
            body: `المندوب في طريقه إليك مع طلبك #${orderId.toString().substring(0, 5)}`,
            type: 'delivery_update',
            order_id: orderId,
          })
        }
        break
      }

      case 'deliver': {
        const { error: updateError } = await supabase.from('orders').update({ status: 'delivered', delivered_at: new Date().toISOString() }).eq('id', orderId)
        if (updateError) throw updateError
        
        if (order.customer_id) {
          await supabase.from('notifications').insert({
            user_id: order.customer_id,
            title: 'تم توصيل طلبك',
            body: `تم توصيل طلبك #${orderId.toString().substring(0, 5)} بنجاح. شكراً لتسوقك معنا!`,
            type: 'order_update',
            order_id: orderId,
          })
        }
        break
      }

      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(
      JSON.stringify({ success: true, message: `Order ${action}ed successfully` }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
