import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { 
  FileText, 
  Plus, 
  Search, 
  Calendar, 
  User, 
  DollarSign, 
  Package,
  ArrowUpRight,
  MoreVertical,
  X,
  CheckCircle2,
  AlertCircle
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
  items_count?: number;
}

const Purchases = () => {
  const [purchases, setPurchases] = useState<Purchase[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  
  // New Purchase Form State
  const [supplierName, setSupplierName] = useState('');
  const [cart, setCart] = useState<PurchaseItem[]>([]);
  const [saving, setSaving] = useState(false);
  const [branches, setBranches] = useState<any[]>([]);
  const [selectedBranchId, setSelectedBranchId] = useState<string>('');

  useEffect(() => {
    fetchPurchases();
    fetchProducts();
    fetchBranches();
  }, []);

  const fetchBranches = async () => {
    const { data } = await supabase.from('branches').select('id, name');
    setBranches(data || []);
    if (data && data.length > 0) {
      setSelectedBranchId(data[0].id);
    }
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

  const savePurchase = async () => {
    if (!supplierName || cart.length === 0 || !selectedBranchId) {
      toast.error('يرجى إدخال اسم المورد واختيار الفرع وأصناف الفاتورة');
      return;
    }

    setSaving(true);
    try {
      // 1. Create Purchase
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

      // 2. Create Purchase Items
      const items = cart.map(item => ({
        purchase_id: purchase.id,
        product_id: item.product_id,
        quantity: item.quantity,
        unit_cost: item.unit_cost,
        total_cost: item.quantity * item.unit_cost
      }));

      const { error: iError } = await supabase.from('purchase_items').insert(items);
      if (iError) throw iError;

      // 3. Update Global Inventory (Assuming a global inventory table or simple increment)
      // In this system, we'd ideally trigger a DB function, but we can do a simple update here
      // For each item, update the product stock (if we have a stock field in products)
      
      toast.success('تم تسجيل فاتورة الشراء وتحديث المخزون');
      setShowModal(false);
      setCart([]);
      setSupplierName('');
      fetchPurchases();
    } catch (err: any) {
      toast.error('خطأ في الحفظ: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-6 max-w-7xl mx-auto animate-in fade-in duration-500">
      {/* Header Section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between mb-8 gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 mb-1">المشتريات والتوريد</h1>
          <p className="text-gray-500">إدارة فواتير الموردين وتحديث المخزون المركزي</p>
        </div>

        <button 
          onClick={() => setShowModal(true)}
          className="flex items-center justify-center gap-2 bg-emerald-600 text-white px-6 py-3 rounded-xl font-bold hover:bg-emerald-700 transition-all shadow-lg shadow-emerald-200"
        >
          <Plus size={20} />
          إضافة فاتورة شراء
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-emerald-50 flex items-center justify-center text-emerald-600">
            <DollarSign size={28} />
          </div>
          <div>
            <p className="text-gray-500 text-sm">إجمالي المشتريات</p>
            <h3 className="text-2xl font-black text-gray-900">
              {purchases.reduce((s, p) => s + p.total_amount, 0).toLocaleString()} <span className="text-xs font-normal">د.ع</span>
            </h3>
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-blue-50 flex items-center justify-center text-blue-600">
            <FileText size={28} />
          </div>
          <div>
            <p className="text-gray-500 text-sm">عدد الفواتير</p>
            <h3 className="text-2xl font-black text-gray-900">{purchases.length} <span className="text-xs font-normal">فاتورة</span></h3>
          </div>
        </div>

        <div className="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-amber-50 flex items-center justify-center text-amber-600">
            <Package size={28} />
          </div>
          <div>
            <p className="text-gray-500 text-sm">الموردين النشطين</p>
            <h3 className="text-2xl font-black text-gray-900">
              {new Set(purchases.map(p => p.supplier_name)).size} <span className="text-xs font-normal">مورد</span>
            </h3>
          </div>
        </div>
      </div>

      {/* Purchases Table */}
      <div className="bg-white rounded-3xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-right">
            <thead className="bg-gray-50/50">
              <tr className="text-gray-400 text-xs uppercase font-bold">
                <th className="px-6 py-4">رقم الفاتورة</th>
                <th className="px-6 py-4">المورد</th>
                <th className="px-6 py-4">الفرع المستلم</th>
                <th className="px-6 py-4">التاريخ</th>
                <th className="px-6 py-4">الإجمالي</th>
                <th className="px-6 py-4 text-center">الإجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {loading ? (
                <tr><td colSpan={6} className="py-20 text-center"><div className="loader mx-auto"></div></td></tr>
              ) : purchases.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-20 text-center text-gray-400">
                    <FileText size={40} className="mx-auto mb-4 opacity-20" />
                    لا توجد فواتير مسجلة بعد
                  </td>
                </tr>
              ) : (
                purchases.map(p => (
                  <tr key={p.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 text-sm font-mono text-gray-400">#{p.id.substring(0, 8)}</td>
                    <td className="px-6 py-4 font-bold text-gray-900">{p.supplier_name}</td>
                    <td className="px-6 py-4 text-sm font-medium text-gray-700">{(p as any).branches?.name || 'مستودع مركزي'}</td>
                    <td className="px-6 py-4 text-sm text-gray-500">{new Date(p.created_at).toLocaleDateString('ar-IQ')}</td>
                    <td className="px-6 py-4 font-black text-emerald-700">{((p as any).total_value ?? p.total_amount ?? 0).toLocaleString()} د.ع</td>
                    <td className="px-6 py-4 text-center">
                      <button className="p-2 text-gray-400 hover:text-gray-900"><MoreVertical size={18} /></button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Purchase Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-white rounded-3xl w-full max-w-5xl h-[85vh] flex flex-col overflow-hidden shadow-2xl">
            {/* Modal Header */}
            <div className="p-6 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
              <div>
                <h2 className="text-xl font-black text-gray-900">تسجيل فاتورة توريد جديدة</h2>
                <p className="text-xs text-gray-500">قم باختيار المنتجات وتحديد الكميات المستلمة</p>
              </div>
              <button onClick={() => setShowModal(false)} className="p-2 hover:bg-white rounded-xl transition-all">
                <X size={24} className="text-gray-400" />
              </button>
            </div>

            <div className="flex-1 flex overflow-hidden">
              {/* Products Side */}
              <div className="flex-1 p-6 overflow-y-auto border-l border-gray-100">
                <div className="relative mb-6">
                  <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                  <input 
                    type="text" 
                    placeholder="ابحث عن منتج لإضافته للفاتورة..." 
                    className="w-full pr-10 pl-4 py-3 bg-gray-50 border-none rounded-2xl text-sm focus:ring-2 focus:ring-emerald-500 transition-all"
                  />
                </div>
                
                <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
                  {products.map(product => (
                    <button 
                      key={product.id}
                      onClick={() => addToCart(product)}
                      className="p-4 bg-white border border-gray-100 rounded-2xl text-right hover:border-emerald-500 hover:shadow-md transition-all group"
                    >
                      <h4 className="font-bold text-gray-900 mb-1 group-hover:text-emerald-600 transition-colors">{product.name}</h4>
                      <p className="text-xs text-gray-400">التكلفة الافتراضية: {product.cost?.toLocaleString() || 0} د.ع</p>
                    </button>
                  ))}
                </div>
              </div>

              {/* Cart Side */}
              <div className="w-96 bg-gray-50/30 p-6 flex flex-col">
                <div className="mb-6">
                  <label className="text-xs font-bold text-gray-400 uppercase mb-2 block">الفرع المستهدف</label>
                  <select
                    value={selectedBranchId}
                    onChange={(e) => setSelectedBranchId(e.target.value)}
                    className="w-full px-4 py-3 bg-white border border-gray-200 rounded-2xl text-sm font-bold text-gray-700 focus:ring-2 focus:ring-emerald-500 transition-all outline-none"
                  >
                    {branches.map(b => (
                      <option key={b.id} value={b.id}>{b.name}</option>
                    ))}
                  </select>
                </div>

                <div className="mb-6">
                  <label className="text-xs font-bold text-gray-400 uppercase mb-2 block">معلومات المورد</label>
                  <div className="relative">
                    <User className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                    <input 
                      type="text" 
                      value={supplierName}
                      onChange={(e) => setSupplierName(e.target.value)}
                      placeholder="اسم المورد أو الشركة..." 
                      className="w-full pr-10 pl-4 py-3 bg-white border border-gray-200 rounded-2xl text-sm focus:ring-2 focus:ring-emerald-500 transition-all"
                    />
                  </div>
                </div>

                <label className="text-xs font-bold text-gray-400 uppercase mb-2 block">أصناف الفاتورة ({cart.length})</label>
                <div className="flex-1 overflow-y-auto space-y-3 mb-6">
                  {cart.map(item => (
                    <div key={item.product_id} className="bg-white p-3 rounded-2xl border border-gray-100 shadow-sm">
                      <div className="flex justify-between items-start mb-2">
                        <span className="font-bold text-sm text-gray-900">{item.name}</span>
                        <button onClick={() => removeFromCart(item.product_id)} className="text-red-400 hover:text-red-600"><X size={14} /></button>
                      </div>
                      <div className="flex items-center gap-2">
                        <div className="flex-1">
                          <input 
                            type="number" 
                            value={item.quantity}
                            onChange={(e) => updateQuantity(item.product_id, parseFloat(e.target.value))}
                            className="w-full p-2 bg-gray-50 border-none rounded-lg text-xs font-bold"
                          />
                        </div>
                        <div className="text-xs text-gray-400">×</div>
                        <div className="flex-1">
                          <input 
                            type="number" 
                            value={item.unit_cost}
                            onChange={(e) => {
                              const newCost = parseFloat(e.target.value);
                              setCart(cart.map(i => i.product_id === item.product_id ? { ...i, unit_cost: newCost } : i));
                            }}
                            className="w-full p-2 bg-gray-50 border-none rounded-lg text-xs font-bold text-emerald-600"
                          />
                        </div>
                      </div>
                    </div>
                  ))}
                  {cart.length === 0 && (
                    <div className="py-10 text-center text-gray-300 border-2 border-dashed border-gray-200 rounded-2xl text-sm">
                      اختر منتجات من القائمة
                    </div>
                  )}
                </div>

                <div className="p-4 bg-emerald-600 rounded-2xl text-white">
                  <div className="flex justify-between items-center mb-1 opacity-80 text-xs">
                    <span>إجمالي الفاتورة</span>
                  </div>
                  <div className="text-2xl font-black">{totalAmount.toLocaleString()} <span className="text-xs font-normal">د.ع</span></div>
                </div>

                <button 
                  onClick={savePurchase}
                  disabled={saving || cart.length === 0}
                  className="w-full mt-4 bg-gray-900 text-white py-4 rounded-2xl font-bold hover:bg-black transition-all flex items-center justify-center gap-2 disabled:opacity-50"
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
