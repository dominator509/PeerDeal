[CmdletBinding()]
param(
    [string]$ExecutablePath = '',
    [ValidateRange(1, 300)]
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    # RTK's PowerShell bridge can invoke a script with an empty PSScriptRoot.
    $scriptRoot = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($scriptRoot) -and
        -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
        $scriptRoot = Join-Path (Get-Location).Path 'tool'
    }
    $ExecutablePath = Join-Path $scriptRoot '..\build\windows\x64\runner\Debug\peerdeal_desktop.exe'
}
$resolvedExecutablePath = [System.IO.Path]::GetFullPath($ExecutablePath)
if (-not (Test-Path -LiteralPath $resolvedExecutablePath -PathType Leaf)) {
    throw "Windows native host smoke executable was not found: $resolvedExecutablePath"
}

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $resolvedExecutablePath
$startInfo.WorkingDirectory = [System.IO.Path]::GetDirectoryName($resolvedExecutablePath)
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true

$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo
$started = $false
try {
    $started = $process.Start()
    if (-not $started) {
        throw "Windows native host smoke process did not start."
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try {
            $process.Kill($true)
        } catch {
            Write-Warning "Windows native host smoke process did not terminate cleanly after timeout: $($_.Exception.Message)"
        }
        throw "Windows native host smoke timed out after $TimeoutSeconds seconds."
    }

    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    if ($stdout) {
        Write-Output $stdout.TrimEnd()
    }
    if ($stderr) {
        [Console]::Error.WriteLine($stderr.TrimEnd())
    }
    if ($process.ExitCode -ne 0) {
        throw "Windows native host smoke exited with code $($process.ExitCode)."
    }
    if ($stdout -notmatch 'PEERDEAL_NATIVE_HOST_SMOKE_PASS') {
        throw 'Windows native host smoke did not emit its required pass marker.'
    }
} finally {
    if ($started -and -not $process.HasExited) {
        try {
            $process.Kill($true)
        } catch {
            Write-Warning "Windows native host smoke cleanup failed: $($_.Exception.Message)"
        }
    }
    $process.Dispose()
}
