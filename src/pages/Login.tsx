import { useState } from 'react'
import { Leaf, Lock, User, Eye, EyeOff } from 'lucide-react'
import { supabase } from '../lib/supabase'

export default function Login({ onLogin }: { onLogin: () => void }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [showPass, setShowPass] = useState(false)
  const [error, setError] = useState('')

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')
    
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    
    if (error) {
      setError('خطأ في تسجيل الدخول. يرجى التأكد من البيانات.')
      setLoading(false)
    } else {
      onLogin()
    }
  }

  return (
    <div className="login-page" style={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--gray50)' }}>
      <div className="card" style={{ width: '100%', maxWidth: 400, padding: 40 }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div className="brand-icon" style={{ margin: '0 auto 16px', width: 64, height: 64, borderRadius: 20 }}>
            <Leaf size={32} color="white" />
          </div>
          <h1 style={{ fontSize: 24, fontWeight: 800 }}>لوحة تحكم "فرش"</h1>
          <p style={{ color: 'var(--gray400)', fontSize: 13, marginTop: 4 }}>الإدارة المركزية للفروع والمنظومة</p>
        </div>

        {error && <div style={{ background: '#fee2e2', color: '#b91c1c', padding: '12px', borderRadius: 8, fontSize: 13, marginBottom: 20, textAlign: 'center' }}>{error}</div>}

        <form onSubmit={handleLogin}>
          <div className="form-group">
            <label className="form-label">البريد الإلكتروني / اسم المستخدم</label>
            <div style={{ position: 'relative' }}>
              <User size={18} style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
              <input 
                className="form-input" 
                style={{ paddingRight: 44 }} 
                type="email" 
                placeholder="admin@fresh.iq" 
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">كلمة المرور</label>
            <div style={{ position: 'relative' }}>
              <Lock size={18} style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
              <input 
                className="form-input" 
                style={{ paddingRight: 44, paddingLeft: 44 }} 
                type={showPass ? 'text' : 'password'} 
                placeholder="••••••••" 
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
              />
              <button 
                type="button"
                onClick={() => setShowPass(!showPass)}
                style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', border: 'none', background: 'none', color: 'var(--gray400)', cursor: 'pointer' }}
              >
                {showPass ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <button className="btn btn-primary" style={{ width: '100%', padding: 14, marginTop: 10 }} disabled={loading}>
            {loading ? 'جاري التحقق...' : 'تسجيل الدخول للنظام'}
          </button>
        </form>

        <div style={{ textAlign: 'center', marginTop: 24, fontSize: 12, color: 'var(--gray400)' }}>
          جميع الحقوق محفوظة لمنظومة "فرش" 2026 ©
        </div>
      </div>
    </div>
  )
}
