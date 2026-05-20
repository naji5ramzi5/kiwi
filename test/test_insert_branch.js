import { createClient } from '@supabase/supabase-js';

const supabaseUrl = "https://pftjlvtdzokbzuioqfug.supabase.co";
const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM";

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testInsert() {
  console.log("Simulating a new branch creation...");
  
  const payload = {
    name: "فرع المنصور التجريبي",
    phone: "07701234567",
    address: "المنصور، بغداد",
    location_url: "https://maps.google.com/?q=33.3152,44.3661",
    access_code: "9876",
    latitude: 33.3152,
    longitude: 44.3661,
    status: "نشط",
    city: "بغداد",
    delivery_zones: []
  };

  const { data, error } = await supabase
    .from('branches')
    .insert([payload])
    .select();

  if (error) {
    console.error("❌ New branch insertion failed with error:", error);
  } else {
    console.log("✅ New branch insertion succeeded!", data);
    
    // Clean it up immediately to avoid cluttering the DB
    if (data && data[0]) {
      console.log("Cleaning up created branch ID:", data[0].id);
      const { error: delError } = await supabase.from('branches').delete().eq('id', data[0].id);
      if (delError) console.error("Clean up error:", delError);
      else console.log("Cleaned up successfully!");
    }
  }
}

testInsert();
