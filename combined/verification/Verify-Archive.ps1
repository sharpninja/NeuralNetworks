#Requires -Version 7.0
[CmdletBinding()]
param([string] $C1541 = 'c1541', [string] $Petcat = 'petcat')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$diskTool = (Get-Command $C1541 -CommandType Application -ErrorAction Stop).Source
$basicTool = (Get-Command $Petcat -CommandType Application -ErrorAction Stop).Source
$scratch = Join-Path $PSScriptRoot 'build/archive'
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

function Assert-SameBytes([string] $Expected, [string] $Actual) {
    [byte[]] $a = [IO.File]::ReadAllBytes($Expected)
    [byte[]] $b = [IO.File]::ReadAllBytes($Actual)
    if ($a.Length -ne $b.Length) { throw "Length mismatch: $Actual" }
    for ($i = 0; $i -lt $a.Length; $i++) {
        if ($a[$i] -ne $b[$i]) { throw "Byte mismatch at offset $i in $Actual" }
    }
}

function Read-Basic([string] $Path) {
    [byte[]] $b = [IO.File]::ReadAllBytes($Path)
    if ($b[0] -ne 1 -or $b[1] -ne 8) { throw "Wrong BASIC load address: $Path" }
    $position = 2; $previous = -1; $lines = @{}
    while ($position + 1 -lt $b.Length) {
        $next = [int]$b[$position] + 256 * [int]$b[$position + 1]
        if ($next -eq 0) {
            if ($position + 2 -ne $b.Length) { throw "Unexpected bytes after BASIC terminator: $Path" }
            return ,$lines
        }
        if ($position + 4 -ge $b.Length) { throw "Truncated BASIC line: $Path" }
        $line = [int]$b[$position + 2] + 256 * [int]$b[$position + 3]
        if ($line -le $previous) { throw "Nonascending BASIC line numbers: $Path" }
        $end = $position + 4
        while ($end -lt $b.Length -and $b[$end] -ne 0) { $end++ }
        if ($end -ge $b.Length) { throw "Missing line terminator: $Path" }
        if ($next -ne (0x0801 + $end + 1 - 2)) { throw "Bad next-line pointer at $line in $Path" }
        $lines[$line] = [byte[]]$b[($position + 4)..($end - 1)]
        $previous = $line; $position = $end + 1
    }
    throw "Missing BASIC end marker: $Path"
}

foreach ($name in 'XOR', 'ENCODE', 'DIPOLE', 'BP.ML', 'CL.ML') {
    $prg = Join-Path $root "prg/$name.prg"
    $extracted = Join-Path $scratch "$name.disk.prg"
    $nativeOutput = & $diskTool -attach (Join-Path $root 'Neural-Networks-C64.d64') -read $name.ToLowerInvariant() $extracted 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Disk extraction failed: $nativeOutput" }
    Assert-SameBytes $prg $extracted
    Write-Output "$name D64 extraction: identical"
}

$originalCount = 0; $addedCount = 0
foreach ($name in 'XOR', 'ENCODE', 'DIPOLE') {
    $prg = Join-Path $root "prg/$name.prg"
    $lines = Read-Basic $prg
    $original = Read-Basic (Join-Path $root "original-basic/$name.prg")
    foreach ($line in $original.Keys) {
        if (-not $lines.ContainsKey($line) -or [Convert]::ToHexString($lines[$line]) -cne [Convert]::ToHexString($original[$line])) {
            throw "Original line $line changed in $name"
        }
        $originalCount++
    }
    foreach ($line in $lines.Keys) {
        if (-not $original.ContainsKey($line)) {
            if ($lines[$line][0] -ne 0x8F) { throw "Added non-REM line in $name" }
            $addedCount++
        }
    }
    $retokenized = Join-Path $scratch "$name.retokenized.prg"
    $nativeOutput = & $basicTool -w2 -o $retokenized -- (Join-Path $root "basic/$name.bas") 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Retokenization failed: $nativeOutput" }
    Assert-SameBytes $prg $retokenized
    Write-Output "$name BASIC pointers, original lines and source round trip: verified"
}
if ($originalCount -ne 131 -or $addedCount -ne 36) { throw 'Unexpected BASIC line totals' }
Write-Output "Original BASIC lines preserved: $originalCount; additional REM lines: $addedCount"

foreach ($audit in @(@('BASIC-Checks.csv', 131), @('MLX-Checks.csv', 818))) {
    $rows = @(Import-Csv -LiteralPath (Join-Path $PSScriptRoot $audit[0]))
    if ($rows.Count -ne $audit[1] -or @($rows | Where-Object { $_.Result -ne 'MATCH' -or $_.Printed -ne $_.Calculated }).Count) {
        throw "Inconsistent recorded listing audit: $($audit[0])"
    }
    Write-Output "$($audit[0]): $($rows.Count) matching recorded checksums"
}

$manifest = Join-Path $root 'SHA256SUMS.txt'
if (-not (Test-Path -LiteralPath $manifest)) { throw 'Missing SHA256SUMS.txt' }
$hashCount = 0
foreach ($line in [IO.File]::ReadAllLines($manifest)) {
    if (-not $line.Trim()) { continue }
    if ($line -notmatch '^([a-fA-F0-9]{64})  (.+)$') { throw 'Invalid hash manifest line' }
    $expectedHash = $Matches[1]; $relative = $Matches[2]
    $path = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $path.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Manifest path outside archive' }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine $expectedHash) { throw "Hash mismatch: $relative" }
    $hashCount++
}
Write-Output "SHA256 manifest entries verified: $hashCount"
