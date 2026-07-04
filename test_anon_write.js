import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  console.log('Fetching active branch...');
  const { data: branches } = await supabase.from('branches').select('*').limit(1);
  if (!branches || branches.length === 0) {
    console.error('No branches found.');
    return;
  }
  const branchId = branches[0].id;
  console.log('Branch ID:', branchId);

  console.log('Fetching active product...');
  const { data: products } = await supabase.from('products').select('*').limit(1);
  if (!products || products.length === 0) {
    console.error('No products found.');
    return;
  }
  const productId = products[0].id;
  console.log('Product ID:', productId);

  console.log('Attempting anonymous upsert to branch_inventory...');
  const { data, error } = await supabase.from('branch_inventory').upsert({
    branch_id: branchId,
    product_id: productId,
    actual_stock: 12.00,
    buffer_limit: 2.00,
    is_active: true
  }, {
    onConflict: 'branch_id,product_id'
  });

  if (error) {
    console.error('Upsert failed:', error.message);
  } else {
    console.log('Upsert succeeded! Anonymous writes are ALLOWED on branch_inventory.');
  }
}

run();
