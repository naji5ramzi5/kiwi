import { AlertTriangle, XCircle, CheckCircle } from 'lucide-react'

interface ConfirmDialogProps {
  open: boolean
  title: string
  description: string
  variant?: 'danger' | 'warning' | 'info'
  confirmLabel?: string
  cancelLabel?: string
  onConfirm: () => void
  onCancel: () => void
}

const VARIANTS = {
  danger: { icon: XCircle, iconBg: '#fee2e2', iconColor: '#dc2626', btnClass: 'btn-danger' },
  warning: { icon: AlertTriangle, iconBg: '#fef3c7', iconColor: '#d97706', btnClass: 'btn-primary' },
  info: { icon: CheckCircle, iconBg: '#dbeafe', iconColor: '#2563eb', btnClass: 'btn-primary' },
}

export default function ConfirmDialog({ open, title, description, variant = 'danger', confirmLabel = 'تأكيد', cancelLabel = 'إلغاء', onConfirm, onCancel }: ConfirmDialogProps) {
  if (!open) return null
  const v = VARIANTS[variant]
  const Icon = v.icon

  return (
    <div className="confirm-overlay" onClick={onCancel}>
      <div className="confirm-box" onClick={e => e.stopPropagation()}>
        <div className="confirm-icon" style={{ background: v.iconBg }}>
          <Icon size={28} color={v.iconColor} />
        </div>
        <div className="confirm-title">{title}</div>
        <div className="confirm-desc">{description}</div>
        <div className="confirm-actions">
          <button className={`btn ${v.btnClass}`} onClick={onConfirm}>{confirmLabel}</button>
          <button className="btn btn-ghost" onClick={onCancel}>{cancelLabel}</button>
        </div>
      </div>
    </div>
  )
}
