$ErrorActionPreference = 'Stop'

function Assert-Match {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -notmatch $Pattern) {
        throw "Workflow compliance check failed: $Message"
    }
}

$projectRoot = Split-Path $PSScriptRoot -Parent
$workflowPath = Join-Path $projectRoot '.github\workflows\release.yml'
$versionPath = Join-Path $projectRoot 'VERSION'

if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
    throw 'Workflow compliance check failed: release.yml is missing.'
}

$workflow = Get-Content -LiteralPath $workflowPath -Raw
$version = (Get-Content -LiteralPath $versionPath -Raw).Trim()

if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Workflow compliance check failed: VERSION is not SemVer: $version"
}

Assert-Match $workflow '(?m)^on:\s*$' 'The workflow must define an on block.'
Assert-Match $workflow '(?m)^\s{2}push:\s*$' 'Release must be triggered by tag push.'
Assert-Match $workflow "(?m)^\s+- 'v\*'\s*$" 'Release tags must match v*.'
Assert-Match $workflow '(?m)^\s+id-token:\s*write\s*$' 'id-token: write is required.'
Assert-Match $workflow '(?m)^\s+contents:\s*write\s*$' 'contents: write is required.'
Assert-Match $workflow '(?m)^\s+attestations:\s*write\s*$' 'attestations: write is required.'
Assert-Match $workflow 'actions/attest-build-provenance@v2' 'Attestation action v2 is required.'
Assert-Match $workflow "subject-path:\s*'dist/\*'" 'Attestation must cover final dist assets.'
Assert-Match $workflow 'softprops/action-gh-release@v2' 'GitHub Release action v2 is required.'
Assert-Match $workflow 'files:\s*dist/\*' 'Release must upload the same final dist assets.'

if ($workflow -match '(?m)^\s*workflow_dispatch\s*:') {
    throw 'Workflow compliance check failed: workflow_dispatch is not allowed for L2 release provenance.'
}

if ($workflow -match '(?i)secrets\.[A-Z0-9_]*(PAT|TOKEN)') {
    throw 'Workflow compliance check failed: a personal token appears to be configured.'
}

Write-Output "Release workflow compliance checks passed for v$version."
