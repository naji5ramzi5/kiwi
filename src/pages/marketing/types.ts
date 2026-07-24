export interface Banner {
  id: string; title: string; imageUrl: string;
  linkType: 'none' | 'external' | 'product'; linkValue: string; active: boolean
}

export interface StoryItem {
  id: string; type: 'image' | 'video' | 'text'; url?: string;
  textContent?: string; bgColor?: string; duration: number;
}

export interface StoryGroup {
  id: string; title: string; thumbnailUrl: string; items: StoryItem[]; active: boolean
}

export interface Discount {
  id: string; code: string; discount_amount: number; type: 'percent' | 'fixed';
  max_uses: number; used_count: number; is_active: boolean; expires_at?: string;
  min_order_amount?: number; created_at: string;
}

export type Tab = 'notifications' | 'banners' | 'stories' | 'discounts'

export function generateCode(prefix = 'KIWI') {
  return `${prefix}${Math.random().toString(36).substring(2, 7).toUpperCase()}`
}
