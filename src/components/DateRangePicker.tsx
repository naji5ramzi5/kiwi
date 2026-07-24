import { Calendar } from 'lucide-react'

interface DateRangePickerProps {
  startDate: string
  endDate: string
  onStartDateChange: (date: string) => void
  onEndDateChange: (date: string) => void
  label?: string
}

export default function DateRangePicker({ startDate, endDate, onStartDateChange, onEndDateChange, label = 'الفترة الزمنية' }: DateRangePickerProps) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, background: 'var(--white)', border: '1px solid var(--gray200)', borderRadius: 10, padding: '6px 14px' }}>
      <Calendar size={16} color="var(--gray400)" />
      <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--gray500)', whiteSpace: 'nowrap' }}>{label}</span>
      <input type="date" value={startDate} onChange={e => onStartDateChange(e.target.value)}
        style={{ border: '1px solid var(--gray200)', borderRadius: 8, padding: '6px 10px', fontSize: 12, fontFamily: 'var(--font-ar)', color: 'var(--gray700)', background: 'var(--gray50)', outline: 'none' }} />
      <span style={{ fontSize: 12, color: 'var(--gray400)' }}>—</span>
      <input type="date" value={endDate} onChange={e => onEndDateChange(e.target.value)}
        style={{ border: '1px solid var(--gray200)', borderRadius: 8, padding: '6px 10px', fontSize: 12, fontFamily: 'var(--font-ar)', color: 'var(--gray700)', background: 'var(--gray50)', outline: 'none' }} />
    </div>
  )
}
