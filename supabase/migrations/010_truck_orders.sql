create table public.truck_orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.profiles(id) on delete cascade,
  order_code text not null,
  products_text text not null,
  customer_name text,
  customer_phone text,
  delivery_address text,
  notes text,
  status text not null default 'new',
  created_at timestamptz not null default now()
);

alter table public.truck_orders enable row level security;

create policy "Customers can view own truck orders"
  on public.truck_orders for select
  using (auth.uid() = customer_id);

create policy "Customers can insert own truck orders"
  on public.truck_orders for insert
  with check (auth.uid() = customer_id);

create index idx_truck_orders_customer_id on public.truck_orders(customer_id);
create index idx_truck_orders_status on public.truck_orders(status);
create index idx_truck_orders_created_at on public.truck_orders(created_at desc);
