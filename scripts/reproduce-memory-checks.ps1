param(
    [string]$DeviceSerial = 'emulator-5554',
    [string]$SdkPath,
    [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$repoSafe = $repoRoot.Replace('\', '/')
$appRoot = Join-Path $repoRoot 'NewsBulletin'
$testClass = 'com.example.newsbulletin.LeakReproductionInstrumentationTest'
$testName = 'threeFollowPassagesAndAboutReturnDoNotRetainDestroyedActivities'
$gradleTask = ':app:connectedDebugAndroidTest'

function Invoke-Git([string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    $result = @(& git -c "safe.directory=$repoSafe" -C $repoRoot @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Git $($Arguments -join ' ') failed: $($result -join ' ')" }
    return $result
}

function Assert-CleanCheckout([string]$AllowedOutput) {
    $status = @(Invoke-Git -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
    $blocked = @($status | Where-Object {
        $path = $_.Substring(3).Replace('\', '/')
        -not ($AllowedOutput -and $path.StartsWith($AllowedOutput + '/', [StringComparison]::Ordinal))
    })
    if ($blocked.Count -gt 0) { throw "Checkout has tracked changes or untracked files; preserve them before switching states: $($blocked -join '; ')" }
}

function Get-ReportResult([string]$ReportDirectory, [string]$Version) {
    $files = @(Get-ChildItem -LiteralPath $ReportDirectory -Filter '*.xml' -File -Recurse)
    if ($files.Count -eq 0) { throw "${Version}: no fresh JUnit XML was saved." }
    $cases = @()
    foreach ($file in $files) {
        try { [xml]$document = Get-Content -LiteralPath $file.FullName -Raw }
        catch { throw "${Version}: invalid JUnit XML in $($file.Name): $_" }
        $cases += @($document.SelectNodes('//testcase'))
    }
    $expected = @($cases | Where-Object { $_.classname -eq $testClass -and $_.name -eq $testName })
    if ($expected.Count -ne 1) { throw "${Version}: expected test must occur exactly once; found $($expected.Count)." }
    $bad = @($cases | Where-Object { $_.SelectNodes('failure|error|skipped').Count -gt 0 })
    $failures = @($expected[0].SelectNodes('failure'))
    $errors = @($expected[0].SelectNodes('error'))
    $skips = @($expected[0].SelectNodes('skipped'))
    return [pscustomobject]@{
        CaseCount = $cases.Count
        FailureCount = $bad.Count
        ExpectedFailures = $failures.Count
        ExpectedErrors = $errors.Count
        ExpectedSkips = $skips.Count
        FailureText = (($failures | ForEach-Object { $_.InnerText }) -join "`n")
    }
}

function Assert-Result([string]$Version, [int]$GradleExit, $Report, [string]$LogText) {
    if ($Report.ExpectedSkips -ne 0 -or $Report.ExpectedErrors -ne 0) { throw "${Version}: expected test was skipped or errored." }
    if ($Version -eq 'baseline') {
        if ($GradleExit -eq 0 -or $Report.CaseCount -ne 1 -or $Report.FailureCount -ne 1 -or $Report.ExpectedFailures -ne 1) {
            throw 'Baseline: expected exactly one failed test and a nonzero Gradle exit.'
        }
        $failure = $Report.FailureText
        $markers = @('NoLeakAssertionFailedError', '1 APPLICATION LEAKS', 'UpdateRegistry.listeners', 'ArticleActivity$onCreate$1$listener$1', 'this$0', 'ArticleActivity', 'mDestroyed = true', 'LeakAssertions.assertNoLeaks')
        foreach ($marker in $markers) {
            if (-not $failure.Contains($marker)) { throw "Baseline: missing LeakCanary assertion or reference-chain marker: $marker" }
        }
        return 'expected LeakCanary assertion failure with retained destroyed ArticleActivity'
    }
    if ($GradleExit -ne 0 -or $Report.CaseCount -ne 1 -or $Report.FailureCount -ne 0 -or $Report.ExpectedFailures -ne 0) {
        throw 'Correction: Gradle and the expected JUnit test must pass without other failures.'
    }
    if ($LogText.Contains('No watched objects after triggering an explicit GC.')) {
        return 'test passed; explicit LeakCanary assertion outcome captured'
    }
    return 'test passed; explicit LeakCanary diagnostic output missing (diagnostic conclusion inconclusive)'
}

function Invoke-Device([string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    $response = @(& $script:adbExe -s $DeviceSerial @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "adb $($Arguments -join ' ') failed: $($response -join ' ')" }
    return ($response -join "`n").Trim()
}

function Invoke-InstrumentedRun([string]$Version, [string]$Directory) {
    New-Item -ItemType Directory -Path $Directory -ErrorAction Stop | Out-Null
    Invoke-Device -Arguments @('shell', 'am', 'force-stop', 'com.example.newsbulletin') | Out-Null
    Invoke-Device -Arguments @('logcat', '-c') | Out-Null
    $reportSource = Join-Path $appRoot 'app/build/outputs/androidTest-results/connected/debug'
    $started = (Get-Date).ToUniversalTime()
    $gradleLog = Join-Path $Directory 'gradle-output.txt'
    Push-Location $appRoot
    try {
        & (Join-Path $appRoot 'gradlew.bat') $gradleTask '--console=plain' *> $gradleLog
        $gradleExit = $LASTEXITCODE
    } finally { Pop-Location }
    $ErrorActionPreference = 'Continue'
    $rawLog = @(& $script:adbExe -s $DeviceSerial logcat -d -v brief -s 'LeakCanary:D' 'LeakStudy:D' 'TestRunner:E' '*:S' 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "${Version}: could not collect Logcat." }
    $selected = @($rawLog | Where-Object {
        $_ -match '^D/LeakStudy.*(screen=|event=)' -or
        $_ -match '^D/LeakCanary.*(No watched objects after triggering an explicit GC|detecting leaks)' -or
        $_ -match '^E/TestRunner.*NoLeakAssertionFailedError'
    })
    $selected | Set-Content -LiteralPath (Join-Path $Directory 'selected-logcat.txt') -Encoding UTF8
    if (-not (Test-Path $reportSource)) { throw "${Version}: no JUnit report directory; Gradle exit $gradleExit. Inspect build and device output." }
    $reports = @(Get-ChildItem -LiteralPath $reportSource -Filter '*.xml' -File -Recurse | Where-Object { $_.LastWriteTimeUtc -ge $started })
    if ($reports.Count -eq 0) { throw "${Version}: no JUnit XML; Gradle exit $gradleExit. Inspect build and device output." }
    $junitDir = Join-Path $Directory 'junit'
    New-Item -ItemType Directory -Path $junitDir | Out-Null
    foreach ($report in $reports) {
        $relative = $report.FullName.Substring($reportSource.Length).TrimStart('\', '/')
        $destination = Join-Path $junitDir $relative
        New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
        Copy-Item -LiteralPath $report.FullName -Destination $destination
    }
    $parsed = Get-ReportResult $junitDir $Version
    $runRecord = [ordered]@{ Version = $Version; SourceCommit = @(Invoke-Git -Arguments @('rev-parse', 'HEAD'))[0]; GradleExit = $gradleExit; TestCases = $parsed.CaseCount; FailedOrSkippedCases = $parsed.FailureCount; Result = 'pending validation' }
    $recordPath = Join-Path $Directory 'run-result.json'
    try { $runRecord.Result = Assert-Result $Version $gradleExit $parsed ($selected -join "`n") }
    catch { $runRecord.Result = "rejected: $($_.Exception.Message)"; $runRecord | ConvertTo-Json | Set-Content -LiteralPath $recordPath -Encoding UTF8; throw }
    $runRecord | ConvertTo-Json | Set-Content -LiteralPath $recordPath -Encoding UTF8
    return [pscustomobject]$runRecord
}

function Invoke-Reproduction {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is required.' }
    if (-not (Get-Command java -ErrorAction SilentlyContinue)) { throw 'JDK 17 is required.' }
    $ErrorActionPreference = 'Continue'
    $javaVersion = @(& java -version 2>&1) -join ' '
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0 -or $javaVersion -notmatch 'version "(\d+)\.' -or [int]$Matches[1] -lt 17) { throw "JDK 17 or newer is required; found: $javaVersion" }
    if (-not (Test-Path (Join-Path $appRoot 'gradlew.bat'))) { throw 'Gradle wrapper is missing.' }
    if (-not $SdkPath) {
        if ($env:ANDROID_HOME -and (Test-Path -LiteralPath $env:ANDROID_HOME -PathType Container)) { $SdkPath = $env:ANDROID_HOME }
        elseif ($env:LOCALAPPDATA) { $SdkPath = Join-Path $env:LOCALAPPDATA 'Android/Sdk' }
    }
    if (-not $SdkPath -or -not (Test-Path -LiteralPath $SdkPath -PathType Container)) { throw 'Valid Android SDK path required. Pass -SdkPath or set ANDROID_HOME.' }
    $script:adbExe = Join-Path $SdkPath 'platform-tools/adb.exe'
    if (-not (Test-Path $script:adbExe)) { throw "adb.exe missing from SDK: $SdkPath" }
    if (-not (Test-Path (Join-Path $SdkPath 'platforms/android-36'))) { throw 'Android SDK platform 36 is missing.' }
    $env:ANDROID_HOME = (Resolve-Path -LiteralPath $SdkPath).Path
    if (-not $DeviceSerial.StartsWith('emulator-')) { throw 'Select an emulator serial, such as emulator-5554.' }
    $ErrorActionPreference = 'Continue'
    $devices = @(& $script:adbExe devices 2>&1)
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0) { throw 'Could not list adb devices.' }
    $connected = @($devices | Where-Object { $_ -match '^\S+\s+device(?:\s|$)' } | ForEach-Object { ($_ -split '\s+')[0] })
    if ($connected.Count -ne 1 -or $connected[0] -ne $DeviceSerial) { throw "Selected emulator must be the only connected device; connected count: $($connected.Count)." }
    if ((Invoke-Device -Arguments @('get-state')) -ne 'device' -or (Invoke-Device -Arguments @('shell', 'getprop', 'sys.boot_completed')) -ne '1') { throw 'Selected emulator is not ready.' }
    if (@(Invoke-Git -Arguments @('branch', '--show-current'))[0] -ne 'main') { throw 'Start from main so the corrected source state is unambiguous.' }
    $initialCommit = @(Invoke-Git -Arguments @('rev-parse', 'HEAD'))[0]
    $correctedCommit = $initialCommit
    $baselineCommit = @(Invoke-Git -Arguments @('rev-parse', 'baseline-leak^{commit}'))[0]
    $root = if ($OutputRoot) { [IO.Path]::GetFullPath($OutputRoot) } else { Join-Path $repoRoot 'evidence' }
    $relativeOutput = $null
    if ($root.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        $relativeOutput = $root.Substring($repoRoot.Length + 1).Replace('\', '/')
    }
    Assert-CleanCheckout $null
    $runDir = Join-Path $root ("reproduction-{0}-{1}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), ([guid]::NewGuid().ToString('N').Substring(0, 8)))
    if (Test-Path -LiteralPath $runDir) { throw "Evidence directory already exists: $runDir" }
    New-Item -ItemType Directory -Path $runDir -Force -ErrorAction Stop | Out-Null
    $allowed = if ($relativeOutput) { "$relativeOutput/$([IO.Path]::GetFileName($runDir))" } else { $null }
    $metadata = [ordered]@{ StartedUtc = (Get-Date).ToUniversalTime().ToString('o'); DeviceSerial = $DeviceSerial; TestClass = $testClass; TestName = $testName; Command = ".\\gradlew.bat $gradleTask --console=plain"; InitialBranch = 'main'; InitialCommit = $initialCommit; BaselineCommit = $baselineCommit; CorrectedCommit = $correctedCommit; Runs = @(); Status = 'incomplete' }
    $problem = $null
    try {
        Assert-CleanCheckout $allowed
        Invoke-Git -Arguments @('switch', '--detach', $baselineCommit) | Out-Null
        $metadata.Runs += Invoke-InstrumentedRun 'baseline' (Join-Path $runDir 'baseline')
        Assert-CleanCheckout $allowed
        Invoke-Git -Arguments @('switch', 'main') | Out-Null
        if (@(Invoke-Git -Arguments @('rev-parse', 'HEAD'))[0] -ne $correctedCommit) { throw 'main moved during reproduction.' }
        $metadata.Runs += Invoke-InstrumentedRun 'corrected' (Join-Path $runDir 'corrected')
        $metadata.Status = 'validated'
    } catch { $problem = $_; $metadata.Status = 'failed'; $metadata.Error = $_.Exception.Message }
    finally {
        try {
            Assert-CleanCheckout $allowed
            Invoke-Git -Arguments @('switch', 'main') | Out-Null
            if (@(Invoke-Git -Arguments @('rev-parse', 'HEAD'))[0] -ne $initialCommit) { throw 'main no longer points to the starting commit.' }
        } catch {
            $ErrorActionPreference = 'Continue'
            $state = @(& git -c "safe.directory=$repoSafe" -C $repoRoot status --short --branch 2>&1) -join '; '
            $head = @(& git -c "safe.directory=$repoSafe" -C $repoRoot rev-parse HEAD 2>&1) -join '; '
            $metadata.RestorationError = "$_; repository state: HEAD=$head; $state; after preserving any new changes, recovery command: git -C '$repoRoot' switch main"
            if (-not $problem) { $problem = $_ }
        }
        $metadata.FinishedUtc = (Get-Date).ToUniversalTime().ToString('o')
        $metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runDir 'metadata.json') -Encoding UTF8
    }
    Write-Host "Evidence: $runDir"
    if ($metadata.RestorationError) { Write-Error $metadata.RestorationError }
    if ($problem) { throw $problem }
    $metadata.Runs | ForEach-Object { Write-Host "$($_.Version): $($_.Result)" }
}

if ($MyInvocation.InvocationName -ne '.') { Invoke-Reproduction }
