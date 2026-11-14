[CmdletBinding()]
param([Parameter(Mandatory)] [psobject] $Manifest)
$ErrorActionPreference = 'Stop'
if ($Manifest.InternalName -cne 'AutomaticHunting' -or $Manifest.Author -cne 'SFY') { throw 'Unexpected upstream plugin identity.' }
$version = [version]$Manifest.AssemblyVersion
if ($version -lt [version]'2.4.5.1') { throw 'Expected the Global port version.' }
if ($Manifest.RepoUrl -cne 'https://github.com/WayneXXDD/AutomaticHuntingGlobal' -or [int]$Manifest.DalamudApiLevel -ne 15) { throw 'Expected the Global build repository and API level.' }
if (-not $Manifest.IsTestingExclusive -or [version]$Manifest.TestingAssemblyVersion -ne $version -or [int]$Manifest.TestingDalamudApiLevel -ne 15) { throw 'Expected Global testing-channel metadata.' }
$tag = 'v' + $Manifest.AssemblyVersion
$url = "https://github.com/WayneXXDD/AutomaticHuntingGlobal/releases/download/$tag/AutomaticHunting.zip"
foreach ($key in @('DownloadLinkInstall','DownloadLinkUpdate','DownloadLinkTesting')) {
    if ($Manifest.$key -cne $url) { throw "Unexpected AutomaticHunting $key." }
}
$headers = @{ 'Accept' = 'application/vnd.github+json'; 'User-Agent' = 'WayneXXDD-DalamudPlugins' }
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/WayneXXDD/AutomaticHuntingGlobal/releases/tags/$tag" -Headers $headers
if ($release.draft -or $release.prerelease -or $release.tag_name -cne $tag) { throw 'Expected a published stable upstream release.' }
$assets = @($release.assets | Where-Object { $_.name -ceq 'AutomaticHunting.zip' })
if ($assets.Count -ne 1 -or $assets[0].browser_download_url -cne $url) { throw 'Missing or mismatched upstream ZIP.' }
$asset = $assets[0]
if ([long]$asset.size -le 0 -or [long]$asset.size -gt 64MB) { throw 'Unexpected upstream ZIP size.' }
if ([string]$asset.digest -cnotmatch '^sha256:[0-9a-f]{64}$') { throw 'Upstream asset does not provide a SHA-256 digest.' }
if (-not $env:RUNNER_TEMP) { throw 'Package verification must run in GitHub Actions temporary storage.' }
$tempRoot = [IO.Path]::GetFullPath($env:RUNNER_TEMP)
$stage = [IO.Path]::GetFullPath((Join-Path $tempRoot ('automatic-hunting-check-' + [guid]::NewGuid().ToString('N'))))
if (-not $stage.StartsWith($tempRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid verification directory.' }
[void][IO.Directory]::CreateDirectory($stage)
$zipPath = Join-Path $stage 'AutomaticHunting.zip'
Invoke-WebRequest -Uri $url -OutFile $zipPath -UserAgent 'WayneXXDD-DalamudPlugins'
if ((Get-Item -LiteralPath $zipPath).Length -ne [long]$asset.size) { throw 'Downloaded ZIP size differs from the release asset.' }
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
if (('sha256:' + $hash) -cne [string]$asset.digest) { throw 'Downloaded ZIP checksum mismatch.' }
$zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $names = @($zip.Entries.FullName)
    if (@($names | Sort-Object -Unique).Count -ne $names.Count) { throw 'Duplicate ZIP entry names.' }
    foreach ($required in @('AutomaticHunting.dll','AutomaticHunting.json')) {
        if (@($zip.Entries | Where-Object { $_.FullName -ceq $required }).Count -ne 1) { throw "Missing root package entry: $required" }
    }
    $jsonEntry = $zip.GetEntry('AutomaticHunting.json')
    if ($jsonEntry.Length -gt 1MB) { throw 'Package manifest is unexpectedly large.' }
    $reader = [IO.StreamReader]::new($jsonEntry.Open(), [Text.Encoding]::UTF8, $true)
    try { $inside = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
    if ($inside.InternalName -cne 'AutomaticHunting' -or
        [version]$inside.AssemblyVersion -ne $version -or
        [int]$inside.DalamudApiLevel -ne [int]$Manifest.DalamudApiLevel) { throw 'Package manifest identity/version/API differs from the index.' }
    # Read assembly metadata only. Never load or execute the downloaded plugin.
    $dllPath = Join-Path $stage 'AutomaticHunting.dll'
    $inputStream = $zip.GetEntry('AutomaticHunting.dll').Open()
    $outputStream = [IO.File]::Create($dllPath)
    try { $inputStream.CopyTo($outputStream) } finally { $outputStream.Dispose(); $inputStream.Dispose() }
    $assembly = [Reflection.AssemblyName]::GetAssemblyName($dllPath)
    if ($assembly.Name -cne 'AutomaticHunting' -or $assembly.Version -ne $version) { throw 'Plugin DLL identity/version differs from the index.' }
    Write-Output ("Verified AutomaticHunting {0}, API {1}, SHA256 {2}; entries: {3}" -f $version,$inside.DalamudApiLevel,$hash,($names -join ', '))
}
finally { $zip.Dispose() }
