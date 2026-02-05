# Claude Code + Gemini Skills Installation Script (Windows PowerShell)

Write-Host "Installing Claude Code + Gemini Skills..." -ForegroundColor Cyan

# Create skills directory
$skillsPath = "$env:USERPROFILE\.claude\skills"

$skills = @("gemini-collab", "gemini-discuss", "gemini-research", "gemini-review")

foreach ($skill in $skills) {
    $targetDir = Join-Path $skillsPath $skill

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Host "  [+] Created directory: $skill" -ForegroundColor Green
    }

    $sourceFile = Join-Path $PSScriptRoot "skills\$skill\SKILL.md"
    $targetFile = Join-Path $targetDir "SKILL.md"

    Copy-Item -Path $sourceFile -Destination $targetFile -Force
    Write-Host "  [+] Installed skill: $skill" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  In a Claude Code session, use natural language requests like:"
Write-Host "  - 'Research with Gemini: [topic]'"
Write-Host "  - 'Discuss with Gemini: [topic]'"
Write-Host "  - 'Review code with Gemini: [file]'"
Write-Host "  - 'Collaborate with Gemini to write: [request]'"
