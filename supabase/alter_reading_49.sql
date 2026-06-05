alter table public.exam_scores
drop constraint if exists exam_scores_reading_score_check;

alter table public.exam_scores
add constraint exam_scores_reading_score_check
check (reading_score between 0 and 49);
