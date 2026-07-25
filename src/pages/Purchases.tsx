import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { 
  FileText, Plus, Search, User, DollarSign, Package,
  MoreVertical, X, TrendingUp, ShoppingCart
} from 'lucide-react';
import toast from 'react-hot-toast';

interface Product {
  id: string;
  name: string;
  cost: number;
}

interface PurchaseItem {
  product_id: string;
  name: string;
  quantity: number;
  unit_cost: number;
}

interface Purchase {
  id: string;
  created_at: string;
  supplier_name: string;
  total_amount: number;
  status: string;
  total_value?: number;
  branches?: { name: string };
}

const Purchases = () => {
  const [purchases, setPurchases] = useState<Purchase[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [search, setSearch] = useState('');
  const [supplierName, setSupplierName] = useState('');
  const [cart, setCart] = useState<PurchaseItem[]>([]);
  const [saving, setSaving] = useState(false);
  const [branches, setBranches] = useState<Array<{ id: string; name: string }>>([]);
  const [selectedBranchId, setSelectedBranchId] = useState<string>('');
  const [page, setPage] = useState(1);
  const [productSearch, setProductSearch] = useState('');
  const PAGE_SIZE = 15;

  const fetchBranches = async () => {
    const { data } = await supabase.from('branches').select('id, name');
    setBranches(data || []);
    if (data && data.length > 0) setSelectedBranchId(data[0].id);
  };

  const fetchPurchases = async () => {
    try {
      const { data, error } = await supabase
        .from('purchases')
        .select('*, branches(name)')
        .order('created_at', { ascending: false });
      if (error && error.code !== '42P01') throw error;
      setPurchases(data || []);
    } catch (err) {
      console.error('Error fetching purchases:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchProducts = async () => {
    const { data } = await supabase.from('products').select('id, name, cost');
    setProducts(data || []);
  };

  useEffect(() => {
    void (async () => {
      await fetchPurchases();
      await fetchProducts();
      await fetchBranches();
    })();
  }, []);

  const addToCart = (product: Product) => {
    const existing = cart.find(item => item.product_id === product.id);
    if (existing) {
      setCart(cart.map(item => 
        item.product_id === product.id 
          ? { ...item, quantity: item.quantity + 1 }
          : item
      ));
    } else {
      setCart([...cart, { 
        product_id: product.id, 
        name: product.name, 
        quantity: 1, 
        unit_cost: product.cost || 0 
      }]);
    }
  };

  const removeFromCart = (productId: string) => {
    setCart(cart.filter(item => item.product_id !== productId));
  };

  const updateQuantity = (productId: string, q: number) => {
    setCart(cart.map(item => 
      item.product_id === productId ? { ...item, quantity: Math.max(0.1, q) } : item
    ));
  };

  const totalAmount = cart.reduce((sum, item) => sum + (item.quantity * item.unit_cost), 0);

  const filteredPurchases = purchases.filter(p => !search || p.supplier_name?.includes(search));
  const totalPages = Math.max(1, Math.ceil(filteredPurchases.length / PAGE_SIZE));
  const pagedPurchases = filteredPurchases.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  const filteredProducts = products.filter(p => 
    !productSearch || p.name.includes(productSearch)
  );

  const savePurchase = async () => {
    if (!supplierName || cart.length === 0 || !selectedBranchId) {
      toast.error('يرجى إدخال اسم المورد واختيار الفرع وأصناف الفاتورة');
      return;
    }
    setSaving(true);
    try {
      const { data: purchase, error: pError } = await supabase
        .from('purchases')
        .insert({
          branch_id: selectedBranchId,
          supplier_name: supplierName,
          total_value: totalAmount,
          payment_status: 'مدفوع'
        })
        .select()
        .single();
      if (pError) throw pError;

      const items = cart.map(item => ({
        purchase_id: purchase.id,
        product_id: item.product_id,
        quantity: item.quantity,
        unit_cost: item.unit_cost,
        total_cost: item.quantity * item.unit_cost
      }));
      const { error: iError } = await supabase.from('purchase_items').insert(items);
      if (iError) throw iError;

      toast.success('تم تسجيل فاتورة الشراء وتحديث المخزون');
      setShowModal(false);
      setCart([]);
      setSupplierName('');
      fetchPurchases();
    } catch (err: unknown) {
      toast.error('خطأ في الحفظ: ' + ((err as Error).message));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={{ height: '100vh', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      {/* Header */}
      <div style={{ padding: '24px 32px 0', flexShrink: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <div>
            <h1 className="brand-name" style={{ fontSize: 24, margin: 0 }}>المشتريات والتوريد</h1>
            <p className="brand-sub" style={{ margin: '4px 0 0' }}>إدارة فواتير الموردين وتحديث المخزون المركزي</p>
          </div>
          <button className="btn btn-primary" onClick={() => setShowModal(true)}>
            <Plus size={18} /> إضافة فاتورة شراء
          </button>
        </div>

        {/* Search + Stats */}
        <div style={{ display: 'flex', gap: 16, marginBottom: 20, alignItems: 'center' }}>
          <div className="icon-btn" style={{ flex: 1, maxWidth: 300, gap: 8, padding: '0 16px' }}>
            <Search size={16} />
            <input 
              placeholder="بحث بالمورد..." 
              style={{ border: 'none', outline: 'none', background: 'transparent', flex: 1, fontSize: 13 }}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
        </div>

        {/* Stats Cards */}
        <div className="stats-grid" style={{ marginBottom: 20 }}>
          <div className="stat-card stat-green">
            <div className="stat-icon-wrap" style={{ background: 'var(--g50)' }}><DollarSign color="var(--g600)" /></div>
            <div className="stat-label">إجمالي المشتريات</div>
            <div className="stat-value">{purchases.reduce((s, p) => s + (p.total_value || p.total_amount || 0), 0).toLocaleString()} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
          </div>
          <div className="stat-card stat-blue">
            <div className="stat-icon-wrap" style={{ background: '#dbeafe' }}><FileText color="#2563eb" /></div>
            <div className="stat-label">عدد الفواتير</div>
            <div className="stat-value">{purchases.length} <span style={{ fontSize: 12, fontWeight: 500 }}>فاتورة</span></div>
          </div>
          <div className="stat-card stat-amber">
            <div className="stat-icon-wrap" style={{ background: '#fff7ed' }}><Package color="#ea580c" /></div>
            <div className="stat-label">الموردين النشطين</div>
            <div className="stat-value">{new Set(purchases.map(p => p.supplier_name)).size} <span style={{ fontSize: 12, fontWeight: 500 }}>مورد</span></div>
          </div>
        </div>
      </div>

      {/* Scrollable Table */}
      <div style={{ flex: 1, overflow: 'auto', padding: '0 32px 24px' }}>
        <div className="card" style={{ margin: 0 }}>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>رقم الفاتورة</th>
                  <th>المورد</th>
                  <th>الفرع المستلم</th>
                  <th>التاريخ</th>
                  <th>الإجمالي</th>
                  <th style={{ textAlign: 'center' }}>الإجراءات</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan={6} style={{ textAlign: 'center', padding: 40 }}><div className="loader" style={{ margin: 'auto' }}></div></td></tr>
                ) : pagedPurchases.length === 0 ? (
                  <tr>
                    <td colSpan={6} style={{ textAlign: 'center', color: 'var(--gray400)', padding: '40px 0' }}>
                      <FileText size={40} style={{ marginBottom: 12, opacity: 0.2, display: 'block', margin: '0 auto 12px' }} />
                      لا توجد فواتير مسجلة بعد
                    </td>
                  </tr>
                ) : (
                  pagedPurchases.map(p => (
                    <tr key={p.id}>
                      <td style={{ fontSize: 13, fontFamily: 'monospace', color: 'var(--gray400)' }}>#{p.id.substring(0, 8)}</td>
                      <td style={{ fontWeight: 700 }}>{p.supplier_name}</td>
                      <td style={{ fontSize: 13, color: 'var(--gray600)' }}>{p.branches?.name || 'مستودع مركزي'}</td>
                      <td style={{ fontSize: 13, color: 'var(--gray500)' }}>{new Date(p.created_at).toLocaleDateString('ar-IQ')}</td>
                      <td style={{ fontWeight: 800, color: 'var(--g700)' }}>{(p.total_value || p.total_amount || 0).toLocaleString()} د.ع</td>
                      <td style={{ textAlign: 'center' }}>
                        <button className="btn btn-icon btn-ghost btn-sm"><MoreVertical size={18} /></button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 8, marginTop: 20 }}>
            <button className="btn btn-ghost btn-sm" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>السابق</button>
            {Array.from({ length: totalPages }, (_, i) => (
              <button key={i} className={`btn btn-sm ${page === i + 1 ? 'btn-primary' : 'btn-ghost'}`} onClick={() => setPage(i + 1)}>{i + 1}</button>
            ))}
            <button className="btn btn-ghost btn-sm" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>التالي</button>
          </div>
        )}
      </div>

      {/* Add Purchase Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 900, height: '85vh', display: 'flex', flexDirection: 'column' }}>
            {/* Modal Header */}
            <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--gray100)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
              <div>
                <h2 className="modal-title" style={{ margin: 0, fontSize: 18 }}>تسجيل فاتورة توريد جديدة</h2>
                <p style={{ fontSize: 12, color: 'var(--gray500)', margin: '4px 0 0' }}>اختر المنتجات وحدد الكميات المستلمة</p>
              </div>
              <button onClick={() => setShowModal(false)} className="btn btn-icon btn-ghost"><X size={20} /></button>
            </div>

            <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>
              {/* Products Side */}
              <div style={{ flex: 1, padding: 20, overflowY: 'auto', borderLeft: '1px solid var(--gray100)' }}>
                <div className="icon-btn" style={{ gap: 8, padding: '0 14px', marginBottom: 16 }}>
                  <Search size={16} />
                  <input 
                    placeholder="ابحث عن منتج..." 
                    style={{ border: 'none', outline: 'none', background: 'transparent', flex: 1, fontSize: 13 }}
                    value={productSearch}
                    onChange={e => setProductSearch(e.target.value)}
                  />
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: 10 }}>
                  {filteredProducts.map(product => (
                    <button 
                      key={product.id}
                      onClick={() => addToCart(product)}
                      className="card"
                      style={{ padding: 14, textAlign: 'right', cursor: 'pointer', transition: 'all .2s', border: '1px solid var(--gray100)' }}
                      onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--g400)'; e.currentTarget.style.boxShadow = 'var(--shadow-md)'; }}
                      onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--gray100)'; e.currentTarget.style.boxShadow = 'none'; }}
                    >
                      <h4 style={{ fontWeight: 700, fontSize: 13, margin: '0 0 4px', color: 'var(--gray900)' }}>{product.name}</h4>
                      <p style={{ fontSize: 11, color: 'var(--gray400)', margin: 0 }}>التكلفة: {(product.cost || 0).toLocaleString()} د.ع</p>
                    </button>
                  ))}
                </div>
              </div>

              {/* Cart Side */}
              <div style={{ width: 320, padding: 20, overflowY: 'auto', background: 'var(--gray50)', flexShrink: 0 }}>
                <div style={{ marginBottom: 16 }}>
                  <label className="form-label">الفرع المستهدف</label>
                  <select
                    value={selectedBranchId}
                    onChange={(e) => setSelectedBranchId(e.target.value)}
                    className="form-select"
                  >
                    {branches.map(b => (
                      <option key={b.id} value={b.id}>{b.name}</option>
                    ))}
                  </select>
                </div>

                <div style={{ marginBottom: 16 }}>
                  <label className="form-label">اسم المورد</label>
                  <div style={{ position: 'relative' }}>
                    <User size={16} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--gray400)' }} />
                    <input 
                      className="form-input"
                      style={{ paddingRight: 36 }}
                      value={supplierName}
                      onChange={(e) => setSupplierName(e.target.value)}
                      placeholder="اسم المورد أو الشركة..."
                    />
                  </div>
                </div>

                <label className="form-label">أصناف الفاتورة ({cart.length})</label>
                <div style={{ maxHeight: 250, overflowY: 'auto', marginBottom: 16 }}>
                  {cart.map(item => (
                    <div key={item.product_id} className="card" style={{ padding: 12, marginBottom: 8, border: '1px solid var(--gray100)' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                        <span style={{ fontWeight: 700, fontSize: 13 }}>{item.name}</span>
                        <button onClick={() => removeFromCart(item.product_id)} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }}>
                          <X size={14} color="#ef4444" />
                        </button>
                      </div>
                      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                        <input 
                          type="number" 
                          value={item.quantity}
                          onChange={(e) => updateQuantity(item.product_id, parseFloat(e.target.value))}
                          className="form-input"
                          style={{ flex: 1, padding: '6px 8px', fontSize: 12 }}
                        />
                        <span style={{ fontSize: 11, color: 'var(--gray400)' }}>×</span>
                        <input 
                          type="number" 
                          value={item.unit_cost}
                          onChange={(e) => {
                            const newCost = parseFloat(e.target.value);
                            setCart(cart.map(i => i.product_id === item.product_id ? { ...i, unit_cost: newCost } : i));
                          }}
                          className="form-input"
                          style={{ flex: 1, padding: '6px 8px', fontSize: 12, color: 'var(--g600)' }}
                        />
                      </div>
                    </div>
                  ))}
                  {cart.length === 0 && (
                    <div style={{ padding: 30, textAlign: 'center', color: 'var(--gray400)', border: '2px dashed var(--gray200)', borderRadius: 12, fontSize: 13 }}>
                      <ShoppingCart size={32} style={{ marginBottom: 8, opacity: 0.3 }} />
                      <div>اختر منتجات من القائمة</div>
                    </div>
                  )}
                </div>

                <div style={{ padding: 16, background: 'var(--g600)', borderRadius: 12, color: 'white', marginBottom: 12 }}>
                  <div style={{ fontSize: 12, opacity: 0.8, marginBottom: 4 }}>إجمالي الفاتورة</div>
                  <div style={{ fontSize: 24, fontWeight: 900 }}>{totalAmount.toLocaleString()} <span style={{ fontSize: 12, fontWeight: 500 }}>د.ع</span></div>
                </div>

                <button 
                  onClick={savePurchase}
                  disabled={saving || cart.length === 0}
                  className="btn btn-primary"
                  style={{ width: '100%', height: 44 }}
                >
                  {saving ? 'جاري الحفظ...' : 'تثبيت الفاتورة وتوريد المخزون'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Purchases;
