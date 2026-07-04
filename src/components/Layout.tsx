import { useState, useRef, useEffect } from 'react'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, Package, GitBranch, ShoppingCart, Activity,
  Truck, Megaphone, DollarSign, Users, Bell, Search, Settings, FileText, Box, Leaf,
  X, CheckCheck, Trash2, ShieldAlert, Tag, UserCheck, Printer, MapPin, Star
} from 'lucide-react'
import { useNotifications } from '../lib/notifications'
import type { AppNotification } from '../lib/notifications'

const NAV = [
  { label: 'الرئيسية', path: '/dashboard', icon: LayoutDashboard, section: 'اللوحة المركزية' },
  { label: 'الطلبات الحية', path: '/orders', icon: Activity, section: 'اللوحة المركزية' },
  
  { label: 'المخزون المركزي', path: '/inventory', icon: Box, section: 'التشغيل' },
  { label: 'المشتريات والتوريد', path: '/purchases', icon: FileText, section: 'التشغيل' },
  { label: 'إدارة المنتجات', path: '/products', icon: Package, section: 'التشغيل' },
  { label: 'الفئات المركزية', path: '/categories', icon: Tag, section: 'التشغيل' },
  
  { label: 'الفروع', path: '/branches', icon: GitBranch, section: 'الموارد البشرية والفروع' },
  { label: 'مناطق التوصيل', path: '/delivery-zones', icon: MapPin, section: 'الموارد البشرية والفروع' },
  { label: 'المناديب والسائقين', path: '/drivers', icon: Truck, section: 'الموارد البشرية والفروع' },
  { label: 'التقييمات', path: '/ratings', icon: Star, section: 'الموارد البشرية والفروع' },
  { label: 'العملاء', path: '/customers', icon: Users, section: 'الموارد البشرية والفروع' },
  
  { label: 'الحسابات والتقارير', path: '/finance', icon: DollarSign, section: 'المالية والتسويق' },
  { label: 'التسويق', path: '/marketing', icon: Megaphone, section: 'المالية والتسويق' },
  { label: 'KiwiAI (الذكاء الاصطناعي)', path: '/ai-chat', icon: Activity, section: 'الذكاء الاصطناعي' },
]

const SECTIONS = ['اللوحة المركزية', 'التشغيل', 'الموارد البشرية والفروع', 'المالية والتسويق', 'الذكاء الاصطناعي']

const PAGE_TITLES: Record<string, string> = {
  '/dashboard': 'لوحة التحكم الرئيسية',
  '/orders': 'إدارة الطلبات الحية',
  '/inventory': 'المخزون والتوالف',
  '/purchases': 'سجل المشتريات',
  '/products': 'إدارة المنتجات والتسعير',
  '/branches': 'إدارة الفروع',
  '/delivery-zones': 'مناطق التوصيل',
  '/drivers': 'إدارة فريق التوصيل',
  '/ratings': 'التقييمات والتعليقات',
  '/customers': 'قاعدة العملاء',
  '/finance': 'التقارير المالية والشركاء',
  '/marketing': 'الحملات التسويقية',
  '/ai-chat': 'KiwiAI - المساعد الذكي',
}

const NOTIF_ICONS: Record<string, string> = {
  order: '🛒', driver: '🚴', inventory: '⚠️', system: '🔔'
}

function timeAgo(date: Date): string {
  const diff = Math.floor((Date.now() - date.getTime()) / 1000)
  if (diff < 60) return 'الآن'
  if (diff < 3600) return `منذ ${Math.floor(diff / 60)} د`
  if (diff < 86400) return `منذ ${Math.floor(diff / 3600)} س`
  return `منذ ${Math.floor(diff / 86400)} يوم`
}

function NotificationPanel({
  notifications, onMarkRead, onMarkAllRead, onClear, onClose, onRequestPermission, permission
}: {
  notifications: AppNotification[]
  onMarkRead: (id: string) => void
  onMarkAllRead: () => void
  onClear: () => void
  onClose: () => void
  onRequestPermission: () => void
  permission: NotificationPermission
}) {
  return (
    <div style={{
      position: 'absolute', top: '100%', left: 0, width: 360, background: 'white',
      borderRadius: 16, boxShadow: '0 20px 60px rgba(0,0,0,.15)', border: '1px solid var(--gray100)',
      zIndex: 1000, overflow: 'hidden', marginTop: 8
    }}>
      {/* Header */}
      <div style={{ padding: '14px 18px', borderBottom: '1px solid var(--gray100)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--gray900)' }}>الإشعارات</div>
          <div style={{ fontSize: 11, color: 'var(--gray400)', marginTop: 1 }}>
            {notifications.filter(n => !n.read).length} غير مقروء
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <button className="btn btn-ghost btn-sm" onClick={onMarkAllRead} title="تحديد الكل كمقروء">
            <CheckCheck size={14} />
          </button>
          <button className="btn btn-ghost btn-sm" onClick={onClear} title="مسح الكل">
            <Trash2 size={14} />
          </button>
          <button className="btn btn-ghost btn-sm" onClick={onClose}>
            <X size={14} />
          </button>
        </div>
      </div>

      {/* Permission Warning */}
      {permission !== 'granted' && (
        <div style={{ padding: '10px 18px', background: '#fef3c7', borderBottom: '1px solid #fde68a', display: 'flex', alignItems: 'center', gap: 10 }}>
          <ShieldAlert size={16} color="#d97706" />
          <div style={{ flex: 1, fontSize: 12, color: '#92400e' }}>الإشعارات غير مفعّلة</div>
          <button className="btn btn-sm" style={{ background: '#d97706', color: 'white', fontSize: 11, padding: '3px 10px' }} onClick={onRequestPermission}>
            تفعيل
          </button>
        </div>
      )}

      {/* List */}
      <div style={{ maxHeight: 380, overflowY: 'auto' }}>
        {notifications.length === 0 ? (
          <div style={{ padding: '40px 20px', textAlign: 'center', color: 'var(--gray400)' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>🔔</div>
            <div style={{ fontSize: 13 }}>لا توجد إشعارات</div>
          </div>
        ) : (
          notifications.map(n => (
            <div
              key={n.id}
              onClick={() => onMarkRead(n.id)}
              style={{
                padding: '12px 18px', borderBottom: '1px solid var(--gray50)',
                background: n.read ? 'white' : 'var(--g50)',
                cursor: 'pointer', display: 'flex', gap: 12, alignItems: 'flex-start',
                transition: 'background .15s',
              }}
            >
              <div style={{ fontSize: 20, flexShrink: 0, marginTop: 1 }}>{NOTIF_ICONS[n.type]}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: n.read ? 500 : 700, fontSize: 13, color: 'var(--gray900)', marginBottom: 2 }}>{n.title}</div>
                <div style={{ fontSize: 11.5, color: 'var(--gray500)', lineHeight: 1.5, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{n.body}</div>
                <div style={{ fontSize: 10, color: 'var(--gray400)', marginTop: 4 }}>{timeAgo(n.time)}</div>
              </div>
              {!n.read && <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--g500)', flexShrink: 0, marginTop: 5 }} />}
            </div>
          ))
        )}
      </div>
    </div>
  )
}

export default function Layout() {
  const location = useLocation()
  const navigate = useNavigate()
  const [showNotif, setShowNotif] = useState(false)
  const notifRef = useRef<HTMLDivElement>(null)

  const { notifications, unreadCount, permission, markRead, markAllRead, clearAll, requestPermission } = useNotifications()

  let title = PAGE_TITLES[location.pathname] || 'Kiwi System'
  if (location.pathname.includes('/branches/')) title = 'تفاصيل الفرع والأداء'

  // Close panel on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(e.target as Node)) {
        setShowNotif(false)
      }
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
  }, [])

  return (
    <div className="app-layout">
      {/* ── Sidebar ── */}
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="brand-logo">
            <div className="brand-icon" style={{ background: 'var(--gray900)', color: 'white', boxShadow: 'none' }}>
              <Leaf size={24} />
            </div>
            <div>
              <div className="brand-name" style={{ letterSpacing: '0.5px' }}>KIWI</div>
              <div className="brand-sub">ENTERPRISE SYSTEM</div>
            </div>
          </div>
        </div>

        <nav className="sidebar-nav">
          {SECTIONS.map(section => {
            const items = NAV.filter(n => n.section === section)
            return (
              <div key={section}>
                <div className="nav-section-label">{section}</div>
                {items.map(item => {
                  const Icon = item.icon
                  const active = location.pathname === item.path || (location.pathname.includes('/branches/') && item.path === '/branches')
                  return (
                    <button
                      key={item.path}
                      className={`nav-item ${active ? 'active' : ''}`}
                      onClick={() => navigate(item.path)}
                      style={{ padding: '12px 16px', gap: 12 }}
                    >
                      <Icon size={20} className="nav-icon" />
                      <span style={{ fontSize: 15, fontWeight: 600 }}>{item.label}</span>
                    </button>
                  )
                })}
              </div>
            )
          })}
        </nav>

        <div className="sidebar-footer">
          <div className="user-card">
            <div className="user-avatar" style={{ background: 'var(--gray900)' }}>SA</div>
            <div>
              <div className="user-name">الإدارة العليا</div>
              <div className="user-role">Super Admin</div>
            </div>
            <Settings size={16} style={{ marginRight: 'auto', color: 'var(--gray400)', flexShrink: 0 }} />
          </div>
        </div>
      </aside>

      {/* ── Main ── */}
      <div className="main-content">
        <header className="topbar">
          <h1 className="topbar-title">{title}</h1>
          <div className="topbar-actions">
            <button className="icon-btn" title="طباعة الصفحة الحالية" onClick={() => window.print()}>
              <Printer size={18} />
            </button>
            <button className="icon-btn" title="بحث"><Search size={18} /></button>

            {/* Notifications Bell */}
            <div ref={notifRef} style={{ position: 'relative' }}>
              <button
                className="icon-btn"
                title="إشعارات"
                onClick={() => setShowNotif(v => !v)}
                style={{ position: 'relative' }}
              >
                <Bell size={18} />
                {unreadCount > 0 && (
                  <span style={{
                    position: 'absolute', top: -4, left: -4,
                    background: '#ef4444', color: 'white',
                    borderRadius: '50%', width: 18, height: 18,
                    fontSize: 10, fontWeight: 800,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    border: '2px solid white', lineHeight: 1,
                  }}>
                    {unreadCount > 9 ? '9+' : unreadCount}
                  </span>
                )}
              </button>

              {showNotif && (
                <NotificationPanel
                  notifications={notifications}
                  onMarkRead={markRead}
                  onMarkAllRead={markAllRead}
                  onClear={clearAll}
                  onClose={() => setShowNotif(false)}
                  onRequestPermission={requestPermission}
                  permission={permission}
                />
              )}
            </div>
          </div>
        </header>

        <main className="page-content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
