ALTER POLICY "message_room_members_policy" ON "message_room_members" TO authenticated USING (exists (
        select 1 from message_room_members as mr
        where mr.message_room_id = "message_room_members"."message_room_id"
        and mr.profile_id = auth.uid()
      ));