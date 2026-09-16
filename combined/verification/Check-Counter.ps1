#Requires -Version 7.0
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$cc = (Get-Command cl65 -CommandType Application -ErrorAction Stop).Source
$as = (Get-Command ca65 -CommandType Application -ErrorAction Stop).Source
$sim = (Get-Command sim65 -CommandType Application -ErrorAction Stop).Source
Push-Location -LiteralPath $PSScriptRoot
try {
    New-Item -ItemType Directory -Path build -Force | Out-Null
    & $cc -t sim6502 -c -o build/cl-counter.o cl-counter.c
    if ($LASTEXITCODE -ne 0) { throw 'C harness compilation failed' }
    & $as -t sim6502 -o build/counter-bridge.o counter-bridge.s
    if ($LASTEXITCODE -ne 0) { throw 'Counter bridge assembly failed' }
    & $cc -t sim6502 -C sim-counter.cfg -o build/cl-counter.bin build/cl-counter.o build/counter-bridge.o
    if ($LASTEXITCODE -ne 0) { throw 'Counter harness link failed' }
    & $sim -x 20000000 build/cl-counter.bin
    if ($LASTEXITCODE -ne 0) { throw 'Counter behavior differs from the recorded results' }
} finally {
    Pop-Location
}
