import { createClient } from '@supabase/supabase-js';

const supabaseUrl = "https://pftjlvtdzokbzuioqfug.supabase.co";
const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM";

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testSignup() {
  console.log("Testing Driver Signup...");
  const testEmail = "driver_test_" + Date.now() + "@fresh.com";
  
  const { data: res, error: signUpError } = await supabase.auth.signUp({
    email: testEmail,
    password: "Password123!",
    options: {
      data: {
        full_name: "Test Driver",
        role: "driver",
        vehicle_type: "bike",
        plate_number: "12345"
      }
    }
  });

  if (signUpError) {
    console.error("❌ Sign up error:", signUpError);
    return;
  }
  console.log("✅ Sign up successful! User ID:", res.user.id);
  console.log("Session:", res.session ? "Active" : "Null (Email confirmation probably required)");

  console.log("Attempting to insert into profiles...");
  const { error: upsertError } = await supabase.from('profiles').upsert({
    id: res.user.id,
    full_name: "Test Driver",
    role: "driver",
    vehicle_type: "bike",
    plate_number: "12345",
    is_approved: false,
    is_online: false
  });

  if (upsertError) {
    console.error("❌ Profile upsert error:", upsertError);
  } else {
    console.log("✅ Profile upsert successful!");
  }
}

testSignup();
