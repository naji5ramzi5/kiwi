import { useState, useEffect } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { supabase } from './lib/supabase'
import type { Session } from '@supabase/supabase-js'
import toast from 'react-hot-toast'
import Layout from './components/Layout'
import ErrorBoundary from './components/ErrorBoundary'
import Dashboard from './pages/Dashboard'
import Products from './pages/Products'
import Branches from './pages/Branches'
import BranchDetail from './pages/BranchDetail'
import Orders from './pages/Orders'
import Drivers from './pages/Drivers'
import Marketing from './pages/Marketing'
import Finance from './pages/Finance'
import Customers from './pages/Customers'
import Inventory from './pages/Inventory'
import Purchases from './pages/Purchases'
import Categories from './pages/Categories'
import AIChat from './pages/AIChat'
import Ratings from './pages/Ratings'
import Login from './pages/Login'
import { GeoFenceStatus } from './components/GeoFenceStatus'
import OrderForm from './pages/OrderForm'
import DeliveryZones from './pages/DeliveryZones'
import Profile from './pages/Profile'

export default function App() {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      setSession(session)
      if (event === 'SIGNED_OUT') {
        toast.success('تم تسجيل الخروج بنجاح')
      }
      if (event === 'TOKEN_REFRESHED' && !session) {
        toast.error('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى')
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  if (loading) return <div className="loader-overlay"><div className="loader"></div></div>

  if (!session) {
    return <Login onLogin={async () => {
      const { data: { session: s } } = await supabase.auth.getSession()
      if (s) setSession(s)
    }} />
  }

  // Try to get a branchId from the session (if available) to limit the geo-fence check.
  // Adjust the path according to how you store branch info in the user's metadata.
  const branchId = session?.user?.app_metadata?.default_branch_id ?? null;

  return (
    <BrowserRouter>
      <ErrorBoundary>
      <Routes>
        <Route path="/" element={
          <>
            <Layout />
            <GeoFenceStatus branchId={branchId} />
          </>
        }>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="products" element={<Products />} />
          <Route path="branches" element={<Branches />} />
          <Route path="branches/:id" element={<BranchDetail />} />
          <Route path="orders" element={<Orders />} />
          <Route path="drivers" element={<Drivers />} />
          <Route path="marketing" element={<Marketing />} />
          <Route path="finance" element={<Finance />} />
          <Route path="customers" element={<Customers />} />
          <Route path="inventory" element={<Inventory />} />
          <Route path="purchases" element={<Purchases />} />
          <Route path="categories" element={<Categories />} />
          <Route path="delivery-zones" element={<DeliveryZones />} />
          <Route path="ratings" element={<Ratings />} />
          <Route path="ai-chat" element={<AIChat />} />
          <Route path="checkout" element={<OrderForm />} />
          <Route path="profile" element={<Profile />} />
        </Route>
      </Routes>
      </ErrorBoundary>
    </BrowserRouter>
  )
}
