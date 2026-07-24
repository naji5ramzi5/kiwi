import { Component } from 'react'
import type { ErrorInfo, ReactNode } from 'react'

interface Props {
  children: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export default class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          justifyContent: 'center', minHeight: '60vh', padding: 40, textAlign: 'center',
        }}>
          <div style={{
            width: 80, height: 80, borderRadius: 24,
            background: 'linear-gradient(135deg, #fee2e2, #fecaca)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            marginBottom: 24,
          }}>
            <span style={{ fontSize: 36 }}>⚠️</span>
          </div>
          <h2 style={{ fontSize: 20, fontWeight: 800, color: '#111827', marginBottom: 8, fontFamily: 'Cairo' }}>
            حدث خطأ غير متوقع
          </h2>
          <p style={{ fontSize: 14, color: '#6b7280', marginBottom: 24, maxWidth: 400, fontFamily: 'Cairo' }}>
            {this.state.error?.message || 'تعذر تحميل الصفحة. حاول مرة أخرى.'}
          </p>
          <button
            onClick={() => this.setState({ hasError: false, error: null })}
            style={{
              padding: '10px 28px', borderRadius: 12, border: 'none', cursor: 'pointer',
              background: 'linear-gradient(135deg, #22c55e, #16a34a)',
              color: 'white', fontWeight: 700, fontSize: 14, fontFamily: 'Cairo',
              boxShadow: '0 4px 12px rgba(22,163,74,.25)',
            }}
          >
            إعادة المحاولة
          </button>
        </div>
      )
    }

    return this.props.children
  }
}
