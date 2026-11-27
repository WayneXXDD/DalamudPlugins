[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$comboUrl = 'https://raw.githubusercontent.com/WayneXXDD/Combo/plugin-repo/build-manifest.json'
$nativeUrl = 'https://raw.githubusercontent.com/WayneXXDD/NativeChatTabs/plugin-repo/build-manifest.json'
$guildhestUrl = 'https://raw.githubusercontent.com/WayneXXDD/GuildhestQueue/plugin-repo/build-manifest.json'
$buffOffUrl = 'https://raw.githubusercontent.com/WayneXXDD/RaidBuffOff/plugin-repo/build-manifest.json'
$bocchiUrl = 'https://raw.githubusercontent.com/WayneXXDD/BOCCHI/plugin-repo/build-manifest.json'
$timerUrl = 'https://raw.githubusercontent.com/WayneXXDD/ComboTimer/plugin-repo/build-manifest.json'
$huntingUrl = 'https://raw.githubusercontent.com/WayneXXDD/AutomaticHuntingGlobal/main/AutomaticHunting.json'
$combo = @((Invoke-WebRequest -Uri $comboUrl).Content | ConvertFrom-Json)
$native = @((Invoke-WebRequest -Uri $nativeUrl).Content | ConvertFrom-Json)
$guildhest = @((Invoke-WebRequest -Uri $guildhestUrl).Content | ConvertFrom-Json)
$buffOff = @((Invoke-WebRequest -Uri $buffOffUrl).Content | ConvertFrom-Json)
$timer = @((Invoke-WebRequest -Uri $timerUrl).Content | ConvertFrom-Json)
if ($timer.Count -ne 1 -or $timer[0].InternalName -cne 'WayneComboTimer') { throw 'Expected Combo Timer.' }
$bocchi = @((Invoke-WebRequest -Uri $bocchiUrl).Content | ConvertFrom-Json)
if ($bocchi.Count -ne 1 -or $bocchi[0].InternalName -cne 'BOCCHI' -or [int]$bocchi[0].DalamudApiLevel -ne 15) { throw 'Expected the Wayne BOCCHI Global build.' }
$hunting = @((Invoke-WebRequest -Uri $huntingUrl).Content | ConvertFrom-Json)
if ($hunting.Count -ne 1 -or $hunting[0].InternalName -ne 'AutomaticHunting') { throw 'Expected AutomaticHunting.' }
if ($hunting[0].Name -cne 'AutomaticHunting Global' -or [version]$hunting[0].AssemblyVersion -lt [version]'2.4.5.3') { throw 'Expected the WayneXXDD Global build.' }
& (Join-Path $PSScriptRoot 'Validate-ExternalPlugin.ps1') -Manifest $hunting[0]
if ($combo.Count -ne 2 -or ((@($combo.InternalName | Sort-Object) -join ',') -ne 'Oracle,XIVComboExpandedest')) { throw 'Expected Combo and Oracle.' }
if ($native.Count -ne 1 -or $native[0].InternalName -ne 'NativeChatTabs') { throw 'Expected Native Chat Tabs.' }
if ($guildhest.Count -ne 1 -or $guildhest[0].InternalName -ne 'GuildhestQueue') { throw 'Expected Guildhest Queue.' }
if ($buffOff.Count -ne 1 -or $buffOff[0].InternalName -ne 'RaidBuffOff') { throw 'Expected Raid Buff Off.' }
$bmrRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/WayneXXDD/BossmodRebornCN/releases/latest'
$bmrVersion = $bmrRelease.tag_name
if ($bmrRelease.draft -or $bmrRelease.prerelease -or $bmrVersion -notmatch '^\d+\.\d+\.\d+\.\d+$') { throw 'Expected a published version of the BossModReborn fork.' }
$bmrBase = "https://github.com/WayneXXDD/BossmodRebornCN/releases/download/$bmrVersion"
$bmrManifests = @($bmrRelease.assets | Where-Object { $_.name -ceq 'BossModReborn.json' -and $_.browser_download_url -ceq "$bmrBase/BossModReborn.json" })
$bmrPackages = @($bmrRelease.assets | Where-Object { $_.name -ceq 'latest.zip' -and $_.browser_download_url -ceq "$bmrBase/latest.zip" })
if ($bmrManifests.Count -ne 1 -or $bmrPackages.Count -ne 1 -or $bmrPackages[0].size -le 0) { throw 'BossModReborn release is missing its manifest or package.' }
$bmrResponse = (Invoke-WebRequest -Uri $bmrManifests[0].browser_download_url).Content
if ($bmrResponse -is [byte[]]) { $bmrResponse = [Text.Encoding]::UTF8.GetString($bmrResponse) }
$bmr = $bmrResponse | ConvertFrom-Json
if ($bmr.InternalName -cne 'BossModReborn' -or $bmr.AssemblyVersion -ne $bmrVersion -or [int]$bmr.DalamudApiLevel -ne 15) { throw 'BossModReborn package identity, version, or API does not match.' }
if ($bmr.DownloadLinkInstall -cne $bmrPackages[0].browser_download_url -or $bmr.DownloadLinkUpdate -cne $bmrPackages[0].browser_download_url) { throw 'BossModReborn download links do not match its verified release.' }
$entries = @(@($combo) + @($native) + @($guildhest) + @($buffOff) + @($hunting) + @($bmr) + @($timer) + @($bocchi) | Sort-Object InternalName)
if ($entries.Count -ne 9 -or ((@($entries.InternalName | Sort-Object) -join ',') -ne 'AutomaticHunting,BOCCHI,BossModReborn,GuildhestQueue,NativeChatTabs,Oracle,RaidBuffOff,WayneComboTimer,XIVComboExpandedest')) { throw 'Plugin index is incomplete or duplicated.' }
foreach ($entry in $entries) {
    if ([version]$entry.AssemblyVersion -le [version]'0.0.0.0' -or [int]$entry.DalamudApiLevel -le 0) { throw 'Invalid version or API level.' }
    if ($entry.InternalName -eq 'AutomaticHunting') { continue } # Verified against the Global build release and ZIP above.
    if ($entry.InternalName -ceq 'BossModReborn') { continue } # Version and release asset URLs checked above.
    $repository = switch ($entry.InternalName) {
        'NativeChatTabs' { 'NativeChatTabs' }
        'GuildhestQueue' { 'GuildhestQueue' }
        'RaidBuffOff' { 'RaidBuffOff' }
        'WayneComboTimer' { 'ComboTimer' }
        'BOCCHI' { 'BOCCHI' }
        default { 'Combo' }
    }
    $expected = "https://raw.githubusercontent.com/WayneXXDD/$repository/plugin-repo/plugins/$($entry.InternalName)/latest.zip"
    $downloadKeys = @('DownloadLinkInstall','DownloadLinkUpdate')
    if ($entry.InternalName -notin @('RaidBuffOff','WayneComboTimer','BOCCHI')) { $downloadKeys += 'DownloadLinkTesting' }
    foreach ($key in $downloadKeys) {
        if ($entry.$key -ne $expected) { throw "Unexpected download URL for $($entry.InternalName)." }
    }
    if ($entry.InternalName -in @('NativeChatTabs','GuildhestQueue')) {
        if (-not $entry.IsTestingExclusive -or [int]$entry.TestingDalamudApiLevel -ne [int]$entry.DalamudApiLevel -or
            [version]$entry.TestingAssemblyVersion -ne [version]$entry.AssemblyVersion) { throw "Testing metadata is invalid for $($entry.InternalName)." }
    }
    if ($entry.InternalName -in @('RaidBuffOff','WayneComboTimer','BOCCHI')) {
        if ($entry.IsTestingExclusive -or $entry.Name -match 'Testing' -or
            @($entry.PSObject.Properties.Name | Where-Object { $_ -in @('TestingAssemblyVersion','TestingDalamudApiLevel','DownloadLinkTesting') }).Count -ne 0) {
            throw "$($entry.InternalName) must use stable-channel metadata."
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
