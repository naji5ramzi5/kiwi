const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  try {
    console.log('1. Fetching all products from Supabase...');
    const { data: products, error: pError } = await supabase.from('products').select('*');
    if (pError) throw pError;
    console.log(`Found ${products.length} products in catalog.`);

    console.log('2. Fetching all branches from Supabase...');
    const { data: branches, error: bError } = await supabase.from('branches').select('*');
    if (bError) throw bError;
    console.log(`Found ${branches.length} branches.`);

    console.log('3. Inserting/updating branch_inventory for all combinations...');
    let successCount = 0;
    
    for (const branch of branches) {
      for (const product of products) {
        console.log(`Setting stock = 50 for Product: ${product.name} at Branch: ${branch.name}`);
        
        // We will try to upsert the inventory row
        const { error: invError } = await supabase
          .from('branch_inventory')
          .upsert({
            branch_id: branch.id,
            product_id: product.id,
            actual_stock: 50.00,
            buffer_limit: 2.00,
            is_active: true
          }, {
            onConflict: 'branch_id,product_id'
          });
          
        if (invError) {
          console.error(`Error for ${product.name} at ${branch.name}:`, invError.message);
        } else {
          successCount++;
        }
      }
    }
    
    console.log(`Successfully seeded ${successCount} inventory items!`);
  } catch (err) {
    console.error('Seeding crashed:', err.message);
  }
}

run();
