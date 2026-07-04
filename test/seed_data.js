import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://pftjlvtdzokbzuioqfug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdGpsdnRkem9rYnp1aW9xZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDg0NjgsImV4cCI6MjA5NDE4NDQ2OH0.3ujKn2bxihvFfhfeIXPVNDjxjfqpWsXJq4bpaPNsQOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function seed() {
  console.log("Starting database seeding process...");

  // 1. Seed Banners
  console.log("Seeding banners...");
  const bannerData = [
    {
      image_url: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&fit=crop&q=80',
      link_type: 'none',
      is_active: true,
      sort_order: 1
    },
    {
      image_url: 'https://images.unsplash.com/photo-1607349913338-fca6f7fc42d0?w=800&fit=crop&q=80',
      link_type: 'none',
      is_active: true,
      sort_order: 2
    },
    {
      image_url: 'https://images.unsplash.com/photo-1506084868230-bb9d95c24759?w=800&fit=crop&q=80',
      link_type: 'none',
      is_active: true,
      sort_order: 3
    }
  ];
  
  const { error: bannerError } = await supabase.from('banners').insert(bannerData);
  if (bannerError) console.error("Banner seeding error:", bannerError.message);
  else console.log("Banners seeded successfully!");

  // 2. Seed Categories
  console.log("Seeding categories...");
  const categoriesData = [
    {
      name: "خضروات",
      icon: "carrot",
      image_url: "https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=400&fit=crop&q=80"
    },
    {
      name: "فواكه",
      icon: "apple-l",
      image_url: "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400&fit=crop&q=80"
    },
    {
      name: "ورقيات",
      icon: "leaf",
      image_url: "https://images.unsplash.com/photo-1622312693822-4917a14e9124?w=400&fit=crop&q=80"
    },
    {
      name: "تمور",
      icon: "sun",
      image_url: "https://images.unsplash.com/photo-1596431989042-49764de3d037?w=400&fit=crop&q=80"
    },
    {
      name: "مكسرات",
      icon: "nut",
      image_url: "https://images.unsplash.com/photo-1599598425947-330026296906?w=400&fit=crop&q=80"
    }
  ];

  const { error: catError } = await supabase.from('categories').upsert(categoriesData, { onConflict: 'name' });
  if (catError) console.error("Category seeding error:", catError.message);
  else console.log("Categories seeded successfully!");

  // 3. Seed Products
  console.log("Seeding products...");
  const productsData = [
    {
      name: "طماطم طازجة",
      category: "خضروات",
      unit: "كيلو",
      price: 1250,
      cost: 1500, // cost > price to show it as an offer
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1595855759920-86582396756a?w=500&q=80"
    },
    {
      name: "بطاطا عراقية",
      category: "خضروات",
      unit: "كيلو",
      price: 1000,
      cost: 1200,
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500&q=80"
    },
    {
      name: "خيار ماء",
      category: "خضروات",
      unit: "كيلو",
      price: 1500,
      cost: 1800,
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1590301157890-4810ed352733?w=500&q=80"
    },
    {
      name: "تفاح أحمر لبناني",
      category: "فواكه",
      unit: "كيلو",
      price: 2500,
      cost: 3000,
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&q=80"
    },
    {
      name: "موز صومالي",
      category: "فواكه",
      unit: "كيلو",
      price: 2000,
      cost: 2500,
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&q=80"
    },
    {
      name: "برتقال أبو صرة",
      category: "فواكه",
      unit: "كيلو",
      price: 1750,
      cost: 2000,
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1582979512210-99b6a53885f3?w=500&q=80"
    },
    {
      name: "نعناع طازج",
      category: "ورقيات",
      unit: "باقة",
      price: 250,
      cost: 400,
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1536882240095-0379873feb4e?w=500&q=80"
    },
    {
      name: "بقدونس أخضر",
      category: "ورقيات",
      unit: "باقة",
      price: 250,
      cost: 400,
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1515224526905-51c7d77c7bb8?w=500&q=80"
    },
    {
      name: "تمر خلاص الأحساء",
      category: "تمور",
      unit: "علبة",
      price: 4500,
      cost: 5000,
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1596431989042-49764de3d037?w=500&q=80"
    },
    {
      name: "لوز أمريكي مقشر",
      category: "مكسرات",
      unit: "كيلو",
      price: 12000,
      cost: 14000,
      is_active: true,
      image_url: "https://images.unsplash.com/photo-1508061253366-f7da158b6db4?w=500&q=80"
    }
  ];

  const { data: newProducts, error: pError } = await supabase.from('products').upsert(productsData, { onConflict: 'name' }).select();
  if (pError) {
    console.error("Product seeding error:", pError.message);
    return;
  }
  console.log(`Products seeded successfully! Count: ${newProducts.length}`);

  // 4. Update branch inventory stock to ensure they display as in-stock
  console.log("Updating stock level in all branches...");
  
  // Get all active branches
  const { data: branches, error: bError } = await supabase.from('branches').select('id');
  if (bError) {
    console.error("Failed to query branches:", bError.message);
    return;
  }
  console.log(`Found ${branches.length} branches.`);

  // For each branch and each product, update/insert stock to 100
  let inventoryUpserts = [];
  for (let branch of branches) {
    for (let product of newProducts) {
      inventoryUpserts.push({
        branch_id: branch.id,
        product_id: product.id,
        actual_stock: 100.0,
        buffer_limit: 2,
        is_active: true
      });
    }
  }

  const { error: invError } = await supabase.from('branch_inventory').upsert(inventoryUpserts, { onConflict: 'branch_id,product_id' });
  if (invError) {
    console.error("Inventory stock seeding failed:", invError.message);
  } else {
    console.log("Stock levels updated to 100.0 for all branch/product pairs!");
  }

  console.log("Database seeding completed!");
}

seed();
