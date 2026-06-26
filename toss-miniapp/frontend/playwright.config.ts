import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/e2e",
  timeout: 30_000,
  use: {
    baseURL: "http://127.0.0.1:5177",
    trace: "retain-on-failure",
  },
  webServer: {
    command: "npm run dev -- --host 127.0.0.1 --port 5177",
    reuseExistingServer: true,
    timeout: 60_000,
    url: "http://127.0.0.1:5177",
  },
  projects: [
    {
      name: "chromium-mobile",
      use: { ...devices["Pixel 5"] },
    },
    {
      name: "chromium-desktop",
      use: {
        browserName: "chromium",
        viewport: { width: 1440, height: 1000 },
      },
    },
  ],
});
