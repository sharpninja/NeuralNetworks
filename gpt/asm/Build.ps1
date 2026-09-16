#Requires -Version 7.0
[CmdletBinding()]
param(
    [string] $OutputDirectory = (Join-Path $PSScriptRoot 'build'),
    [string] $Ca65 = 'ca65',
    [string] $Ld65 = 'ld65'
)

$ErrorActionPreference = 'Stop'
$ca65Command = (Get-Command $Ca65 -CommandType Application -ErrorAction Stop).Source
$ld65Command = (Get-Command $Ld65 -CommandType Application -ErrorAction Stop).Source
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

foreach ($engine in 'BP', 'CL') {
    $name = "$engine.ML"
    $source = Join-Path $PSScriptRoot "$name.s"
    $object = Join-Path $outputRoot "$name.o"
    $rebuilt = Join-Path $outputRoot "$name.prg"
    $original = Join-Path $PSScriptRoot "../Neural-Networks-C64/$name.prg"

    & $ca65Command --cpu 6502 -o $object -l (Join-Path $outputRoot "$name.lst") $source
    if ($LASTEXITCODE -ne 0) { throw "ca65 failed for $name (exit $LASTEXITCODE)" }
    & $ld65Command -C (Join-Path $PSScriptRoot 'c64-ml.cfg') -o $rebuilt -m (Join-Path $outputRoot "$name.map") $object
    if ($LASTEXITCODE -ne 0) { throw "ld65 failed for $name (exit $LASTEXITCODE)" }

    [byte[]] $expected = [IO.File]::ReadAllBytes($original)
    [byte[]] $actual = [IO.File]::ReadAllBytes($rebuilt)
    if ($actual.Length -ne $expected.Length) {
        throw "$name length mismatch: expected $($expected.Length), got $($actual.Length)"
    }
    for ($offset = 0; $offset -lt $expected.Length; $offset++) {
        if ($actual[$offset] -ne $expected[$offset]) {
            throw ('{0} differs at file offset ${1:X4}: expected ${2:X2}, got ${3:X2}' -f $name, $offset, $expected[$offset], $actual[$offset])
        }
    }
    $hash = (Get-FileHash -LiteralPath $rebuilt -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Output "$name : identical, $($actual.Length) bytes including load header; SHA256 $hash"
}
