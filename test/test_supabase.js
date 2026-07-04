import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  const email = `admin_test_${Date.now()}@fresh.com`;
  const password = 'Password123!';
  
  console.log(`Attempting email signup for ${email}...`);
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: 'Test Super Admin',
        role: 'super_admin'
      }
    }
  });

  if (error) {
    console.error('Signup error:', error.message);
    return;
  }

  console.log('Signup successful! User ID:', data.user?.id);
  console.log('Session:', data.session ? 'Active' : 'Null (Verification required)');

  if (data.session) {
    console.log('Trying to insert super_admin profile...');
    const { error: profileError } = await supabase
      .from('profiles')
      .upsert({
        id: data.user.id,
        role: 'super_admin',
        full_name: 'Test Super Admin',
        phone: '+964770' + Math.floor(1000000 + Math.random() * 9000000)
      });
    
    if (profileError) {
      console.error('Profile upsert error:', profileError.message);
    } else {
      console.log('Profile upserted successfully as super_admin!');
    }
  }
}

run();
