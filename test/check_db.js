import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
  console.log("Checking Supabase connection and tables...");
  
  // 1. Check branches
  const { data: branches, error: bErr } = await supabase.from('branches').select('*');
  console.log("Branches:", bErr ? bErr.message : branches);

  // 2. Check categories
  const { data: categories, error: catErr } = await supabase.from('categories').select('*');
  console.log("Categories:", catErr ? catErr.message : categories);

  // 3. Check products
  const { data: products, error: pErr } = await supabase.from('products').select('*');
  console.log("Products count:", pErr ? pErr.message : products?.length);

  // 4. Check if branch_inventory view/table exists
  const { data: bInv, error: biErr } = await supabase.from('branch_inventory').select('*').limit(5);
  console.log("branch_inventory (limit 5):", biErr ? biErr.message : bInv);

  // 5. Check if inventory table exists
  const { data: inv, error: iErr } = await supabase.from('inventory').select('*').limit(5);
  console.log("inventory (limit 5):", iErr ? iErr.message : inv);
}

check();
