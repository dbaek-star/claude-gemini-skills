# Claude Code + Gemini Skills 설치 스크립트 (Windows PowerShell)

Write-Host "Claude Code + Gemini Skills 설치를 시작합니다..." -ForegroundColor Cyan

# 스킬 디렉토리 생성
$skillsPath = "$env:USERPROFILE\.claude\skills"

$skills = @("gemini-collab", "gemini-discuss", "gemini-research", "gemini-review")

foreach ($skill in $skills) {
    $targetDir = Join-Path $skillsPath $skill

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Host "  [+] 디렉토리 생성: $skill" -ForegroundColor Green
    }

    $sourceFile = Join-Path $PSScriptRoot "skills\$skill\SKILL.md"
    $targetFile = Join-Path $targetDir "SKILL.md"

    Copy-Item -Path $sourceFile -Destination $targetFile -Force
    Write-Host "  [+] 스킬 설치: $skill" -ForegroundColor Green
}

Write-Host ""
Write-Host "설치 완료!" -ForegroundColor Cyan
Write-Host ""
Write-Host "사용법:" -ForegroundColor Yellow
Write-Host "  Claude Code 세션에서 다음과 같이 요청하세요:"
Write-Host "  - 'Gemini로 조사해줘: [주제]'"
Write-Host "  - 'Gemini와 논의해줘: [주제]'"
Write-Host "  - 'Gemini로 코드 리뷰해줘: [파일]'"
Write-Host "  - 'Gemini와 협업해서 코드 작성해줘: [요청]'"
