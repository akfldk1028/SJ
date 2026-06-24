ALTER TABLE "public"."jobs" ALTER COLUMN "salary_range" SET DATA TYPE text;--> statement-breakpoint
DROP TYPE "public"."salary_range";--> statement-breakpoint
CREATE TYPE "public"."salary_range" AS ENUM('$0 - $50,000', '$50,000 - $70,000', '$70,000 - $100,000', '$100,000 - $120,000', '$120,000 - $150,000', '$150,000 - $250,000', '$250,000 - $500,000');--> statement-breakpoint
ALTER TABLE "public"."jobs" ALTER COLUMN "salary_range" SET DATA TYPE "public"."salary_range" USING "salary_range"::"public"."salary_range";