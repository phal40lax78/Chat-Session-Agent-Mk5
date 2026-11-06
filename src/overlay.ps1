# Chat Session Agent Mk.5, src/overlay.ps1: dot-sourced by Chat-Session-Agent-Mk5.ps1
# in its turn, never on its own - see the list there.

#region overlay: the command ---------------------------------------------------

function Test-ChatOverlayAlive {
    return (Test-ChatqLockHeld $script:ChatOverlayLockPath)
}

function Test-ChatOverlayAutoStart {
    # on a system with a panel to draw, unless chatoverlay -AutoStart off -
    # on by default on Windows (Get-ChatOverlayConfig), so a missing
    # config.json, or one with no such key, reads as on there too. One that
    # is there but does not read is off: it may be the file that says off,
    # and a panel nobody wanted is worse than one not started.
    if (-not $script:ChatqIsWindows -and -not $script:ChatIsMac) { return $false }
    if (Test-Path -LiteralPath $script:ChatqConfigPath) {
        $cfg = Read-ChatqJson $script:ChatqConfigPath
        if ($null -eq $cfg) { return $false }
        return [bool](Get-ChatOverlayConfig $cfg).autoStart
    }
    return [bool](Get-ChatOverlayConfig).autoStart
}

function Start-ChatOverlayAuto {
    <#
    The overlay started if it should be and is not running: what a new shell
    and every VS Code window (the extension, through setup.js) do as they
    open. Prints exactly one line for the caller to read - started, running,
    off (not to start here, -AutoStart off, no chatq-overlay.exe for this
    version, or closed by hand since this sign-in) or failed - and nothing else, so the launch's own words are
    kept off stdout. Those words say why a launch failed, so they go to
    overlay.log instead: nobody sees a shell's start or the extension's call.
    A close by hand is off rather than a word of its own: the extension
    takes these four, and to it both mean the same - nothing to start.
    #>
    $say = 'failed'
    $why = $null
    try {
        if (-not (Test-ChatOverlayAutoStart)) { $say = 'off' }
        elseif (Test-ChatOverlayAlive) { $say = 'running' }
        # the x, the tray's Quit or chatoverlay -Stop, since this sign-in:
        # closed until the next, or until chatoverlay starts it
        elseif (Test-ChatOverlayClosedByHand) { $say = 'off' }
        else {
            # Write-Host is the information stream: taken apart from what
            # the launch returns
            $out = @(Start-ChatOverlayProcess 6>&1)
            $said = @($out | Where-Object { $_ -is [System.Management.Automation.InformationRecord] } | ForEach-Object { ([string]$_.MessageData).Trim() } | Where-Object { $_ })
            $ok = @($out | Where-Object { $_ -isnot [System.Management.Automation.InformationRecord] })
            if ($ok.Count -and $ok[-1] -eq $true) { $say = 'started' }
            # no chatq-overlay.exe for this version: nothing to start, said
            # once a version in overlay.log (Start-ChatOverlayProcess), not a failure
            elseif ($script:ChatOverlayNoExe) { $say = 'off' }
            else { $why = if ($said.Count) { $said -join ' / ' } else { 'the launch gave no reason' } }
        }
    }
    catch { $say = 'failed'; $why = $_.Exception.Message }
    if ($say -eq 'failed') { Write-ChatOverlayLog "auto-start failed: $why" }
    Write-Output $say
}

function ConvertFrom-ChatOverlayHotkey {
    <#
    'Ctrl+Alt+Shift+O' -> @{ Mods; Vk; Text } for RegisterHotKey, and 'none'
    -> $null. Throws on anything it cannot read, so a typo shows when it is
    set rather than when the overlay next starts.
    #>
    param([string]$Text)
    $t = ([string]$Text).Trim()
    if (-not $t -or $t -eq 'none') { return $null }
    $mods = 0
    $vk = $null
    foreach ($p in @($t -split '\+' | ForEach-Object { $_.Trim() })) {
        if ($p -match '^(ctrl|control)$') { $mods = $mods -bor 2 }
        elseif ($p -eq 'alt') { $mods = $mods -bor 1 }
        elseif ($p -eq 'shift') { $mods = $mods -bor 4 }
        elseif ($p -match '^win(dows)?$') { $mods = $mods -bor 8 }
        elseif ($p -match '^f([1-9]|1[0-9]|2[0-4])$') { $vk = 0x6F + [int]$Matches[1] }
        elseif ($p -match '^[a-z]$') { $vk = [int][char]$p.ToUpperInvariant() }
        elseif ($p -match '^[0-9]$') { $vk = 0x30 + [int]$p }
        else { throw "cannot read '$p' in hotkey '$t' - use e.g. Ctrl+Alt+Shift+O, Ctrl+Win+F9 or none" }
    }
    if ($null -eq $vk) { throw "hotkey '$t' names no key - e.g. Ctrl+Alt+Shift+O" }
    if (-not $mods) { throw "hotkey '$t' needs Ctrl, Alt, Shift or Win with the key" }
    return @{ Mods = $mods; Vk = $vk; Text = $t }
}

function Get-ChatOverlayLaunch {
    <#
    How the overlay process is started: @{ Exe; Args; Command }. On Windows
    always Windows PowerShell with -STA, even from pwsh: WPF needs an STA
    thread, and every Windows has powershell.exe. The command carries the
    environment it needs, and a failure before the log function exists still
    reaches the log. CHATQ_OVERLAY marks the process as the overlay - no key
    bindings, no watches - and stays, for every process it starts to inherit;
    CHATQ_ALLPARTS loads the parts only it draws from - the console's, the
    Mac's - and goes once they are in, so none of those loads them too.
    -Open console: the console opens as it starts - a command left for it
    now would be swept away as it takes its lock. -Console: the Rust host's
    console, in a process of its own (Start-ChatConsoleHost) that loads
    every part, -HostPid the host that starts it, -ConsoleOpen how it was
    asked for (show, or key: its hotkey). -Rust (with -UiExe, the exe): the
    Rust host's start, watched - the command starts that exe first, before
    anything is loaded, so it keeps the caller's environment and starts as
    fast as ever, keeps its process, then loads the loader and runs
    Watch-ChatOverlayRustStart, with no CHATQ_ALLPARTS: an exe that exits
    before it takes the lock is a line in overlay.log. The process is hidden
    and ends with the watch. Windows has no other start since 0.12.0;
    without -Rust the entry is the Mac's.
    #>
    param([string]$Path = $script:ChatqScriptPath, [ValidateSet('', 'console')][string]$Open = '', [string]$UiExe = '',
        [switch]$Console, [int]$HostPid = 0, [ValidateSet('show', 'key')][string]$ConsoleOpen = 'show', [switch]$Rust)
    $q = { param($s) "'" + [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent([string]$s) + "'" }
    $first = ''
    if ($Rust -and $UiExe -and -not $Console) {
        $first = '$p = $null; try { $p = Start-Process -FilePath ' + (& $q $UiExe) + ' -ArgumentList ' + (& $q (Get-ChatOverlayRustArgs $Open)) +
        ' -WindowStyle Hidden -WorkingDirectory ' + (& $q ([WildcardPattern]::Escape($HOME))) + ' -PassThru -EA Stop; $null = $p.Handle } catch { $p = $_.Exception.Message }; '
    }
    $pre = if ($first) { '$env:CHATQ_OVERLAY=''1''; ' } else { '$env:CHATQ_OVERLAY=''1''; $env:CHATQ_ALLPARTS=''1''; ' }
    foreach ($n in 'CLAUDE_CONFIG_DIR', 'CODEX_HOME', 'CHATQ_CLAUDE', 'CHATQ_CODEX', 'CHATQ_GH') {
        $v = [Environment]::GetEnvironmentVariable($n)
        if ($v) { $pre += "`$env:$n=$(& $q $v); " }
    }
    $entry = if ($Console) { "[void](Start-ChatConsoleHost -HostPid $HostPid -Open '$ConsoleOpen')" }
    elseif ($first) { "[void](Watch-ChatOverlayRustStart `$p -UiExe $(& $q $UiExe) -Open '$Open')" }
    else { 'Start-ChatOverlayMacHost' }
    $log = Join-Path $script:ChatqLogDir 'overlay.log'
    $what = if ($Console) { 'console' } else { 'overlay' }
    $cmd = $first + $pre + "try { . $(& $q $Path); Remove-Item -LiteralPath 'env:CHATQ_ALLPARTS' -EA SilentlyContinue; $entry } catch { try { [void][IO.Directory]::CreateDirectory($(& $q $script:ChatqLogDir)); " +
    "[IO.File]::AppendAllText($(& $q $log), (Get-Date).ToString('o') + '  $what failed to start: ' + `$_.Exception.Message + [char]10) } catch {} }"
    $enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cmd))
    if ($script:ChatqIsWindows) {
        $root = if ($env:SystemRoot) { $env:SystemRoot } else { 'C:\Windows' }
        $exe = Join-Path $root 'System32\WindowsPowerShell\v1.0\powershell.exe'
        return [pscustomobject]@{ Exe = $exe; Args = @('-NoProfile', '-NonInteractive', '-STA', '-EncodedCommand', $enc); Command = $cmd }
    }
    return [pscustomobject]@{ Exe = (Get-Process -Id $PID).Path; Args = @('-NoProfile', '-NonInteractive', '-EncodedCommand', $enc); Command = $cmd }
}

function Get-ChatOverlayPanelVersion {
    # the version the script on disk says - a restart onto new code is that
    # code's - else this process's own
    $ver = Get-ChatqLoaderVersion $script:ChatqScriptPath
    if (-not $ver) { $ver = $script:ChatVersion }
    return [string]$ver
}

# Deferred: DEFERRED.md "Signing chatq-overlay.exe"
# Deferred: DEFERRED.md "The panel exe for install.ps1"
function Get-ChatOverlayPanelExe {
    <#
    The overlay's exe on Windows: chatq-overlay.exe staged beside the script
    under bin/<version>/x86_64-pc-windows-msvc/, as the VSIX puts it there
    and as chatqd is looked for (Get-ChatqNativePath) - the version the
    script on disk says, so a restart onto new code starts the new code's
    exe. A git checkout's own build (Get-ChatOverlayPanelBuild) comes first
    while its --version is that version and it is newer than the staged
    one: the Overlay task builds it there, so a working-tree build never
    sits in bin/ looking like the release. '' off Windows, or where
    neither is there - Start-ChatOverlayProcess says so (Get-ChatOverlayPanelMissing).
    #>
    if (-not $script:ChatqIsWindows -or -not $script:ChatRoot) { return '' }
    return (Find-ChatOverlayPanelExe $script:ChatRoot (Get-ChatOverlayPanelVersion))
}

function Find-ChatOverlayPanelExe {
    # the panel's exe for -Version under -Root: the checkout's build
    # while it says -Version and is newer than the one staged in bin/
    # (the Overlay task builds the working tree there and stages nothing,
    # so bin/ holds only what native/stage.ps1 staged), else the staged
    # one, else ''. A start (Get-ChatOverlayPanelExe) and a restart onto
    # new code (the Rust host's, through Start-ChatOverlayProcess) both
    # ask here, so they agree.
    param([string]$Root, [string]$Version)
    $exe = [System.IO.Path]::Combine($Root, 'bin', $Version, 'x86_64-pc-windows-msvc', 'chatq-overlay.exe')
    $build = Get-ChatOverlayPanelBuild $Root
    $staged = [System.IO.File]::Exists($exe)
    $newer = [System.IO.File]::Exists($build) -and (-not $staged -or [System.IO.File]::GetLastWriteTimeUtc($build) -gt [System.IO.File]::GetLastWriteTimeUtc($exe))
    if ($newer -and (Get-ChatOverlayBuildVersion $build) -ceq $Version) { return $build }
    if ($staged) { return $exe }
    return ''
}

function Get-ChatOverlayPanelBuild {
    # where a git checkout's release build of the panel lands: cargo's own
    # target folder for native/overlay, its workspace, built from the
    # repo's root as TESTING.md S60 builds it but with no --target-dir
    param([string]$Root = $script:ChatRoot)
    return [System.IO.Path]::Combine([string]$Root, 'native', 'overlay', 'target', 'x86_64-pc-windows-msvc', 'release', 'chatq-overlay.exe')
}

function Get-ChatOverlayBuildVersion {
    <#
    The version chatq-overlay.exe at -Exe says it is, asked as
    extension/build.js asks before it stages one: its one line,
    chatq-overlay <version>. '' for no exe, any other line, or none in
    10 s. Kept for the process by the exe's path, size and time written:
    every start and restart looks (Get-ChatOverlayPanelExe), and a rebuild
    in place is a new size or time, so asked again. One that did not end
    in time, or would not start, is kept for a minute only: an antivirus'
    first look at a new exe is slow or blocks it, and the linker may hold
    it still, but a hung one must not stall every look by 10 s - the
    restart onto new code asks too (Start-ChatOverlayProcess), so a hung
    build holds that up by 10 s at most once a minute.
    #>
    param([string]$Exe)
    try { $fi = [System.IO.FileInfo]::new($Exe) } catch { return '' }
    if (-not $fi.Exists) { return '' }
    $key = "$($fi.FullName)|$($fi.Length)|$($fi.LastWriteTimeUtc.Ticks)"
    if (-not $script:ChatOverlayBuildVersions) { $script:ChatOverlayBuildVersions = @{} }
    $was = $script:ChatOverlayBuildVersions[$key]
    if ($was -and [datetime]::UtcNow.Ticks -lt $was.Until) { return $was.V }
    $said = ''
    $done = $true
    $p = $null
    try {
        if ($script:ChatOverlayBuildVersionSeam) {
            # tests: no real exe; $null stands for none in time
            $r = & $script:ChatOverlayBuildVersionSeam $fi.FullName
            if ($null -eq $r) { $done = $false } else { $said = [string]$r }
        }
        else {
            $si = [System.Diagnostics.ProcessStartInfo]::new($fi.FullName, '--version')
            $si.UseShellExecute = $false
            $si.RedirectStandardOutput = $true
            $si.CreateNoWindow = $true
            $p = [System.Diagnostics.Process]::Start($si)
            $out = $p.StandardOutput.ReadToEndAsync()
            $done = $p.WaitForExit(10000)
            if ($done) { $said = [string]$out.Result } else { try { $p.Kill() } catch {} }
        }
    }
    catch { $done = $false }
    finally { if ($p) { $p.Dispose() } }
    $v = if ($said.Trim() -match '^chatq-overlay (\d+\.\d+\.\d+)$') { $Matches[1] } else { '' }
    $until = if ($done) { [datetime]::MaxValue.Ticks } else { [datetime]::UtcNow.AddMinutes(1).Ticks }
    $script:ChatOverlayBuildVersions[$key] = [pscustomobject]@{ V = $v; Until = $until }
    return $v
}

function Get-ChatOverlayPanelMissing {
    <#
    Why there is no overlay for -Version, and what to do: @{ Log; Fix }.
    overlay.log's line, with the paths and what is there instead - other
    versions' exes under bin/, the checkout's build
    (Get-ChatOverlayPanelBuild) at another version, a bump nothing staged or
    rebuilt for - and the what-to-do alone, for the shell: in a git checkout
    the cargo build, else the VS Code extension or the exe's path, which is
    all a zip install can do (DEFERRED.md "The panel exe for install.ps1").
    #>
    param([string]$Version)
    $leaf = 'x86_64-pc-windows-msvc\chatq-overlay.exe'
    $bin = Join-Path ([string]$script:ChatRoot) 'bin'
    $want = Join-Path (Join-Path $bin $Version) $leaf
    $others = @(Get-ChildItem -LiteralPath $bin -Directory -EA SilentlyContinue | Where-Object { $_.Name -cne $Version -and [System.IO.File]::Exists((Join-Path $_.FullName $leaf)) } | ForEach-Object { $_.Name })
    $build = Get-ChatOverlayPanelBuild
    $hasBuild = [System.IO.File]::Exists($build)
    $built = if ($hasBuild) { Get-ChatOverlayBuildVersion $build } else { '' }
    $cmd = 'cargo build --release --manifest-path native/overlay/Cargo.toml --config native/.cargo/config.toml --target x86_64-pc-windows-msvc'
    $repo = [System.IO.File]::Exists([System.IO.Path]::Combine([string]$script:ChatRoot, 'native', 'overlay', 'Cargo.toml'))
    $had = @()
    if ($others.Count) { $had += "bin has $($others -join ', ')" }
    if ($hasBuild) { $had += "$build is $(if ($built) { $built } else { 'no version it says' })" }
    $fix = if ($repo) { "build it from $($script:ChatRoot): $cmd" } else { "install the VS Code extension, or put chatq-overlay.exe at $want" }
    return [pscustomobject]@{
        Log = "no overlay for $Version - $want is not there$(if ($had.Count) { " and $($had -join '; ')" }) - $fix"
        Fix = $fix
    }
}

function Clear-ChatOverlayHostFuse {
    # chatoverlay started by name: the Rust host's unclean starts forgotten
    # (host-starts.json), so a start asked for always tries - it would
    # otherwise give up at once on the 3 it counted (native/overlay/collect/src/host)
    Remove-Item -LiteralPath (Get-ChatqNativeFile 'host-starts.json') -Force -EA SilentlyContinue
}

function Write-ChatOverlayPsHostNote {
    # Once a version, on Windows: config.json's overlay.host ps or shadow, its
    # overlay.panel ps, or CHATQ_RUST_HOST=0 in the shell asks for
    # PowerShell's host or the WPF panel, which are gone since 0.12.0 - the
    # Rust host is the only one. A log line, not a balloon: nothing is
    # wrong, and config.json (and its vector) stay as they are. The raw
    # words, not Get-ChatOverlayConfig's, which read the default for none.
    # data/native/host-ps-said.json keeps the version said, as
    # panel-missing.json does.
    try {
        if (-not $script:ChatqIsWindows) { return }
        $cfg = Get-ChatqConfig
        $o = if ($cfg.PSObject.Properties['overlay'] -and $cfg.overlay) { $cfg.overlay } else { $null }
        $ask = @()
        if ($o -and $o.PSObject.Properties['host']) {
            $w = ([string]$o.host).ToLowerInvariant()
            if ($w -in 'ps', 'shadow') { $ask += "overlay.host $w" }
        }
        if ($o -and $o.PSObject.Properties['panel'] -and ([string]$o.panel).ToLowerInvariant() -eq 'ps') { $ask += 'overlay.panel ps' }
        if ($env:CHATQ_RUST_HOST -eq '0') { $ask += 'CHATQ_RUST_HOST=0' }
        if (-not $ask.Count) { return }
        $path = Get-ChatqNativeFile 'host-ps-said.json'
        $was = Read-ChatqJson $path
        if ($was -and [string]$was.version -ceq [string]$script:ChatVersion) { return }
        Save-ChatqJson $path ([ordered]@{ version = [string]$script:ChatVersion; at = Get-ChatqStamp })
        Write-ChatOverlayLog "$($ask -join ', ') is ignored on Windows since 0.12.0 - the Rust host, chatq-overlay.exe, is the only host and panel here" -Always
    }
    catch { Write-ChatOverlayLog "host note: $($_.Exception.Message)" }
}

function Start-ChatOverlayProcess {
    # just the launch; chatoverlay decides whether one is needed. On Windows
    # the Rust host: chatq-overlay.exe (Get-ChatOverlayPanelExe) given --host
    # and the data folder, -Open console as --open console, which takes the
    # same lock - its restarts come back through here. Its start is watched
    # until it holds the lock or exits (Get-ChatOverlayLaunch -Rust): this
    # returns once the hidden watcher is spawned, never waiting for the
    # watch, and an exe that dies first is a line in overlay.log. No exe for
    # this version starts nothing: one line a version in overlay.log, the
    # same at the shell, $false - and ChatOverlayNoExe, for
    # Start-ChatOverlayAuto, which says off for it. On macOS the Mac host.
    # -UiExe and -Wpf: ignored, there for the launch text of a copy older
    # than 0.12.0 - the Rust host's restart sent -Wpf.
    param([string]$Open = '', [string]$UiExe = '', [switch]$Wpf)
    $script:ChatOverlayNoExe = $false
    $exe = Get-ChatOverlayPanelExe
    $kind = if ($script:ChatqIsWindows) { 'rust' } else { 'ps' }
    if ($script:ChatOverlaySpawn) { return (& $script:ChatOverlaySpawn $Open $exe $kind) }   # tests: no real process
    if (-not $script:ChatqIsWindows -and -not $script:ChatIsMac) { return $false }
    if ($script:ChatqIsWindows) {
        Write-ChatOverlayPsHostNote
        if (-not $exe) {
            $script:ChatOverlayNoExe = $true
            $ver = Get-ChatOverlayPanelVersion
            $miss = Get-ChatOverlayPanelMissing $ver
            try {
                $said = Get-ChatqNativeFile 'panel-missing.json'
                $was = Read-ChatqJson $said
                if (-not ($was -and [string]$was.version -ceq $ver)) {
                    Save-ChatqJson $said ([ordered]@{ version = $ver; at = Get-ChatqStamp })
                    Write-ChatOverlayLog $miss.Log -Always
                }
            }
            catch { Write-ChatOverlayLog "panel missing note: $($_.Exception.Message)" }
            Write-Host "  cannot start the overlay: no chatq-overlay.exe for $ver - $($miss.Fix)" -ForegroundColor Yellow
            return $false
        }
    }
    $path = $script:ChatqScriptPath
    if (-not $path -or -not (Test-Path -LiteralPath $path)) {
        Write-Host '  cannot start the overlay: this shell does not know where Chat-Session-Agent-Mk5.ps1 is' -ForegroundColor Yellow
        return $false
    }
    $l = if ($script:ChatqIsWindows) { Get-ChatOverlayLaunch $path -Open $Open -UiExe $exe -Rust } else { Get-ChatOverlayLaunch $path -Open $Open }
    # in your home folder, never the caller's, escaped, and -EA Stop, for
    # the reasons in Start-ChatqWatcherProcess: the panel outlives the shell
    # or VS Code that started it, and every copy it restarts into
    $wd = [WildcardPattern]::Escape($HOME)
    try {
        # the Rust host's too: the hidden PowerShell starts its exe and watches it
        if ($script:ChatqIsWindows) { Start-Process -FilePath $l.Exe -ArgumentList $l.Args -WindowStyle Hidden -WorkingDirectory $wd -EA Stop | Out-Null }
        else {
            New-ChatqDir $script:ChatqLogDir
            Start-Process -FilePath 'nohup' -ArgumentList (@($l.Exe) + $l.Args) -WorkingDirectory $wd -EA Stop `
                -RedirectStandardOutput (Join-Path $script:ChatqLogDir 'overlay.out') `
                -RedirectStandardError (Join-Path $script:ChatqLogDir 'overlay.err') | Out-Null
        }
    }
    catch {
        Write-Host "  cannot start the overlay: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Get-ChatOverlayRustArgs {
    # the Rust host's command line: --host and the data folder, -Open console
    # as --open console. A trailing \ would escape the closing quote.
    param([string]$Open = '')
    return '--host "' + ([string]$script:ChatqData).TrimEnd('\') + '"' + $(if ($Open) { " --open $Open" })
}

function Start-ChatOverlayRustExe {
    # the Rust host's exe, hidden, in your home folder (as Start-ChatOverlayProcess
    # starts a host): its process, or the message of a start that failed. Never throws.
    param([string]$UiExe, [string]$Open = '')
    if ($script:ChatOverlayRustSpawnSeam) { return (& $script:ChatOverlayRustSpawnSeam $UiExe $Open) }   # tests
    try {
        $p = Start-Process -FilePath $UiExe -ArgumentList (Get-ChatOverlayRustArgs $Open) -WindowStyle Hidden -WorkingDirectory ([WildcardPattern]::Escape($HOME)) -PassThru -EA Stop
        $null = $p.Handle   # Windows PowerShell 5.1 keeps ExitCode only once the handle is taken
        return $p
    }
    catch { return $_.Exception.Message }
}

function Wait-ChatOverlayRustStart {
    <#
    Watches the Rust host's start, -Proc (Start-ChatOverlayRustExe), until it
    holds overlay.lock or ends: '' where the start is good, else why not.
    Good: the lock is held (by it, or by a host already running); it exited 0,
    in its own order (it found one running, or gave up on its own count of
    unclean starts); or it exited otherwise after it had written its start
    to host-starts.json - it took the lock and then died, which its own
    count has. Not: it would not start, it exited before it took the lock (a
    missing DLL, an early panic, a quarantine), or took none in -Ms, and is
    then killed.
    #>
    param($Proc, [int]$Ms = $script:ChatOverlayRustWatchMs)
    if ($Proc -is [string]) { return "it would not start: $Proc" }
    $until = (Get-Date).AddMilliseconds($Ms)
    while ($true) {
        if (Test-ChatOverlayAlive) { return '' }
        if ($Proc.HasExited) {
            $code = [int]$Proc.ExitCode
            if ($code -eq 0) { return '' }
            $st = Read-ChatqJson (Get-ChatqNativeFile 'host-starts.json')
            if ($st -and $st.PSObject.Properties['starts'] -and @($st.starts | Where-Object { [string]$_.pid -eq [string]$Proc.Id }).Count) { return '' }
            return "it exited ($code) before it took the lock"
        }
        if ((Get-Date) -ge $until) { break }
        Start-Sleep -Milliseconds 100
    }
    try { $Proc.Kill() } catch {}
    return "it took no lock in $([Math]::Round($Ms / 1000, 1)) s"
}

function Watch-ChatOverlayRustStart {
    # what the hidden watcher runs (Get-ChatOverlayLaunch -Rust): $true where
    # the Rust host started; else a line in overlay.log - chatoverlay or the
    # next shell tries again - and $false. -UiExe, -Open and -Fallback: ignored,
    # there for the launch text of a copy older than 0.12.0, whose failed
    # start fell back to PowerShell's host.
    param($Proc, [string]$UiExe, [string]$Open = '', [switch]$Fallback)
    $why = Wait-ChatOverlayRustStart $Proc
    if (-not $why) { return $true }
    Write-ChatOverlayLog "the Rust host did not start ($why) - chatoverlay tries again" -Always
    return $false
}

function Stop-ChatOverlay {
    # $true once it has let go of its lock
    if (-not (Test-ChatOverlayAlive)) { return $true }
    Send-ChatOverlayCommand 'stop'
    $until = (Get-Date).AddMilliseconds($script:ChatOverlayStopWaitMs)
    while ((Get-Date) -lt $until) {
        Start-Sleep -Milliseconds 200
        if (-not (Test-ChatOverlayAlive)) { return $true }
    }
    return $false
}

function chatoverlay {
    <#
    .SYNOPSIS
    A small always-on-top panel: usage live at the top, every open Claude chat and the queue beneath. On Windows it starts with every shell and VS Code window unless -AutoStart off.
    .DESCRIPTION
    Each open chat is a row: project, title, and whether it is working
    (green), waiting on you (amber, at the top), or idle (grey). On Windows
    the row is a tile in that colour alone: a mark for where the chat is
    open, over a seven-segment clock - how long it has worked, waited or
    sat idle, or how long until it resets or sends; its project and title
    are on the card a rest on it brings up. On macOS and with -Print its
    newest prompt is under it instead.
    Chats the limit cut off are red, with when it resets; once it is
    over, the panel says how many it cut off and continues them if you say
    so (chatq -AutoContinue off only marks them). Queued prompts
    are rows too (purple), or ride on their chat's row when it is open. On
    Windows, a chat that finished a turn while you were elsewhere, since
    you last opened it from the overlay, has a small dot, cyan in the dark
    look and blue in the light - not one whose window was in front as it
    finished; macOS has no such dot, as it has no open chip to clear it.
    Under them, on Windows, a faint Recent list: the newest chats not open,
    each openable as a tab like an open one. Usage sits at the top, a line
    for each of Claude, Codex and Copilot, each ending with when its figure
    is from - or as bars with a countdown to each reset. On Windows the
    panel is only as wide as a tile, and usage is a thin bar a window for
    those with a chat or job open now, its figures on the card a rest on
    it brings up. Claude's is asked
    live from its usage endpoint every five minutes while a chat works,
    every fifteen while all are idle, and on the refresh button; Copilot's
    through the GitHub CLI (gh) every fifteen; Codex's from
    codex app-server, which spends no turn on it, every five minutes while
    Codex works and fifteen while it is idle - or what Codex wrote on its
    last run, when that is newer.

    Clicks go through it and it never takes focus. On Windows a bar along
    its top strip is the exception: shown with the panel, it takes the
    mouse, so hold it anywhere off its buttons to drag the panel. Its
    buttons are collapse to one line, refresh usage, settings (opacity,
    rows, theme, how many recent chats, and whether chats the limit cut
    off are asked about or only marked), then, as on any window, minimize
    (to the tray - the tray icon shows it again), maximize (the console,
    chatconsole) and close. Rest the pointer on the panel and its top and
    bottom edges come, to drag for rows and then recent chats. The hotkey (Ctrl+Alt+Shift+O) or
    the tray menu unlocks the whole panel to drag; it locks again by itself
    two minutes after the pointer leaves. Windows and macOS (untested);
    elsewhere -Print shows the same in the console. charlie, its name from
    0.10.11 to 0.11.10, still works. On Windows it is chatq-overlay.exe, the
    Rust host and its panel in one process, which the VS Code extension puts
    under bin/<version>/x86_64-pc-windows-msvc/ beside the script; a git
    checkout with none there uses its own build, native\overlay\target\x86_64-pc-windows-msvc\release,
    while that says this version. With neither (a zip install; a checkout
    not rebuilt since a bump) there is no overlay, and overlay.log says what
    to do. overlay.host and overlay.panel ps in config.json are ignored there.
    .PARAMETER Stop
    Close it.
    .PARAMETER Unlock
    Take the mouse, to drag it somewhere else. -Lock lets clicks through again.
    .PARAMETER Reset
    Back to the main screen's top-right corner.
    .PARAMETER Collapse
    Down to one line: how many chats wait, work or idle, and usage. -Expand undoes it.
    .PARAMETER Refresh
    Ask Claude's usage endpoint now - unless it said to wait, which the panel shows.
    .PARAMETER Print
    One pass, drawn in this console.
    .PARAMETER AutoStart
    on (the default on Windows): start it with every new shell and every VS Code window, the way the watcher comes back after a reboot. off: only when asked for by name.
    .PARAMETER Hotkey
    The key that unlocks it or shows it: Ctrl+Alt+Shift+O by default, none for no key.
    .PARAMETER LiveUsage
    off: show only Claude Code's own cached usage figure, and never ask the endpoint.
    .PARAMETER Theme
    dark (the default: blue-black, cyan and gold), light, or system - following the OS's own light or dark setting.
    .PARAMETER Opacity
    How opaque the panel is, 0.3 to 1 - or as a percent, 30 to 100.
    .PARAMETER Width
    How wide the panel is on macOS, 260 to 800 (380 by default) - in pixels at 100% scaling. The Windows panel is as wide as a tile.
    .PARAMETER Rows
    How many chat rows it shows at most, 1 to 30 (8 by default); the rest are counted on a line of their own.
    .PARAMETER Compact
    on: one line a chat, no newest prompt under it - on macOS and with -Print. off (the default): the prompt line too. The Windows panel's row is its tile alone either way.
    .PARAMETER ChipDelay
    How long the pointer rests on a chat's row before its open chip comes, in milliseconds: 100 to 3000, 400 by default.
    .PARAMETER Recent
    How many of the newest chats not open are listed under the open ones: 0 to 20, 5 by default; 0 is no Recent list.
    .PARAMETER Console
    Open the console: pick a chat, write to it, drop files on it, send it next or queue it; the queue beside it. It opens in the panel's own place, grown from its top-right corner; Esc, its back button or the console hotkey return it to the panel. It is a window of its own, a couple of seconds to open, that closes as it returns. Starts the overlay if it is not running. Windows only.
    .PARAMETER ConsoleHotkey
    The key that opens the console: Ctrl+Alt+Shift+Q by default, none for no key.
    .PARAMETER UsageView
    On macOS and with -Print - lines (the default): usage as one line a provider. bars: a bar and a reset countdown per window. The Windows panel draws a thin bar per window, its figures on its card.
    .PARAMETER CopilotUsage
    off: no Copilot line, and gh is never run for it.
    .PARAMETER CodexUsage
    off: Codex's line only from what Codex wrote on its last run, and codex app-server is never started for it.
    .PARAMETER HostCheck
    on: on Windows, a PowerShell checker runs beside the Rust host, about 130 MB while it does, and data/logs/overlay-check.log says what differs. off (the default): none. A running overlay starts again on the one chosen.
    .EXAMPLE
    chatoverlay
    .EXAMPLE
    chatoverlay -AutoStart off
    .EXAMPLE
    chatoverlay -Theme system -Opacity 85
    .EXAMPLE
    chatoverlay -Rows 12
    .EXAMPLE
    chatoverlay -Compact on -ChipDelay 250
    .EXAMPLE
    chatoverlay -Recent 10
    #>
    [CmdletBinding()]
    param(
        [switch]$Stop, [switch]$Unlock, [switch]$Lock, [switch]$Reset, [switch]$Print,
        [switch]$Collapse, [switch]$Expand, [switch]$Refresh, [switch]$Console,
        [ValidateSet('on', 'off')][string]$AutoStart,
        [string]$Hotkey,
        [string]$ConsoleHotkey,
        [ValidateSet('on', 'off')][string]$LiveUsage,
        [ValidateSet('dark', 'light', 'system')][string]$Theme,
        [double]$Opacity,
        [int]$Width,
        [int]$Rows,
        [ValidateSet('on', 'off')][string]$Compact,
        [int]$ChipDelay,
        [int]$Recent,
        [ValidateSet('lines', 'bars')][string]$UsageView,
        [ValidateSet('on', 'off')][string]$CopilotUsage,
        [ValidateSet('on', 'off')][string]$CodexUsage,
        [ValidateSet('on', 'off')][string]$HostCheck
    )
    Set-StrictMode -Off
    if ($Print) { Write-ChatOverlayPrint; return }
    $alive = Test-ChatOverlayAlive
    if ($Stop) {
        # A close by hand, kept against this sign-in: the overlay keeps its
        # own as it takes the stop (Invoke-ChatOverlayVerb), this one where
        # none runs. What stays closed is said only where the auto start
        # would otherwise have brought it back.
        $auto = (Get-ChatOverlayConfig).autoStart
        $until = " - it stays closed until you next sign in, or chatoverlay starts it"
        if (-not $alive) {
            $kept = Set-ChatOverlayClosed
            Write-Host "  the overlay is not running$(if ($kept -and $auto) { $until })" -ForegroundColor DarkGray
            return
        }
        if (Stop-ChatOverlay) {
            $after = if (-not $auto) { '' } elseif (Test-ChatOverlayClosedByHand) { $until } else { ' - the next shell or VS Code window starts it again' }
            Write-Host "  overlay closed$after" -ForegroundColor DarkGray
        }
        else { Write-Host '  asked the overlay to close - it has not yet; data/logs/overlay.log may say why' -ForegroundColor Yellow }
        return
    }
    $set = @{}
    if ($AutoStart) { $set.autoStart = ($AutoStart -eq 'on') }
    if ($LiveUsage) { $set.liveUsage = ($LiveUsage -eq 'on') }
    if ($Theme) { $set.theme = $Theme.ToLowerInvariant() }
    if ($UsageView) { $set.usageView = $UsageView.ToLowerInvariant() }
    if ($CopilotUsage) { $set.copilotUsage = ($CopilotUsage -eq 'on') }
    if ($CodexUsage) { $set.codexUsage = ($CodexUsage -eq 'on') }
    # a check day: read by the Rust host at its start only
    if ($HostCheck) { $set.hostCheck = ($HostCheck -eq 'on') }
    # compact is prompts off: the name from when full rows showed the prompt
    # everywhere - on macOS and in -Print they still do; the Windows panel's
    # row is its tile alone whichever (Add-ChatOverlayTileRow)
    if ($Compact) { $set.prompts = ($Compact -eq 'off') }
    if ($PSBoundParameters.ContainsKey('Opacity')) {
        $o = if ($Opacity -gt 1) { $Opacity / 100 } else { $Opacity }
        if ($o -lt 0.3 -or $o -gt 1) { Write-Host '  -Opacity takes 0.3 to 1, or 30 to 100 as a percent' -ForegroundColor Yellow; return }
        $set.opacity = [Math]::Round($o, 2)
    }
    # refused out of range rather than held to it, as -Opacity is: a typo
    # shows now, not as a panel of some other size
    if ($PSBoundParameters.ContainsKey('Width')) {
        if ($Width -lt 260 -or $Width -gt 800) { Write-Host '  -Width takes 260 to 800' -ForegroundColor Yellow; return }
        $set.width = $Width
    }
    if ($PSBoundParameters.ContainsKey('Rows')) {
        if ($Rows -lt 1 -or $Rows -gt 30) { Write-Host '  -Rows takes 1 to 30' -ForegroundColor Yellow; return }
        $set.maxRows = $Rows
    }
    if ($PSBoundParameters.ContainsKey('ChipDelay')) {
        if ($ChipDelay -lt 100 -or $ChipDelay -gt 3000) { Write-Host '  -ChipDelay takes 100 to 3000 milliseconds' -ForegroundColor Yellow; return }
        $set.chipDelayMs = $ChipDelay
    }
    if ($PSBoundParameters.ContainsKey('Recent')) {
        if ($Recent -lt 0 -or $Recent -gt 20) { Write-Host '  -Recent takes 0 to 20 - 0 for none' -ForegroundColor Yellow; return }
        $set.recent = $Recent
    }
    if ($PSBoundParameters.ContainsKey('Hotkey')) {
        try { $k = ConvertFrom-ChatOverlayHotkey $Hotkey }
        catch { Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow; return }
        $set.hotkey = if ($k) { $k.Text } else { 'none' }
    }
    if ($PSBoundParameters.ContainsKey('ConsoleHotkey')) {
        try { $k = ConvertFrom-ChatOverlayHotkey $ConsoleHotkey }
        catch { Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow; return }
        $set.consoleHotkey = if ($k) { $k.Text } else { 'none' }
    }
    if ($set.Count) {
        Set-ChatOverlayConfig $set
        # on asked for by name: a close by hand no longer holds it off
        if ($set.autoStart) { Clear-ChatOverlayClosed }
        if ($set.ContainsKey('autoStart')) { Write-Host "  start with every shell and VS Code window: $AutoStart" -ForegroundColor Green }
        if ($set.ContainsKey('liveUsage')) { Write-Host "  live usage: $LiveUsage" -ForegroundColor Green }
        if ($set.ContainsKey('hotkey')) { Write-Host "  hotkey: $($set.hotkey)" -ForegroundColor Green }
        if ($set.ContainsKey('consoleHotkey')) { Write-Host "  console hotkey: $($set.consoleHotkey)" -ForegroundColor Green }
        if ($set.ContainsKey('theme')) { Write-Host "  theme: $($set.theme)" -ForegroundColor Green }
        if ($set.ContainsKey('opacity')) { Write-Host "  opacity: $([int]($set.opacity * 100))%" -ForegroundColor Green }
        if ($set.ContainsKey('width')) { Write-Host "  width: $($set.width)$(if ($script:ChatqIsWindows) { ' - for macOS; the panel here is as wide as a tile' })" -ForegroundColor Green }
        if ($set.ContainsKey('maxRows')) { Write-Host "  rows: $($set.maxRows) at most" -ForegroundColor Green }
        if ($set.ContainsKey('prompts')) { Write-Host "  compact rows: $Compact$(if ($script:ChatqIsWindows) { ' - for -Print; the panel''s row is its tile alone either way' } elseif ($Compact -eq 'on') { ' - one line a chat' } else { ' - each with its newest prompt' })" -ForegroundColor Green }
        if ($set.ContainsKey('chipDelayMs')) { Write-Host "  open chip: after a $($set.chipDelayMs) ms rest on a row" -ForegroundColor Green }
        if ($set.ContainsKey('recent')) { Write-Host "  recent chats: $(if ($set.recent) { "the newest $($set.recent) not open, under the open ones" } else { 'off' })" -ForegroundColor Green }
        if ($set.ContainsKey('usageView')) { Write-Host "  usage as $($set.usageView)$(if ($script:ChatqIsWindows) { ' - for -Print; the panel draws a thin bar a window' })" -ForegroundColor Green }
        if ($set.ContainsKey('copilotUsage')) { Write-Host "  Copilot usage: $CopilotUsage$(if ($CopilotUsage -eq 'on') { ' - through the GitHub CLI, gh, when it is logged in' })" -ForegroundColor Green }
        if ($set.ContainsKey('codexUsage')) { Write-Host "  Codex usage asked live: $CodexUsage$(if ($CodexUsage -eq 'on') { ' - through codex app-server, no turn spent' } else { ' - from what Codex wrote on its last run only' })" -ForegroundColor Green }
        if ($set.ContainsKey('hostCheck')) {
            Write-Host "  host check: $HostCheck - $(if ($set.hostCheck) { 'a PowerShell checker beside the Rust host, about 130 MB while it runs' } else { 'none' })" -ForegroundColor Green
            if (-not $script:ChatqIsWindows) { Write-Host '  for the Rust host - Windows only' -ForegroundColor Yellow }
        }
        # a check day is read by the Rust host at its start only, so a
        # running one starts again onto it; every other setting is a reload
        $restart = $set.ContainsKey('hostCheck') -and $script:ChatqIsWindows
        if ($alive) { Send-ChatOverlayCommand $(if ($restart) { 'restart' } else { 'reload' }) }
    }
    $verbs = @()
    if ($Unlock) { $verbs += 'unlock' }
    if ($Lock) { $verbs += 'lock' }
    if ($Reset) { $verbs += 'reset' }
    if ($Collapse) { $verbs += 'collapse' }
    if ($Expand) { $verbs += 'expand' }
    if ($verbs) {
        if ($alive) { foreach ($v in $verbs) { Send-ChatOverlayCommand $v } }
        else {
            # not running: left the way the next start will read it (the
            # native panel has no lock and ignores -Lock and -Unlock)
            $st = Read-ChatOverlayState
            if ($Unlock) { $st.locked = $false }
            if ($Lock) { $st.locked = $true }
            if ($Reset) { $st.x = $null; $st.y = $null }
            if ($Collapse) { $st.collapsed = $true }
            if ($Expand) { $st.collapsed = $false }
            Save-ChatOverlayState $st
        }
        Write-Host "  $($verbs -join ', ')$(if (-not $alive) { ' - applies when it next starts' })" -ForegroundColor DarkGray
    }
    if ($Refresh) {
        # a wait the endpoint named: said here, not asked through
        $snapNow = Read-ChatqJson $script:ChatOverlayPath
        $held = if ($snapNow -and $snapNow.PSObject.Properties['header'] -and $snapNow.header.PSObject.Properties['liveHold'] -and $snapNow.header.liveHold) { [int64]$snapNow.header.liveHold } else { 0 }
        if ($held -gt [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) {
            $until = [DateTimeOffset]::FromUnixTimeMilliseconds($held).LocalDateTime.ToString('HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
            Write-Host "  Claude's usage endpoint asked to wait until $until - asking earlier only gets refused again" -ForegroundColor Yellow
        }
        elseif ($alive) {
            Send-ChatOverlayCommand 'refresh'
            $cxSay = if ((Get-ChatOverlayConfig).codexUsage) { ' Codex is asked too.' } else { " Codex's moves only when Codex runs (-CodexUsage off)." }
            Write-Host "  asked Claude for usage now - it shows within a few seconds.$cxSay" -ForegroundColor DarkGray
        }
        else { Write-Host '  the overlay is not running - chatoverlay -Print asks once' -ForegroundColor DarkGray }
    }
    if ($Console) {
        if (-not $script:ChatqIsWindows) { Write-Host '  the console is Windows only for now - chatq, chatqlist and chatqrm do the same from a shell' -ForegroundColor Yellow; return }
        # Windows gives the focus to what the user started; a running overlay
        # only told to open it may just flash its taskbar button
        if ($alive) { Send-ChatOverlayCommand 'console'; Write-Host '  the console opens in the panel''s place - its taskbar button, if it stays behind; Esc returns the panel' -ForegroundColor DarkGray }
        elseif (Start-ChatOverlayProcess -Open 'console') { Write-Host '  starting the overlay with its console - a few seconds; Esc returns the panel' -ForegroundColor DarkGray }
        return
    }
    if ($set.Count -or $verbs -or $Refresh) { return }

    if (-not $script:ChatqIsWindows -and -not $script:ChatIsMac) {
        Write-Host '  the panel is Windows and macOS only - chatoverlay -Print shows the same here' -ForegroundColor Yellow
        return
    }
    if ($alive) {
        Send-ChatOverlayCommand 'show'
        Write-Host '  the overlay is running - shown' -ForegroundColor DarkGray
    }
    else {
        # asked for by name: shown, even if it was hidden when it last closed,
        # and a close by hand holds no longer - the overlay clears that as it
        # starts too, but a start that fails should not leave it
        $st = Read-ChatOverlayState
        if ($st.hidden -or $null -ne $st.closedSignIn) { $st.hidden = $false; $st.closedSignIn = $null; Save-ChatOverlayState $st }
        # and the Rust host's count of unclean starts: asked for by name, it
        # always tries (host-starts.json)
        Clear-ChatOverlayHostFuse
        if (-not (Start-ChatOverlayProcess)) { return }
        $up = $false
        for ($i = 0; $i -lt 40 -and -not $up; $i++) { Start-Sleep -Milliseconds 250; $up = Test-ChatOverlayAlive }
        if (-not $up) {
            Write-Host '  the overlay did not start - data/logs/overlay.log may say why' -ForegroundColor Yellow
            return
        }
        Write-Host '  overlay started - top right of the main screen' -ForegroundColor Green
        if ($script:ChatIsMac) { Write-Host '  macOS support is untested - TESTING.md lists what to check' -ForegroundColor DarkGray }
    }
    # the Rust host's panel has no lock: it takes every click
    if ($script:ChatqIsWindows) { Write-Host '  drag its frame to move it, swipe a chat sideways and click its bin to delete it; its bar collapses, hides and closes it' -ForegroundColor DarkGray }
    else { Write-Host '  clicks go through it - the CQ menu bar item unlocks it to drag' -ForegroundColor DarkGray }
    # what comes back by itself, as config.json has it now
    # a close kept until the next sign-in is Windows' alone: a Mac's
    # sign-in is not looked for (Get-ChatqSignInAt)
    if ((Get-ChatOverlayConfig).autoStart -and $script:ChatqIsWindows) {
        Write-Host "  chatoverlay -Stop, or its x, closes it until you next sign in $($script:ChatqDot) -AutoStart off keeps it to when you start it" -ForegroundColor DarkGray
    }
    elseif ((Get-ChatOverlayConfig).autoStart) {
        Write-Host "  chatoverlay -Stop closes it $($script:ChatqDot) it starts again with every shell and VS Code window unless -AutoStart off" -ForegroundColor DarkGray
    }
    else { Write-Host "  chatoverlay -Stop closes it $($script:ChatqDot) -AutoStart on brings it back with every shell and VS Code window" -ForegroundColor DarkGray }
}

function chatconsole {
    <#
    .SYNOPSIS
    chatq in a window: pick a chat, write to it, drop files on it, send it next or queue it.
    .DESCRIPTION
    The chats cut off by the limit (Continue, or Continue all - ahead of the
    prompts waiting), the ones open in VS Code, and the recent ones, with a
    search; + New chat starts one in a folder. When Next, Send puts the
    prompt at the front of the queue - within seconds, or once the job
    running ends; once the chat is idle if it is working in VS Code - and
    In turn, At or In queue it. The queue
    sits below: each job's outcome and log, Try now, First, Remove, Cancel,
    Requeue. It is the overlay's own window: the panel grows into it from
    its top-right corner, and Esc, the back button in its header or
    Ctrl+Alt+Shift+Q again return it to the panel, where and as it was.
    With the native panel it is a window of the overlay's own, started as
    it is asked for - a couple of seconds - and closed as it returns. So
    this starts the overlay if it is not running. Windows only.
    Ctrl+Alt+Shift+Q, the overlay's maximize button and the tray menu
    open it too.
    #>
    Set-StrictMode -Off
    chatoverlay -Console
}

#endregion
