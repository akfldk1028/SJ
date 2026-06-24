ALTER POLICY "message_room_members_policy" ON "message_room_members" TO authenticated USING (exists (
        select 1 from message_rooms
        where message_rooms.message_room_id = "message_room_members"."message_room_id"
        and exists (
          select 1 from message_room_members as mrm
          where mrm.message_room_id = message_rooms.message_room_id
          and mrm.profile_id = auth.uid()
        )
      ));