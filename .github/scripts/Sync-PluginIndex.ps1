[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$comboUrl = 'https://raw.githubusercontent.com/WayneXXDD/Combo/plugin-repo/build-manifest.json'
$nativeUrl = 'https://raw.githubusercontent.com/WayneXXDD/NativeChatTabs/plugin-repo/build-manifest.json'
$combo = @((Invoke-WebRequest -Uri $comboUrl).Content | ConvertFrom-Json)
$native = @((Invoke-WebRequest -Uri $nativeUrl).Content | ConvertFrom-Json)
if ($combo.Count -ne 2 -or ((@($combo.InternalName | Sort-Object) -join ',') -ne 'Oracle,XIVComboExpandedest')) { throw 'Expected Combo and Oracle.' }
if ($native.Count -ne 1 -or $native[0].InternalName -ne 'NativeChatTabs') { throw 'Expected Native Chat Tabs.' }
$entries = @(@($combo) + @($native) | Sort-Object InternalName)
if ($entries.Count -ne 3 -or ((@($entries.InternalName | Sort-Object) -join ',') -ne 'NativeChatTabs,Oracle,XIVComboExpandedest')) { throw 'Plugin index is incomplete or duplicated.' }
foreach ($entry in $entries) {
    if ([version]$entry.AssemblyVersion -le [version]'0.0.0.0' -or [int]$entry.DalamudApiLevel -le 0) { throw 'Invalid version or API level.' }
    $repository = if ($entry.InternalName -eq 'NativeChatTabs') { 'NativeChatTabs' } else { 'Combo' }
    $expected = "https://raw.githubusercontent.com/WayneXXDD/$repository/plugin-repo/plugins/$($entry.InternalName)/latest.zip"
    foreach ($key in @('DownloadLinkInstall','DownloadLinkUpdate','DownloadLinkTesting')) {
        if ($entry.$key -ne $expected) { throw "Unexpected download URL for $($entry.InternalName)." }
    }
    if ($entry.InternalName -eq 'NativeChatTabs') {
        if (-not $entry.IsTestingExclusive -or [int]$entry.TestingDalamudApiLevel -ne [int]$entry.DalamudApiLevel -or
            [version]$entry.TestingAssemblyVersion -ne [version]$entry.AssemblyVersion) { throw 'Native Chat Tabs testing metadata is invalid.' }
    }
}
$path = Join-Path $env:GITHUB_WORKSPACE 'pluginmaster.json'
if (Test-Path -LiteralPath $path) {
    $previous = @(Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
    foreach ($entry in $entries) {
        $old = $previous | Where-Object InternalName -eq $entry.InternalName | Select-Object -First 1
        if ($old -and [version]$entry.AssemblyVersion -lt [version]$old.AssemblyVersion) { throw "Refusing version downgrade: $($entry.InternalName)." }
    }
}
[IO.File]::WriteAllText($path,(ConvertTo-Json -InputObject $entries -Depth 30) + "`n",[Text.UTF8Encoding]::new($false))
Write-Output ('Validated index: ' + ($entries.InternalName -join ', '))
