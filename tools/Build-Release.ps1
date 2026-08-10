param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
$version = (Get-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Raw).Trim()

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot 'dist'
}

$resolvedProjectRoot = [System.IO.Path]::GetFullPath($projectRoot).TrimEnd('\')
$resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\')

if ([string]::Equals(
        $resolvedProjectRoot,
        $resolvedOutputDirectory,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
    throw 'OutputDirectory cannot be the project root.'
}

New-Item -ItemType Directory -Path $resolvedOutputDirectory -Force | Out-Null

$releaseName = "Filename-Suffix-Cleaner-v$version"
$stageDirectory = Join-Path $resolvedOutputDirectory $releaseName
$zipPath = Join-Path $resolvedOutputDirectory "$releaseName.zip"

if (Test-Path -LiteralPath $stageDirectory) {
    Remove-Item -LiteralPath $stageDirectory -Recurse -Force
}
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

New-Item -ItemType Directory -Path $stageDirectory | Out-Null

Copy-Item -LiteralPath (Join-Path $projectRoot 'src\Install.ps1') -Destination $stageDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'src\Remove-XxSubtitled.ps1') -Destination $stageDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'src\Undo-XxSubtitled.ps1') -Destination $stageDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'src\Uninstall.ps1') -Destination $stageDirectory

$launcherDirectory = Join-Path $projectRoot 'launchers'
Copy-Item -Path (Join-Path $launcherDirectory '*.cmd') -Destination $stageDirectory
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs\用户说明.txt') `
    -Destination (Join-Path $stageDirectory '使用说明.txt')

Compress-Archive -Path (Join-Path $stageDirectory '*') -DestinationPath $zipPath -CompressionLevel Optimal
Remove-Item -LiteralPath $stageDirectory -Recurse -Force

$hash = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
Write-Output "Release package: $zipPath"
Write-Output "SHA256: $($hash.Hash)"
