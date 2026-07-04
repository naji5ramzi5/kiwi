import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Star, StarHalf, MessageCircle, User, Calendar, ChevronDown, ChevronUp } from 'lucide-react';
import toast from 'react-hot-toast';

interface Rating {
  id: string;
  driver_id: string;
  user_id: string;
  rating: number;
  comment: string;
  created_at: string;
  profiles?: { full_name: string; avatar_url: string };
}

interface DriverWithRating {
  id: string;
  full_name: string;
  avatar_url: string;
  avg_rating: number;
  total_ratings: number;
}

export default function Ratings() {
  const [drivers, setDrivers] = useState<DriverWithRating[]>([]);
  const [selectedDriver, setSelectedDriver] = useState<string | null>(null);
  const [ratings, setRatings] = useState<Rating[]>([]);
  const [loading, setLoading] = useState(true);
  const [ratingLoading, setRatingLoading] = useState(false);

  useEffect(() => {
    fetchDriversWithRatings();
  }, []);

  async function fetchDriversWithRatings() {
    try {
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, full_name, avatar_url')
        .eq('role', 'driver');

      if (!profiles) return;

      const driverData: DriverWithRating[] = await Promise.all(
        profiles.map(async (p) => {
          const { data: ratingData } = await supabase
            .from('driver_ratings')
            .select('rating')
            .eq('driver_id', p.id);

          const ratings = (ratingData || []) as { rating: number }[];
          const total = ratings.length;
          const avg = total > 0 ? ratings.reduce((s, r) => s + r.rating, 0) / total : 0;

          return {
            id: p.id,
            full_name: p.full_name,
            avatar_url: p.avatar_url || '',
            avg_rating: Math.round(avg * 10) / 10,
            total_ratings: total,
          };
        })
      );

      setDrivers(driverData.sort((a, b) => b.avg_rating - a.avg_rating));
    } catch {
      toast.error('خطأ في جلب التقييمات');
    } finally {
      setLoading(false);
    }
  }

  async function fetchDriverRatings(driverId: string) {
    setRatingLoading(true);
    try {
      const { data, error } = await supabase
        .from('driver_ratings')
        .select('*, profiles!inner(full_name, avatar_url)')
        .eq('driver_id', driverId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setRatings(data || []);
    } catch {
      toast.error('خطأ في جلب التقييمات');
    } finally {
      setRatingLoading(false);
    }
  }

  function renderStars(rating: number) {
    const full = Math.floor(rating);
    const half = rating - full >= 0.5;
    return (
      <div className="flex gap-0.5">
        {Array.from({ length: 5 }, (_, i) => (
          <Star
            key={i}
            size={16}
            className={i < full ? 'fill-amber-400 text-amber-400' : i === full && half ? 'text-amber-400' : 'text-gray-200'}
          />
        ))}
      </div>
    );
  }

  function getRatingColor(rating: number) {
    if (rating >= 4.5) return 'text-emerald-600';
    if (rating >= 4.0) return 'text-green-600';
    if (rating >= 3.0) return 'text-amber-600';
    return 'text-red-500';
  }

  if (loading) return <div className="p-6"><div className="loader"></div></div>;

  return (
    <div className="p-6" dir="rtl">
      <div className="mb-8">
        <h1 className="text-3xl font-black text-gray-900">التقييمات</h1>
        <p className="text-gray-500 mt-1">متابعة تقييم المناديب من قبل الزبائن</p>
      </div>

      {drivers.length === 0 ? (
        <div className="text-center py-24 bg-white rounded-[3rem] border-4 border-dashed border-gray-50">
          <div className="w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
            <Star size={40} className="text-gray-200" />
          </div>
          <p className="text-gray-400 font-bold">لا توجد تقييمات بعد</p>
        </div>
      ) : (
        <div className="space-y-4">
          {drivers.map((driver) => (
            <div key={driver.id} className="bg-white rounded-[2rem] shadow-xl shadow-gray-100/50 border border-gray-100 overflow-hidden transition-all">
              <button
                onClick={() => {
                  if (selectedDriver === driver.id) {
                    setSelectedDriver(null);
                  } else {
                    setSelectedDriver(driver.id);
                    fetchDriverRatings(driver.id);
                  }
                }}
                className="w-full p-6 flex items-center gap-4 hover:bg-gray-50/50 transition-colors"
              >
                <div className="relative">
                  {driver.avatar_url ? (
                    <img src={driver.avatar_url} className="w-14 h-14 rounded-2xl object-cover border-2 border-emerald-50" alt={driver.full_name} />
                  ) : (
                    <div className="w-14 h-14 rounded-2xl bg-emerald-50 flex items-center justify-center text-emerald-600 border-2 border-emerald-100">
                      <User size={24} />
                    </div>
                  )}
                </div>
                <div className="flex-1 text-right">
                  <h3 className="font-black text-gray-900">{driver.full_name}</h3>
                  <div className="flex items-center gap-2 mt-1">
                    {renderStars(driver.avg_rating)}
                    <span className={`font-black text-lg ${getRatingColor(driver.avg_rating)}`}>
                      {driver.avg_rating.toFixed(1)}
                    </span>
                    <span className="text-gray-400 text-sm">({driver.total_ratings} تقييم)</span>
                  </div>
                </div>
                {selectedDriver === driver.id ? <ChevronUp size={20} className="text-gray-400" /> : <ChevronDown size={20} className="text-gray-400" />}
              </button>

              {selectedDriver === driver.id && (
                <div className="px-6 pb-6 border-t border-gray-100 pt-4">
                  {ratingLoading ? (
                    <div className="flex justify-center py-8">
                      <div className="w-8 h-8 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin" />
                    </div>
                  ) : ratings.length === 0 ? (
                    <p className="text-center text-gray-400 py-8">لا توجد تقييمات مفصلة</p>
                  ) : (
                    <div className="space-y-3 max-h-96 overflow-y-auto">
                      {ratings.map((r) => (
                        <div key={r.id} className="p-4 bg-gray-50 rounded-2xl border border-gray-100">
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center gap-2">
                              <div className="flex">
                                {Array.from({ length: 5 }, (_, i) => (
                                  <Star key={i} size={14} className={i < r.rating ? 'fill-amber-400 text-amber-400' : 'text-gray-200'} />
                                ))}
                              </div>
                            </div>
                            <span className="text-xs text-gray-400 flex items-center gap-1">
                              <Calendar size={12} />
                              {new Date(r.created_at).toLocaleDateString('ar-IQ')}
                            </span>
                          </div>
                          {r.comment && (
                            <p className="text-sm text-gray-600 flex items-start gap-2">
                              <MessageCircle size={14} className="text-gray-300 mt-0.5 shrink-0" />
                              {r.comment}
                            </p>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
