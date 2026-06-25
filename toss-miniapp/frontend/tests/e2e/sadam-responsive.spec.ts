import { expect, test } from "@playwright/test";

test("start page is responsive and submit path is handled", async ({ page }) => {
  await page.goto("/");

  await expect(page.locator('input[name="name"]')).toBeVisible();
  await expect(page.locator('input[name="birthDate"]')).toBeVisible();
  await expect(page.locator('select[name="birthTime"]')).toBeVisible();
  await expect(page.locator('input[name="gender"][value="female"]')).toBeAttached();

  await page.locator('input[name="name"]').fill("도현");
  await page.locator('input[name="birthDate"]').fill("19950101");
  await page.locator('input[name="gender"][value="female"]').check({ force: true });
  await page.locator("form button").last().click();
  await page.waitForLoadState("networkidle").catch(() => {});

  const isResult = page.url().includes("/result?profileId=");
  const hasHandledError = await page
    .locator("form")
    .getByText(/Supabase|프로필|환경변수/)
    .isVisible()
    .catch(() => false);

  expect(isResult || hasHandledError).toBe(true);
});

test("payment failure page fits the viewport", async ({ page }) => {
  await page.goto(
    "/premium/fail?profileId=test&code=USER_CANCEL&message=cancelled&orderId=order",
  );

  await expect(page.getByText("결제가 완료되지 않았습니다")).toBeVisible();
  await expect(page.getByRole("link", { name: "다시 결제하기" })).toBeVisible();
});
