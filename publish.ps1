# CricketHub — One-Click Publish Script
# Usage: Right-click → Run with PowerShell
# Or: powershell -ExecutionPolicy Bypass -File publish.ps1

param(
    [string]$ZipPath
)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Yellow
Write-Host "  🏏 CricketHub — One-Click Article Publisher" -ForegroundColor Yellow
Write-Host "  ===========================================" -ForegroundColor Yellow
Write-Host ""

# ---- Step 0: Get ZIP file ----
if (-not $ZipPath) {
    # Check Downloads folder for most recent ZIP
    $downloads = "$env:USERPROFILE\Downloads"
    $recentZips = Get-ChildItem -Path $downloads -Filter "*.zip" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 5

    if ($recentZips.Count -gt 0) {
        Write-Host "  Recent ZIPs found in Downloads:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $recentZips.Count; $i++) {
            $size = [math]::Round($recentZips[$i].Length / 1KB, 1)
            $time = $recentZips[$i].LastWriteTime.ToString("MMM dd, hh:mm tt")
            Write-Host "    [$($i+1)] $($recentZips[$i].Name) ($size KB, $time)" -ForegroundColor White
        }
        Write-Host ""
        $choice = Read-Host "  Enter number (1-$($recentZips.Count)) or full path to ZIP"

        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $recentZips.Count) {
            $ZipPath = $recentZips[[int]$choice - 1].FullName
        } else {
            $ZipPath = $choice.Trim('"', "'", ' ')
        }
    } else {
        $ZipPath = Read-Host "  Enter path to article ZIP file"
        $ZipPath = $ZipPath.Trim('"', "'", ' ')
    }
}

if (-not (Test-Path $ZipPath)) {
    Write-Host "  ❌ ZIP file not found: $ZipPath" -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}

Write-Host "  📦 Using: $(Split-Path -Leaf $ZipPath)" -ForegroundColor Green
Write-Host ""

# ---- Step 1: Extract ZIP to temp ----
$tempDir = Join-Path $env:TEMP "crickethub_publish_$(Get-Random)"
try {
    Expand-Archive -Path $ZipPath -DestinationPath $tempDir -Force
} catch {
    Write-Host "  ❌ Failed to extract ZIP: $_" -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}

# ---- Step 2: Find metadata.json ----
$metadataFile = Get-ChildItem -Path $tempDir -Filter "metadata.json" -Recurse | Select-Object -First 1
if (-not $metadataFile) {
    Write-Host "  ❌ No metadata.json found in ZIP. Was this generated from the Admin Panel?" -ForegroundColor Red
    Remove-Item -Path $tempDir -Recurse -Force
    Read-Host "  Press Enter to exit"
    exit 1
}

$metadata = Get-Content $metadataFile.FullName -Raw | ConvertFrom-Json
$slug = $metadata.slug
$title = $metadata.title

Write-Host "  📝 Article: $title" -ForegroundColor Cyan
Write-Host "  🔗 Slug: $slug" -ForegroundColor Cyan
Write-Host ""

# ---- Step 3: Find article index.html ----
$articleHtml = Get-ChildItem -Path $tempDir -Filter "index.html" -Recurse | Select-Object -First 1
if (-not $articleHtml) {
    Write-Host "  ❌ No index.html found in ZIP." -ForegroundColor Red
    Remove-Item -Path $tempDir -Recurse -Force
    Read-Host "  Press Enter to exit"
    exit 1
}

# ---- Step 4: Copy article to correct folder ----
$articleDir = Join-Path $ProjectRoot "articles\$slug"
if (Test-Path $articleDir) {
    Write-Host "  ⚠️  Article folder already exists. Overwriting..." -ForegroundColor Yellow
}
New-Item -ItemType Directory -Path $articleDir -Force | Out-Null
Copy-Item -Path $articleHtml.FullName -Destination (Join-Path $articleDir "index.html") -Force
Write-Host "  ✅ Article HTML copied to articles/$slug/index.html" -ForegroundColor Green

# ---- Step 5: Update index.js (add to ARTICLES array) ----
$indexJsPath = Join-Path $ProjectRoot "index.js"
$indexJs = Get-Content $indexJsPath -Raw -Encoding UTF8

$jsEntry = $metadata.jsEntry

# Check if article already exists in index.js
if ($indexJs -match [regex]::Escape($slug)) {
    Write-Host "  ⚠️  Article already exists in index.js. Skipping..." -ForegroundColor Yellow
} else {
    # Find the ARTICLES array and insert the new entry
    # We look for "const ARTICLES = [" and insert after it
    $pattern = 'const ARTICLES = \['
    if ($indexJs -match $pattern) {
        $insertPoint = $indexJs.IndexOf('const ARTICLES = [') + 'const ARTICLES = ['.Length
        $newEntry = "`n    $jsEntry,"
        $indexJs = $indexJs.Insert($insertPoint, $newEntry)
        [System.IO.File]::WriteAllText($indexJsPath, $indexJs, [System.Text.Encoding]::UTF8)
        Write-Host "  ✅ Article added to ARTICLES array in index.js" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Could not find ARTICLES array in index.js. Add manually." -ForegroundColor Yellow
    }
}

# ---- Step 6: Update sitemap.xml ----
$sitemapPath = Join-Path $ProjectRoot "sitemap.xml"
$sitemap = Get-Content $sitemapPath -Raw -Encoding UTF8

if ($sitemap -match [regex]::Escape("articles/$slug/")) {
    Write-Host "  ⚠️  Article already in sitemap.xml. Skipping..." -ForegroundColor Yellow
} else {
    $sitemapEntry = $metadata.sitemapEntry
    # Insert before </urlset>
    $sitemap = $sitemap -replace '</urlset>', "$sitemapEntry`n</urlset>"
    [System.IO.File]::WriteAllText($sitemapPath, $sitemap, [System.Text.Encoding]::UTF8)
    Write-Host "  ✅ Sitemap entry added to sitemap.xml" -ForegroundColor Green
}

# ---- Step 7: Git commit and push ----
Write-Host ""
Write-Host "  📤 Pushing to GitHub..." -ForegroundColor Cyan

Push-Location $ProjectRoot
try {
    git add . 2>&1 | Out-Null
    git commit -m "Published: $title" 2>&1 | Out-Null
    $pushResult = git push origin main 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Successfully pushed to GitHub!" -ForegroundColor Green
    } else {
        # Try pull and push again
        Write-Host "  ⚠️  Pull required, syncing..." -ForegroundColor Yellow
        git pull origin main --rebase 2>&1 | Out-Null
        git push origin main 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Synced and pushed to GitHub!" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Push failed. Run manually: git push origin main" -ForegroundColor Red
        }
    }
} finally {
    Pop-Location
}

# ---- Cleanup ----
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Green
Write-Host "  🎉 ARTICLE PUBLISHED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "  ===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  🌐 Live at: https://crickethub.co.in/articles/$slug/" -ForegroundColor Cyan
Write-Host "  ⏱️  Takes 1-2 minutes for GitHub Pages to deploy" -ForegroundColor Yellow
Write-Host ""
Read-Host "  Press Enter to exit"
