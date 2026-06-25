import { useState } from "react";
import { Link, type MetaFunction, useLoaderData } from "react-router";
import { CheckIcon, CreditCardIcon, LockKeyholeIcon } from "lucide-react";
import { Badge } from "~/common/components/ui/badge";
import { Button } from "~/common/components/ui/button";
import {
  ZodiacElementBackground,
  ZodiacRevealCard,
} from "../components/zodiac-widgets";
import {
  loadSadamProfile,
  type SadamProfileLoaderData,
} from "../data/route-loaders";
import {
  formatKrw,
  premiumProducts,
  requestPremiumPurchase,
  type PremiumProduct,
  type PremiumProductId,
} from "../toss-adapters";

export const meta: MetaFunction = () => {
  return [{ title: "SaDam 상세 분석권" }];
};

export const loader = loadSadamProfile;

const premiumItems = [
  "보호신과 오행 상세 리포트",
  "대운/세운/관계 흐름 분석",
  "AI 캐릭터 코치와 추가 질문",
];

export default function PremiumPage() {
  const data = useLoaderData() as SadamProfileLoaderData;
  const [selectedProductId, setSelectedProductId] =
    useState<PremiumProductId>("sadam_week_pass");
  const [status, setStatus] = useState<"idle" | "loading" | "done" | "error">(
    "idle",
  );
  const [message, setMessage] = useState("");

  if (data.error || !data.profile || !data.calculation) {
    return (
      <ZodiacElementBackground elementName="목">
        <div className="mx-auto flex min-h-screen w-full max-w-md flex-col justify-center px-5 py-6">
          <section className="rounded-lg bg-white p-5 text-slate-950">
            <h1 className="text-xl font-bold">프로필을 불러오지 못했습니다</h1>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              {data.error ?? "프로필 정보가 없습니다. 다시 입력해 주세요."}
            </p>
            <Button
              asChild
              className="mt-5 h-12 w-full rounded-md bg-sky-600 text-white"
            >
              <Link to="/">다시 입력하기</Link>
            </Button>
          </section>
        </div>
      </ZodiacElementBackground>
    );
  }

  const name = data.profile.display_name;
  const identity = data.calculation.identity;
  const selectedProduct =
    premiumProducts.find((product) => product.id === selectedProductId) ??
    premiumProducts[0];

  const handlePurchase = async () => {
    setStatus("loading");
    setMessage("");
    const result = await requestPremiumPurchase({
      product: selectedProduct,
      profileId: data.profile.id,
      customerName: name,
    });
    setMessage(result.message);
    setStatus(result.ok ? "done" : "error");
  };

  return (
    <ZodiacElementBackground elementName={identity.elementName}>
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col px-5 py-6 lg:max-w-5xl">
        <header>
          <p className="text-xs font-semibold uppercase text-white/65">
            Premium Analysis
          </p>
          <h1 className="mt-1 text-2xl font-bold">상세 분석권</h1>
        </header>

        <section className="mt-6 overflow-hidden rounded-lg border border-white/10 bg-white/[0.06] lg:grid lg:grid-cols-[minmax(20rem,0.9fr)_minmax(0,1.1fr)]">
          <div className={identity.colorClass}>
            <ZodiacRevealCard
              elementName={identity.elementName}
              emoji={identity.animalEmoji}
              imageUrl={identity.largeImageUrl}
              fullName={identity.fullName}
              ganjiHanja={identity.ganjiHanja}
              subtitle={`${name}님 전용 프리미엄 분석`}
            />
          </div>

          <div className="p-5">
            <div className="flex items-center justify-between">
              <div className="rounded-md bg-white/10 p-2">
                <LockKeyholeIcon className="size-5" />
              </div>
              <Badge className="rounded-md bg-white/10 text-white">
                Toss Payments
              </Badge>
            </div>

            <h2 className="mt-8 text-2xl font-bold">
              {name}님 전용 AI 분석을 더 깊게 확인하세요
            </h2>
            <p className="mt-2 text-sm leading-6 text-slate-300">
              Flutter 앱의 프리미엄 이용권 구조를 유지하고, 토스 미니앱에서는
              토스페이먼츠 결제창으로 구매를 진행합니다.
            </p>

            <div className="mt-5 space-y-3">
              {premiumItems.map((item) => (
                <div className="flex items-center gap-3 text-sm" key={item}>
                  <span className="rounded-full bg-emerald-400 p-1 text-slate-950">
                    <CheckIcon className="size-3" />
                  </span>
                  {item}
                </div>
              ))}
            </div>

            <div className="mt-6 grid gap-2 lg:grid-cols-3">
              {premiumProducts.map((product) => (
                <PremiumProductButton
                  isSelected={product.id === selectedProduct.id}
                  key={product.id}
                  onSelect={() => setSelectedProductId(product.id)}
                  product={product}
                />
              ))}
            </div>

            {message ? (
              <div
                className={`mt-5 rounded-lg p-4 text-sm leading-6 ${
                  status === "error"
                    ? "bg-rose-400/10 text-rose-100"
                    : "bg-emerald-400/10 text-emerald-100"
                }`}
              >
                {message}
              </div>
            ) : null}

            <Button
              className="mt-6 h-12 w-full rounded-md bg-blue-500 text-white hover:bg-blue-400"
              disabled={status === "loading"}
              onClick={handlePurchase}
            >
              <CreditCardIcon className="size-4" />
              {status === "loading"
                ? "결제창 여는 중"
                : `${formatKrw(selectedProduct.amount)} 결제하기`}
            </Button>
          </div>
        </section>

        <div className="mt-auto pt-5">
          <Button asChild className="h-12 w-full rounded-md" variant="secondary">
            <Link to={`/result?${data.query}`}>결과 카드로 돌아가기</Link>
          </Button>
        </div>
      </div>
    </ZodiacElementBackground>
  );
}

function PremiumProductButton({
  isSelected,
  onSelect,
  product,
}: {
  isSelected: boolean;
  onSelect: () => void;
  product: PremiumProduct;
}) {
  return (
    <button
      aria-pressed={isSelected}
      className={`w-full rounded-lg border p-4 text-left transition ${
        isSelected
          ? "border-blue-300 bg-blue-400/15"
          : "border-white/10 bg-white/[0.04]"
      }`}
      onClick={onSelect}
      type="button"
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="font-bold text-white">{product.name}</h3>
            <Badge className="rounded-md bg-white/10 text-white">
              {product.badge}
            </Badge>
          </div>
          <p className="mt-1 text-xs text-white/55">{product.periodLabel}</p>
        </div>
        <strong className="whitespace-nowrap text-base text-white">
          {formatKrw(product.amount)}
        </strong>
      </div>
      <p className="mt-3 text-sm leading-6 text-slate-300">
        {product.description}
      </p>
      <div className="mt-3 flex flex-wrap gap-2">
        {product.features.map((feature) => (
          <span
            className="rounded-md bg-white/10 px-2 py-1 text-xs text-white/75"
            key={feature}
          >
            {feature}
          </span>
        ))}
      </div>
    </button>
  );
}
