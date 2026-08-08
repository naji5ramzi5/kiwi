import { useState, useEffect, lazy, Suspense } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import { supabase } from './lib/supabase'
import type { Session } from '@supabase/supabase-js'
import toast from 'react-hot-toast'
import Layout from './components/Layout'
import ErrorBoundary from './components/ErrorBoundary'
import Login from './pages/Login'

const Dashboard = lazy(() => import('./pages/Dashboard'))
const Products = lazy(() => import('./pages/Products'))
const Branches = lazy(() => import('./pages/Branches'))
const BranchDetail = lazy(() => import('./pages/BranchDetail'))
const Orders = lazy(() => import('./pages/Orders'))
const Drivers = lazy(() => import('./pages/Drivers'))
const Marketing = lazy(() => import('./pages/Marketing'))
const Finance = lazy(() => import('./pages/Finance'))
const FinancialDashboard = lazy(() => import('./pages/FinancialDashboard'))
const Settings = lazy(() => import('./pages/Settings'))
const Customers = lazy(() => import('./pages/Customers'))
const Inventory = lazy(() => import('./pages/Inventory'))
const Purchases = lazy(() => import('./pages/Purchases'))
const Categories = lazy(() => import('./pages/Categories'))
const AIChat = lazy(() => import('./pages/AIChat'))
const Ratings = lazy(() => import('./pages/Ratings'))
const OrderForm = lazy(() => import('./pages/OrderForm'))
const DeliveryZones = lazy(() => import('./pages/DeliveryZones'))
const BranchPrices = lazy(() => import('./pages/BranchPrices'))
const Profile = lazy(() => import('./pages/Profile'))
const TransferDelivery = lazy(() => import('./pages/TransferDelivery'))
const DeliveredOrders = lazy(() => import('./pages/DeliveredOrders'))
const DeliveryEmployeesReport = lazy(() => import('./pages/DeliveryEmployeesReport'))

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

  return (
    <BrowserRouter>
      <Toaster 
        position="top-center"
        toastOptions={{
          duration: 3000,
          style: {
            background: '#1f2937',
            color: '#fff',
            borderRadius: '12px',
            fontSize: '14px',
            fontFamily: 'Cairo, sans-serif',
            padding: '12px 20px',
          },
          success: {
            iconTheme: { primary: '#10b981', secondary: '#fff' },
          },
          error: {
            iconTheme: { primary: '#ef4444', secondary: '#fff' },
          },
        }}
      />
      <ErrorBoundary>
      <Suspense fallback={<div className="loader-overlay"><div className="loader"></div></div>}>
      <Routes>
        <Route path="/" element={
          <>
            <Layout />
          </>
        }>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="products" element={<Products />} />
          <Route path="branches" element={<Branches />} />
          <Route path="branches/:id" element={<BranchDetail />} />
          <Route path="orders" element={<Orders />} />
          <Route path="drivers" element={<Drivers />} />
          <Route path="transfer-delivery" element={<TransferDelivery />} />
          <Route path="delivered-orders" element={<DeliveredOrders />} />
          <Route path="delivery-employees-report" element={<DeliveryEmployeesReport />} />
          <Route path="marketing" element={<Marketing />} />
          <Route path="finance" element={<Finance />} />
          <Route path="financial-dashboard" element={<FinancialDashboard />} />
          <Route path="settings" element={<Settings />} />
          <Route path="customers" element={<Customers />} />
          <Route path="inventory" element={<Inventory />} />
          <Route path="purchases" element={<Purchases />} />
          <Route path="categories" element={<Categories />} />
          <Route path="delivery-zones" element={<DeliveryZones />} />
          <Route path="branch-prices" element={<BranchPrices />} />
          <Route path="ratings" element={<Ratings />} />
          <Route path="ai-chat" element={<AIChat />} />
          <Route path="checkout" element={<OrderForm />} />
          <Route path="profile" element={<Profile />} />
        </Route>
      </Routes>
      </Suspense>
      </ErrorBoundary>
    </BrowserRouter>
  )
}
