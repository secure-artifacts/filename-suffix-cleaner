$ErrorActionPreference = 'Stop'

function New-MenuEntry {
    param(
        [string]$BasePath,
        [string]$KeyName,
        [string]$Label,
        [string]$Command
    )

    $menuPath = Join-Path $BasePath $KeyName
    $commandPath = Join-Path $menuPath 'command'

    New-Item -Path $commandPath -Force | Out-Null
    Set-ItemProperty -Path $menuPath -Name 'MUIVerb' -Value $Label
    Set-ItemProperty -Path $menuPath -Name 'Icon' -Value 'shell32.dll,-16769'
    Set-ItemProperty -Path $menuPath -Name 'Position' -Value 'Top'
    Set-Item -Path $commandPath -Value $Command
}

try {
    $installRoot = Join-Path $env:LOCALAPPDATA 'FilenameSuffixCleaner'
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

    $removeScript = Join-Path $installRoot 'Remove-XxSubtitled.ps1'
    $undoScript = Join-Path $installRoot 'Undo-XxSubtitled.ps1'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Remove-XxSubtitled.ps1') `
        -Destination $removeScript -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Undo-XxSubtitled.ps1') `
        -Destination $undoScript -Force

    $powerShellExe = Join-Path $PSHOME 'powershell.exe'
    $removeBackgroundCommand = (
        '"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{1}" -TargetPath "%V"' `
            -f $powerShellExe, $removeScript
    )
    $removeFolderCommand = (
        '"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{1}" -TargetPath "%1"' `
            -f $powerShellExe, $removeScript
    )
    $undoBackgroundCommand = (
        '"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{1}" -TargetPath "%V"' `
            -f $powerShellExe, $undoScript
    )
    $undoFolderCommand = (
        '"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{1}" -TargetPath "%1"' `
            -f $powerShellExe, $undoScript
    )

    $removeLabel = '{0}{1}{2}{3} _{4}xx_subtitled' -f `
        [char]0x4E00, [char]0x952E, [char]0x53BB, [char]0x6389, [char]0x884C
    $undoLabel = '{0}{1}{2}{3}{4}{5}' -f `
        [char]0x64A4, [char]0x9500, [char]0x4E0A, [char]0x6B21, [char]0x6539, [char]0x540D

    $backgroundBase = 'HKCU:\Software\Classes\Directory\Background\shell'
    $folderBase = 'HKCU:\Software\Classes\Directory\shell'

    New-MenuEntry -BasePath $backgroundBase -KeyName 'RemoveXxSubtitled' `
        -Label $removeLabel -Command $removeBackgroundCommand
    New-MenuEntry -BasePath $folderBase -KeyName 'RemoveXxSubtitled' `
        -Label $removeLabel -Command $removeFolderCommand
    New-MenuEntry -BasePath $backgroundBase -KeyName 'UndoXxSubtitled' `
        -Label $undoLabel -Command $undoBackgroundCommand
    New-MenuEntry -BasePath $folderBase -KeyName 'UndoXxSubtitled' `
        -Label $undoLabel -Command $undoFolderCommand

    $shell = New-Object -ComObject WScript.Shell
    [void]$shell.Popup(
        'Installed. In Windows 11, open "Show more options" in the folder menu.',
        0,
        'Filename Suffix Cleaner',
        64
    )
}
catch {
    $message = 'Install failed: ' + $_.Exception.Message
    try {
        $shell = New-Object -ComObject WScript.Shell
        [void]$shell.Popup($message, 0, 'Filename Suffix Cleaner', 16)
    }
    catch {
        Write-Error $message
    }
    exit 1
}
