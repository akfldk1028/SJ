import { type RouteConfig, index, route } from "@react-router/dev/routes";

export default [
  index("features/sadam/pages/start-page.tsx"),
  route("/result", "features/sadam/pages/result-page.tsx"),
  route("/extra", "features/sadam/pages/extra-page.tsx"),
  route("/premium", "features/sadam/pages/premium-page.tsx"),
] satisfies RouteConfig;
