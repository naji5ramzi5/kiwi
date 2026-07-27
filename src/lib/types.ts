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
          access_code: string | null
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
          avatar_url: string | null
          partnership_division_id: string | null
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
          offer_price: number | null
          image_url: string | null
          description: string | null
          barcode: string | null
          sku: string | null
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
          actual_stock: number
          buffer_limit: number
          is_active: boolean
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
          delivery_lat: number | null
          delivery_lng: number | null
          delivery_note: string | null
          distance_km: number | null
          estimated_duration_minutes: number | null
          actual_distance_km: number | null
          actual_duration_minutes: number | null
          vat_rate: number
          total_tax: number
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
          name_snapshot: string | null
          image_url_snapshot: string | null
          unit_snapshot: string | null
          vat_rate: number
          tax_amount: number
          original_price: number | null
          discount_amount: number | null
          is_offer: boolean
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
      branch_managers: {
        Row: {
          id: string
          branch_id: string
          user_id: string
          partnership_division_id: string | null
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['branch_managers']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['branch_managers']['Insert']>
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
export type BranchManager = Database['public']['Tables']['branch_managers']['Row']

// Extended types with joins
export type OrderWithDetails = Order & {
  profiles?: Pick<Profile, 'full_name' | 'phone'> | null
  branches?: Pick<Branch, 'name'> | null
  drivers?: Pick<Driver, 'vehicle_type'> & { profiles?: Pick<Profile, 'full_name'> | null } | null
  order_items?: OrderItem[] | null
}

export type InventoryWithProduct = Inventory & {
  products?: Pick<Product, 'name' | 'category' | 'unit' | 'price'> | null
  branches?: Pick<Branch, 'name'> | null
}
