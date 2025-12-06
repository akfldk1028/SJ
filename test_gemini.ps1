$apiKey = "AIzaSyDhPRP9wU5gqIpz0nPlzWyrPxgkLPyBMzg"
$uri = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey"

$body = @{
    contents = @(
        @{
            parts = @(
                @{
                    text = "1990년 1월 15일생 남자의 사주를 간단히 분석해주세요. 천간지지와 오행을 포함해서 설명해주세요."
                }
            )
        }
    )
    generationConfig = @{
        thinkingConfig = @{
            thinkingBudget = 2048
        }
    }
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

Write-Host "=== Gemini API Response ===" -ForegroundColor Green
foreach ($part in $response.candidates[0].content.parts) {
    if ($part.thought) {
        Write-Host "[THINKING]" -ForegroundColor Yellow
    }
    Write-Host $part.text
    Write-Host ""
}
