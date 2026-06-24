import { makeAdminClient, makeSSRClient } from "~/supa-client";
import type { Route } from "./+types/send-message-page";
import { getLoggedInUserId, getUserProfile } from "../queries";
import { sendMessage } from "../mutations";
import { z } from "zod";
import { redirect } from "react-router";

const formSchema = z.object({
  content: z.string().min(1),
});

export const action = async ({ request, params }: Route.ActionArgs) => {
  if (request.method !== "POST") {
    return Response.json({ error: "Method not allowed" }, { status: 405 });
  }
  const formData = await request.formData();
  const { client } = makeSSRClient(request);
  const fromUserId = await getLoggedInUserId(client);
  const { profile_id: toUserId } = await getUserProfile(client, {
    username: params.username,
  });
  const adminClient = makeAdminClient();
  const messageRoomId = await sendMessage(adminClient, {
    fromUserId,
    toUserId,
    content: formData.get("content") as string,
  });
  return redirect(`/my/messages/${messageRoomId}`);
};
