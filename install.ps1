# Installs or updates the shared Claude setup on Windows.
# Safe to run again any time: it pulls the latest version and refreshes everything.
# Run with:  powershell -ExecutionPolicy Bypass -File .\install.ps1
$ErrorActionPreference = "Stop"

$RepoDir   = $PSScriptRoot
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$TargetDir = Join-Path $ClaudeDir "claude-setup"
$UserMd    = Join-Path $ClaudeDir "CLAUDE.md"
$ImportLine = "@~/.claude/claude-setup/CLAUDE.md"

Write-Host "==> Updating repo"
if (Get-Command git -ErrorAction SilentlyContinue) {
  git -C $RepoDir pull --ff-only
  if ($LASTEXITCODE -ne 0) { Write-Host "    Couldn't pull; using the local copy." }
}

Write-Host "==> Installing shared CLAUDE.md"
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
Copy-Item (Join-Path $RepoDir "CLAUDE.md") (Join-Path $TargetDir "CLAUDE.md") -Force
if (-not (Test-Path $UserMd)) { New-Item -ItemType File -Path $UserMd | Out-Null }
$existing = Get-Content $UserMd -ErrorAction SilentlyContinue
if (-not ($existing -contains $ImportLine)) {
  Add-Content -Path $UserMd -Value "`n$ImportLine"
  Write-Host "    Linked it from ~\.claude\CLAUDE.md (your own content there is untouched)."
}

Write-Host "==> Installing plugins"
if (Get-Command claude -ErrorAction SilentlyContinue) {
  $ErrorActionPreference = "Continue"
  claude plugin marketplace add dandoonian/claude-setup 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) { claude plugin marketplace update dandoonian }
  claude plugin install claude-setup@dandoonian
  # CLAUDE.md asks for /code-review before every push; this provides it.
  claude plugin install code-review@claude-plugins-official
} else {
  Write-Host "    Claude Code not found. Install it, then run this script again."
}

Write-Host "==> Done. Restart Claude Code to load the changes."
