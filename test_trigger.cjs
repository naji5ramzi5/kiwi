const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testTrigger() {
  console.log('1. Signing in/up as Super Admin to bypass RLS for products management...');
  const email = `admin_tester_${Date.now()}@fresh.com`;
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
  console.log('User signed up. ID:', userId);

  console.log('2. Promoting user profile to super_admin...');
  const { error: profileError } = await supabase.from('profiles').upsert({
    id: userId,
    role: 'super_admin',
    full_name: 'Tester Super Admin',
    phone: '+964770' + Math.floor(1000000 + Math.random() * 9000000)
  });

  if (profileError) {
    console.error('Profile upsert error:', profileError.message);
    return;
  }
  console.log('User role updated to super_admin successfully!');

  // Authenticate the client as this new super admin
  const { error: loginError } = await supabase.auth.signInWithPassword({
    email,
    password
  });
  if (loginError) {
     console.error('Login error:', loginError.message);
     return;
  }
  console.log('Logged in as super_admin successfully!');

  console.log('3. Inserting a test product catalog entry...');
  const testProductId = '66666666-6666-6666-6666-666666666666';
  const { data: pData, error: pError } = await supabase.from('products').upsert({
    id: testProductId,
    name: 'اختبار الزناد التلقائي',
    category: 'طازج',
    unit: 'كيس',
    price: 999.00,
    cost: 500.00,
    is_active: true
  }).select();

  if (pError) {
    console.error('Error inserting product:', pError);
    return;
  }
  console.log('Product inserted successfully:', pData);

  console.log('4. Checking if branch_inventory rows were automatically created (zero stock)...');
  await new Promise(r => setTimeout(r, 1500));
  
  const { data: invData, error: invError } = await supabase
    .from('branch_inventory')
    .select('*')
    .eq('product_id', testProductId);

  if (invError) {
    console.error('Error checking branch_inventory:', invError);
  } else {
    console.log('Branch inventory rows found for this product:', invData);
    if (invData.length > 0) {
      console.log('🎉 SUCCESS! The DB Trigger is active and working!');
    } else {
      console.log('❌ Trigger not working or not active.');
    }
  }

  // Clean up
  console.log('5. Cleaning up test data...');
  await supabase.from('branch_inventory').delete().eq('product_id', testProductId);
  await supabase.from('products').delete().eq('id', testProductId);
  console.log('Cleanup complete!');
}

testTrigger();
