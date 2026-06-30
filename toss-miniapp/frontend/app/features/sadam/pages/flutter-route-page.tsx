import {
  Form,
  Link,
  redirect,
  type ActionFunctionArgs,
  type LoaderFunctionArgs,
  type MetaFunction,
  useActionData,
  useLoaderData,
  useLocation,
} from "react-router";
import {
  BellIcon,
  CalendarDaysIcon,
  ChevronRightIcon,
  CreditCardIcon,
  FileTextIcon,
  HeartIcon,
  HistoryIcon,
  HomeIcon,
  MessageCircleIcon,
  PlusIcon,
  SettingsIcon,
  ShieldIcon,
  SparklesIcon,
  UserRoundIcon,
  UsersRoundIcon,
} from "lucide-react";
import { Badge } from "~/common/components/ui/badge";
import { Button } from "~/common/components/ui/button";
import {
  getAiSummariesForProfile,
  getChatSessionsForProfile,
  getCompatibilityForProfile,
  getProfilesForUser,
  getRelationsForUser,
  getSubscriptionsForUser,
  type CompatibilityAnalysisRow,
  type ProfileRelationRow,
} from "../data/flutter-parity";
import { resolveCalculationFromProfile, type AiSummaryRow, type SajuProfileRow } from "../data/models";
import { createClientFromRequest } from "../data/supabase-server";
import type { ChatSessionRow } from "../data/chat";
import type { SubscriptionRow } from "../data/subscriptions";

type LoaderData = {
  path: string;
  userId: string | null;
  selectedProfileId: string | null;
  profiles: SajuProfileRow[];
  relations: ProfileRelationRow[];
  compatibility: CompatibilityAnalysisRow[];
  chats: ChatSessionRow[];
  summaries: AiSummaryRow[];
  subscriptions: SubscriptionRow[];
  errors: string[];
};

export const meta: MetaFunction = () => {
  return [{ title: "SaDam Toss" }];
};

export async function loader({ request, context }: LoaderFunctionArgs) {
  const url = new URL(request.url);
  const path = url.pathname;
  const client = createClientFromRequest(
    request,
    (context as { cloudflare: { env: CloudflareEnvironment } }).cloudflare.env,
  );

  if (!client) {
    if (path === "/splash") return redirect("/");
    return emptyData(path, null, null, ["로그인 세션이 없습니다. 홈에서 기본 정보를 먼저 입력해 주세요."]);
  }

  const { data: auth, error: authError } = await client.auth.getUser();
  if (authError || !auth.user) {
    if (path === "/splash") return redirect("/");
    return emptyData(path, null, null, ["로그인 세션을 확인하지 못했습니다."]);
  }

  const profilesResult = await getProfilesForUser(client, auth.user.id);
  const profiles = profilesResult.data;
  const selectedProfileId =
    url.searchParams.get("profileId") ??
    profiles.find((profile) => profile.profile_type === "primary")?.id ??
    profiles[0]?.id ??
    null;

  if (path === "/splash") {
    return redirect(selectedProfileId ? `/menu?profileId=${selectedProfileId}` : "/");
  }

  const [relationsResult, compatibilityResult, chatsResult, summariesResult, subscriptionsResult] =
    await Promise.all([
      getRelationsForUser(client, auth.user.id),
      getCompatibilityForProfile(client, selectedProfileId),
      getChatSessionsForProfile(client, selectedProfileId),
      getAiSummariesForProfile(client, selectedProfileId),
      getSubscriptionsForUser(client, auth.user.id),
    ]);

  return {
    path,
    userId: auth.user.id,
    selectedProfileId,
    profiles,
    relations: relationsResult.data,
    compatibility: compatibilityResult.data,
    chats: chatsResult.data,
    summaries: summariesResult.data,
    subscriptions: subscriptionsResult.data,
    errors: [
      profilesResult.error,
      relationsResult.error,
      compatibilityResult.error,
      chatsResult.error,
      summariesResult.error,
      subscriptionsResult.error,
    ].filter((error): error is string => Boolean(error)),
  } satisfies LoaderData;
}

export async function action({ request, context }: ActionFunctionArgs) {
  const url = new URL(request.url);
  const client = createClientFromRequest(
    request,
    (context as { cloudflare: { env: CloudflareEnvironment } }).cloudflare.env,
  );

  if (!client) return { error: "로그인 세션이 없습니다." };
  const { data: auth, error: authError } = await client.auth.getUser();
  if (authError || !auth.user) return { error: "로그인 세션을 확인하지 못했습니다." };

  if (url.pathname !== "/relationships/add") return { error: "지원하지 않는 작업입니다." };

  const formData = await request.formData();
  const fromProfileId = String(formData.get("fromProfileId") ?? "");
  const toProfileId = String(formData.get("toProfileId") ?? "");
  const relationType = String(formData.get("relationType") ?? "friend");
  const displayName = String(formData.get("displayName") ?? "").trim();
  const memo = String(formData.get("memo") ?? "").trim();

  if (!fromProfileId || !toProfileId || fromProfileId === toProfileId) {
    return { error: "서로 다른 두 프로필을 선택해 주세요." };
  }

  const { error } = await client.from("profile_relations").insert({
    id: crypto.randomUUID(),
    user_id: auth.user.id,
    from_profile_id: fromProfileId,
    to_profile_id: toProfileId,
    relation_type: relationType,
    display_name: displayName || null,
    memo: memo || null,
    is_favorite: false,
    sort_order: 0,
    analysis_status: "pending",
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });

  if (error) return { error: `관계 저장 실패: ${error.message}` };
  return redirect(`/relationships?profileId=${fromProfileId}`);
}

function emptyData(
  path: string,
  userId: string | null,
  selectedProfileId: string | null,
  errors: string[],
): LoaderData {
  return {
    path,
    userId,
    selectedProfileId,
    profiles: [],
    relations: [],
    compatibility: [],
    chats: [],
    summaries: [],
    subscriptions: [],
    errors,
  };
}

export default function FlutterRoutePage() {
  const data = useLoaderData() as LoaderData;
  const actionData = useActionData() as { error?: string } | undefined;
  const selected = data.profiles.find((profile) => profile.id === data.selectedProfileId) ?? data.profiles[0] ?? null;
  const query = selected ? `profileId=${selected.id}` : "";

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top_left,#fb7185_0,#111827_34%,#020617_100%)] text-white">
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col px-4 py-5 sm:px-5 lg:max-w-5xl lg:py-7">
        <header className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-semibold uppercase text-white/60">SaDam Toss</p>
            <h1 className="mt-1 text-2xl font-bold tracking-tight">{titleForPath(data.path)}</h1>
            <p className="mt-2 max-w-2xl text-sm leading-6 text-white/70">
              Flutter 앱의 같은 메뉴 구조를 React 미니앱에서 바로 확인할 수 있게 연결했습니다.
            </p>
          </div>
          <Button asChild className="size-10 shrink-0 rounded-md bg-white/10 p-0 text-white hover:bg-white/15" variant="ghost">
            <Link aria-label="홈으로" to={selected ? `/menu?${query}` : "/"}>
              <HomeIcon className="size-5" />
            </Link>
          </Button>
        </header>

        {data.errors.length > 0 ? (
          <section className="mt-4 rounded-lg border border-amber-300/30 bg-amber-100/95 p-3 text-sm leading-6 text-amber-950">
            {data.errors.slice(0, 2).map((error) => <p key={error}>{error}</p>)}
          </section>
        ) : null}

        {actionData?.error ? (
          <section className="mt-4 rounded-lg border border-red-300/40 bg-red-50 p-3 text-sm text-red-900">
            {actionData.error}
          </section>
        ) : null}

        <ProfileStrip profiles={data.profiles} selectedProfileId={data.selectedProfileId} />

        <section className="mt-5 grid gap-4 lg:grid-cols-[minmax(0,0.72fr)_minmax(18rem,0.28fr)]">
          <div className="space-y-4">
            {renderRouteBody(data, selected)}
          </div>
          <aside className="space-y-4">
            <QuickMenu query={query} />
            <DataHealth data={data} />
          </aside>
        </section>
      </div>
    </main>
  );
}

function renderRouteBody(data: LoaderData, selected: SajuProfileRow | null) {
  switch (data.path) {
    case "/menu":
      return <MenuPage selected={selected} data={data} />;
    case "/profile/select":
      return <ProfileSelectPage data={data} />;
    case "/profile/edit":
      return <ProfileEditPage selected={selected} />;
    case "/relationships":
      return <RelationshipsPage data={data} />;
    case "/relationships/add":
      return <RelationshipAddPage data={data} />;
    case "/fortune/compatibility":
    case "/compatibility/list":
      return <CompatibilityListPage data={data} />;
    case "/compatibility/detail":
      return <CompatibilityDetailPage data={data} />;
    case "/history":
      return <HistoryPage data={data} />;
    case "/calendar":
      return <CalendarPage data={data} />;
    case "/settings":
      return <SettingsPage selected={selected} />;
    case "/settings/profile":
      return <ProfileSelectPage data={data} compact />;
    case "/settings/notification":
      return <NoticePage title="알림 설정" body="운세 리마인드와 분석 완료 알림을 받을 준비가 된 화면입니다. Toss 미니앱 권한 정책에 맞춰 실제 알림 권한 연결만 남겨두면 됩니다." />;
    case "/settings/terms":
      return <NoticePage title="이용약관" body="서비스 이용 조건, 계정, 결제, AI 분석 고지 항목을 Flutter 앱과 같은 메뉴 위치에 배치했습니다." />;
    case "/settings/privacy":
      return <NoticePage title="개인정보 처리방침" body="생년월일, 성별, 사주 분석 데이터, 채팅 데이터가 Supabase에 저장되는 흐름을 사용자에게 안내하는 화면입니다." />;
    case "/settings/disclaimer":
      return <NoticePage title="고지사항" body="사주와 AI 해석은 참고용 콘텐츠이며, 법률/의료/투자 판단을 대체하지 않는다는 고지를 노출합니다." />;
    case "/settings/icon-generator":
      return <NoticePage title="아이콘 생성" body="프로필 사주 색상과 동물 정체성을 기반으로 아이콘을 만드는 Flutter 도구 메뉴를 React 라우터에 연결했습니다." />;
    case "/settings/subscription":
      return <SubscriptionPage data={data} />;
    default:
      return <FortunePage data={data} selected={selected} />;
  }
}

function titleForPath(path: string) {
  const titles: Record<string, string> = {
    "/menu": "홈",
    "/profile/select": "프로필 선택",
    "/profile/edit": "프로필 관리",
    "/relationships": "관계",
    "/relationships/add": "관계 추가",
    "/fortune/daily": "오늘의 운세",
    "/fortune/daily/category": "카테고리 운세",
    "/fortune/monthly": "월간 운세",
    "/fortune/new-year": "신년 운세",
    "/fortune/yearly-2025": "2025 운세",
    "/fortune/traditional-saju": "정통 사주",
    "/fortune/compatibility": "궁합",
    "/compatibility/list": "궁합 목록",
    "/compatibility/detail": "궁합 상세",
    "/history": "분석 기록",
    "/calendar": "운세 캘린더",
    "/settings": "설정",
    "/settings/profile": "프로필 설정",
    "/settings/notification": "알림",
    "/settings/terms": "이용약관",
    "/settings/privacy": "개인정보 처리방침",
    "/settings/disclaimer": "고지사항",
    "/settings/icon-generator": "아이콘 생성",
    "/settings/subscription": "구독 관리",
  };
  return titles[path] ?? "운세";
}

function profileQuery(profile: SajuProfileRow | null) {
  return profile ? `profileId=${profile.id}` : "";
}

function ProfileStrip({ profiles, selectedProfileId }: { profiles: SajuProfileRow[]; selectedProfileId: string | null }) {
  if (profiles.length === 0) {
    return (
      <section className="mt-5 rounded-lg border border-white/15 bg-white/[0.96] p-4 text-slate-950">
        <h2 className="text-base font-bold">프로필이 없습니다</h2>
        <p className="mt-2 text-sm text-slate-600">홈에서 기본 정보를 입력하면 사주 분석과 메뉴가 연결됩니다.</p>
        <Button asChild className="mt-4 h-11 w-full rounded-md bg-rose-600 text-white">
          <Link to="/">사주 알아보기</Link>
        </Button>
      </section>
    );
  }

  return (
    <section className="mt-5 flex gap-2 overflow-x-auto pb-1">
      {profiles.map((profile) => (
        <Link
          className={`min-w-40 rounded-lg border px-3 py-3 text-sm shadow-lg ${
            profile.id === selectedProfileId
              ? "border-white bg-white text-slate-950"
              : "border-white/15 bg-white/10 text-white"
          }`}
          key={profile.id}
          to={`?profileId=${profile.id}`}
        >
          <p className="font-bold">{profile.display_name}</p>
          <p className="mt-1 text-xs opacity-70">{profile.is_lunar ? "음력" : "양력"} {profile.birth_date}</p>
        </Link>
      ))}
    </section>
  );
}

function Card({ title, icon, children }: { title: string; icon?: React.ReactNode; children: React.ReactNode }) {
  return (
    <section className="rounded-lg border border-white/15 bg-white/[0.96] p-4 text-slate-950 shadow-xl shadow-black/10">
      <div className="flex items-center gap-2">
        {icon}
        <h2 className="text-base font-bold">{title}</h2>
      </div>
      <div className="mt-4">{children}</div>
    </section>
  );
}

function MenuPage({ selected, data }: { selected: SajuProfileRow | null; data: LoaderData }) {
  const query = profileQuery(selected);
  const items = [
    { title: "사주 차트", to: `/saju/chart?${query}`, icon: <SparklesIcon className="size-4" /> },
    { title: "AI 상담", to: `/saju/chat?${query}`, icon: <MessageCircleIcon className="size-4" /> },
    { title: "오늘 운세", to: `/fortune/daily?${query}`, icon: <CalendarDaysIcon className="size-4" /> },
    { title: "관계", to: `/relationships?${query}`, icon: <UsersRoundIcon className="size-4" /> },
    { title: "궁합", to: `/fortune/compatibility?${query}`, icon: <HeartIcon className="size-4" /> },
    { title: "설정", to: `/settings?${query}`, icon: <SettingsIcon className="size-4" /> },
  ];

  return (
    <>
      <Card title="요약" icon={<UserRoundIcon className="size-4 text-rose-600" />}>
        {selected ? <ProfileSummary profile={selected} /> : <p className="text-sm text-slate-600">프로필을 먼저 만들어 주세요.</p>}
      </Card>
      <div className="grid gap-3 sm:grid-cols-2">
        {items.map((item) => (
          <Link className="rounded-lg border border-white/15 bg-white/[0.96] p-4 text-slate-950 shadow-xl shadow-black/10" key={item.to} to={item.to}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 font-bold">{item.icon}{item.title}</div>
              <ChevronRightIcon className="size-4 text-slate-400" />
            </div>
          </Link>
        ))}
      </div>
      <Card title="최근 흐름">
        <div className="grid gap-2 sm:grid-cols-3">
          <Metric label="프로필" value={`${data.profiles.length}개`} />
          <Metric label="관계" value={`${data.relations.length}개`} />
          <Metric label="채팅" value={`${data.chats.length}개`} />
        </div>
      </Card>
    </>
  );
}

function ProfileSummary({ profile }: { profile: SajuProfileRow }) {
  let ganji = profile.zodiac_ganji ?? "-";
  try {
    ganji = resolveCalculationFromProfile(profile).identity.ganjiHanja;
  } catch {
    ganji = profile.zodiac_ganji ?? "-";
  }

  return (
    <div className="grid gap-2 sm:grid-cols-2">
      <Metric label="이름" value={profile.display_name} />
      <Metric label="일주" value={ganji} />
      <Metric label="생년월일" value={`${profile.is_lunar ? "음력" : "양력"} ${profile.birth_date}`} />
      <Metric label="성별" value={profile.gender === "male" ? "남성" : "여성"} />
    </div>
  );
}

function Metric({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="rounded-md bg-slate-100 p-3">
      <p className="text-xs font-semibold text-slate-500">{label}</p>
      <p className="mt-1 font-bold text-slate-950">{value}</p>
    </div>
  );
}

function ProfileSelectPage({ data, compact = false }: { data: LoaderData; compact?: boolean }) {
  return (
    <Card title={compact ? "프로필 설정" : "프로필 선택"} icon={<UserRoundIcon className="size-4 text-rose-600" />}>
      <div className="space-y-3">
        {data.profiles.map((profile) => (
          <Link className="flex items-center justify-between rounded-lg border border-slate-200 p-3" key={profile.id} to={`/menu?profileId=${profile.id}`}>
            <div>
              <p className="font-bold">{profile.display_name}</p>
              <p className="mt-1 text-xs text-slate-500">{profile.is_lunar ? "음력" : "양력"} {profile.birth_date}</p>
            </div>
            <ChevronRightIcon className="size-4 text-slate-400" />
          </Link>
        ))}
        <Button asChild className="h-11 w-full rounded-md bg-rose-600 text-white">
          <Link to="/">새 프로필 만들기</Link>
        </Button>
      </div>
    </Card>
  );
}

function ProfileEditPage({ selected }: { selected: SajuProfileRow | null }) {
  return (
    <Card title="프로필 관리" icon={<UserRoundIcon className="size-4 text-rose-600" />}>
      {selected ? <ProfileSummary profile={selected} /> : <p className="text-sm text-slate-600">선택된 프로필이 없습니다.</p>}
      <Button asChild className="mt-4 h-11 w-full rounded-md bg-slate-950 text-white">
        <Link to="/">새 정보로 다시 입력하기</Link>
      </Button>
    </Card>
  );
}

function RelationshipsPage({ data }: { data: LoaderData }) {
  const profileMap = new Map(data.profiles.map((profile) => [profile.id, profile.display_name]));

  return (
    <Card title="관계 목록" icon={<UsersRoundIcon className="size-4 text-rose-600" />}>
      <div className="space-y-3">
        {data.relations.length === 0 ? <p className="text-sm text-slate-600">저장된 관계가 없습니다. 두 프로필을 만들고 관계를 추가해 주세요.</p> : null}
        {data.relations.map((relation) => (
          <div className="rounded-lg border border-slate-200 p-3" key={relation.id}>
            <div className="flex items-center justify-between gap-3">
              <p className="font-bold">{relation.display_name || profileMap.get(relation.to_profile_id) || "상대 프로필"}</p>
              <Badge className="rounded-md bg-rose-100 text-rose-800">{relation.relation_type ?? "관계"}</Badge>
            </div>
            <p className="mt-2 text-sm text-slate-600">
              {profileMap.get(relation.from_profile_id) ?? "나"}{" -> "}
              {profileMap.get(relation.to_profile_id) ?? "상대"}
            </p>
            {relation.memo ? <p className="mt-2 text-sm text-slate-500">{relation.memo}</p> : null}
          </div>
        ))}
        <Button asChild className="h-11 w-full rounded-md bg-rose-600 text-white">
          <Link to={`/relationships/add${data.selectedProfileId ? `?profileId=${data.selectedProfileId}` : ""}`}>
            <PlusIcon className="size-4" />
            관계 추가
          </Link>
        </Button>
      </div>
    </Card>
  );
}

function RelationshipAddPage({ data }: { data: LoaderData }) {
  return (
    <Card title="관계 추가" icon={<PlusIcon className="size-4 text-rose-600" />}>
      {data.profiles.length < 2 ? (
        <div className="space-y-3">
          <p className="text-sm leading-6 text-slate-600">관계 분석에는 두 개 이상의 프로필이 필요합니다.</p>
          <Button asChild className="h-11 w-full rounded-md bg-rose-600 text-white"><Link to="/">프로필 추가</Link></Button>
        </div>
      ) : (
        <Form className="space-y-3" method="post">
          <SelectField defaultValue={data.selectedProfileId ?? data.profiles[0].id} label="기준 프로필" name="fromProfileId" profiles={data.profiles} />
          <SelectField defaultValue={data.profiles.find((profile) => profile.id !== data.selectedProfileId)?.id ?? data.profiles[1].id} label="상대 프로필" name="toProfileId" profiles={data.profiles} />
          <label className="block text-sm font-semibold text-slate-700">
            관계
            <select className="mt-1 h-11 w-full rounded-md border border-slate-200 bg-white px-3" name="relationType">
              <option value="friend">친구</option>
              <option value="lover">연인</option>
              <option value="family">가족</option>
              <option value="coworker">동료</option>
            </select>
          </label>
          <label className="block text-sm font-semibold text-slate-700">
            표시 이름
            <input className="mt-1 h-11 w-full rounded-md border border-slate-200 px-3" name="displayName" placeholder="예: 민지와의 궁합" />
          </label>
          <label className="block text-sm font-semibold text-slate-700">
            메모
            <textarea className="mt-1 min-h-24 w-full rounded-md border border-slate-200 p-3" name="memo" placeholder="관계 메모" />
          </label>
          <Button className="h-11 w-full rounded-md bg-rose-600 text-white" type="submit">저장</Button>
        </Form>
      )}
    </Card>
  );
}

function SelectField({ label, name, profiles, defaultValue }: { label: string; name: string; profiles: SajuProfileRow[]; defaultValue: string }) {
  return (
    <label className="block text-sm font-semibold text-slate-700">
      {label}
      <select className="mt-1 h-11 w-full rounded-md border border-slate-200 bg-white px-3" defaultValue={defaultValue} name={name}>
        {profiles.map((profile) => <option key={profile.id} value={profile.id}>{profile.display_name}</option>)}
      </select>
    </label>
  );
}

function FortunePage({ data, selected }: { data: LoaderData; selected: SajuProfileRow | null }) {
  const summary = data.summaries[0];
  const query = profileQuery(selected);

  return (
    <Card title={titleForPath(data.path)} icon={<SparklesIcon className="size-4 text-rose-600" />}>
      <div className="space-y-3">
        {selected ? <ProfileSummary profile={selected} /> : null}
        <p className="text-sm leading-6 text-slate-600">
          저장된 사주 분석과 AI 요약을 기준으로 Flutter의 운세 메뉴를 React 라우터에 연결했습니다.
        </p>
        {summary ? <JsonPreview value={summary.content} /> : <p className="text-sm text-slate-500">저장된 AI 요약이 없으면 상담 화면에서 새 분석을 시작할 수 있습니다.</p>}
        <div className="grid gap-2 sm:grid-cols-2">
          <Button asChild className="h-11 rounded-md bg-slate-950 text-white"><Link to={`/saju/detail?${query}`}>정통 사주 보기</Link></Button>
          <Button asChild className="h-11 rounded-md bg-rose-600 text-white"><Link to={`/saju/chat?${query}&type=${chatTypeForPath(data.path)}`}>AI로 이어서 보기</Link></Button>
        </div>
      </div>
    </Card>
  );
}

function chatTypeForPath(path: string) {
  if (path.includes("monthly")) return "monthly";
  if (path.includes("compatibility")) return "compatibility";
  if (path.includes("year")) return "yearly";
  return "daily";
}

function CompatibilityListPage({ data }: { data: LoaderData }) {
  return (
    <Card title="궁합" icon={<HeartIcon className="size-4 text-rose-600" />}>
      <div className="space-y-3">
        {data.compatibility.length === 0 ? <p className="text-sm text-slate-600">저장된 궁합 분석이 없습니다. 관계를 추가하거나 AI 상담에서 궁합 질문을 시작해 주세요.</p> : null}
        {data.compatibility.map((item) => (
          <Link className="block rounded-lg border border-slate-200 p-3" key={item.id} to={`/compatibility/detail?profileId=${data.selectedProfileId ?? ""}&analysisId=${item.id}`}>
            <div className="flex items-center justify-between">
              <p className="font-bold">{item.relation_type ?? "궁합 분석"}</p>
              <Badge className="rounded-md bg-rose-100 text-rose-800">{item.overall_score ?? "-"}점</Badge>
            </div>
            <p className="mt-2 line-clamp-2 text-sm text-slate-600">{stringifyShort(item.summary ?? item.analysis_content)}</p>
          </Link>
        ))}
      </div>
    </Card>
  );
}

function CompatibilityDetailPage({ data }: { data: LoaderData }) {
  const location = useLocation();
  const analysisId = new URLSearchParams(location.search).get("analysisId");
  const item = data.compatibility.find((analysis) => analysis.id === analysisId) ?? data.compatibility[0];

  return (
    <Card title="궁합 상세" icon={<HeartIcon className="size-4 text-rose-600" />}>
      {item ? (
        <div className="space-y-3">
          <Metric label="총점" value={item.overall_score ?? "-"} />
          <JsonPreview value={item.summary ?? item.analysis_content ?? item.category_scores} />
        </div>
      ) : <p className="text-sm text-slate-600">표시할 궁합 분석이 없습니다.</p>}
    </Card>
  );
}

function HistoryPage({ data }: { data: LoaderData }) {
  return (
    <Card title="분석 기록" icon={<HistoryIcon className="size-4 text-rose-600" />}>
      <div className="space-y-3">
        {[...data.chats].slice(0, 10).map((chat) => (
          <Link className="block rounded-lg border border-slate-200 p-3" key={chat.id} to={`/saju/chat?profileId=${chat.profile_id}&sessionId=${chat.id}`}>
            <p className="font-bold">{chat.title || chat.chat_type || "AI 상담"}</p>
            <p className="mt-1 text-sm text-slate-600">{chat.last_message_preview || chat.context_summary || "상담 기록"}</p>
          </Link>
        ))}
        {data.chats.length === 0 ? <p className="text-sm text-slate-600">아직 상담 기록이 없습니다.</p> : null}
      </div>
    </Card>
  );
}

function CalendarPage({ data }: { data: LoaderData }) {
  return (
    <Card title="운세 캘린더" icon={<CalendarDaysIcon className="size-4 text-rose-600" />}>
      <div className="grid gap-2 sm:grid-cols-3">
        {["오늘", "이번 주", "이번 달"].map((label) => (
          <Metric key={label} label={label} value="AI 운세 확인" />
        ))}
      </div>
      <div className="mt-4 space-y-2">
        {data.profiles.map((profile) => (
          <Link className="flex items-center justify-between rounded-lg border border-slate-200 p-3" key={profile.id} to={`/fortune/daily?profileId=${profile.id}`}>
            <span className="font-semibold">{profile.display_name}</span>
            <span className="text-sm text-slate-500">{profile.birth_date}</span>
          </Link>
        ))}
      </div>
    </Card>
  );
}

function SettingsPage({ selected }: { selected: SajuProfileRow | null }) {
  const query = profileQuery(selected);
  const items = [
    { title: "프로필", to: `/settings/profile?${query}`, icon: <UserRoundIcon className="size-4" /> },
    { title: "알림", to: `/settings/notification?${query}`, icon: <BellIcon className="size-4" /> },
    { title: "구독", to: `/settings/subscription?${query}`, icon: <CreditCardIcon className="size-4" /> },
    { title: "이용약관", to: `/settings/terms?${query}`, icon: <FileTextIcon className="size-4" /> },
    { title: "개인정보", to: `/settings/privacy?${query}`, icon: <ShieldIcon className="size-4" /> },
  ];

  return (
    <Card title="설정" icon={<SettingsIcon className="size-4 text-rose-600" />}>
      <div className="space-y-2">
        {items.map((item) => (
          <Link className="flex items-center justify-between rounded-lg border border-slate-200 p-3" key={item.to} to={item.to}>
            <span className="flex items-center gap-2 font-semibold">{item.icon}{item.title}</span>
            <ChevronRightIcon className="size-4 text-slate-400" />
          </Link>
        ))}
      </div>
    </Card>
  );
}

function NoticePage({ title, body }: { title: string; body: string }) {
  return (
    <Card title={title} icon={<FileTextIcon className="size-4 text-rose-600" />}>
      <p className="text-sm leading-6 text-slate-600">{body}</p>
    </Card>
  );
}

function SubscriptionPage({ data }: { data: LoaderData }) {
  return (
    <Card title="구독 관리" icon={<CreditCardIcon className="size-4 text-rose-600" />}>
      <div className="space-y-3">
        {data.subscriptions.map((subscription) => (
          <div className="rounded-lg border border-slate-200 p-3" key={subscription.id}>
            <div className="flex items-center justify-between">
              <p className="font-bold">{subscription.product_id}</p>
              <Badge className="rounded-md bg-slate-100 text-slate-800">{subscription.status}</Badge>
            </div>
            <p className="mt-1 text-sm text-slate-500">만료: {subscription.expires_at ?? "없음"}</p>
          </div>
        ))}
        {data.subscriptions.length === 0 ? <p className="text-sm text-slate-600">활성 구독 기록이 없습니다.</p> : null}
        <Button asChild className="h-11 w-full rounded-md bg-rose-600 text-white">
          <Link to={`/premium${data.selectedProfileId ? `?profileId=${data.selectedProfileId}` : ""}`}>프리미엄 보기</Link>
        </Button>
      </div>
    </Card>
  );
}

function QuickMenu({ query }: { query: string }) {
  const suffix = query ? `?${query}` : "";
  const items = [
    ["홈", `/menu${suffix}`],
    ["차트", `/saju/chart${suffix}`],
    ["상담", `/saju/chat${suffix}`],
    ["관계", `/relationships${suffix}`],
    ["설정", `/settings${suffix}`],
  ];

  return (
    <Card title="빠른 이동">
      <div className="grid grid-cols-2 gap-2">
        {items.map(([label, to]) => (
          <Button asChild className="h-10 rounded-md bg-slate-100 text-slate-950 hover:bg-slate-200" key={to} variant="secondary">
            <Link to={to}>{label}</Link>
          </Button>
        ))}
      </div>
    </Card>
  );
}

function DataHealth({ data }: { data: LoaderData }) {
  return (
    <Card title="연결 상태">
      <div className="grid gap-2">
        <Metric label="프로필" value={data.profiles.length} />
        <Metric label="관계" value={data.relations.length} />
        <Metric label="궁합" value={data.compatibility.length} />
        <Metric label="AI 기록" value={data.chats.length + data.summaries.length} />
      </div>
    </Card>
  );
}

function JsonPreview({ value }: { value: unknown }) {
  return (
    <pre className="max-h-64 overflow-auto rounded-md bg-slate-950 p-3 text-xs leading-5 text-slate-100">
      {typeof value === "string" ? value : JSON.stringify(value, null, 2)}
    </pre>
  );
}

function stringifyShort(value: unknown) {
  if (typeof value === "string") return value;
  if (!value) return "저장된 요약이 없습니다.";
  return JSON.stringify(value).slice(0, 160);
}
