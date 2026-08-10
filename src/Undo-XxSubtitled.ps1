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
    $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath).Path.TrimEnd('\')
    $logDirectory = Join-Path (Join-Path $env:LOCALAPPDATA 'FilenameSuffixCleaner') 'logs'

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        Show-ResultMessage -Message 'No rename history was found.'
        exit 0
    }

    $selectedLogFile = $null
    $selectedLog = $null

    foreach ($candidate in Get-ChildItem -LiteralPath $logDirectory -Filter '*.json' -File |
        Sort-Object LastWriteTime -Descending) {
        try {
            $candidateLog = Get-Content -LiteralPath $candidate.FullName -Raw |
                ConvertFrom-Json
            $candidateTarget = ([string]$candidateLog.TargetPath).TrimEnd('\')

            if (
                [string]::Equals(
                    $candidateTarget,
                    $resolvedTarget,
                    [System.StringComparison]::OrdinalIgnoreCase
                ) -and
                -not $candidateLog.UndoCompletedAt
            ) {
                $selectedLogFile = $candidate.FullName
                $selectedLog = $candidateLog
                break
            }
        }
        catch {
            continue
        }
    }

    if (-not $selectedLog) {
        Show-ResultMessage -Message 'No rename operation is available to undo for this folder.'
        exit 0
    }

    $restored = 0
    $alreadyRestored = 0
    $skipped = New-Object System.Collections.Generic.List[string]

    foreach ($record in @($selectedLog.Records)) {
        $oldPath = Join-Path $resolvedTarget ([string]$record.OldName)
        $newPath = Join-Path $resolvedTarget ([string]$record.NewName)
        $oldExists = Test-Path -LiteralPath $oldPath
        $newExists = Test-Path -LiteralPath $newPath

        if ($newExists -and -not $oldExists) {
            try {
                Rename-Item -LiteralPath $newPath -NewName ([string]$record.OldName) -ErrorAction Stop
                $restored++
            }
            catch {
                $skipped.Add("$($record.NewName) ($($_.Exception.Message))")
            }
        }
        elseif ($oldExists -and -not $newExists) {
            $alreadyRestored++
        }
        else {
            $skipped.Add("$($record.NewName) (missing or destination conflict)")
        }
    }

    if ($skipped.Count -eq 0) {
        $selectedLog | Add-Member -NotePropertyName UndoCompletedAt `
            -NotePropertyValue ((Get-Date).ToString('o')) -Force
        $selectedLog | ConvertTo-Json -Depth 4 |
            Set-Content -LiteralPath $selectedLogFile -Encoding UTF8
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Restored: $restored")
    $lines.Add("Already restored: $alreadyRestored")
    $lines.Add("Skipped: $($skipped.Count)")
    if ($skipped.Count -gt 0) {
        $lines.Add('')
        $lines.Add('Resolve the conflicts and run Undo again:')
        foreach ($item in $skipped | Select-Object -First 8) {
            $lines.Add("  $item")
        }
    }

    Show-ResultMessage -Message ($lines -join [Environment]::NewLine)
}
catch {
    Show-ResultMessage -Message ("Failed: " + $_.Exception.Message) -Icon 16
    exit 1
}
