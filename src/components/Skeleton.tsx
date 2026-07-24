interface SkeletonProps {
  type?: 'card' | 'table' | 'stats' | 'text'
  rows?: number
}

export default function Skeleton({ type = 'card', rows = 5 }: SkeletonProps) {
  if (type === 'stats') {
    return (
      <div className="stats-grid">
        {[1, 2, 3, 4].map(i => (
          <div key={i} className="skeleton skeleton-card" />
        ))}
      </div>
    )
  }

  if (type === 'table') {
    return (
      <div className="card" style={{ padding: 0 }}>
        <div style={{ padding: '18px 22px', borderBottom: '1px solid var(--gray100)' }}>
          <div className="skeleton skeleton-title" />
        </div>
        {Array.from({ length: rows }, (_, i) => (
          <div key={i} className="skeleton-row">
            <div className="skeleton skeleton-avatar" />
            <div className="skeleton" style={{ flex: 2, height: 14 }} />
            <div className="skeleton" style={{ flex: 1, height: 14 }} />
            <div className="skeleton" style={{ flex: 1, height: 14 }} />
          </div>
        ))}
      </div>
    )
  }

  if (type === 'text') {
    return (
      <div>
        <div className="skeleton skeleton-title" />
        {Array.from({ length: rows }, (_, i) => (
          <div key={i} className="skeleton skeleton-text" style={{ width: `${85 - i * 8}%` }} />
        ))}
      </div>
    )
  }

  // card
  return (
    <div className="card">
      <div style={{ padding: 22 }}>
        <div className="skeleton skeleton-title" />
        <div className="skeleton skeleton-text" style={{ width: '90%' }} />
        <div className="skeleton skeleton-text" style={{ width: '70%' }} />
        <div className="skeleton skeleton-text" style={{ width: '80%' }} />
      </div>
    </div>
  )
}
