$ErrorActionPreference = 'Stop'

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

$projectRoot = Split-Path $PSScriptRoot -Parent
$removeScript = Join-Path $projectRoot 'src\Remove-XxSubtitled.ps1'
$undoScript = Join-Path $projectRoot 'src\Undo-XxSubtitled.ps1'
$tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$testRoot = Join-Path $tempBase ('FilenameSuffixCleaner-Test-' + [guid]::NewGuid().ToString('N'))
$originalLocalAppData = $env:LOCALAPPDATA

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    $sampleDirectory = Join-Path $testRoot 'samples'
    New-Item -ItemType Directory -Path $sampleDirectory | Out-Null

    $env:LOCALAPPDATA = Join-Path $testRoot 'appdata'
    $lineCharacter = [char]0x884C
    $matchingOne = "demo_${lineCharacter}1_subtitled.mp4"
    $matchingTwo = "clip_${lineCharacter}25_SUBTITLED.mkv"
    $collisionSource = "existing_${lineCharacter}2_subtitled.mp4"
    $nonMatching = "middle_${lineCharacter}3_subtitled_final.mp4"

    $initialNames = @(
        $matchingOne,
        $matchingTwo,
        $collisionSource,
        'existing.mp4',
        $nonMatching,
        'plain.mp4'
    )

    foreach ($name in $initialNames) {
        New-Item -ItemType File -Path (Join-Path $sampleDirectory $name) | Out-Null
    }

    & $removeScript -TargetPath $sampleDirectory -NoPopup | Out-Null

    Assert-True (Test-Path -LiteralPath (Join-Path $sampleDirectory 'demo.mp4')) `
        'First matching file was not renamed.'
    Assert-True (Test-Path -LiteralPath (Join-Path $sampleDirectory 'clip.mkv')) `
        'Case-insensitive matching failed.'
    Assert-True (Test-Path -LiteralPath (Join-Path $sampleDirectory $collisionSource)) `
        'Collision source should have been skipped.'
    Assert-True (Test-Path -LiteralPath (Join-Path $sampleDirectory $nonMatching)) `
        'Text not at the end of BaseName should not be changed.'

    $logDirectory = Join-Path $env:LOCALAPPDATA 'FilenameSuffixCleaner\logs'
    $logs = @(Get-ChildItem -LiteralPath $logDirectory -Filter '*.json' -File)
    Assert-True ($logs.Count -eq 1) 'Exactly one rename log should be created.'

    & $undoScript -TargetPath $sampleDirectory -NoPopup | Out-Null

    Assert-True (Test-Path -LiteralPath (Join-Path $sampleDirectory $matchingOne)) `
        'Undo did not restore the first filename.'
    Assert-True (Test-Path -LiteralPath (Join-Path $sampleDirectory $matchingTwo)) `
        'Undo did not restore the second filename.'

    $updatedLog = Get-Content -LiteralPath $logs[0].FullName -Raw | ConvertFrom-Json
    Assert-True (-not [string]::IsNullOrWhiteSpace([string]$updatedLog.UndoCompletedAt)) `
        'Undo completion was not recorded.'

    Write-Output 'All Filename Suffix Cleaner tests passed.'
}
finally {
    $env:LOCALAPPDATA = $originalLocalAppData

    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
        if (-not $resolvedTestRoot.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected test path: $resolvedTestRoot"
        }
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
