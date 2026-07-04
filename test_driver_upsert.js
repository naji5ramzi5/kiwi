import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  console.log('Testing profiles table schema by inserting dummy user...');
  
  // Note: we can use a random uuid, but since there's RLS or foreign key on auth.users(id), 
  // let's see if it fails on column name or foreign key.
  const { error } = await supabase.from('profiles').upsert({
    id: '00000000-0000-0000-0000-000000000000',
    full_name: 'Test Upsert Columns',
    role: 'driver',
    vehicle_type: 'bike',
    plate_number: '12345',
    is_approved: false,
    is_online: false
  });
  
  if (error) {
    console.log('Insert error details:', error);
  } else {
    console.log('Insert succeeded! This means all columns exist in profiles.');
  }
}

run();
