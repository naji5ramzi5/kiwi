import { useState, useRef, useEffect } from 'react'
import { Send, Bot, User, Sparkles, TrendingUp, AlertCircle, ShoppingBag, DollarSign } from 'lucide-react'
import { supabase } from '../lib/supabase'

interface Message {
  role: 'user' | 'assistant';
  content: string;
  type?: 'text' | 'chart' | 'stat';
  data?: any;
}

export default function AIChat() {
  const [messages, setMessages] = useState<Message[]>([
    { 
      role: 'assistant', 
      content: 'أهلاً بك يا مدير! أنا KiwiAI، مساعدك الذكي. يمكنني تحليل البيانات، تقديم تقارير عن المبيعات، التنبؤ بالتوالف، أو حتى اقتراح أسعار جديدة. كيف يمكنني مساعدتك اليوم؟' 
    }
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const chatEndRef = useRef<HTMLDivElement>(null)

  const scrollToBottom = () => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const handleSend = async () => {
    if (!input.trim()) return
    
    const userMsg = input.trim()
    setMessages(prev => [...prev, { role: 'user', content: userMsg }])
    setInput('')
    setLoading(true)

    // Simulate AI thinking and querying DB
    setTimeout(async () => {
      let aiResponse: Message = { role: 'assistant', content: 'عذراً، لم أفهم طلبك بدقة. هل يمكنك سؤال عن المبيعات، الفروع، أو التوالف؟' }

      if (userMsg.includes('مبيعات') || userMsg.includes('بكم') || userMsg.includes('دخل')) {
        const { data: sales } = await supabase.from('orders').select('total_amount').eq('status', 'delivered');
        const total = sales?.reduce((sum, o) => sum + (o.total_amount || 0), 0) || 0;
        aiResponse = { 
          role: 'assistant', 
          content: `إجمالي المبيعات المكتملة للنظام حتى الآن هو ${total.toLocaleString('ar-IQ')} د.ع. هل تريد تحليل المبيعات لكل فرع على حدة؟`,
          type: 'stat',
          data: { label: 'إجمالي المبيعات', value: total.toLocaleString('ar-IQ'), icon: DollarSign }
        }
      } else if (userMsg.includes('توالف') || userMsg.includes('خسارة') || userMsg.includes('تلف')) {
        const { data: waste } = await supabase.from('waste_records').select('loss_value');
        const totalLoss = waste?.reduce((sum, w) => sum + (w.loss_value || 0), 0) || 0;
        aiResponse = { 
          role: 'assistant', 
          content: `سجلت التقارير خسائر ناتجة عن التوالف بقيمة إجمالية ${totalLoss.toLocaleString('ar-IQ')} د.ع. أنصح بمراجعة مخزون فرع "الكرادة" حيث سجل أعلى نسبة تلف اليوم.`,
          type: 'stat',
          data: { label: 'إجمالي التوالف', value: totalLoss.toLocaleString('ar-IQ'), icon: AlertCircle, color: '#ef4444' }
        }
      } else if (userMsg.includes('فروع') || userMsg.includes('فرع')) {
        const { data: branches } = await supabase.from('branches').select('count');
        aiResponse = { 
          role: 'assistant', 
          content: `النظام يضم حالياً ${branches?.[0]?.count || 0} فروع نشطة. جميعها تعمل بشكل طبيعي باستثناء فرع "المنصور" الذي يشهد ضغط طلبات مرتفع حالياً.`,
          type: 'stat',
          data: { label: 'عدد الفروع', value: branches?.[0]?.count || 0, icon: ShoppingBag }
        }
      }

      setMessages(prev => [...prev, aiResponse])
      setLoading(false)
    }, 1000)
  }

  return (
    <div className="animate-in" style={{ height: 'calc(100vh - 140px)', display: 'flex', flexDirection: 'column' }}>
      <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: 0, overflow: 'hidden' }}>
        {/* Chat Header */}
        <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--gray100)', display: 'flex', alignItems: 'center', gap: 12, background: 'var(--g50)' }}>
          <div style={{ width: 40, height: 40, borderRadius: 12, background: 'var(--gray900)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
            <Bot size={24} />
          </div>
          <div>
            <div style={{ fontWeight: 800, fontSize: 16 }}>KiwiAI Assistant</div>
            <div style={{ fontSize: 12, color: 'var(--g700)', display: 'flex', alignItems: 'center', gap: 4 }}>
              <Sparkles size={12} /> متصل وجاهز للتحليل
            </div>
          </div>
        </div>

        {/* Messages Area */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '24px', display: 'flex', flexDirection: 'column', gap: 20 }}>
          {messages.map((m, i) => (
            <div key={i} style={{ display: 'flex', justifyContent: m.role === 'user' ? 'flex-start' : 'flex-end', flexDirection: m.role === 'user' ? 'row-reverse' : 'row', gap: 12 }}>
              <div style={{ 
                width: 32, height: 32, borderRadius: 10, flexShrink: 0,
                background: m.role === 'user' ? 'var(--g500)' : 'var(--gray900)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white'
              }}>
                {m.role === 'user' ? <User size={18} /> : <Bot size={18} />}
              </div>
              <div style={{ maxWidth: '70%' }}>
                <div style={{ 
                  padding: '12px 16px', borderRadius: 16, fontSize: 14, lineHeight: 1.6,
                  background: m.role === 'user' ? 'var(--g50)' : 'white',
                  border: '1px solid ' + (m.role === 'user' ? 'var(--g100)' : 'var(--gray100)'),
                  color: 'var(--gray900)',
                  boxShadow: '0 2px 5px rgba(0,0,0,0.02)'
                }}>
                  {m.content}
                </div>
                
                {m.data && (
                  <div className="card" style={{ marginTop: 12, padding: 16, borderLeft: `4px solid ${m.data.color || 'var(--g500)'}` }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <m.data.icon size={20} color={m.data.color || 'var(--g500)'} />
                      <div>
                        <div style={{ fontSize: 11, color: 'var(--gray400)' }}>{m.data.label}</div>
                        <div style={{ fontSize: 20, fontWeight: 900 }}>{m.data.value}</div>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          ))}
          {loading && (
            <div style={{ display: 'flex', gap: 12 }}>
              <div style={{ width: 32, height: 32, borderRadius: 10, background: 'var(--gray900)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
                <Bot size={18} />
              </div>
              <div className="loader-dots"><span></span><span></span><span></span></div>
            </div>
          )}
          <div ref={chatEndRef} />
        </div>

        {/* Input Area */}
        <div style={{ padding: 24, borderTop: '1px solid var(--gray100)', background: 'white' }}>
          <div style={{ display: 'flex', gap: 12 }}>
            <input 
              className="form-input" 
              placeholder="اسألني أي شيء عن المبيعات، المخزون، أو التوالف..." 
              style={{ flex: 1, height: 48, borderRadius: 12 }}
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleSend()}
            />
            <button className="btn btn-primary" style={{ width: 48, height: 48, padding: 0, borderRadius: 12 }} onClick={handleSend}>
              <Send size={20} />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
