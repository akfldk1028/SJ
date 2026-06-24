export type TossActionResult = {
  ok: boolean;
  message: string;
};

export async function requestRewardedAd(): Promise<TossActionResult> {
  await new Promise((resolve) => setTimeout(resolve, 450));
  return {
    ok: true,
    message: "리워드 광고 시청이 완료된 상태로 처리했습니다.",
  };
}

export async function requestPremiumPurchase(): Promise<TossActionResult> {
  await new Promise((resolve) => setTimeout(resolve, 450));
  return {
    ok: true,
    message: "상세 분석권 결제가 완료된 상태로 처리했습니다.",
  };
}
