ALTER POLICY "message_room_members_policy" ON "message_room_members" TO authenticated USING (exists (
        select 1 from "profiles"
        where "profiles"."profile_id" = auth.uid()
        and "profiles"."profile_id" = "message_room_members"."profile_id"
      ));