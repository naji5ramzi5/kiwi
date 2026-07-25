import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Star, MessageCircle, User, Calendar, ChevronDown, ChevronUp } from 'lucide-react';
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

  useEffect(() => {
    void (async () => { await fetchDriversWithRatings(); })();
  }, []);

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
      <div style={{ display: 'flex', gap: 2 }}>
        {Array.from({ length: 5 }, (_, i) => (
          <Star
            key={i}
            size={16}
            style={{
              color: i < full || (i === full && half) ? '#f59e0b' : '#e5e7eb',
              fill: i < full ? '#f59e0b' : 'none',
            }}
          />
        ))}
      </div>
    );
  }

  function getRatingColor(rating: number) {
    if (rating >= 4.5) return '#059669';
    if (rating >= 4.0) return '#16a34a';
    if (rating >= 3.0) return '#d97706';
    return '#ef4444';
  }

  if (loading) return <div className="empty-state"><div className="loader"></div></div>;

  return (
    <div className="animate-in">
      <div style={{ marginBottom: 24 }}>
        <h1 className="brand-name" style={{ fontSize: 24 }}>التقييمات</h1>
        <p className="brand-sub">متابعة تقييم المناديب من قبل الزبائن</p>
      </div>

      {drivers.length === 0 ? (
        <div className="empty-state">
          <div style={{ width: 80, height: 80, borderRadius: '50%', background: 'var(--gray100)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px' }}>
            <Star size={36} style={{ color: 'var(--gray300)' }} />
          </div>
          <p style={{ color: 'var(--gray400)', fontWeight: 700 }}>لا توجد تقييمات بعد</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {drivers.map((driver) => (
            <div key={driver.id} className="card">
              <button
                onClick={() => {
                  if (selectedDriver === driver.id) {
                    setSelectedDriver(null);
                  } else {
                    setSelectedDriver(driver.id);
                    fetchDriverRatings(driver.id);
                  }
                }}
                style={{
                  width: '100%', padding: 20, display: 'flex', alignItems: 'center', gap: 16,
                  border: 'none', background: 'none', cursor: 'pointer', textAlign: 'right',
                  fontFamily: 'var(--font-ar)',
                }}
              >
                <div style={{ position: 'relative', flexShrink: 0 }}>
                  {driver.avatar_url ? (
                    <img src={driver.avatar_url} style={{ width: 56, height: 56, borderRadius: 14, objectFit: 'cover', border: '2px solid var(--g100)' }} alt={driver.full_name} />
                  ) : (
                    <div style={{ width: 56, height: 56, borderRadius: 14, background: 'var(--g50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--g600)', border: '2px solid var(--g100)' }}>
                      <User size={26} />
                    </div>
                  )}
                </div>
                <div style={{ flex: 1 }}>
                  <h3 style={{ fontWeight: 800, fontSize: 16, color: 'var(--gray900)', margin: 0 }}>{driver.full_name}</h3>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6 }}>
                    {renderStars(driver.avg_rating)}
                    <span style={{ fontWeight: 800, fontSize: 16, color: getRatingColor(driver.avg_rating) }}>
                      {driver.avg_rating.toFixed(1)}
                    </span>
                    <span style={{ color: 'var(--gray400)', fontSize: 12 }}>({driver.total_ratings} تقييم)</span>
                  </div>
                </div>
                {selectedDriver === driver.id ? <ChevronUp size={20} style={{ color: 'var(--gray400)' }} /> : <ChevronDown size={20} style={{ color: 'var(--gray400)' }} />}
              </button>

              {selectedDriver === driver.id && (
                <div style={{ padding: '0 20px 20px', borderTop: '1px solid var(--gray100)', paddingTop: 16 }}>
                  {ratingLoading ? (
                    <div style={{ display: 'flex', justifyContent: 'center', padding: '32px 0' }}>
                      <div className="loader"></div>
                    </div>
                  ) : ratings.length === 0 ? (
                    <p style={{ textAlign: 'center', color: 'var(--gray400)', padding: '32px 0' }}>لا توجد تقييمات مفصلة</p>
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 12, maxHeight: 384, overflowY: 'auto' }}>
                      {ratings.map((r) => (
                        <div key={r.id} style={{ padding: 16, background: 'var(--gray50)', borderRadius: 12, border: '1px solid var(--gray100)' }}>
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                            <div style={{ display: 'flex', gap: 2 }}>
                              {Array.from({ length: 5 }, (_, i) => (
                                <Star key={i} size={14} style={{ color: i < r.rating ? '#f59e0b' : '#e5e7eb', fill: i < r.rating ? '#f59e0b' : 'none' }} />
                              ))}
                            </div>
                            <span style={{ fontSize: 11, color: 'var(--gray400)', display: 'flex', alignItems: 'center', gap: 4 }}>
                              <Calendar size={12} />
                              {new Date(r.created_at).toLocaleDateString('ar-IQ')}
                            </span>
                          </div>
                          {r.comment && (
                            <p style={{ fontSize: 13, color: 'var(--gray600)', display: 'flex', alignItems: 'flex-start', gap: 8, margin: 0 }}>
                              <MessageCircle size={14} style={{ color: 'var(--gray300)', marginTop: 2, flexShrink: 0 }} />
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
