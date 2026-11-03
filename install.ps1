# Installs or updates the shared Claude setup on Windows.
# Safe to run again any time: it pulls the latest version and refreshes everything.
#
# Usage:  powershell -ExecutionPolicy Bypass -File .\install.ps1                  ask if you already have a CLAUDE.md
#         powershell -ExecutionPolicy Bypass -File .\install.ps1 -Mode merge      keep yours, add the shared notes
#         powershell -ExecutionPolicy Bypass -File .\install.ps1 -Mode replace    back up yours, use only the shared notes
#         powershell -ExecutionPolicy Bypass -File .\install.ps1 -Mode abort      stop if you already have one
param(
  [ValidateSet("merge", "replace", "abort")]
  [string]$Mode = ""
)
$ErrorActionPreference = "Stop"

$RepoDir    = $PSScriptRoot
$ClaudeDir  = Join-Path $env:USERPROFILE ".claude"
$TargetDir  = Join-Path $ClaudeDir "claude-setup"
$UserMd     = Join-Path $ClaudeDir "CLAUDE.md"
$SharedMd   = Join-Path $RepoDir "CLAUDE.md"
$ImportLine = "@~/.claude/claude-setup/CLAUDE.md"

Write-Host "==> Updating repo"
if (Get-Command git -ErrorAction SilentlyContinue) {
  git -C $RepoDir pull --ff-only
  if ($LASTEXITCODE -ne 0) { Write-Host "    Couldn't pull; using the local copy." }
}

# ---------- CLAUDE.md ----------
Write-Host "==> Shared CLAUDE.md"
New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

$userLines = @()
if (Test-Path $UserMd) { $userLines = @(Get-Content $UserMd) }
$hasContent = ($userLines | Where-Object { $_.Trim() -ne "" }).Count -gt 0

if ($hasContent -and ($userLines -contains $ImportLine)) {
  $Action = "refresh"
} elseif (-not $hasContent) {
  $Action = "merge"
} else {
  $sharedLines = @(Get-Content $SharedMd | Where-Object { $_.Trim() -ne "" })
  $overlap = @($sharedLines | Where-Object { $userLines -contains $_ }).Count
  git --no-pager diff --no-index --quiet -w -- $UserMd $SharedMd 2>$null | Out-Null
  $identical = ($LASTEXITCODE -eq 0)
  Write-Host "    You already have ~\.claude\CLAUDE.md ($($userLines.Count) lines)."
  if ($identical) {
    Write-Host "    It's identical to the shared notes, so Replace is the clean choice."
  } elseif ($overlap -gt 0) {
    Write-Host "    Note: $overlap line(s) of the shared notes are already in it. After merging,"
    Write-Host "    remove those from your own file so they don't appear twice."
  }

  $Action = $Mode
  if (-not $Action) {
    $interactive = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
    if ($interactive) {
      while (-not $Action) {
        Write-Host ""
        Write-Host "    What do you want to do?"
        if ($identical) {
          Write-Host "      [m] Merge:   keep your file and add the shared notes"
          Write-Host "      [r] Replace: back up your file and use only the shared notes (recommended)"
        } else {
          Write-Host "      [m] Merge:   keep your file and add the shared notes (recommended)"
          Write-Host "      [r] Replace: back up your file and use only the shared notes"
        }
        Write-Host "      [d] Diff:    show your file vs. the shared notes"
        Write-Host "      [a] Abort:   change nothing"
        $choice = Read-Host "    Choice [m/r/d/a]"
        switch ($choice.ToLower()) {
          ""  { if ($identical) { $Action = "replace" } else { $Action = "merge" } }
          "m" { $Action = "merge" }
          "r" { $Action = "replace" }
          "a" { $Action = "abort" }
          "d" {
            Write-Host ""
            if ($identical) {
              Write-Host "    No differences: your file is the same as the shared notes."
            } else {
              Write-Host "    --- your ~\.claude\CLAUDE.md   +++ shared notes"
              git --no-pager diff --no-index -- $UserMd $SharedMd
            }
          }
          default { Write-Host "    Please type m, r, d or a." }
        }
      }
    } else {
      $Action = "merge"
    }
  }
}

switch ($Action) {
  "abort" {
    Write-Host "    Aborted. Nothing was changed."
    exit 0
  }
  "replace" {
    $backup = "$UserMd.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $UserMd $backup
    Set-Content -Path $UserMd -Value $ImportLine
    Write-Host "    Replaced. Your old file is saved as $backup"
  }
  "merge" {
    Add-Content -Path $UserMd -Value "`n$ImportLine"
    Write-Host "    Merged. Your own content is untouched; the shared notes load alongside it."
  }
  "refresh" {
    Write-Host "    Already linked; refreshing the shared notes."
  }
}

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
Copy-Item $SharedMd (Join-Path $TargetDir "CLAUDE.md") -Force

# ---------- Plugins ----------
Write-Host "==> Installing plugins"
if (Get-Command claude -ErrorAction SilentlyContinue) {
  $ErrorActionPreference = "Continue"
  claude plugin marketplace add dandoonian/claude-setup 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) { claude plugin marketplace update dandoonian }
  claude plugin install claude-setup@dandoonian
  # CLAUDE.md asks for /code-review before every push; this provides it.
  claude plugin marketplace add anthropics/claude-plugins-official 2>$null | Out-Null
  claude plugin install code-review@claude-plugins-official
} else {
  Write-Host "    Claude Code not found. Install it, then run this script again."
}

Write-Host "==> Done. Restart Claude Code to load the changes."
