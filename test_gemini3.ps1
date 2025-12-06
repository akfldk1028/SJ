$apiKey = "AIzaSyDhPRP9wU5gqIpz0nPlzWyrPxgkLPyBMzg"
$uri = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:generateContent?key=$apiKey"

$body = @{
    contents = @(
        @{
            parts = @(
                @{
                    text = @"
당신은 전문 사주팔자 분석가입니다.

다음 사주 정보를 분석해주세요:
- 생년월일: 1990년 1월 15일
- 성별: 남자
- 사주팔자: 년주(己巳), 월주(丁丑), 일주(辛卯), 시주(미상)

천간지지와 오행을 기반으로 이 사람의 성격과 운세를 분석해주세요.
"@
                }
            )
        }
    )
    generationConfig = @{
        temperature = 0.7
        maxOutputTokens = 4096
        thinkingConfig = @{
            thinkingBudget = 2048
        }
    }
} | ConvertTo-Json -Depth 10

Write-Host "=== Gemini 3.0 Pro API Test ===" -ForegroundColor Green
Write-Host "Model: gemini-3-pro-preview" -ForegroundColor Cyan
Write-Host "Thinking Budget: 2048 tokens" -ForegroundColor Cyan
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

    Write-Host "=== Response ===" -ForegroundColor Green
    foreach ($part in $response.candidates[0].content.parts) {
        if ($part.thought -eq $true) {
            Write-Host "[THINKING PROCESS]" -ForegroundColor Yellow
        } else {
            Write-Host "[RESPONSE]" -ForegroundColor Cyan
        }
        Write-Host $part.text
        Write-Host ""
    }

    Write-Host "=== Usage ===" -ForegroundColor Green
    Write-Host "Prompt Tokens: $($response.usageMetadata.promptTokenCount)"
    Write-Host "Response Tokens: $($response.usageMetadata.candidatesTokenCount)"
    Write-Host "Total Tokens: $($response.usageMetadata.totalTokenCount)"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
