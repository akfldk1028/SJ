ALTER POLICY "message_room_members_policy" ON "message_room_members" TO authenticated USING (exists (
        select 1 from message_rooms as mr
        join message_room_members as mrm on mrm.message_room_id = mr.message_room_id
        where mrm.profile_id = auth.uid()
        and mr.message_room_id = "message_room_members"."message_room_id"
      ));