import OpenAI from "openai";
import { zodResponseFormat } from "openai/helpers/zod";
import { z } from "zod";
import { insertIdeas } from "../mutations";
import { makeAdminClient } from "~/supa-client";
import type { Route } from "./+types/generate-idea-page";

const IdeaSchema = z.object({
  title: z.string(),
  description: z.string({
    description: "A short description of the idea. 100 characters max.",
  }),
  problem: z.string(),
  solution: z.string(),
  category: z.enum([
    "tech",
    "business",
    "health",
    "education",
    "finance",
    "other",
  ]),
});

const ResponseSchema = z.object({
  potato: z.array(IdeaSchema),
});

export const action = async ({ request }: Route.ActionArgs) => {
  const openai = new OpenAI();
  if (request.method !== "POST") {
    return new Response(null, { status: 404 });
  }
  const header = request.headers.get("X-POTATO");
  if (!header || header !== "X-TOMATO") {
    return new Response(null, { status: 404 });
  }
  const completion = await openai.beta.chat.completions.parse({
    model: "gpt-4o",
    messages: [
      {
        role: "user",
        content:
          "Give the name and elevator pitch of startup ideas that can be built by small teams.",
      },
      {
        role: "user",
        content:
          "For example: 'An app that helps you find the best deals on groceries.', or 'A platform to rent a coder per hour.'",
      },
      {
        role: "user",
        content: "Give me 10 ideas.",
      },
    ],
    response_format: zodResponseFormat(ResponseSchema, "potato"),
  });
  const descriptions = completion.choices[0].message.parsed?.potato.map(
    (idea) => idea.description
  );
  if (!descriptions) {
    return Response.json(
      {
        error: "No ideas generated",
      },
      { status: 400 }
    );
  }
  await insertIdeas(makeAdminClient(), descriptions);
  return Response.json({
    ok: true,
  });
};
