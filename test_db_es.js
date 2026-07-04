import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  try {
    const { data: profiles, error: pError } = await supabase.from('profiles').select('*').limit(1);
    console.log('Profiles columns:', profiles && profiles.length > 0 ? Object.keys(profiles[0]) : 'Empty table');

    const { data: drivers, error: dError } = await supabase.from('drivers').select('*').limit(1);
    console.log('Drivers columns:', drivers && drivers.length > 0 ? Object.keys(drivers[0]) : 'Empty table');

    const { data: orders, error: oError } = await supabase.from('orders').select('*').limit(1);
    console.log('Orders columns:', orders && orders.length > 0 ? Object.keys(orders[0]) : 'Empty table');
  } catch (e) {
    console.error(e);
  }
}

run();
