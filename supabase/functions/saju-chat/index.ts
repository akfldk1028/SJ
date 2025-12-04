import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { SYSTEM_PROMPT } from "./prompts.ts";

// Gemini API Key from environment variable
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");

serve(async (req) => {
    try {
        const { messages, userProfile, targetProfile } = await req.json();

        if (!GEMINI_API_KEY) {
            throw new Error("GEMINI_API_KEY is not set");
        }

        // Context Injection
        let contextMessage = `
User Profile: ${JSON.stringify(userProfile, null, 2)}
`;

        if (targetProfile) {
            contextMessage += `
Target Profile: ${JSON.stringify(targetProfile, null, 2)}
Relationship: ${targetProfile.relationType || "Unknown"}
`;
        }

        // Construct messages for Gemini
        // Note: This is a simplified structure. Actual Gemini API might require different format.
        const chatMessages = [
            { role: "system", content: SYSTEM_PROMPT },
            { role: "user", content: `Context Data:\n${contextMessage}` },
            ...messages.map((msg: any) => ({
                role: msg.role === "user" ? "user" : "model",
                content: msg.content,
            })),
        ];

        // Call Gemini API (Pseudo-code, replace with actual fetch or SDK)
        const response = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${GEMINI_API_KEY}`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    contents: chatMessages.map(m => ({
                        role: m.role === 'system' ? 'user' : m.role, // Gemini doesn't have system role in v1beta same way
                        parts: [{ text: m.content }]
                    })),
                    generationConfig: {
                        temperature: 0.7,
                        maxOutputTokens: 1000,
                    },
                }),
            }
        );

        const data = await response.json();

        if (data.error) {
            throw new Error(data.error.message);
        }

        const aiResponse = data.candidates[0].content.parts[0].text;

        return new Response(
            JSON.stringify({ response: aiResponse }),
            { headers: { "Content-Type": "application/json" } }
        );

    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500, headers: { "Content-Type": "application/json" } }
        );
    }
});
