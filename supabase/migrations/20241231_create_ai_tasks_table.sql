-- AI Background Tasks 테이블
-- GPT-5.2-thinking 등 장시간 실행 모델의 결과 저장용
-- v14: EdgeRuntime.waitUntil() Background Task 패턴 지원

CREATE TABLE IF NOT EXISTS public.ai_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  task_type TEXT NOT NULL DEFAULT 'saju_analysis',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  request_data JSONB NOT NULL,
  result_data JSONB,
  error_message TEXT,
  model TEXT DEFAULT 'gpt-5.2-thinking',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 hour'
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_ai_tasks_user_id ON public.ai_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_tasks_status ON public.ai_tasks(status);
CREATE INDEX IF NOT EXISTS idx_ai_tasks_created_at ON public.ai_tasks(created_at DESC);

-- RLS 정책
ALTER TABLE public.ai_tasks ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 task만 조회 가능
DROP POLICY IF EXISTS "Users can view own tasks" ON public.ai_tasks;
CREATE POLICY "Users can view own tasks" ON public.ai_tasks
  FOR SELECT USING (auth.uid() = user_id);

-- Service Role만 insert/update 가능 (Edge Function에서 사용)
DROP POLICY IF EXISTS "Service role can manage tasks" ON public.ai_tasks;
CREATE POLICY "Service role can manage tasks" ON public.ai_tasks
  FOR ALL USING (auth.role() = 'service_role');

-- 테이블 설명
COMMENT ON TABLE public.ai_tasks IS 'AI Background Tasks for long-running models like GPT-5.2-thinking. Tasks expire after 1 hour.';
COMMENT ON COLUMN public.ai_tasks.status IS 'pending: 대기중, processing: 처리중, completed: 완료, failed: 실패';
COMMENT ON COLUMN public.ai_tasks.result_data IS 'AI 응답 결과 (성공 시 content, usage 포함)';
