export const ORDER_STATUS = {
  PENDING: 'pending',
  PREPARING: 'preparing',
  PICKED_UP: 'picked_up',
  DELIVERING: 'shipped',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
  REJECTED: 'rejected',
} as const;

export type OrderStatus = (typeof ORDER_STATUS)[keyof typeof ORDER_STATUS];

export const ORDER_STATUS_LABELS: Record<string, string> = {
  pending: 'جديد',
  preparing: 'قيد التحضير',
  picked_up: 'تم الاستلام',
  shipped: 'قيد التوصيل',
  delivered: 'تم التوصيل',
  cancelled: 'ملغي',
  rejected: 'مرفوض',
};

export const ORDER_STATUS_COLORS: Record<string, string> = {
  pending: 'bg-blue-100 text-blue-600 border-blue-200',
  preparing: 'bg-orange-100 text-orange-600 border-orange-200',
  picked_up: 'bg-indigo-100 text-indigo-600 border-indigo-200',
  shipped: 'bg-purple-100 text-purple-600 border-purple-200',
  delivered: 'bg-emerald-100 text-emerald-600 border-emerald-200',
  cancelled: 'bg-red-100 text-red-600 border-red-200',
  rejected: 'bg-gray-100 text-gray-600 border-gray-200',
};

export const ORDER_STATUS_FILTERS = [
  'الكل',
  ORDER_STATUS.PENDING,
  ORDER_STATUS.PREPARING,
  ORDER_STATUS.PICKED_UP,
  ORDER_STATUS.DELIVERING,
  ORDER_STATUS.DELIVERED,
  ORDER_STATUS.CANCELLED,
];

export function getStatusLabel(status: string): string {
  return ORDER_STATUS_LABELS[status] || status;
}

export function getStatusColor(status: string): string {
  return ORDER_STATUS_COLORS[status] || 'bg-gray-100 text-gray-600 border-gray-200';
}
