create table if not exists public.score_audit_log (
  id bigint generated always as identity primary key,
  score_id uuid,
  exam_id text not null,
  student_no integer not null,
  old_row jsonb,
  new_row jsonb,
  changed_by uuid,
  changed_at timestamptz not null default now()
);

alter table public.score_audit_log enable row level security;

create or replace function public.log_exam_score_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.score_audit_log(score_id, exam_id, student_no, old_row, new_row, changed_by)
    values (new.id, new.exam_id, new.student_no, null, to_jsonb(new), auth.uid());
    return new;
  end if;

  if tg_op = 'UPDATE' then
    insert into public.score_audit_log(score_id, exam_id, student_no, old_row, new_row, changed_by)
    values (new.id, new.exam_id, new.student_no, to_jsonb(old), to_jsonb(new), auth.uid());
    return new;
  end if;

  return new;
end;
$$;

drop trigger if exists exam_scores_audit_insert on public.exam_scores;
create trigger exam_scores_audit_insert
after insert on public.exam_scores
for each row execute function public.log_exam_score_change();

drop trigger if exists exam_scores_audit_update on public.exam_scores;
create trigger exam_scores_audit_update
after update on public.exam_scores
for each row execute function public.log_exam_score_change();
