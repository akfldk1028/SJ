import { type ReactNode } from "react";

const elementBackgrounds: Record<string, string> = {
  목: "from-[#0d1b0e] via-[#1b5e20] to-[#0d1b0e]",
  화: "from-[#1a0a0a] via-[#b71c1c] to-[#1a0a0a]",
  토: "from-[#1a1400] via-[#e65100] to-[#1a1400]",
  금: "from-[#0a0a12] via-[#37474f] to-[#0a0a12]",
  수: "from-[#000a12] via-[#0d47a1] to-[#000a12]",
};

const elementAccents: Record<string, string> = {
  목: "border-emerald-300/30 bg-emerald-300/10 shadow-emerald-300/20",
  화: "border-red-300/30 bg-red-300/10 shadow-red-300/20",
  토: "border-amber-300/30 bg-amber-300/10 shadow-amber-300/20",
  금: "border-slate-200/30 bg-slate-200/10 shadow-slate-200/20",
  수: "border-sky-300/30 bg-sky-300/10 shadow-sky-300/20",
};

type ZodiacElementBackgroundProps = {
  elementName: string;
  children: ReactNode;
};

export function ZodiacElementBackground({
  elementName,
  children,
}: ZodiacElementBackgroundProps) {
  const colors = elementBackgrounds[elementName] ?? elementBackgrounds.화;

  return (
    <main className={`min-h-screen bg-gradient-to-br ${colors} text-white`}>
      <div className="min-h-screen bg-[radial-gradient(circle_at_50%_0%,rgba(255,255,255,0.14),transparent_34%),linear-gradient(180deg,rgba(0,0,0,0),rgba(0,0,0,0.2))]">
        {children}
      </div>
    </main>
  );
}

type ZodiacAnimalAvatarProps = {
  emoji: string;
  elementName: string;
  size?: "sm" | "lg";
};

export function ZodiacAnimalAvatar({
  emoji,
  elementName,
  size = "lg",
}: ZodiacAnimalAvatarProps) {
  const accent = elementAccents[elementName] ?? elementAccents.화;
  const sizeClass = size === "lg" ? "size-36 text-7xl" : "size-10 text-2xl";

  return (
    <div
      className={`${sizeClass} flex shrink-0 items-center justify-center rounded-full border shadow-2xl ${accent}`}
    >
      <span>{emoji}</span>
    </div>
  );
}

type ZodiacChatBubbleProps = {
  emoji: string;
  elementName: string;
  children: ReactNode;
  align?: "ai" | "user";
};

export function ZodiacChatBubble({
  emoji,
  elementName,
  children,
  align = "ai",
}: ZodiacChatBubbleProps) {
  const accent = elementAccents[elementName] ?? elementAccents.화;
  const isAi = align === "ai";

  return (
    <div className={`flex gap-2 ${isAi ? "justify-start" : "justify-end"}`}>
      {isAi ? (
        <ZodiacAnimalAvatar emoji={emoji} elementName={elementName} size="sm" />
      ) : null}
      <div
        className={`max-w-[82%] rounded-2xl border px-4 py-3 text-sm leading-6 text-white/90 shadow-lg ${
          isAi ? "rounded-bl" : "rounded-br"
        } ${accent}`}
      >
        {children}
      </div>
    </div>
  );
}

type ZodiacRevealCardProps = {
  emoji: string;
  elementName: string;
  fullName: string;
  ganjiHanja: string;
  subtitle: string;
};

export function ZodiacRevealCard({
  emoji,
  elementName,
  fullName,
  ganjiHanja,
  subtitle,
}: ZodiacRevealCardProps) {
  return (
    <section className="flex flex-col items-center px-5 py-8 text-center">
      <ZodiacAnimalAvatar emoji={emoji} elementName={elementName} />
      <h2 className="mt-6 text-4xl font-bold text-white">{fullName}</h2>
      <p className="mt-2 text-lg tracking-[0.35em] text-white/55">
        {ganjiHanja}
      </p>
      <p className="mt-4 max-w-xs text-sm leading-6 text-white/75">
        {subtitle}
      </p>
    </section>
  );
}
