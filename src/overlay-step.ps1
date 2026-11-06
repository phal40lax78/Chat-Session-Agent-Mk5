# A step of the overlay's native collector (native/SPEC.md 3.9): what it
# starts, with no window, for a piece of the look still written in
# PowerShell, as
#   <powershell> -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <this file>
#     -In <D>\native\ostep-<collector pid>-<n>.in.json -Out <D>\native\ostep-<collector pid>-<n>.out.json
#     -Watcher <the collector's pid> -WatcherStart <its start, UTC ticks>
# Not a part of the script: it loads the parts the step reaches (the
# loader's CHATQ_ROLE ostep; ostep-act for the Rust host's acting verbs,
# the op read from In first), runs the one op In names
# (Invoke-ChatOverlayStep, src/overlay-data.ps1) and exits. Exit 3 is a
# load that failed; any op's outcome is in Out, with exit 0.
param([string]$In, [string]$Out, [int]$Watcher, [int64]$WatcherStart)
$ProgressPreference = 'SilentlyContinue'
$env:CHATQ_OVERLAY = '1'
$stepIn = try { Get-Content -LiteralPath $In -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $null }
$stepAct = $stepIn -and [string]$stepIn.op -cin 'delete', 'archive', 'reload-answer', 'config', 'auto-on', 'auto-ask', 'auto-off', 'auto-notice', 'crash-on', 'crash-off', 'answered-jobs', 'auto-chip', 'live-alert', 'phone-extras', 'act-look', 'look-queue', 'ask-answer', 'ask-phone', 'ask-watch', 'startup'
$env:CHATQ_ROLE = if ($stepAct) { 'ostep-act' } else { 'ostep' }
# Windows PowerShell started by a collector a pwsh 7 host started inherits
# pwsh 7's module path: its own again, as src/ask-hook.ps1 gives itself
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $env:PSModulePath = [Environment]::GetFolderPath('MyDocuments') + '\WindowsPowerShell\Modules;' + $env:ProgramFiles + '\WindowsPowerShell\Modules;' +
    $PSHOME + '\Modules;' + [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
}
try { . (Join-Path (Split-Path -Parent $PSScriptRoot) 'Chat-Session-Agent-Mk5.ps1') *> $null }
catch { exit 3 }
Remove-Item -LiteralPath 'env:PSExecutionPolicyPreference', 'env:CHATQ_OVERLAY' -EA SilentlyContinue

# A step compiles nothing and asks WMI nothing - each costs it seconds and
# tens of MB: what would is refused, and counted for the collector's log.
# The idle time and the process table are what it is fed instead.
$script:ChatOverlayStepRefused = @{ compiles = 0; wmi = 0 }
function Invoke-ChatCompile { $script:ChatOverlayStepRefused.compiles++; throw 'an overlay step compiles nothing' }
function Get-CimInstance { $script:ChatOverlayStepRefused.wmi++; throw 'an overlay step asks WMI nothing' }
function Get-WmiObject { $script:ChatOverlayStepRefused.wmi++; throw 'an overlay step asks WMI nothing' }
$stepArgs = if ($stepIn) { $stepIn.args } else { $null }
if ($stepArgs -and $stepArgs.PSObject.Properties['idleSeconds'] -and $null -ne $stepArgs.idleSeconds) { $script:ChatqIdleSeam = [double]$stepArgs.idleSeconds }
if ($stepArgs -and $stepArgs.PSObject.Properties['procs']) {
    $stepTable = @(foreach ($p in @($stepArgs.procs)) {
            if (-not $p) { continue }
            $start = ConvertTo-ChatqDate (ConvertFrom-ChatqStepText $p.start)
            [pscustomobject]@{ ProcessId = [int]$p.pid; ParentProcessId = [int]$p.parent; Name = "$($p.name).exe"; CreationDate = $(if ($start) { $start.ToLocalTime() } else { $null }) }
        })
    $script:ChatProcessTableSeam = { $stepTable }.GetNewClosure()
}

# The parent test: the collector is alive while a process has its pid and
# its start time, to the second. None, or one whose start cannot be read,
# is a pid reused or the collector gone, and a step that finds it so ends
# itself.
$script:ChatqStepParent = {
    try { [math]::Abs((Get-Process -Id $Watcher -EA Stop).StartTime.ToUniversalTime().Ticks - $WatcherStart) -le 10000000 } catch { $false }
}.GetNewClosure()

if ($stepAct) { Invoke-ChatOverlayStep -In $In -Out $Out -Act ${function:Invoke-ChatOverlayActStep} }
else { Invoke-ChatOverlayStep -In $In -Out $Out }
exit 0
