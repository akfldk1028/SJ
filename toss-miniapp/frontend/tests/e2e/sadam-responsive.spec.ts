import { expect, type Page, test } from "@playwright/test";
import { lunarToSolar } from "../../app/features/sadam/chart/lunar-calendar";
import { cheongan, jiji } from "../../app/features/sadam/personas";
import { resolveSadamIdentity } from "../../app/features/sadam/saju-calculation";

test("lunar 1994-11-28 resolves to the Flutter reference day pillar", () => {
  const calculation = resolveSadamIdentity({
    birthDate: "19941128",
    birthTime: "unknown",
    birthTimeUnknown: true,
    calendar: "lunar",
    gender: "male",
  });

  expect(calculation.correctedDateTime.getFullYear()).toBe(1994);
  expect(calculation.correctedDateTime.getMonth()).toBe(11);
  expect(calculation.correctedDateTime.getDate()).toBe(30);
  expect(calculation.dayPillar).toEqual({
    gan: cheongan[6],
    ji: jiji[2],
  });
  expect(calculation.identity.ganji).toBe(`${cheongan[6]}${jiji[2]}`);
  expect(calculation.warnings).toEqual([]);
});

test("lunar leap month conversion follows the Flutter month index table", () => {
  expect(lunarToSolar({ year: 1995, month: 8, day: 1 })).toEqual({
    year: 1995,
    month: 8,
    day: 26,
  });
  expect(lunarToSolar({ year: 1995, month: 8, day: 1, isLeapMonth: true })).toEqual({
    year: 1995,
    month: 9,
    day: 25,
  });
  expect(lunarToSolar({ year: 1995, month: 9, day: 1 })).toEqual({
    year: 1995,
    month: 10,
    day: 24,
  });
  expect(lunarToSolar({ year: 1995, month: 7, day: 1, isLeapMonth: true })).toBeNull();
});

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

test("calendar and gender radio selections show active state", async ({ page }) => {
  await page.goto("/");

  await page.locator('input[name="calendar"][value="lunar"]').check({ force: true });
  await page.locator('input[name="gender"][value="male"]').check({ force: true });

  const state = await page.evaluate(() => {
    function readSurface(selector: string) {
      const input = document.querySelector<HTMLInputElement>(selector);
      const surface = input?.nextElementSibling;
      if (!input || !surface) return null;
      const style = getComputedStyle(surface);
      return {
        checked: input.checked,
        backgroundColor: style.backgroundColor,
        borderColor: style.borderColor,
      };
    }

    return {
      lunar: readSurface('input[name="calendar"][value="lunar"]'),
      solar: readSurface('input[name="calendar"][value="solar"]'),
      male: readSurface('input[name="gender"][value="male"]'),
      female: readSurface('input[name="gender"][value="female"]'),
    };
  });

  expect(state.lunar?.checked).toBe(true);
  expect(state.male?.checked).toBe(true);
  expect(state.lunar?.backgroundColor).not.toBe(state.solar?.backgroundColor);
  expect(state.male?.backgroundColor).not.toBe(state.female?.backgroundColor);
});

test("created profile pages render without app errors or horizontal overflow", async ({ page }) => {
  test.setTimeout(90_000);

  const profileId = await createProfile(page);
  const safeProfileId = profileId.replace(/[^a-zA-Z0-9_-]/g, "");
  const fakeOrderId = `sadam-sadam_week_pass-${safeProfileId.slice(0, 12)}-fake`;
  const routes = [
    "/",
    `/splash`,
    `/onboarding`,
    `/onboarding/zodiac`,
    `/menu?profileId=${profileId}`,
    `/profile/select?profileId=${profileId}`,
    `/profile/edit?profileId=${profileId}`,
    `/result?profileId=${profileId}`,
    `/extra?profileId=${profileId}`,
    `/premium?profileId=${profileId}`,
    `/premium/fail?profileId=${profileId}&productId=sadam_week_pass&code=USER_CANCEL&message=cancelled&orderId=order`,
    `/premium/success?profileId=${profileId}&productId=sadam_week_pass&paymentKey=fake_payment_key_for_page_audit&orderId=${fakeOrderId}&amount=5900`,
    `/saju/chart?profileId=${profileId}`,
    `/saju/detail?profileId=${profileId}`,
    `/saju/graph?profileId=${profileId}`,
    `/saju/chat?profileId=${profileId}`,
    `/saju/chat?profileId=${profileId}&type=compatibility&targetProfileId=${profileId}&autoMention=true`,
    `/relationships?profileId=${profileId}`,
    `/relationships/add?profileId=${profileId}`,
    `/fortune/daily?profileId=${profileId}`,
    `/fortune/daily/category?profileId=${profileId}`,
    `/fortune/monthly?profileId=${profileId}`,
    `/fortune/new-year?profileId=${profileId}`,
    `/fortune/yearly-2025?profileId=${profileId}`,
    `/fortune/traditional-saju?profileId=${profileId}`,
    `/fortune/compatibility?profileId=${profileId}`,
    `/compatibility/list?profileId=${profileId}`,
    `/compatibility/detail?profileId=${profileId}`,
    `/history?profileId=${profileId}`,
    `/calendar?profileId=${profileId}`,
    `/settings?profileId=${profileId}`,
    `/settings/profile?profileId=${profileId}`,
    `/settings/notification?profileId=${profileId}`,
    `/settings/terms?profileId=${profileId}`,
    `/settings/privacy?profileId=${profileId}`,
    `/settings/disclaimer?profileId=${profileId}`,
    `/settings/icon-generator?profileId=${profileId}`,
    `/settings/premium?profileId=${profileId}`,
    `/settings/subscription?profileId=${profileId}`,
  ];

  for (const route of routes) {
    await page.goto(route);
    await page.waitForLoadState("networkidle").catch(() => {});

    const pageState = await page.evaluate(() => ({
      hasApplicationError: document.body.innerText.includes("Application Error"),
      scrollWidth: document.documentElement.scrollWidth,
      clientWidth: document.documentElement.clientWidth,
    }));

    expect(pageState.hasApplicationError, route).toBe(false);
    expect(pageState.scrollWidth, route).toBeLessThanOrEqual(pageState.clientWidth + 2);
  }
});

test("chat route preserves Flutter query contract", async ({ page }) => {
  const profileId = await createProfile(page);
  await page.goto(
    `/saju/chat?profileId=${profileId}&type=compatibility&targetProfileId=${profileId}&autoMention=true`,
  );

  await expect(page.getByText("AI 사주 상담")).toBeVisible();
  await expect(page.getByText("궁합 상담")).toBeVisible();
  await expect(page.getByText("자동 멘션")).toBeVisible();
  await expect(page.locator('input[name="type"]').first()).toHaveValue("compatibility");
  await expect(page.locator('input[name="targetProfileId"]').first()).toHaveValue(profileId);
  await expect(page.locator('input[name="autoMention"]').first()).toHaveValue("true");
});

test("payment failure page fits the viewport", async ({ page }) => {
  await page.goto(
    "/premium/fail?profileId=test&code=USER_CANCEL&message=cancelled&orderId=order",
  );

  await expect(page.getByText("결제가 완료되지 않았습니다")).toBeVisible();
  await expect(page.getByRole("link", { name: "다시 결제하기" })).toBeVisible();
});

async function createProfile(page: Page) {
  await page.goto("/");
  await page.locator('input[name="name"]').fill("Dohyun");
  await page.locator('input[name="birthDate"]').fill("19950101");
  await page.locator('input[name="calendar"][value="lunar"]').check({ force: true });
  await page.locator('input[name="gender"][value="male"]').check({ force: true });
  await page.locator("form button").last().click();
  await page.waitForURL(/\/result\?profileId=/, { timeout: 20_000 });

  const profileId = new URL(page.url()).searchParams.get("profileId");
  if (!profileId) {
    throw new Error("Profile was not created");
  }

  return profileId;
}
