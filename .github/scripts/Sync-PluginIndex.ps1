[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$comboUrl = 'https://raw.githubusercontent.com/WayneXXDD/Combo/plugin-repo/build-manifest.json'
$nativeUrl = 'https://raw.githubusercontent.com/WayneXXDD/NativeChatTabs/plugin-repo/build-manifest.json'
$guildhestUrl = 'https://raw.githubusercontent.com/WayneXXDD/GuildhestQueue/plugin-repo/build-manifest.json'
$buffOffUrl = 'https://raw.githubusercontent.com/WayneXXDD/RaidBuffOff/plugin-repo/build-manifest.json'
$combo = @((Invoke-WebRequest -Uri $comboUrl).Content | ConvertFrom-Json)
$native = @((Invoke-WebRequest -Uri $nativeUrl).Content | ConvertFrom-Json)
$guildhest = @((Invoke-WebRequest -Uri $guildhestUrl).Content | ConvertFrom-Json)
$buffOff = @((Invoke-WebRequest -Uri $buffOffUrl).Content | ConvertFrom-Json)
if ($combo.Count -ne 2 -or ((@($combo.InternalName | Sort-Object) -join ',') -ne 'Oracle,XIVComboExpandedest')) { throw 'Expected Combo and Oracle.' }
if ($native.Count -ne 1 -or $native[0].InternalName -ne 'NativeChatTabs') { throw 'Expected Native Chat Tabs.' }
if ($guildhest.Count -ne 1 -or $guildhest[0].InternalName -ne 'GuildhestQueue') { throw 'Expected Guildhest Queue.' }
if ($buffOff.Count -ne 1 -or $buffOff[0].InternalName -ne 'RaidBuffOff') { throw 'Expected Raid Buff Off.' }
$entries = @(@($combo) + @($native) + @($guildhest) + @($buffOff) | Sort-Object InternalName)
if ($entries.Count -ne 5 -or ((@($entries.InternalName | Sort-Object) -join ',') -ne 'GuildhestQueue,NativeChatTabs,Oracle,RaidBuffOff,XIVComboExpandedest')) { throw 'Plugin index is incomplete or duplicated.' }
foreach ($entry in $entries) {
    if ([version]$entry.AssemblyVersion -le [version]'0.0.0.0' -or [int]$entry.DalamudApiLevel -le 0) { throw 'Invalid version or API level.' }
    $repository = switch ($entry.InternalName) {
        'NativeChatTabs' { 'NativeChatTabs' }
        'GuildhestQueue' { 'GuildhestQueue' }
        'RaidBuffOff' { 'RaidBuffOff' }
        default { 'Combo' }
    }
    $expected = "https://raw.githubusercontent.com/WayneXXDD/$repository/plugin-repo/plugins/$($entry.InternalName)/latest.zip"
    $downloadKeys = @('DownloadLinkInstall','DownloadLinkUpdate')
    if ($entry.InternalName -ne 'RaidBuffOff') { $downloadKeys += 'DownloadLinkTesting' }
    foreach ($key in $downloadKeys) {
        if ($entry.$key -ne $expected) { throw "Unexpected download URL for $($entry.InternalName)." }
    }
    if ($entry.InternalName -in @('NativeChatTabs','GuildhestQueue')) {
        if (-not $entry.IsTestingExclusive -or [int]$entry.TestingDalamudApiLevel -ne [int]$entry.DalamudApiLevel -or
            [version]$entry.TestingAssemblyVersion -ne [version]$entry.AssemblyVersion) { throw "Testing metadata is invalid for $($entry.InternalName)." }
    }
    if ($entry.InternalName -eq 'RaidBuffOff') {
        if ($entry.IsTestingExclusive -or $entry.Name -match 'Testing' -or
            @($entry.PSObject.Properties.Name | Where-Object { $_ -in @('TestingAssemblyVersion','TestingDalamudApiLevel','DownloadLinkTesting') }).Count -ne 0) {
            throw 'Raid Buff Off must use stable-channel metadata.'
        }
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
