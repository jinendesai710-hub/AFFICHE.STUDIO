$ErrorActionPreference = 'Stop'
$folder = 'C:\Users\Jinen\Desktop\Affiche.studios\assets\posters'
$out = 'C:\Users\Jinen\Desktop\Affiche.studios\_encoded.js'
$lines = New-Object System.Collections.Generic.List[string]

# order matters: this is the order we'll need to substitute back into the PRODUCTS array
$files = Get-ChildItem -Path $folder -Filter '*.png' | Sort-Object Name
foreach ($f in $files) {
  $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
  $b64 = [Convert]::ToBase64String($bytes)
  $name = $f.BaseName
  $dataUri = "data:image/png;base64,$b64"
  $lines.Add("__POSTER__$name__$dataUri")
}

[System.IO.File]::WriteAllText($out, ($lines -join "`n"), [System.Text.Encoding]::UTF8)
Write-Host "Wrote $($lines.Count) encoded posters to $out"
Write-Host ("Total bytes: {0:N0}" -f ((Get-Item $out).Length))
