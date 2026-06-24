ALTER TABLE "message_room_members" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE POLICY "message_room_members_policy" ON "message_room_members" AS PERMISSIVE FOR SELECT TO "authenticated" USING ("message_room_members"."message_room_id" IN (
        SELECT message_room_id FROM message_room_members WHERE profile_id = auth.uid()
      ));