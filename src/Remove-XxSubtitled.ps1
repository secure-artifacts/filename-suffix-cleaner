param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,

    [switch]$NoPopup
)

$ErrorActionPreference = 'Stop'

function Show-ResultMessage {
    param(
        [string]$Message,
        [int]$Icon = 64
    )

    if ($NoPopup) {
        Write-Output $Message
        return
    }

    try {
        $shell = New-Object -ComObject WScript.Shell
        [void]$shell.Popup($Message, 0, 'Filename Suffix Cleaner', $Icon)
    }
    catch {
        Write-Output $Message
    }
}

try {
    $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath).Path
    if (-not (Test-Path -LiteralPath $resolvedTarget -PathType Container)) {
        throw "The target is not a folder: $resolvedTarget"
    }

    $lineCharacter = [char]0x884C
    $suffixPattern = '_{0}\d+_subtitled$' -f [regex]::Escape([string]$lineCharacter)
    $renamed = New-Object System.Collections.Generic.List[object]
    $skipped = New-Object System.Collections.Generic.List[string]

    foreach ($file in Get-ChildItem -LiteralPath $resolvedTarget -File) {
        $newBaseName = [regex]::Replace(
            $file.BaseName,
            $suffixPattern,
            '',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if ($newBaseName -eq $file.BaseName) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($newBaseName)) {
            $skipped.Add("$($file.Name) (empty result)")
            continue
        }

        $newName = $newBaseName + $file.Extension
        $destination = Join-Path $resolvedTarget $newName

        if (Test-Path -LiteralPath $destination) {
            $skipped.Add("$($file.Name) -> $newName (already exists)")
            continue
        }

        try {
            Rename-Item -LiteralPath $file.FullName -NewName $newName -ErrorAction Stop
            $renamed.Add([pscustomobject]@{
                OldName = $file.Name
                NewName = $newName
            })
        }
        catch {
            $skipped.Add("$($file.Name) ($($_.Exception.Message))")
        }
    }

    $logPath = $null
    if ($renamed.Count -gt 0) {
        $appRoot = Join-Path $env:LOCALAPPDATA 'FilenameSuffixCleaner'
        $logDirectory = Join-Path $appRoot 'logs'
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
        $logPath = Join-Path $logDirectory "$timestamp.json"
        $log = [ordered]@{
            Version = 1
            TargetPath = $resolvedTarget
            CreatedAt = (Get-Date).ToString('o')
            Records = @($renamed | ForEach-Object { $_ })
        }
        $log | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $logPath -Encoding UTF8
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Renamed: $($renamed.Count)")
    $lines.Add("Skipped: $($skipped.Count)")
    if ($renamed.Count -eq 0 -and $skipped.Count -eq 0) {
        $lines.Add('')
        $lines.Add('No matching filenames were found.')
    }
    if ($skipped.Count -gt 0) {
        $lines.Add('')
        $lines.Add('Skipped items:')
        foreach ($item in $skipped | Select-Object -First 8) {
            $lines.Add("  $item")
        }
        if ($skipped.Count -gt 8) {
            $lines.Add("  ... and $($skipped.Count - 8) more")
        }
    }
    if ($logPath) {
        $lines.Add('')
        $lines.Add('You can use "Undo last filename cleanup" from the folder menu.')
    }

    Show-ResultMessage -Message ($lines -join [Environment]::NewLine)
}
catch {
    Show-ResultMessage -Message ("Failed: " + $_.Exception.Message) -Icon 16
    exit 1
}
