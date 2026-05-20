export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export interface Database {
  public: {
    Tables: {
      branches: {
        Row: {
          id: string
          name: string
          address: string
          city: string
          phone: string | null
          status: string
          location_url: string | null
          latitude: number | null
          longitude: number | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['branches']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['branches']['Insert']>
      }
      profiles: {
        Row: {
          id: string
          role: 'super_admin' | 'branch_manager' | 'driver' | 'customer'
          full_name: string | null
          phone: string | null
          branch_id: string | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['profiles']['Row'], 'created_at'>
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>
      }
      products: {
        Row: {
          id: string
          name: string
          category: string
          unit: string
          price: number
          cost: number | null
          is_active: boolean
          is_offer: boolean
          image_url: string | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['products']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['products']['Insert']>
      }
      inventory: {
        Row: {
          id: string
          branch_id: string
          product_id: string
          stock_quantity: number
          min_stock_level: number
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['inventory']['Row'], 'id' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['inventory']['Insert']>
      }
      purchases: {
        Row: {
          id: string
          branch_id: string
          supplier_name: string
          total_value: number
          payment_status: string
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['purchases']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['purchases']['Insert']>
      }
      damaged_goods: {
        Row: {
          id: string
          branch_id: string
          product_id: string
          quantity: number
          loss_value: number
          reason: string | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['damaged_goods']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['damaged_goods']['Insert']>
      }
      drivers: {
        Row: {
          id: string
          vehicle_type: string | null
          license_number: string | null
          is_active: boolean
          current_status: string
          last_location_lat: number | null
          last_location_lng: number | null
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['drivers']['Row'], 'updated_at'>
        Update: Partial<Database['public']['Tables']['drivers']['Insert']>
      }
      orders: {
        Row: {
          id: string
          customer_id: string | null
          branch_id: string | null
          driver_id: string | null
          total_amount: number
          delivery_fee: number
          status: string
          payment_method: string
          delivery_address: string
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['orders']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['orders']['Insert']>
      }
      order_items: {
        Row: {
          id: string
          order_id: string
          product_id: string | null
          quantity: number
          unit_price: number
          total_price: number
        }
        Insert: Omit<Database['public']['Tables']['order_items']['Row'], 'id'>
        Update: Partial<Database['public']['Tables']['order_items']['Insert']>
      }
      categories: {
        Row: {
          id: string
          name: string
          icon: string | null
          image_url: string | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['categories']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['categories']['Insert']>
      }
    }
  }
}

// Convenience types
export type Branch = Database['public']['Tables']['branches']['Row']
export type Profile = Database['public']['Tables']['profiles']['Row']
export type Product = Database['public']['Tables']['products']['Row']
export type Inventory = Database['public']['Tables']['inventory']['Row']
export type Purchase = Database['public']['Tables']['purchases']['Row']
export type DamagedGood = Database['public']['Tables']['damaged_goods']['Row']
export type Driver = Database['public']['Tables']['drivers']['Row']
export type Order = Database['public']['Tables']['orders']['Row']
export type OrderItem = Database['public']['Tables']['order_items']['Row']
export type Category = Database['public']['Tables']['categories']['Row']

// Extended types with joins
export type OrderWithDetails = Order & {
  profiles?: Pick<Profile, 'full_name' | 'phone'> | null
  branches?: Pick<Branch, 'name'> | null
  drivers?: Pick<Driver, 'vehicle_type'> & { profiles?: Pick<Profile, 'full_name'> | null } | null
}

export type InventoryWithProduct = Inventory & {
  products?: Pick<Product, 'name' | 'category' | 'unit' | 'price'> | null
  branches?: Pick<Branch, 'name'> | null
}
