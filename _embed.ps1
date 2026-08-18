$ErrorActionPreference = 'Stop'

$encPath = 'C:\Users\Jinen\Desktop\Affiche.studios\_encoded.js'
$htmlPath = 'C:\Users\Jinen\Desktop\Affiche.studios\index.html'
$logoPath = 'C:\Users\Jinen\Desktop\Affiche.studios\logo.png'

# 1. Build lookup: name -> data URI from the encoded file
$map = @{}
foreach ($line in Get-Content $encPath) {
  if ($line -match '^__POSTER__(.+)__(data:image/png;base64,.+)$') {
    $map[$Matches[1]] = $Matches[2]
  }
}
Write-Host "Loaded $($map.Count) encoded images."

# 2. Encode logo
$logoBytes = [System.IO.File]::ReadAllBytes($logoPath)
$logoB64 = [Convert]::ToBase64String($logoBytes)
$logoDataUri = "data:image/png;base64,$logoB64"
Write-Host ("Logo encoded: {0:N0} bytes" -f $logoBytes.Length)

# 3. Read HTML
$html = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$origLen = $html.Length
Write-Host ("Original HTML: {0:N0} chars" -f $origLen)

# 4. Replace logo
$html = $html.Replace('src="logo.png"', "src=`"$logoDataUri`"")
Write-Host "Logo replaced."

# 5. Replace each poster path. The path is single-quoted in the source.
$replaced = 0
$missing = @()
foreach ($key in $map.Keys) {
  $old = "image: 'assets/posters/$key.png'"
  if ($html.Contains($old)) {
    # Build the new line preserving the same indentation: split on the value, replace value
    $new = "image: '$($map[$key])'"
    $html = $html.Replace($old, $new)
    $replaced++
  } else {
    $missing += $key
  }
}
Write-Host "Replaced $replaced of $($map.Count) poster references."
if ($missing.Count -gt 0) {
  Write-Host "MISSING (no match in HTML): $($missing -join ', ')"
}

# 6. Write back
[System.IO.File]::WriteAllText($htmlPath, $html, (New-Object System.Text.UTF8Encoding $false))
$newLen = (Get-Item $htmlPath).Length
Write-Host ("New HTML: {0:N0} chars ({1:N1} MB)" -f $newLen, ($newLen / 1MB))
