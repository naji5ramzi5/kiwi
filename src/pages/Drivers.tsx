import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { UserCheck, UserX, Truck, Bike, ShieldCheck, ShieldAlert, CreditCard, User, Star } from 'lucide-react';
import toast from 'react-hot-toast';

interface Driver {
  id: string;
  full_name: string;
  email: string;
  vehicle_type: string;
  is_approved: boolean;
  is_online: boolean;
  plate_number?: string;
  avatar_url?: string;
  avg_rating?: number;
  total_ratings?: number;
}

export default function Drivers() {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDrivers();
  }, []);

  async function fetchDrivers() {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'driver');
    
    if (error) {
      toast.error('خطأ في جلب البيانات');
      setLoading(false);
      return;
    }
    
    const driversWithRatings = await Promise.all((data || []).map(async (d) => {
      const { data: ratingData } = await supabase
        .from('driver_ratings')
        .select('rating')
        .eq('driver_id', d.id);
      const ratings = (ratingData || []) as { rating: number }[];
      const avg = ratings.length > 0 ? ratings.reduce((s, r) => s + r.rating, 0) / ratings.length : 0;
      return { ...d, avg_rating: Math.round(avg * 10) / 10, total_ratings: ratings.length };
    }));
    
    setDrivers(driversWithRatings);
    setLoading(false);
  }

  async function toggleApproval(id: string, currentStatus: boolean) {
    const { error } = await supabase
      .from('profiles')
      .update({ is_approved: !currentStatus })
      .eq('id', id);

    if (error) toast.error('فشلت العملية');
    else {
      toast.success(currentStatus ? 'تم إلغاء التفعيل' : 'تم تفعيل حساب المندوب');
      fetchDrivers();
    }
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-black text-gray-900">إدارة فريق التوصيل</h1>
          <p className="text-gray-500">مراجعة ملفات المناديب والموافقة على طلبات الانضمام</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {drivers.map((driver) => (
          <div key={driver.id} className="bg-white rounded-[2rem] shadow-xl shadow-gray-100/50 border border-gray-100 p-6 transition-all hover:translate-y-[-4px]">
            <div className="flex justify-between items-start mb-6">
              <div className="flex items-center gap-4">
                <div className="relative">
                  {driver.avatar_url ? (
                    <img src={driver.avatar_url} className="w-16 h-16 rounded-2xl object-cover border-2 border-emerald-50 shadow-md" alt={driver.full_name} />
                  ) : (
                    <div className="w-16 h-16 rounded-2xl bg-emerald-50 flex items-center justify-center text-emerald-600 border-2 border-emerald-100">
                      <User size={28} />
                    </div>
                  )}
                  <div className={`absolute -bottom-1 -right-1 w-5 h-5 rounded-full border-4 border-white ${driver.is_online ? 'bg-emerald-500' : 'bg-gray-400'}`} />
                </div>
                <div>
                  <h3 className="font-black text-gray-900 text-lg leading-tight">{driver.full_name}</h3>
                  <div className="flex items-center gap-1 text-gray-400 mt-1">
                    {driver.vehicle_type === 'truck' ? <Truck size={14} /> : <Bike size={14} />}
                    <span className="text-xs font-bold">{driver.vehicle_type === 'truck' ? 'شاحنة خضار' : 'دراجة نارية'}</span>
                  </div>
                </div>
              </div>
              <div className={`px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-wider ${driver.is_online ? 'bg-emerald-50 text-emerald-600' : 'bg-gray-50 text-gray-400'}`}>
                {driver.is_online ? 'Active Now' : 'Offline'}
              </div>
            </div>

            <div className="space-y-3 mb-6">
              <div className="flex items-center justify-between p-4 bg-gray-50/50 rounded-2xl border border-gray-100">
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <CreditCard size={18} className="text-emerald-600" />
                  <span className="font-bold">رقم اللوحة:</span>
                </div>
                <span className="text-sm font-black text-gray-900">{driver.plate_number || 'غير مسجل'}</span>
              </div>

              <div className="flex items-center justify-between p-4 bg-gray-50/50 rounded-2xl border border-gray-100">
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  {driver.is_approved ? <ShieldCheck size={18} className="text-emerald-500" /> : <ShieldAlert size={18} className="text-amber-500" />}
                  <span className="font-bold">حالة الاعتماد:</span>
                </div>
                <span className={`text-sm font-black ${driver.is_approved ? 'text-emerald-600' : 'text-amber-600'}`}>
                  {driver.is_approved ? 'حساب معتمد' : 'بانتظار المراجعة'}
                </span>
              </div>

              {(driver.total_ratings ?? 0) > 0 && (
                <div className="flex items-center justify-between p-4 bg-gray-50/50 rounded-2xl border border-gray-100">
                  <div className="flex items-center gap-2 text-sm text-gray-600">
                    <Star size={18} className="text-amber-400" />
                    <span className="font-bold">التقييم:</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <div className="flex">
                      {Array.from({ length: 5 }, (_, i) => (
                        <Star key={i} size={14} className={i < Math.round(driver.avg_rating ?? 0) ? 'fill-amber-400 text-amber-400' : 'text-gray-200'} />
                      ))}
                    </div>
                    <span className="text-sm font-black text-gray-900">{driver.avg_rating?.toFixed(1)}</span>
                    <span className="text-xs text-gray-400">({driver.total_ratings})</span>
                  </div>
                </div>
              )}
            </div>

            <button
              onClick={() => toggleApproval(driver.id, driver.is_approved)}
              className={`w-full py-4 rounded-2xl font-black transition-all flex items-center justify-center gap-2 shadow-lg ${
                driver.is_approved 
                ? 'bg-red-50 text-red-600 hover:bg-red-100 shadow-red-100' 
                : 'bg-gray-900 text-white hover:bg-black shadow-gray-200'
              }`}
            >
              {driver.is_approved ? <UserX size={20} /> : <UserCheck size={20} />}
              {driver.is_approved ? 'إلغاء الاعتماد' : 'الموافقة على الانضمام'}
            </button>
          </div>
        ))}
      </div>
      
      {drivers.length === 0 && !loading && (
        <div className="text-center py-24 bg-white rounded-[3rem] border-4 border-dashed border-gray-50">
          <div className="w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
            <User size={40} className="text-gray-200" />
          </div>
          <p className="text-gray-400 font-bold">لا يوجد طلبات انضمام حالياً</p>
        </div>
      )}
    </div>
  );
}
