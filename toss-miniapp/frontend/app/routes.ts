import { type RouteConfig, index, route } from "@react-router/dev/routes";

const startAlias = (path: string, id: string) =>
  route(path, "features/sadam/pages/start-page.tsx", { id });

const parity = (path: string, id: string) =>
  route(path, "features/sadam/pages/flutter-route-page.tsx", { id });

export default [
  index("features/sadam/pages/start-page.tsx"),
  parity("/splash", "sadam-splash"),
  startAlias("/onboarding", "sadam-onboarding"),
  startAlias("/onboarding/zodiac", "sadam-onboarding-zodiac"),
  parity("/menu", "sadam-menu"),
  parity("/profile/select", "sadam-profile-select"),
  parity("/profile/edit", "sadam-profile-edit"),
  route("/result", "features/sadam/pages/result-page.tsx"),
  route("/extra", "features/sadam/pages/extra-page.tsx"),
  route("/premium", "features/sadam/pages/premium-page.tsx"),
  route("/premium/success", "features/sadam/pages/payment-success-page.tsx"),
  route("/premium/fail", "features/sadam/pages/payment-fail-page.tsx"),
  parity("/relationships", "sadam-relationships"),
  parity("/relationships/add", "sadam-relationships-add"),
  parity("/fortune/daily", "sadam-fortune-daily"),
  parity("/fortune/daily/category", "sadam-fortune-daily-category"),
  parity("/fortune/monthly", "sadam-fortune-monthly"),
  parity("/fortune/new-year", "sadam-fortune-new-year"),
  parity("/fortune/yearly-2025", "sadam-fortune-yearly-2025"),
  parity("/fortune/traditional-saju", "sadam-fortune-traditional-saju"),
  parity("/fortune/compatibility", "sadam-fortune-compatibility"),
  parity("/compatibility/list", "sadam-compatibility-list"),
  parity("/compatibility/detail", "sadam-compatibility-detail"),
  parity("/history", "sadam-history"),
  parity("/calendar", "sadam-calendar"),
  parity("/settings", "sadam-settings"),
  parity("/settings/profile", "sadam-settings-profile"),
  parity("/settings/notification", "sadam-settings-notification"),
  parity("/settings/terms", "sadam-settings-terms"),
  parity("/settings/privacy", "sadam-settings-privacy"),
  parity("/settings/disclaimer", "sadam-settings-disclaimer"),
  parity("/settings/icon-generator", "sadam-settings-icon-generator"),
  route("/settings/premium", "features/sadam/pages/premium-page.tsx", { id: "sadam-settings-premium" }),
  parity("/settings/subscription", "sadam-settings-subscription"),
  route("/saju/chart", "features/sadam/pages/saju-chart-page.tsx"),
  route("/saju/detail", "features/sadam/pages/saju-detail-page.tsx"),
  route("/saju/graph", "features/sadam/pages/saju-graph-page.tsx"),
  route("/saju/chat", "features/sadam/pages/saju-chat-page.tsx"),
] satisfies RouteConfig;
