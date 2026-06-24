import { Outlet, useOutletContext } from "react-router";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarMenu,
  SidebarProvider,
  SidebarTrigger,
} from "~/common/components/ui/sidebar";
import MessageRoomCard from "../components/message-room-card";
import type { Route } from "./+types/messages-layout";
import { makeSSRClient } from "~/supa-client";
import { getLoggedInUserId, getMessages } from "../queries";
import { EyeClosedIcon } from "lucide-react";

export const loader = async ({ request }: Route.LoaderArgs) => {
  const { client } = await makeSSRClient(request);
  const userId = await getLoggedInUserId(client);
  const messages = await getMessages(client, { userId });
  return {
    messages,
  };
};

export default function MessagesLayout({ loaderData }: Route.ComponentProps) {
  const { userId, name, avatar } = useOutletContext<{
    userId: string;
    name: string;
    avatar: string;
  }>();
  return (
    <SidebarProvider className="flex max-h-[calc(100vh-14rem)] overflow-hidden h-[calc(100vh-14rem)] min-h-full">
      <Sidebar className="pt-16" variant="floating">
        <SidebarContent>
          <SidebarGroup>
            <SidebarMenu>
              {loaderData.messages.map((message) => (
                <MessageRoomCard
                  key={message.message_room_id}
                  id={message.message_room_id.toString()}
                  name={message.name}
                  lastMessage={message.last_message}
                  avatarUrl={message.avatar}
                />
              ))}
            </SidebarMenu>
          </SidebarGroup>
          {loaderData.messages.length === 0 && (
            <div className="text-muted-foreground font-semibold h-full flex flex-col items-center justify-center text-center">
              <EyeClosedIcon className="size-10" />
              <span>No messages yet, join a team to start messaging!</span>
            </div>
          )}
        </SidebarContent>
      </Sidebar>
      <div className="w-full flex md:block gap-5 md:gap-0 h-full">
        <SidebarTrigger className="md:hidden" />
        <Outlet context={{ userId, name, avatar }} />
      </div>
    </SidebarProvider>
  );
}
