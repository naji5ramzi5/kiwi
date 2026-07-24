-- Migration 009: daily_reports table
-- Creates the daily_reports table used by the daily-report Edge Function.

CREATE TABLE IF NOT EXISTS public.daily_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_orders INT DEFAULT 0,
  total_revenue NUMERIC DEFAULT 0,
  delivered_orders INT DEFAULT 0,
  cancelled_orders INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(branch_id, report_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_reports_branch_id ON public.daily_reports(branch_id);
CREATE INDEX IF NOT EXISTS idx_daily_reports_date ON public.daily_reports(report_date DESC);

ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated read daily_reports" ON public.daily_reports;
CREATE POLICY "Authenticated read daily_reports" ON public.daily_reports FOR SELECT USING (auth.role() = 'authenticated');
