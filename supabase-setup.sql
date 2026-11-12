-- 바른 면(面)을 모아보면, 갤러리 — Supabase 설정 (SQL Editor에 붙여넣고 Run)

-- 1) 게시물 표
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  room text not null check (room in ('care', 'keep', 'raise')),
  text text not null check (char_length(text) between 1 and 40),
  name text check (name is null or char_length(name) <= 16),
  image_path text not null check (image_path ~ '^uploads/[a-f0-9-]{36}\.jpg$'),
  hidden boolean not null default false
);
alter table public.posts enable row level security;

-- 누구나 숨김 처리 안 된 게시물을 볼 수 있고, 새 게시물을 올릴 수 있음 (수정·삭제는 대시보드에서만)
drop policy if exists "read visible posts" on public.posts;
create policy "read visible posts" on public.posts for select to anon, authenticated using (hidden = false);
drop policy if exists "add posts" on public.posts;
create policy "add posts" on public.posts for insert to anon, authenticated with check (hidden = false);

-- 2) 사진 저장소 (공개 읽기, JPG만, 5MB 이하)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('gallery', 'gallery', true, 5242880, array['image/jpeg'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg'];

drop policy if exists "upload to gallery" on storage.objects;
create policy "upload to gallery" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'gallery' and (storage.foldername(name))[1] = 'uploads');
