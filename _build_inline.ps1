$ErrorActionPreference = 'Stop'

$root      = 'C:\Users\Jinen\Desktop\Affiche.studios'
$htmlPath  = Join-Path $root 'index.html'
$logoPath  = Join-Path $root 'logo.png'
$postersDir = Join-Path $root 'assets\posters'

# 1. Encode the logo as a data URI
$logoBytes = [System.IO.File]::ReadAllBytes($logoPath)
$logoB64   = [Convert]::ToBase64String($logoBytes)
$logoUri   = "data:image/png;base64,$logoB64"
Write-Host ("Logo encoded: {0:N0} bytes" -f $logoBytes.Length)

# 2. Build a poster-name -> data URI map by encoding all .png files in assets/posters
$posterMap = @{}
foreach ($f in Get-ChildItem -Path $postersDir -Filter '*.png') {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $b64   = [Convert]::ToBase64String($bytes)
    $posterMap[$f.BaseName] = "data:image/png;base64,$b64"
}
Write-Host ("Posters encoded: {0}" -f $posterMap.Count)

# 3. Read the current HTML
$html = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$origLen = $html.Length
Write-Host ("Original HTML: {0:N0} chars ({1:N2} MB)" -f $origLen, ($origLen / 1MB))

# 4. Replace the logo reference
$logoOld = 'src="logo.png"'
if ($html.Contains($logoOld)) {
    $html = $html.Replace($logoOld, "src=`"$logoUri`"")
    Write-Host "Logo replaced."
} else {
    Write-Host "WARNING: logo.png reference not found in HTML."
}

# 5. Replace every poster reference. The HTML uses single-quoted strings like
#    image: 'assets/posters/<filename>.png'
$replaced = 0
$missing  = @()
foreach ($key in $posterMap.Keys) {
    $old = "image: 'assets/posters/$key.png'"
    if ($html.Contains($old)) {
        $new = "image: '$($posterMap[$key])'"
        $html = $html.Replace($old, $new)
        $replaced++
    } else {
        $missing += $key
    }
}
Write-Host ("Replaced {0} of {1} poster references." -f $replaced, $posterMap.Count)
if ($missing.Count -gt 0) {
    Write-Host ("WARNING - no matching reference in HTML: {0}" -f ($missing -join ', '))
}

# 6. Final sanity checks: there should be no remaining references to logo.png
#    or to assets/posters/*.png.
$leftoverLogo = ([regex]::Matches($html, 'src="logo\.png"')).Count
$leftoverPost = ([regex]::Matches($html, "assets/posters/[a-zA-Z0-9\-]+\.png")).Count
Write-Host ("Leftover logo refs: {0}, leftover poster refs: {1}" -f $leftoverLogo, $leftoverPost)

# 7. Write back as UTF-8 (no BOM) so GitHub Pages serves it cleanly.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($htmlPath, $html, $utf8NoBom)
$newLen = (Get-Item $htmlPath).Length
Write-Host ("Final HTML: {0:N0} chars ({1:N2} MB)" -f $newLen, ($newLen / 1MB))
Write-Host "Done. Drop index.html into your GitHub repo and it will render standalone."
