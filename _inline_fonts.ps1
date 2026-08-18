$ErrorActionPreference = 'Stop'
$root    = 'C:\Users\Jinen\Desktop\Affiche.studios'
$cssIn   = Join-Path $root '_fonts.css'
$cssOut  = Join-Path $root '_fonts_inline.css'

$css = [System.IO.File]::ReadAllText($cssIn, [System.Text.Encoding]::UTF8)

# Capture every fonts.gstatic.com URL from the CSS
$urls = [regex]::Matches($css, 'https://fonts\.gstatic\.com/[^)]+')
Write-Host "Found $($urls.Count) font URLs."

$cacheDir = Join-Path $root '_fonts_cache'
if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir | Out-Null }

# Track which URLs we already downloaded
$seen = @{}

foreach ($m in $urls) {
    $url = $m.Value
    if ($seen.ContainsKey($url)) { continue }
    $name = Split-Path $url -Leaf
    $cachePath = Join-Path $cacheDir $name

    if (-not (Test-Path $cachePath)) {
        Write-Host "Downloading $name ..."
        Invoke-WebRequest -Uri $url -OutFile $cachePath -UseBasicParsing
    } else {
        Write-Host "Cached     $name"
    }
    $bytes = [System.IO.File]::ReadAllBytes($cachePath)
    $b64   = [Convert]::ToBase64String($bytes)
    $dataUri = "data:font/ttf;base64,$b64"
    # Replace ALL occurrences of this URL with the data URI
    $css = $css.Replace($url, $dataUri)
    $seen[$url] = $true
}

# Patch format('truetype') -> format('truetype') is still fine; nothing to change.
[System.IO.File]::WriteAllText($cssOut, $css, (New-Object System.Text.UTF8Encoding($false)))
$len = (Get-Item $cssOut).Length
Write-Host ("Wrote {0:N0} bytes to {1}" -f $len, $cssOut)
