import { type RouteConfig, index, route } from "@react-router/dev/routes";

export default [
  index("features/sadam/pages/start-page.tsx"),
  route("/result", "features/sadam/pages/result-page.tsx"),
  route("/extra", "features/sadam/pages/extra-page.tsx"),
  route("/premium", "features/sadam/pages/premium-page.tsx"),
  route("/premium/success", "features/sadam/pages/payment-success-page.tsx"),
  route("/premium/fail", "features/sadam/pages/payment-fail-page.tsx"),
  route("/saju/chart", "features/sadam/pages/saju-chart-page.tsx"),
  route("/saju/detail", "features/sadam/pages/saju-detail-page.tsx"),
  route("/saju/graph", "features/sadam/pages/saju-graph-page.tsx"),
  route("/saju/chat", "features/sadam/pages/saju-chat-page.tsx"),
] satisfies RouteConfig;
