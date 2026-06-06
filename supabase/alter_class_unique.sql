alter table public.exam_scores
drop constraint if exists exam_scores_exam_id_student_no_key;

alter table public.exam_scores
drop constraint if exists exam_scores_exam_id_class_name_student_no_key;

alter table public.exam_scores
add constraint exam_scores_exam_id_class_name_student_no_key
unique (exam_id, class_name, student_no);
