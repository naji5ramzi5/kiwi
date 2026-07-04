import { createClient } from '@supabase/supabase-js';

const supabaseUrl = "https://pftjlvtdzokbzuioqfug.supabase.co";
const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM";

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testPhoneSignup() {
  console.log("Testing Phone Signup...");
  const phone = "+964770" + Math.floor(1000000 + Math.random() * 9000000);
  const password = "Password123!";
  
  const { data: res, error: signUpError } = await supabase.auth.signUp({
    phone: phone,
    password: password,
    options: {
      data: {
        full_name: "Phone Seeder",
        role: "super_admin",
      }
    }
  });

  if (signUpError) {
    console.error("❌ Sign up error:", signUpError);
    return;
  }
  console.log("✅ Sign up successful! User ID:", res.user?.id);
  console.log("Session:", res.session ? "Active" : "Null");
}

testPhoneSignup();
