create table public.branch_ratings (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  rating integer not null check (rating >= 1 and rating <= 5),
  created_at timestamptz not null default now()
);

alter table public.branch_ratings enable row level security;

create policy "Users can view branch ratings"
  on public.branch_ratings for select
  using (true);

create policy "Users can insert own branch ratings"
  on public.branch_ratings for insert
  with check (auth.uid() = user_id);

create index idx_branch_ratings_branch_id on public.branch_ratings(branch_id);
create index idx_branch_ratings_order_id on public.branch_ratings(order_id);
create index idx_branch_ratings_user_id on public.branch_ratings(user_id);
