create extension if not exists pgcrypto;
create table if not exists public.exam_scores (
id uuid primary key default gen_random_uuid(),
exam_id text not null,
exam_title text not null,
student_no integer not null check (student_no between 1 and 120),
student_name text,
class_name text,
writing_score numeric(5,2) not null default 0 check (writing_score between 0 and 30),
reading_score numeric(5,2) not null default 0 check (reading_score between 0 and 49),
listening_score numeric(5,2) not null default 0 check (listening_score between 0 and 25),
speaking_score numeric(5,2) not null default 0 check (speaking_score between 0 and 15),
teacher_note text,
updated_by uuid references auth.users(id),
created_at timestamptz not null default now(),
updated_at timestamptz not null default now(),
unique (exam_id, class_name, student_no)
);
alter table public.exam_scores enable row level security;
drop policy if exists teachers_read_scores on public.exam_scores;
create policy teachers_read_scores on public.exam_scores for select to authenticated using (true);
drop policy if exists teachers_insert_scores on public.exam_scores;
create policy teachers_insert_scores on public.exam_scores for insert to authenticated with check (true);
drop policy if exists teachers_update_scores on public.exam_scores;
create policy teachers_update_scores on public.exam_scores for update to authenticated using (true) with check (true);
