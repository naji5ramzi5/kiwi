import { useState } from 'react'
import { Bell, Image as ImageIcon, Megaphone, Tag } from 'lucide-react'
import NotificationsTab from './marketing/NotificationsTab'
import BannersTab from './marketing/BannersTab'
import StoriesTab from './marketing/StoriesTab'
import DiscountsTab from './marketing/DiscountsTab'
import type { Tab } from './marketing/types'

export default function Marketing() {
  const [tab, setTab] = useState<Tab>('notifications')

  const TABS: { id: Tab; label: string; icon: React.ReactNode }[] = [
    { id: 'notifications', label: 'الإشعارات الذكية', icon: <Bell size={16} /> },
    { id: 'banners', label: 'إدارة البنرات', icon: <ImageIcon size={16} /> },
    { id: 'stories', label: 'قصص التطبيق', icon: <Megaphone size={16} /> },
    { id: 'discounts', label: 'أكواد الخصم', icon: <Tag size={16} /> },
  ]

  return (
    <div style={{ paddingBottom: 40 }}>
      <div style={{ display: 'flex', gap: 6, marginBottom: 24, background: 'var(--white)', borderRadius: 12, padding: 6, border: '1px solid var(--gray100)', width: 'fit-content', boxShadow: 'var(--shadow-sm)' }}>
        {TABS.map(t => (
          <button key={t.id} onClick={() => setTab(t.id)}
            className={tab === t.id ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}
            style={{ gap: 8, padding: '8px 16px', fontSize: 13, fontWeight: 700 }}>
            {t.icon} {t.label}
          </button>
        ))}
      </div>

      {tab === 'notifications' && <NotificationsTab />}
      {tab === 'banners' && <BannersTab />}
      {tab === 'stories' && <StoriesTab />}
      {tab === 'discounts' && <DiscountsTab />}
    </div>
  )
}
