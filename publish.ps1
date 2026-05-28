# CricketHub - One-Click Publish Script
# Usage: Double-click publish.bat OR right-click this file > Run with PowerShell

param(
    [string]$ZipPath
)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Yellow
Write-Host "  CricketHub - One-Click Article Publisher" -ForegroundColor Yellow
Write-Host "  ===========================================" -ForegroundColor Yellow
Write-Host ""

# ---- Step 0: Get ZIP file ----
if (-not $ZipPath) {
    $downloads = Join-Path $env:USERPROFILE "Downloads"
    $recentZips = Get-ChildItem -Path $downloads -Filter "*.zip" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 5

    if ($recentZips.Count -gt 0) {
        Write-Host "  Recent ZIPs found in Downloads:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $recentZips.Count; $i++) {
            $num = $i + 1
            $zipName = $recentZips[$i].Name
            $sizeKB = [math]::Round($recentZips[$i].Length / 1024, 1)
            $zipTime = $recentZips[$i].LastWriteTime.ToString("MMM dd, hh:mm tt")
            $line = "    [$num] $zipName - ${sizeKB}KB, $zipTime"
            Write-Host $line -ForegroundColor White
        }
        Write-Host ""
        $maxNum = $recentZips.Count
        $choice = Read-Host "  Enter number 1-$maxNum or full path to ZIP"

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
    Write-Host "  ERROR: ZIP file not found: $ZipPath" -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}

$zipLeaf = Split-Path -Leaf $ZipPath
Write-Host "  Using: $zipLeaf" -ForegroundColor Green
Write-Host ""

# ---- Step 1: Extract ZIP to temp ----
$tempDir = Join-Path $env:TEMP "crickethub_publish_$(Get-Random)"
try {
    Expand-Archive -Path $ZipPath -DestinationPath $tempDir -Force
} catch {
    Write-Host "  ERROR: Failed to extract ZIP" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}

# ---- Step 2: Find metadata.json ----
$metadataFile = Get-ChildItem -Path $tempDir -Filter "metadata.json" -Recurse | Select-Object -First 1
if (-not $metadataFile) {
    Write-Host "  ERROR: No metadata.json found in ZIP." -ForegroundColor Red
    Write-Host "  Was this generated from the Admin Panel?" -ForegroundColor Red
    Remove-Item -Path $tempDir -Recurse -Force
    Read-Host "  Press Enter to exit"
    exit 1
}

$metadata = Get-Content $metadataFile.FullName -Raw | ConvertFrom-Json
$slug = $metadata.slug
$title = $metadata.title

Write-Host "  Article: $title" -ForegroundColor Cyan
Write-Host "  Slug: $slug" -ForegroundColor Cyan
Write-Host ""

# ---- Step 3: Find article index.html ----
$articleHtml = Get-ChildItem -Path $tempDir -Filter "index.html" -Recurse | Select-Object -First 1
if (-not $articleHtml) {
    Write-Host "  ERROR: No index.html found in ZIP." -ForegroundColor Red
    Remove-Item -Path $tempDir -Recurse -Force
    Read-Host "  Press Enter to exit"
    exit 1
}

# ---- Step 4: Copy article to correct folder ----
$articleDir = Join-Path $ProjectRoot "articles\$slug"
if (Test-Path $articleDir) {
    Write-Host "  WARNING: Article folder already exists. Overwriting..." -ForegroundColor Yellow
}
New-Item -ItemType Directory -Path $articleDir -Force | Out-Null
Copy-Item -Path $articleHtml.FullName -Destination (Join-Path $articleDir "index.html") -Force
Write-Host "  DONE: Article HTML copied to articles/$slug/index.html" -ForegroundColor Green

# ---- Step 4.5: Extract base64 images to files ----
Write-Host ""
Write-Host "  Extracting embedded images..." -ForegroundColor Cyan
$artHtmlPath = Join-Path $articleDir "index.html"
$artHtml = [System.IO.File]::ReadAllText($artHtmlPath, [System.Text.Encoding]::UTF8)

$imgPattern = 'src="data:image/([^;]+);base64,([^"]+)"'
$imgMatches = [regex]::Matches($artHtml, $imgPattern)
$featuredImgPath = ""
$imgIdx = 0

foreach ($im in $imgMatches) {
    $imgIdx++
    $mimeExt = $im.Groups[1].Value
    $b64 = $im.Groups[2].Value
    $ext = switch ($mimeExt) {
        'jpeg' { 'jpg' }
        'jpg'  { 'jpg' }
        default { $mimeExt }
    }
    $imgBytes = [Convert]::FromBase64String($b64)
    # Detect AVIF even if declared as PNG
    if ($imgBytes.Length -gt 12) {
        $hdr = -join ($imgBytes[4..11] | ForEach-Object { [char]$_ })
        if ($hdr -match 'ftyp') { $ext = 'avif' }
    }
    if ($imgIdx -eq 1) {
        $fn = "featured.$ext"
        $featuredImgPath = "/articles/$slug/$fn"
    } else {
        $num = $imgIdx - 1
        $fn = "img-$num.$ext"
    }
    [System.IO.File]::WriteAllBytes((Join-Path $articleDir $fn), $imgBytes)
    $sizeKB = [math]::Round($imgBytes.Length / 1024, 1)
    Write-Host "  Saved: $fn (${sizeKB} KB)" -ForegroundColor Green
    $artHtml = $artHtml.Replace($im.Value, "src=`"$fn`"")
}

# Fix og:image meta tags (replace base64 with real URL)
$ogPat = 'content="data:image/[^"]+"'
$ogMs = [regex]::Matches($artHtml, $ogPat)
foreach ($og in $ogMs) {
    $artHtml = $artHtml.Replace($og.Value, "content=`"https://crickethub.co.in$featuredImgPath`"")
}

[System.IO.File]::WriteAllText($artHtmlPath, $artHtml, [System.Text.Encoding]::UTF8)
if ($imgIdx -gt 0) {
    Write-Host "  DONE: $imgIdx images extracted, HTML updated with file paths" -ForegroundColor Green
} else {
    Write-Host "  No base64 images found (already using file paths)" -ForegroundColor Yellow
}

# ---- Step 5: Update index.js (add to ARTICLES array) ----
$indexJsPath = Join-Path $ProjectRoot "index.js"
$indexJs = Get-Content $indexJsPath -Raw -Encoding UTF8

$jsEntry = $metadata.jsEntry
# Replace base64 image in jsEntry with file path
if ($featuredImgPath -and $jsEntry -match 'image:\s*"data:image/[^"]+?"') {
    $jsEntry = $jsEntry -replace 'image:\s*"data:image/[^"]+?"', "image: `"$featuredImgPath`""
    Write-Host "  Image path in ARTICLES entry: $featuredImgPath" -ForegroundColor Green
}

# Check if article already exists in index.js
if ($indexJs -match [regex]::Escape($slug)) {
    Write-Host "  WARNING: Article already exists in index.js. Skipping..." -ForegroundColor Yellow
} else {
    # Find the ARTICLES array and insert the new entry
    $pattern = 'const ARTICLES = ['
    $insertPoint = $indexJs.IndexOf($pattern)
    if ($insertPoint -ge 0) {
        $insertPoint = $insertPoint + $pattern.Length
        $newEntry = "`n    $jsEntry,"
        $indexJs = $indexJs.Insert($insertPoint, $newEntry)
        [System.IO.File]::WriteAllText($indexJsPath, $indexJs, [System.Text.Encoding]::UTF8)
        Write-Host "  DONE: Article added to ARTICLES array in index.js" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Could not find ARTICLES array in index.js. Add manually." -ForegroundColor Yellow
    }
}

# ---- Step 6: Update sitemap.xml ----
$sitemapPath = Join-Path $ProjectRoot "sitemap.xml"
$sitemap = Get-Content $sitemapPath -Raw -Encoding UTF8

if ($sitemap -match [regex]::Escape("articles/$slug/")) {
    Write-Host "  WARNING: Article already in sitemap.xml. Skipping..." -ForegroundColor Yellow
} else {
    $sitemapEntry = $metadata.sitemapEntry
    $sitemap = $sitemap -replace '</urlset>', "$sitemapEntry`n</urlset>"
    [System.IO.File]::WriteAllText($sitemapPath, $sitemap, [System.Text.Encoding]::UTF8)
    Write-Host "  DONE: Sitemap entry added to sitemap.xml" -ForegroundColor Green
}

# ---- Step 7: Git commit and push ----
Write-Host ""
Write-Host "  Pushing to GitHub..." -ForegroundColor Cyan

Push-Location $ProjectRoot
try {
    git add . 2>&1 | Out-Null
    git commit -m "Published: $title" 2>&1 | Out-Null
    $pushResult = git push origin main 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  DONE: Successfully pushed to GitHub!" -ForegroundColor Green
    } else {
        Write-Host "  Pull required, syncing..." -ForegroundColor Yellow
        git pull origin main --rebase 2>&1 | Out-Null
        git push origin main 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  DONE: Synced and pushed to GitHub!" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: Push failed. Run manually: git push origin main" -ForegroundColor Red
        }
    }
} finally {
    Pop-Location
}

# ---- Cleanup ----
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Green
Write-Host "  ARTICLE PUBLISHED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "  ===========================================" -ForegroundColor Green
Write-Host ""
$liveUrl = "https://crickethub.co.in/articles/$slug/"
Write-Host "  Live at: $liveUrl" -ForegroundColor Cyan
Write-Host "  Takes 1-2 minutes for GitHub Pages to deploy" -ForegroundColor Yellow
Write-Host ""
Read-Host "  Press Enter to exit"
