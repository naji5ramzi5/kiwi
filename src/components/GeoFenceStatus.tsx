import { useUserZone } from '../hooks/useUserZone';
import { useEffect } from 'react';
import { toast } from 'react-hot-toast';

/**
 * GeoFenceStatus component shows toast notifications based on whether the user
 * is inside an active delivery zone. It can be placed anywhere in the component
 * tree (e.g., inside Layout) to run once per page load.
 *
 * @param branchId Optional branch ID to limit zone check to a specific branch.
 *                 If null, checks across all branches.
 */
export const GeoFenceStatus = ({
  branchId = null,
}: { branchId?: string | null }) => {
  const { isInsideAnyZone, loading, error, matchingZone } = useUserZone(branchId);

  useEffect(() => {
    if (loading) return;
    if (error) {
      toast.error(`خطأ في الموقع: ${error}`);
      return;
    }
    if (matchingZone) {
      toast.success(
        `✅ أنت داخل منطقة التوصيل "${matchingZone.name}". ` +
          `رسوم التوصيل: ${matchingZone.delivery_fee?.toLocaleString('ar-IQ')} د.ع`
      );
    } else {
      toast.error(
        `❌ أنت خارج جميع مناطق التوصيل النشطة. ` +
          `يرجى الانتقال إلى منطقة خدمية أو التواصل مع الدعم.`
      );
    }
  }, [isInsideAnyZone, loading, error, matchingZone]);

  // This component renders nothing; all work is via side‑effects (toasts)
  return null;
};
