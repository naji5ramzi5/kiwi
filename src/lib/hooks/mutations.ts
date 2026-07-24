import { supabase } from '../supabase'

export async function updateOrderStatus(id: string, status: string) {
  const result = await supabase.from('orders').update({ status }).eq('id', id)
  if (result.error) throw new Error(result.error.message)
  return result
}

export async function updateDriverStatus(id: string, current_status: string) {
  const result = await supabase.from('drivers').update({ current_status, updated_at: new Date().toISOString() }).eq('id', id)
  if (result.error) throw new Error(result.error.message)
  return result
}

export async function createBranch(data: { name: string; address: string; city: string; phone: string }) {
  const result = await supabase.from('branches').insert(data).select().single()
  if (result.error) throw new Error(result.error.message)
  return result
}

export async function updateBranchStatus(id: string, status: string) {
  const result = await supabase.from('branches').update({ status }).eq('id', id)
  if (result.error) throw new Error(result.error.message)
  return result
}

export async function createProduct(data: { name: string; category: string; unit: string; price: number; cost?: number }) {
  const result = await supabase.from('products').insert(data).select().single()
  if (result.error) throw new Error(result.error.message)
  return result
}

export async function updateProduct(id: string, data: Partial<{ name: string; category: string; unit: string; price: number; cost: number; is_active: boolean }>) {
  const result = await supabase.from('products').update(data).eq('id', id)
  if (result.error) throw new Error(result.error.message)
  return result
}

export async function createPurchase(data: { branch_id: string; supplier_name: string; total_value: number; payment_status: string }) {
  const result = await supabase.from('purchases').insert(data).select().single()
  if (result.error) throw new Error(result.error.message)
  return result
}

export async function updateInventoryStock(id: string, stock_quantity: number) {
  const result = await supabase.from('inventory').update({ stock_quantity, updated_at: new Date().toISOString() }).eq('id', id)
  if (result.error) throw new Error(result.error.message)
  return result
}
