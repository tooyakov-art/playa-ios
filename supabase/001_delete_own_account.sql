-- Playa: account deletion RPC.
-- Required by App Store Guideline 5.1.1(v).
--
-- HOW TO APPLY:
--   1. Open Supabase Dashboard -> SQL Editor on project yteqnagkxbbaqjdgoqeu
--   2. Paste this entire file and click Run
--   3. Verify with: select proname from pg_proc where proname = 'delete_own_account';

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  -- Best-effort cleanup of any user-owned rows. Each delete is wrapped so a
  -- missing table does not abort the whole transaction.
  begin delete from public.event_messages   where sender_id = uid;                                exception when undefined_table then null; end;
  begin delete from public.event_comments   where author_id = uid;                                exception when undefined_table then null; end;
  begin delete from public.event_members    where user_id = uid;                                  exception when undefined_table then null; end;
  begin delete from public.events           where creator_id = uid;                               exception when undefined_table then null; end;
  begin delete from public.post_comments    where author_id = uid;                                exception when undefined_table then null; end;
  begin delete from public.posts            where author_id = uid;                                exception when undefined_table then null; end;
  begin delete from public.follows          where follower_id = uid or following_id = uid;        exception when undefined_table then null; end;
  begin delete from public.tickets          where user_id = uid;                                  exception when undefined_table then null; end;
  begin delete from public.direct_messages  where sender_id = uid;                                exception when undefined_table then null; end;
  begin delete from public.direct_chats     where uid = any(participants);                        exception when undefined_table then null; end;
  begin delete from public.profiles         where id = uid;                                       exception when undefined_table then null; end;

  delete from auth.users where id = uid;
end;
$$;

grant execute on function public.delete_own_account() to authenticated;
