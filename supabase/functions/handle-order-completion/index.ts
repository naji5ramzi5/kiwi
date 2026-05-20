import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    const { order_id } = await req.json();

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 1. Get Ratios from Settings
    const { data: settings } = await supabase.from('system_settings').select('key, value_decimal');
    const ratios: Record<string, number> = {};
    settings?.forEach(s => ratios[s.key] = s.value_decimal);

    const devRatio = ratios['dev_partner_ratio'] || 0.35;
    const maintenanceRatio = ratios['system_maintenance_ratio'] || 0.10;

    // 2. Get Order Details
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', order_id)
      .single();

    if (orderError || !order) throw new Error('Order not found');

    const totalRevenue = order.total_amount;

    // 3. Calculate Distribution
    const devProfit = totalRevenue * devRatio;
    const maintenanceFund = totalRevenue * maintenanceRatio;
    const branchProfit = totalRevenue - (devProfit + maintenanceFund);

    // 4. Record Financial Settlement
    const { error: settlementError } = await supabase
      .from('partner_settlements')
      .insert({
        order_id: order.id,
        branch_id: order.branch_id,
        total_revenue: totalRevenue,
        dev_profit: devProfit,
        maintenance_fund: maintenanceFund,
        branch_profit: branchProfit,
        is_settled: false
      });

    if (settlementError) throw settlementError;

    return new Response(
      JSON.stringify({ 
        success: true, 
        breakdown: { devProfit, maintenanceFund, branchProfit } 
      }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    )
  }
})
