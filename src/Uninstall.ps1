$ErrorActionPreference = 'Stop'

try {
    $keys = @(
        'HKCU:\Software\Classes\Directory\Background\shell\RemoveXxSubtitled',
        'HKCU:\Software\Classes\Directory\shell\RemoveXxSubtitled',
        'HKCU:\Software\Classes\Directory\Background\shell\UndoXxSubtitled',
        'HKCU:\Software\Classes\Directory\shell\UndoXxSubtitled'
    )

    foreach ($key in $keys) {
        if (Test-Path -LiteralPath $key) {
            Remove-Item -LiteralPath $key -Recurse -Force
        }
    }

    $installRoot = Join-Path $env:LOCALAPPDATA 'FilenameSuffixCleaner'
    $removeScript = Join-Path $installRoot 'Remove-XxSubtitled.ps1'
    $undoScript = Join-Path $installRoot 'Undo-XxSubtitled.ps1'
    if (Test-Path -LiteralPath $removeScript) {
        Remove-Item -LiteralPath $removeScript -Force
    }
    if (Test-Path -LiteralPath $undoScript) {
        Remove-Item -LiteralPath $undoScript -Force
    }

    $shell = New-Object -ComObject WScript.Shell
    [void]$shell.Popup(
        'Uninstalled. Rename history was kept for safety.',
        0,
        'Filename Suffix Cleaner',
        64
    )
}
catch {
    $message = 'Uninstall failed: ' + $_.Exception.Message
    try {
        $shell = New-Object -ComObject WScript.Shell
        [void]$shell.Popup($message, 0, 'Filename Suffix Cleaner', 16)
    }
    catch {
        Write-Error $message
    }
    exit 1
}
