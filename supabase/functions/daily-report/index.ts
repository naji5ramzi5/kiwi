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

    const { branchId, date } = await req.json()

    // Default to today if no date provided
    const reportDate = date || new Date().toISOString().split('T')[0]
    const startOfDay = `${reportDate}T00:00:00.000Z`
    const endOfDay = `${reportDate}T23:59:59.999Z`

    // Build query for orders
    let ordersQuery = supabase
      .from('orders')
      .select('id, total_amount, status, payment_method, delivery_fee, created_at')
      .gte('created_at', startOfDay)
      .lte('created_at', endOfDay)

    if (branchId) {
      ordersQuery = ordersQuery.eq('branch_id', branchId)
    }

    const { data: orders, error: ordersError } = await ordersQuery
    if (ordersError) throw ordersError

    // Calculate metrics
    const totalOrders = orders?.length ?? 0
    const deliveredOrders = orders?.filter(o => o.status === 'delivered') ?? []
    const pendingOrders = orders?.filter(o => ['pending', 'preparing'].includes(o.status)) ?? []
    const rejectedOrders = orders?.filter(o => o.status === 'rejected') ?? []

    const totalRevenue = deliveredOrders.reduce((sum, o) => sum + (o.total_amount || 0), 0)
    const totalDeliveryFees = deliveredOrders.reduce((sum, o) => sum + (o.delivery_fee || 0), 0)
    const avgOrderValue = deliveredOrders.length > 0 ? totalRevenue / deliveredOrders.length : 0

    // Payment method breakdown
    const paymentBreakdown: Record<string, number> = {}
    for (const order of deliveredOrders) {
      const method = order.payment_method || 'نقداً'
      paymentBreakdown[method] = (paymentBreakdown[method] || 0) + order.total_amount
    }

    // Get top products for the day
    const topProductsQuery = supabase
      .from('order_items')
      .select('product_id, quantity, total_price, products(name)')
      .in('order_id', (orders || []).map(o => o.id))

    const { data: topItems } = await topProductsQuery

    const productSales: Record<string, { name: string; quantity: number; revenue: number }> = {}
    for (const item of (topItems || [])) {
      const name = item.products?.name || 'منتج'
      if (!productSales[item.product_id]) {
        productSales[item.product_id] = { name, quantity: 0, revenue: 0 }
      }
      productSales[item.product_id].quantity += item.quantity
      productSales[item.product_id].revenue += item.total_price
    }

    const topProducts = Object.values(productSales)
      .sort((a, b) => b.quantity - a.quantity)
      .slice(0, 10)

    // Save or update daily report
    const reportData = {
      branch_id: branchId,
      report_date: reportDate,
      total_orders: totalOrders,
      delivered_orders: deliveredOrders.length,
      pending_orders: pendingOrders.length,
      rejected_orders: rejectedOrders.length,
      total_revenue: totalRevenue,
      delivery_fees: totalDeliveryFees,
      avg_order_value: avgOrderValue,
      payment_breakdown: paymentBreakdown,
      top_products: topProducts,
      generated_at: new Date().toISOString(),
    }

    const { error: reportError } = await supabase
      .from('daily_reports')
      .upsert(reportData, { onConflict: 'branch_id,report_date' })

    if (reportError) {
      console.error('Failed to save report:', reportError)
    }

    return new Response(
      JSON.stringify({
        success: true,
        report: {
          date: reportDate,
          branchId: branchId || 'all',
          totalOrders,
          deliveredOrders: deliveredOrders.length,
          pendingOrders: pendingOrders.length,
          rejectedOrders: rejectedOrders.length,
          totalRevenue,
          deliveryFees: totalDeliveryFees,
          avgOrderValue: Math.round(avgOrderValue),
          paymentBreakdown,
          topProducts,
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
