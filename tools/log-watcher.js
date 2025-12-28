/**
 * Supabase AI 로그 감시 스크립트
 *
 * Supabase ai_api_logs 테이블을 폴링하여 새 로그를 txt 파일로 저장합니다.
 *
 * 사용법:
 *   npm install
 *   npm run watch
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// ==================== 설정 ====================
const POLL_INTERVAL = 5000; // 5초마다 폴링
const LOG_DIR = path.join(__dirname, '..', 'frontend', 'assets', 'log');
const STATE_FILE = path.join(__dirname, '.last-log-time');

// Supabase 설정
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('❌ SUPABASE_URL 또는 SUPABASE_ANON_KEY가 설정되지 않았습니다.');
  console.error('   .env 파일을 확인하세요.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ==================== 유틸리티 ====================

function getToday() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function getTimestamp(date) {
  const d = new Date(date);
  const hours = String(d.getHours()).padStart(2, '0');
  const minutes = String(d.getMinutes()).padStart(2, '0');
  const seconds = String(d.getSeconds()).padStart(2, '0');
  return `${hours}:${minutes}:${seconds}`;
}

function getLastLogTime() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return fs.readFileSync(STATE_FILE, 'utf8').trim();
    }
  } catch (e) {
    // 무시
  }
  return null;
}

function saveLastLogTime(timestamp) {
  fs.writeFileSync(STATE_FILE, timestamp);
}

function formatLogEntry(log) {
  const timestamp = getTimestamp(log.created_at);
  const status = log.success ? '✅' : '❌';
  const provider = log.provider || 'unknown';
  const logType = log.log_type || 'unknown';
  const model = log.model || 'N/A';

  let entry = `
╔──────────────────────────────────────────────────────────────────────╗
║ [${timestamp}] ${status} ${provider} - ${logType}${log.success ? '' : ' (실패)'}
╠──────────────────────────────────────────────────────────────────────╣
║ 모델: ${model}
║ 토큰: ${log.success ? `prompt=${log.prompt_tokens || 0}, completion=${log.completion_tokens || 0}` : 'N/A'}
║ 비용: ${log.success ? `$${(log.total_cost_usd || 0).toFixed(6)}` : 'N/A'}`;

  if (log.request_preview) {
    entry += `
║ 요청: ${log.request_preview.substring(0, 100)}${log.request_preview.length > 100 ? '...' : ''}`;
  }

  if (log.success && log.response_preview) {
    let responseStr = log.response_preview;
    try {
      const parsed = JSON.parse(log.response_preview);
      responseStr = JSON.stringify(parsed, null, 2);
    } catch (e) {
      // 파싱 실패 시 원본 사용
    }
    entry += `
╠──────────────────────────────────────────────────────────────────────╣
║ 응답:
║   ${responseStr.split('\n').join('\n║   ')}`;
  }

  if (!log.success && log.error_message) {
    entry += `
╠──────────────────────────────────────────────────────────────────────╣
║ 오류: ${log.error_message}`;
  }

  entry += `
╚──────────────────────────────────────────────────────────────────────╝
`;
  return entry;
}

function ensureLogDir() {
  if (!fs.existsSync(LOG_DIR)) {
    fs.mkdirSync(LOG_DIR, { recursive: true });
    console.log(`📁 로그 폴더 생성: ${LOG_DIR}`);
  }
}

function appendToLogFile(content) {
  const today = getToday();
  const logFile = path.join(LOG_DIR, `${today}.txt`);

  // 파일이 없으면 헤더 추가
  if (!fs.existsSync(logFile)) {
    const header = `════════════════════════════════════════════════════════════════════════════════
AI API 로그 - ${today}
════════════════════════════════════════════════════════════════════════════════
`;
    fs.writeFileSync(logFile, header);
    console.log(`📄 새 로그 파일 생성: ${logFile}`);
  }

  fs.appendFileSync(logFile, content);
}

function updateSummary(logs) {
  const today = getToday();
  const logFile = path.join(LOG_DIR, `${today}.txt`);

  if (!fs.existsSync(logFile)) return;

  // 기존 내용 읽기
  let content = fs.readFileSync(logFile, 'utf8');

  // 기존 요약 제거 (있으면)
  const summaryStart = content.lastIndexOf('\n════════════════════════════════════════════════════════════════════════════════\n총');
  if (summaryStart > 0) {
    content = content.substring(0, summaryStart);
  }

  // 새 요약 계산
  const successCount = logs.filter(l => l.success).length;
  const failCount = logs.filter(l => !l.success).length;
  const totalCost = logs.reduce((sum, l) => sum + parseFloat(l.total_cost_usd || 0), 0);

  const summary = `
════════════════════════════════════════════════════════════════════════════════
총 ${logs.length}개 API 호출 | 성공: ${successCount} | 실패: ${failCount} | 총 비용: $${totalCost.toFixed(6)}
════════════════════════════════════════════════════════════════════════════════
`;

  fs.writeFileSync(logFile, content + summary);
}

// ==================== 메인 로직 ====================

let allTodayLogs = [];
let processedIds = new Set();

async function fetchNewLogs() {
  const today = getToday();
  const lastTime = getLastLogTime();

  try {
    let query = supabase
      .from('ai_api_logs')
      .select('*')
      .gte('created_at', `${today}T00:00:00`)
      .order('created_at', { ascending: true });

    if (lastTime) {
      query = query.gt('created_at', lastTime);
    }

    const { data: logs, error } = await query;

    if (error) {
      console.error('❌ Supabase 조회 오류:', error.message);
      return [];
    }

    // 중복 제거
    const newLogs = (logs || []).filter(log => !processedIds.has(log.id));
    return newLogs;
  } catch (e) {
    console.error('❌ 네트워크 오류:', e.message);
    return [];
  }
}

async function poll() {
  const newLogs = await fetchNewLogs();

  if (newLogs.length > 0) {
    console.log(`\n📥 새 로그 ${newLogs.length}개 감지!`);

    for (const log of newLogs) {
      const entry = formatLogEntry(log);
      appendToLogFile(entry);
      allTodayLogs.push(log);
      processedIds.add(log.id);
      saveLastLogTime(log.created_at);

      const status = log.success ? '✅' : '❌';
      console.log(`   ${status} [${getTimestamp(log.created_at)}] ${log.provider}/${log.log_type}`);
    }

    // 요약 업데이트
    updateSummary(allTodayLogs);
    console.log(`📊 총 ${allTodayLogs.length}개 로그 (오늘)`);
  }
}

async function loadExistingLogs() {
  const today = getToday();

  const { data: logs, error } = await supabase
    .from('ai_api_logs')
    .select('*')
    .gte('created_at', `${today}T00:00:00`)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('❌ 기존 로그 로드 실패:', error.message);
    return;
  }

  if (logs && logs.length > 0) {
    allTodayLogs = logs;
    for (const log of logs) {
      processedIds.add(log.id);
    }
    const lastLog = logs[logs.length - 1];
    saveLastLogTime(lastLog.created_at);
    console.log(`📚 기존 로그 ${logs.length}개 로드됨`);
  }
}

async function main() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║       🔍 Supabase AI 로그 감시 스크립트 시작              ║');
  console.log('╠════════════════════════════════════════════════════════════╣');
  console.log(`║ 폴링 간격: ${POLL_INTERVAL / 1000}초`);
  console.log(`║ 로그 폴더: ${LOG_DIR}`);
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');

  ensureLogDir();
  await loadExistingLogs();

  console.log('\n⏳ 새 로그 감시 중... (Ctrl+C로 종료)\n');

  // 첫 폴링
  await poll();

  // 주기적 폴링
  setInterval(poll, POLL_INTERVAL);
}

main().catch(console.error);
