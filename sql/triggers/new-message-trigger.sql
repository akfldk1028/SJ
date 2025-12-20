CREATE OR REPLACE FUNCTION public.on_new_message()
RETURNS TRIGGER
SECURITY DEFINER SET search_path = ''
LANGUAGE plpgsql
AS $$
BEGIN
    -- if sender id isn't '2a040d91-8acf-40d1-8c07-42471ea091cb'
    IF NEW.sender_id != '2a040d91-8acf-40d1-8c07-42471ea091cb' THEN
        INSERT INTO public.messages (message_room_id, sender_id, content)
        VALUES (NEW.message_room_id, '2a040d91-8acf-40d1-8c07-42471ea091cb', 'I got your message, this message is sent by the server using Supabase Realtime');
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_new_message
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE PROCEDURE public.on_new_message();