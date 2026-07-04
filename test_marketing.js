import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  console.log('--- TESTING MARKETING TABLES ---');
  
  // 1. Check banners
  console.log('\nChecking public.banners table...');
  const { data: banners, error: bannersErr } = await supabase.from('banners').select('*').limit(1);
  if (bannersErr) {
    console.error('Banners fetch error:', bannersErr.message);
  } else {
    console.log('Banners fetch success! Found:', banners.length, 'rows');
  }

  // 2. Check story_groups
  console.log('\nChecking public.story_groups table...');
  const { data: storyGroups, error: storyGroupsErr } = await supabase.from('story_groups').select('*').limit(1);
  if (storyGroupsErr) {
    console.error('Story groups fetch error:', storyGroupsErr.message);
  } else {
    console.log('Story groups fetch success! Found:', storyGroups.length, 'rows');
  }

  // 3. Check story_items
  console.log('\nChecking public.story_items table...');
  const { data: storyItems, error: storyItemsErr } = await supabase.from('story_items').select('*').limit(1);
  if (storyItemsErr) {
    console.error('Story items fetch error:', storyItemsErr.message);
  } else {
    console.log('Story items fetch success! Found:', storyItems.length, 'rows');
  }

  // 4. Try insert to banners (simulated anonymous write)
  console.log('\nAttempting insert to public.banners (anon)...');
  const { data: insBanner, error: insBannerErr } = await supabase.from('banners').insert({
    image_url: 'https://images.unsplash.com/photo-1542838132-92c53300491e',
    link_type: 'none',
    link_value: '{"title":"Test","value":""}',
    is_active: true
  });
  if (insBannerErr) {
    console.error('Banners insert failed:', insBannerErr.message);
  } else {
    console.log('Banners insert success!');
  }
}

run();
