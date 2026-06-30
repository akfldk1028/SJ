import { useEffect } from "react";

type SafeAreaInsets = {
  top: number;
  right: number;
  bottom: number;
  left: number;
};

export function AppsInTossSafeArea() {
  useEffect(() => {
    let isMounted = true;

    async function applySafeArea() {
      try {
        const { SafeAreaInsets } = await import("@apps-in-toss/web-framework");
        const insets = SafeAreaInsets.get();
        if (isMounted) setSafeAreaInsets(insets);
      } catch {
        setSafeAreaInsets({ top: 0, right: 0, bottom: 0, left: 0 });
      }
    }

    applySafeArea();

    return () => {
      isMounted = false;
    };
  }, []);

  return null;
}

function setSafeAreaInsets(insets: SafeAreaInsets) {
  const root = document.documentElement;
  root.style.setProperty("--ait-safe-top", `${insets.top}px`);
  root.style.setProperty("--ait-safe-right", `${insets.right}px`);
  root.style.setProperty("--ait-safe-bottom", `${insets.bottom}px`);
  root.style.setProperty("--ait-safe-left", `${insets.left}px`);
}
