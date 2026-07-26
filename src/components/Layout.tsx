import { useState, useRef, useEffect } from 'react'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, Package, GitBranch, ShoppingCart, Activity,
  Truck, Megaphone, DollarSign, Users, Bell, Search, Settings, FileText, Box, Leaf,
  X, CheckCheck, Trash2, ShieldAlert, Tag, UserCheck, Printer, MapPin, Star,
  Moon, Sun, ChevronDown, ChevronLeft, LogOut, User, Home
} from 'lucide-react'
import { useNotifications } from '../lib/notifications'
import type { AppNotification } from '../lib/notifications'

const NAV = [
  { label: 'الرئيسية', path: '/dashboard', icon: LayoutDashboard, section: 'اللوحة المركزية', color: '#10b981' },
  { label: 'الطلبات الحية', path: '/orders', icon: Activity, section: 'اللوحة المركزية', color: '#10b981' },
  
  { label: 'المخزون المركزي', path: '/inventory', icon: Box, section: 'التشغيل', color: '#3b82f6' },
  { label: 'المشتريات والتوريد', path: '/purchases', icon: FileText, section: 'التشغيل', color: '#3b82f6' },
  { label: 'إدارة المنتجات', path: '/products', icon: Package, section: 'التشغيل', color: '#3b82f6' },
  { label: 'الفئات المركزية', path: '/categories', icon: Tag, section: 'التشغيل', color: '#3b82f6' },
  
  { label: 'الفروع', path: '/branches', icon: GitBranch, section: 'الموارد البشرية والفروع', color: '#f59e0b' },
  { label: 'مناطق التوصيل', path: '/delivery-zones', icon: MapPin, section: 'الموارد البشرية والفروع', color: '#f59e0b' },
  { label: 'المناديب والسائقين', path: '/drivers', icon: Truck, section: 'الموارد البشرية والفروع', color: '#f59e0b' },
  { label: 'التقييمات', path: '/ratings', icon: Star, section: 'الموارد البشرية والفروع', color: '#f59e0b' },
  { label: 'العملاء', path: '/customers', icon: Users, section: 'الموارد البشرية والفروع', color: '#f59e0b' },
  
  { label: 'الحسابات والتقارير', path: '/finance', icon: DollarSign, section: 'المالية والتسويق', color: '#8b5cf6' },
  { label: 'التسويق', path: '/marketing', icon: Megaphone, section: 'المالية والتسويق', color: '#8b5cf6' },
  { label: 'KiwiAI (الذكاء الاصطناعي)', path: '/ai-chat', icon: Activity, section: 'الذكاء الاصطناعي', color: '#ec4899' },
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

const BREADCRUMBS: Record<string, { parent: string; parentPath: string; current: string }> = {
  '/dashboard': { parent: 'الرئيسية', parentPath: '/dashboard', current: 'لوحة التحكم' },
  '/orders': { parent: 'الرئيسية', parentPath: '/dashboard', current: 'الطلبات الحية' },
  '/inventory': { parent: 'التشغيل', parentPath: '/inventory', current: 'المخزون' },
  '/purchases': { parent: 'التشغيل', parentPath: '/inventory', current: 'المشتريات' },
  '/products': { parent: 'التشغيل', parentPath: '/inventory', current: 'المنتجات' },
  '/branches': { parent: 'الفروع', parentPath: '/branches', current: 'إدارة الفروع' },
  '/delivery-zones': { parent: 'الفروع', parentPath: '/branches', current: 'مناطق التوصيل' },
  '/drivers': { parent: 'الفروع', parentPath: '/branches', current: 'المناديب' },
  '/ratings': { parent: 'الفروع', parentPath: '/branches', current: 'التقييمات' },
  '/customers': { parent: 'الفروع', parentPath: '/branches', current: 'العملاء' },
  '/finance': { parent: 'المالية', parentPath: '/finance', current: 'التقارير' },
  '/marketing': { parent: 'المالية', parentPath: '/finance', current: 'التسويق' },
  '/ai-chat': { parent: 'الرئيسية', parentPath: '/dashboard', current: 'KiwiAI' },
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
      position: 'absolute', top: '100%', left: 0, width: 360, background: 'var(--white)',
      borderRadius: 16, boxShadow: '0 20px 60px rgba(0,0,0,.15)', border: '1px solid var(--gray100)',
      zIndex: 1000, overflow: 'hidden', marginTop: 8
    }}>
      <div style={{ padding: '14px 18px', borderBottom: '1px solid var(--gray100)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--gray900)' }}>الإشعارات</div>
          <div style={{ fontSize: 11, color: 'var(--gray400)', marginTop: 1 }}>
            {notifications.filter(n => !n.read).length} غير مقروء
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <button className="btn btn-ghost btn-sm" onClick={onMarkAllRead} title="تحديد الكل كمقروء"><CheckCheck size={14} /></button>
          <button className="btn btn-ghost btn-sm" onClick={onClear} title="مسح الكل"><Trash2 size={14} /></button>
          <button className="btn btn-ghost btn-sm" onClick={onClose}><X size={14} /></button>
        </div>
      </div>

      {permission !== 'granted' && (
        <div style={{ padding: '10px 18px', background: '#fef3c7', borderBottom: '1px solid #fde68a', display: 'flex', alignItems: 'center', gap: 10 }}>
          <ShieldAlert size={16} color="#d97706" />
          <div style={{ flex: 1, fontSize: 12, color: '#92400e' }}>الإشعارات غير مفعّلة</div>
          <button className="btn btn-sm" style={{ background: '#d97706', color: 'white', fontSize: 11, padding: '3px 10px' }} onClick={onRequestPermission}>تفعيل</button>
        </div>
      )}

      <div style={{ maxHeight: 380, overflowY: 'auto' }}>
        {notifications.length === 0 ? (
          <div style={{ padding: '40px 20px', textAlign: 'center', color: 'var(--gray400)' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>🔔</div>
            <div style={{ fontSize: 13 }}>لا توجد إشعارات</div>
          </div>
        ) : (
          notifications.map(n => (
            <div key={n.id} onClick={() => onMarkRead(n.id)}
              style={{
                padding: '12px 18px', borderBottom: '1px solid var(--gray50)',
                background: n.read ? 'var(--white)' : 'var(--g50)',
                cursor: 'pointer', display: 'flex', gap: 12, alignItems: 'flex-start', transition: 'background .15s',
              }}>
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
  const [showUserMenu, setShowUserMenu] = useState(false)
  const [collapsedSections, setCollapsedSections] = useState<Record<string, boolean>>({})
  const [searchExpanded, setSearchExpanded] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const notifRef = useRef<HTMLDivElement>(null)
  const userMenuRef = useRef<HTMLDivElement>(null)
  const searchRef = useRef<HTMLDivElement>(null)
  const [isDark, setIsDark] = useState(() => localStorage.getItem('theme') === 'dark')

  const { notifications, unreadCount, permission, markRead, markAllRead, clearAll, requestPermission } = useNotifications()

  useEffect(() => {
    document.documentElement.classList.toggle('dark', isDark)
    localStorage.setItem('theme', isDark ? 'dark' : 'light')
  }, [isDark])

  let title = PAGE_TITLES[location.pathname] || 'Kiwi System'
  if (location.pathname.includes('/branches/')) title = 'تفاصيل الفرع والأداء'
  const breadcrumb = BREADCRUMBS[location.pathname]

  // Search results
  const searchResults = searchQuery.length > 0
    ? NAV.filter(n => n.label.includes(searchQuery)).slice(0, 5)
    : []

  // Close panels on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(e.target as Node)) setShowNotif(false)
      if (userMenuRef.current && !userMenuRef.current.contains(e.target as Node)) setShowUserMenu(false)
      if (searchRef.current && !searchRef.current.contains(e.target as Node)) { setSearchExpanded(false); setSearchQuery('') }
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
  }, [])

  function toggleSection(section: string) {
    setCollapsedSections(prev => ({ ...prev, [section]: !prev[section] }))
  }

  return (
    <div className="app-layout">
      {/* ── Sidebar ── */}
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="brand-logo">
            <img src="/kiwi-logo.jpg" alt="Kiwi" style={{ width: 40, height: 40, borderRadius: '50%', boxShadow: '0 4px 12px rgba(16,185,129,.3)', objectFit: 'cover' }} />
            <div>
              <div className="brand-name" style={{ letterSpacing: '0.5px' }}>KIWI</div>
              <div className="brand-sub">ENTERPRISE SYSTEM</div>
            </div>
          </div>
        </div>

        <nav className="sidebar-nav">
          {SECTIONS.map(section => {
            const items = NAV.filter(n => n.section === section)
            const isCollapsed = collapsedSections[section]
            return (
              <div key={section}>
                <div className="nav-section-label" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', cursor: 'pointer' }}
                  onClick={() => toggleSection(section)}>
                  <span>{section}</span>
                  <ChevronLeft size={14} style={{ transition: 'transform .2s', transform: isCollapsed ? 'rotate(-90deg)' : 'rotate(0deg)' }} />
                </div>
                {!isCollapsed && items.map(item => {
                  const Icon = item.icon
                  const active = location.pathname === item.path || (location.pathname.includes('/branches/') && item.path === '/branches')
                  return (
                    <button key={item.path} className={`nav-item ${active ? 'active' : ''}`}
                      onClick={() => navigate(item.path)} style={{ padding: '12px 16px', gap: 12 }}>
                      <Icon size={20} className="nav-icon" style={!active ? { color: item.color } : undefined} />
                      <span style={{ fontSize: 15, fontWeight: 600 }}>{item.label}</span>
                    </button>
                  )
                })}
              </div>
            )
          })}
        </nav>

        <div className="sidebar-footer">
          <div ref={userMenuRef} style={{ position: 'relative' }}>
            <div className="user-card" onClick={() => setShowUserMenu(v => !v)}>
              <div className="user-avatar" style={{ background: 'var(--gray900)' }}>SA</div>
              <div style={{ flex: 1 }}>
                <div className="user-name">الإدارة العليا</div>
                <div className="user-role">Super Admin</div>
              </div>
              <ChevronDown size={14} style={{ color: 'var(--gray400)', flexShrink: 0, transition: 'transform .2s', transform: showUserMenu ? 'rotate(180deg)' : 'none' }} />
            </div>
            {showUserMenu && (
              <div style={{
                position: 'absolute', bottom: '100%', right: 0, left: 0,
                background: 'var(--white)', borderRadius: 12, boxShadow: '0 -8px 30px rgba(0,0,0,.12)',
                border: '1px solid var(--gray100)', marginBottom: 8, overflow: 'hidden', zIndex: 1000
              }}>
                <button style={{ width: '100%', padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 10, background: 'none', border: 'none', cursor: 'pointer', fontSize: 13, fontWeight: 600, color: 'var(--gray700)', fontFamily: 'var(--font-ar)' }}
                  onClick={() => { navigate('/profile'); setShowUserMenu(false) }}>
                  <User size={16} /> الملف الشخصي
                </button>
                <button style={{ width: '100%', padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 10, background: 'none', border: 'none', cursor: 'pointer', fontSize: 13, fontWeight: 600, color: 'var(--gray700)', fontFamily: 'var(--font-ar)' }}
                  onClick={() => { navigate('/dashboard'); setShowUserMenu(false) }}>
                  <Settings size={16} /> الإعدادات
                </button>
                <div style={{ borderTop: '1px solid var(--gray100)' }}>
                  <button style={{ width: '100%', padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 10, background: 'none', border: 'none', cursor: 'pointer', fontSize: 13, fontWeight: 600, color: '#ef4444', fontFamily: 'var(--font-ar)' }}
                    onClick={() => { localStorage.removeItem('token'); window.location.href = '/login' }}>
                    <LogOut size={16} /> تسجيل الخروج
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </aside>

      {/* ── Main ── */}
      <div className="main-content">
        <header className="topbar">
          <div style={{ flex: 1 }}>
            <h1 className="topbar-title">{title}</h1>
            {breadcrumb && (
              <div className="breadcrumb">
                <Home size={12} />
                <span className="breadcrumb-sep">/</span>
                <span style={{ cursor: 'pointer' }} onClick={() => navigate(breadcrumb.parentPath)}>{breadcrumb.parent}</span>
                <span className="breadcrumb-sep">/</span>
                <span className="breadcrumb-current">{breadcrumb.current}</span>
              </div>
            )}
          </div>
          <div className="topbar-actions">
            <button className="icon-btn" title={isDark ? 'الوضع الفاتح' : 'الوضع الداكن'} onClick={() => setIsDark(d => !d)}>
              {isDark ? <Sun size={18} /> : <Moon size={18} />}
            </button>
            <button className="icon-btn" title="طباعة الصفحة الحالية" onClick={() => window.print()}>
              <Printer size={18} />
            </button>

            {/* Expandable Search */}
            <div ref={searchRef} style={{ position: 'relative' }}>
              <button className="icon-btn" title="بحث" onClick={() => setSearchExpanded(v => !v)}>
                <Search size={18} />
              </button>
              {searchExpanded && (
                <div style={{
                  position: 'absolute', top: '100%', left: 0, width: 320, marginTop: 8,
                  background: 'var(--white)', borderRadius: 12, boxShadow: '0 12px 40px rgba(0,0,0,.15)',
                  border: '1px solid var(--gray100)', overflow: 'hidden', zIndex: 1000
                }}>
                  <div style={{ padding: '12px 16px', borderBottom: '1px solid var(--gray100)', display: 'flex', alignItems: 'center', gap: 10 }}>
                    <Search size={16} color="var(--gray400)" />
                    <input autoFocus value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
                      placeholder="ابحث عن صفحة..." style={{ border: 'none', outline: 'none', background: 'transparent', flex: 1, fontSize: 13, fontFamily: 'var(--font-ar)' }} />
                    {searchQuery && <button onClick={() => setSearchQuery('')} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}><X size={14} color="var(--gray400)" /></button>}
                  </div>
                  {searchResults.length > 0 && (
                    <div style={{ maxHeight: 250, overflowY: 'auto' }}>
                      {searchResults.map(r => {
                        const Icon = r.icon
                        return (
                          <button key={r.path} onClick={() => { navigate(r.path); setSearchExpanded(false); setSearchQuery('') }}
                            style={{ width: '100%', padding: '10px 16px', display: 'flex', alignItems: 'center', gap: 10, background: 'none', border: 'none', borderBottom: '1px solid var(--gray50)', cursor: 'pointer', fontSize: 13, fontWeight: 600, color: 'var(--gray700)', fontFamily: 'var(--font-ar)', textAlign: 'right' }}>
                            <Icon size={16} color={r.color} /> {r.label}
                          </button>
                        )
                      })}
                    </div>
                  )}
                  {searchQuery.length > 0 && searchResults.length === 0 && (
                    <div style={{ padding: 20, textAlign: 'center', color: 'var(--gray400)', fontSize: 12 }}>لا توجد نتائج</div>
                  )}
                </div>
              )}
            </div>

            {/* Notifications Bell */}
            <div ref={notifRef} style={{ position: 'relative' }}>
              <button className="icon-btn" title="إشعارات" onClick={() => setShowNotif(v => !v)} style={{ position: 'relative' }}>
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
