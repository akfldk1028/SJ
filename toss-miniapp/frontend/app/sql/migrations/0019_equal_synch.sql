ALTER TABLE "products" ALTER COLUMN "stats" SET DEFAULT jsonb_build_object(
          'views', floor(random() * 1000)::int,
          'reviews', 0,
          'upvotes', floor(random() * 1000)::int
        );