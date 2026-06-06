-- BAYETAV Supabase ortak not sistemi
-- Supabase SQL Editor'de tek parca olarak calistirilabilir.

create extension if not exists pgcrypto;

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  student_no integer not null check (student_no between 1 and 120),
  student_name text not null default '',
  class_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_no, class_name)
);

create table if not exists public.exam_scores (
  id uuid primary key default gen_random_uuid(),
  exam_id text not null,
  exam_title text not null,
  student_no integer not null check (student_no between 1 and 120),
  student_name text not null default '',
  class_name text not null default '',
  writing_score numeric(5,2) not null default 0 check (writing_score between 0 and 30),
  reading_score numeric(5,2) not null default 0 check (reading_score between 0 and 49),
  listening_score numeric(5,2) not null default 0 check (listening_score between 0 and 25),
  speaking_score numeric(5,2) not null default 0 check (speaking_score between 0 and 15),
  total_score numeric(5,2) generated always as (
    writing_score + reading_score + listening_score + speaking_score
  ) stored,
  teacher_note text not null default '',
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (exam_id, class_name, student_no)
);

create table if not exists public.score_audit_log (
  id bigint generated always as identity primary key,
  score_id uuid,
  exam_id text not null,
  student_no integer not null,
  old_row jsonb,
  new_row jsonb,
  changed_by uuid references auth.users(id),
  changed_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists students_set_updated_at on public.students;
create trigger students_set_updated_at
before update on public.students
for each row execute function public.set_updated_at();

drop trigger if exists exam_scores_set_updated_at on public.exam_scores;
create trigger exam_scores_set_updated_at
before update on public.exam_scores
for each row execute function public.set_updated_at();

create or replace function public.log_score_change()
returns trigger
language plpgsql
security definer
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.score_audit_log(score_id, exam_id, student_no, old_row, new_row, changed_by)
    values (new.id, new.exam_id, new.student_no, null, to_jsonb(new), auth.uid());
    return new;
  elsif tg_op = 'UPDATE' then
    insert into public.score_audit_log(score_id, exam_id, student_no, old_row, new_row, changed_by)
    values (new.id, new.exam_id, new.student_no, to_jsonb(old), to_jsonb(new), auth.uid());
    return new;
  end if;
  return null;
end;
$$;

drop trigger if exists exam_scores_audit on public.exam_scores;
create trigger exam_scores_audit
after insert or update on public.exam_scores
for each row execute function public.log_score_change();

alter table public.students enable row level security;
alter table public.exam_scores enable row level security;
alter table public.score_audit_log enable row level security;

drop policy if exists "Teachers can read students" on public.students;
create policy "Teachers can read students"
on public.students
for select
to authenticated
using (true);

drop policy if exists "Teachers can write students" on public.students;
create policy "Teachers can write students"
on public.students
for all
to authenticated
using (true)
with check (true);

drop policy if exists "Teachers can read scores" on public.exam_scores;
create policy "Teachers can read scores"
on public.exam_scores
for select
to authenticated
using (true);

drop policy if exists "Teachers can insert scores" on public.exam_scores;
create policy "Teachers can insert scores"
on public.exam_scores
for insert
to authenticated
with check (true);

drop policy if exists "Teachers can update scores" on public.exam_scores;
create policy "Teachers can update scores"
on public.exam_scores
for update
to authenticated
using (true)
with check (true);

drop policy if exists "Teachers can read audit log" on public.score_audit_log;
create policy "Teachers can read audit log"
on public.score_audit_log
for select
to authenticated
using (true);

-- Daha siki domain kontrolu istenirse yukaridaki policy'lerde using/with check
-- kosullari asagidaki gibi degistirilebilir:
-- auth.jwt() ->> 'email' like '%@bayetav.k12.tr'
