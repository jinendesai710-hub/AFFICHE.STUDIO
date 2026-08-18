$ErrorActionPreference = 'Stop'
$root = 'C:\Users\Jinen\Desktop\Affiche.studios'
$html = [System.IO.File]::ReadAllText((Join-Path $root 'index.html'), [System.Text.Encoding]::UTF8)

# Tailwind classes appear inside class="..." and :class="..." attributes.
# We pull every quoted class string, split on whitespace, and collect uniques.
# Also extract @apply-style directives? Not present in this HTML.

$tokens = New-Object System.Collections.Generic.HashSet[string]
$rx = [regex]'class\s*=\s*"([^"]+)"'
foreach ($m in $rx.Matches($html)) {
    foreach ($t in ($m.Groups[1].Value -split '\s+')) {
        if ($t -and -not $tokens.Contains($t)) { [void]$tokens.Add($t) }
    }
}
$rx2 = [regex]"class\s*=\s*'([^']+)'"
foreach ($m in $rx2.Matches($html)) {
    foreach ($t in ($m.Groups[1].Value -split '\s+')) {
        if ($t -and -not $tokens.Contains($t)) { [void]$tokens.Add($t) }
    }
}
# :class="..." expressions are JavaScript strings concatenated with logic.
# A naive split on whitespace inside :class="..." is fine for our needs —
# dynamic tokens like `!${cond} ? 'a' : 'b'` are ignored (we capture both 'a' and 'b').
$rx3 = [regex]':class\s*=\s*"([^"]+)"'
foreach ($m in $rx3.Matches($html)) {
    foreach ($t in ($m.Groups[1].Value -split '\s+')) {
        if ($t -and -not $tokens.Contains($t)) { [void]$tokens.Add($t) }
    }
}
$rx4 = [regex]":class\s*=\s*'([^']+)'"
foreach ($m in $rx4.Matches($html)) {
    foreach ($t in ($m.Groups[1].Value -split '\s+')) {
        if ($t -and -not $tokens.Contains($t)) { [void]$tokens.Add($t) }
    }
}

$tokens | Sort-Object | Set-Content -Encoding utf8 (Join-Path $root '_classlist.txt')
Write-Host ("Unique tokens: {0}" -f $tokens.Count)
