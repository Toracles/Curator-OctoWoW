# SPDX-FileCopyrightText: 2026 CloudNine_Ex
# SPDX-License-Identifier: GPL-3.0-only

param(
    [Parameter(Mandatory)]
    [string]$GameRoot,
    [string]$FFmpeg = 'ffmpeg'
)

$ErrorActionPreference = 'Stop'
$addons = Join-Path (Resolve-Path -LiteralPath $GameRoot).Path 'Interface/AddOns'
$source = Join-Path $addons 'SoftSpoken_Stories/Sounds/og-thrall.mp3'
$expectedHash = '641CE894DCAFCC93D6C9E41F2C6AAECA47AB71CA12CDDC43A657D3F858377681'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw 'Install SoftSpoken Stories to prepare the optional Thrall clip.'
}
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'This recording differs from the version supported by the Thrall excerpt.'
}

$encoder = (Get-Command -Name $FFmpeg -CommandType Application).Source
$pack = Join-Path $addons 'CuratorSoftSpokenVoices'
$tocPath = Join-Path $pack 'CuratorSoftSpokenVoices.toc'
if ((Test-Path -LiteralPath $tocPath) -and ((Get-Content -LiteralPath $tocPath -Raw) -match '(?m)^## Version: [2-9]\d*\s*$')) {
    throw 'The bilingual voice pack is already installed.'
}
New-Item -Path $pack -ItemType Directory -Force | Out-Null
$temporary = Join-Path $pack 'thrall.tmp'
& $encoder -hide_banner -loglevel error -y -i $source -t 4 -map 0:a:0 -map_metadata -1 -codec:a libmp3lame -b:a 64k -f mp3 $temporary
if ($LASTEXITCODE -ne 0) { throw 'FFmpeg could not prepare the Thrall excerpt.' }
Move-Item -LiteralPath $temporary -Destination (Join-Path $pack 'thrall.mp3') -Force

@'
## Interface: 11200
## Title: Curator SoftSpoken Voices
## Notes: Optional voices for Curator's Mythic entrances.
## Version: 1

Voices.lua
'@ | Set-Content -LiteralPath $tocPath -Encoding ascii

$manifest = @'
CuratorSoftSpokenVoices = {
    [4949] = {
        path = [[Interface\AddOns\CuratorSoftSpokenVoices\thrall.mp3]],
        length = 4.08,
        enUS = "All members of the Horde are equal in my eyes.",
        frFR = "Tous les membres de la Horde sont \195\169gaux \195\160 mes yeux.",
    },
}
'@
[IO.File]::WriteAllText((Join-Path $pack 'Voices.lua'), $manifest, [Text.UTF8Encoding]::new($false))
Write-Output "Prepared the optional Thrall voice in $pack"
