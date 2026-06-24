create or replace function track_idea_view(
    idea_id bigint
) returns void as $$
begin
    update public.gpt_ideas
    set views = views + 1
    where idea_id = idea_id;
end;
$$ language plpgsql;