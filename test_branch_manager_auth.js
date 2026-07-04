import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  console.log('1. Fetching branch f51fb43b-a546-483a-b294-0e9f00c11f0c...');
  const branchId = 'f51fb43b-a546-483a-b294-0e9f00c11f0c';
  
  console.log('2. Signing up virtual branch user...');
  const email = `branch_manager_${branchId.substring(0, 8)}_${Date.now()}@fresh.com`;
  const password = 'Password123!';
  
  const { data: authData, error: authError } = await supabase.auth.signUp({
    email,
    password
  });

  if (authError) {
    console.error('Signup error:', authError.message);
    return;
  }
  
  const userId = authData.user.id;
  console.log('Virtual User signed up. ID:', userId);

  console.log('3. Setting profile to branch_manager...');
  const { error: profileError } = await supabase.from('profiles').upsert({
    id: userId,
    role: 'branch_manager',
    full_name: 'Branch Manager Test',
    branch_id: branchId,
    phone: '+964770' + Math.floor(1000000 + Math.random() * 9000000)
  });

  if (profileError) {
    console.error('Profile upsert error:', profileError.message);
    return;
  }
  console.log('User role updated to branch_manager successfully!');

  // Log in
  const { error: loginError } = await supabase.auth.signInWithPassword({
    email,
    password
  });
  if (loginError) {
     console.error('Login error:', loginError.message);
     return;
  }
  console.log('Logged in as branch_manager successfully!');

  console.log('4. Attempting to upsert stock on branch_inventory...');
  const { data: products } = await supabase.from('products').select('*').limit(1);
  const productId = products[0].id;
  
  const { error: invError } = await supabase.from('branch_inventory').upsert({
    branch_id: branchId,
    product_id: productId,
    actual_stock: 45.00,
    buffer_limit: 2.00,
    is_active: true
  }, {
    onConflict: 'branch_id,product_id'
  });

  if (invError) {
    console.error('RLS Blocked updates even with branch_manager profile:', invError.message);
  } else {
    console.log('🎉 SUCCESS! branch_manager can write to branch_inventory!');
  }
}

run();
