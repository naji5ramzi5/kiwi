import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://pftjtdzokbzuioqfug.supabase.co'.replace('pftjtdzokbzuioqfug', 'pftjlvtdzokbzuioqfug');
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  const { data, error } = await supabase.rpc('get_table_columns', { table_name: 'profiles' });
  if (error) {
    console.error('RPC Error:', error.message);
    const { data: cols, error: err } = await supabase.from('profiles').select().limit(0);
    if (err) {
       console.error('Select empty error:', err);
    } else {
       console.log('Direct select profiles:', cols);
    }
  } else {
    console.log('Profiles columns from RPC:', data);
  }
  
  for (const table of ['profiles', 'drivers', 'orders', 'delivery_zones', 'branches', 'inventory', 'branch_inventory']) {
    const { data: d, error: e } = await supabase.from(table).select().limit(1);
    if (e) {
      console.log(`Table ${table} error:`, e.message);
    } else {
      console.log(`Table ${table} exists! Data:`, d);
    }
  }
  process.exit(0);
}

run();


