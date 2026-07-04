const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testPhoneSignup() {
  const phone = '+964770' + Math.floor(1000000 + Math.random() * 9000000);
  const password = 'Password123!';
  
  console.log(`Testing phone signup with ${phone}...`);
  const { data, error } = await supabase.auth.signUp({
    phone,
    password,
    options: {
      data: {
        full_name: 'Test Customer'
      }
    }
  });

  if (error) {
    console.error('Phone signup error:', error.message);
  } else {
    console.log('Phone signup successful! User ID:', data.user?.id);
    console.log('Session returned:', data.session ? 'Yes (SMS confirmation is disabled)' : 'No (SMS confirmation is required)');
  }
}

testPhoneSignup();
