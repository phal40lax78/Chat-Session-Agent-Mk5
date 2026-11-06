# Chat Session Agent Mk.5, src/overlay-host.ps1: dot-sourced by Chat-Session-Agent-Mk5.ps1
# in its turn, never on its own - see the list there.

#region overlay: what the steps and the console share ------------------------
# What an overlay host does whatever draws its panel: the lock, the heap's
# compaction and the memory restart, and its news for you - the ask, low
# memory, a delete's or a reload's outcome. The Rust host is the only host
# on Windows (Start-ChatOverlayProcess) and runs the steps below in a
# process of its own; the console (Start-ChatConsoleHost) is the one
# window left that draws with the WPF kit (src/overlay-windows.ps1).
# Nothing here touches a WPF or WinForms type unless a tray is there to
# show a balloon in, so this part loads where the panel's do not.

# The native panel's own word back: what it has seen, and whether something
# there is under way (Read-ChatOverlayUi)
$script:ChatOverlayUiPath = Join-Path $script:ChatqData 'overlay-ui.json'
# a row's hover card, as the panel asked for it (card <key>):
# { key; at; model } - Get-ChatOverlayCardModel's, its masking unchanged
$script:ChatOverlayCardPath = Join-Path $script:ChatqData 'card.json'

function Lock-ChatOverlay {
    # A few tries, not one: an overlay handing over to a newer copy lets go
    # of the lock only as it exits.
    for ($try = 1; $try -le 5; $try++) {
        $l = try { [System.IO.File]::Open($script:ChatOverlayLockPath, 'OpenOrCreate', 'ReadWrite', 'None') } catch { $null }
        if ($l) { return $l }
        if ($try -lt 5) { Start-Sleep -Milliseconds 200 }
    }
    return $null
}

# Deferred: DEFERRED.md "GC flags for the overlay"
function Invoke-ChatOverlayHeapCompact {
    <#
    A full collection, the large object heap compacted with it. A start
    reads the tail of every transcript of the last week and the open chats
    whole, and the buffers are freed after by a collection that never moves
    what is left, so the heap keeps its size. Live, the first gave back 22
    to 82 MB in about 0.1 s. The passes after put little on that heap,
    which held 12 to 15 MB an hour on, so compacting it again costs little.
    The WPF panel's tick called this every 5 minutes after the first (the
    tick went with the panel, and nothing calls it now): left to itself the
    CLR let generation 2 grow from 89-95 MB to 146-159 between full
    collections 17 to 21 minutes apart, and the private bytes from 250 up
    to 290 with it. Private bytes before and after go in the log, and the
    managed heap left after: private bytes rose from 208 to 287 MB in a day
    with compactions freeing nothing, and only the heap's figure says
    whether what grew is objects the overlay holds or memory outside the
    heap - compiled script, native buffers.
    $Error is emptied first: every caught throw in a pass lands there, up
    to 256 records with their stack traces, and nothing in src reads it.
    Returns the private MB after, for Update-ChatOverlayRestartDue.
    #>
    $p = [System.Diagnostics.Process]::GetCurrentProcess()
    try {
        $was = $p.PrivateMemorySize64
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $global:Error.Clear()
        [System.Runtime.GCSettings]::LargeObjectHeapCompactionMode = [System.Runtime.GCLargeObjectHeapCompactionMode]::CompactOnce
        [System.GC]::Collect()
        $ms = $sw.ElapsedMilliseconds
        $p.Refresh()
        $after = [Math]::Round($p.PrivateMemorySize64 / 1MB)
        Write-ChatOverlayLog ('the heap compacted in {0} ms: private {1} MB, then {2}, the heap {3}' -f $ms, [Math]::Round($was / 1MB), $after, [Math]::Round([System.GC]::GetTotalMemory($false) / 1MB))
        return $after
    }
    finally { $p.Dispose() }
}

function Update-ChatOverlayRestartDue {
    <#
    Whether this run should start again to give its memory back, from the
    private MB a compaction left (Invoke-ChatOverlayHeapCompact). Over 78
    runs in one PC's log that figure sat at 260 MB in the middle and 322 at
    the most; a fresh run settles at 210 to 260, and one up some 30 hours
    sat at 315 to 322 - the heap climbing in steps nothing explains yet
    (FUTURE_WORK.md "The overlay's heap climbs in steps"). This bounds it.
    Settled is the lowest such figure from 30 minutes into the run on,
    once the start's reads are long given back. Due when the figure is at
    config overlay.restartMB or more, 50 or more over where this run
    settled, and the run an hour old: a run that starts high - another PC,
    more chats - never restarts for being itself, and a new one cannot
    restart in its first hour, so it never loops. Due, $H.MemRestart says
    why, for a restart once nothing is
    under way; 0 is never. No figure - a compaction that threw - nothing.
    #>
    param($H, $AfterMB, [datetime]$Now = (Get-Date))
    if ($null -eq $AfterMB -or $H.MemRestart -or $H.StartedAt -isnot [datetime]) { return }
    $mb = [double]$AfterMB
    $age = ($Now - $H.StartedAt).TotalMinutes
    if ($age -ge 30 -and ($null -eq $H.Settled -or $mb -lt $H.Settled)) { $H.Settled = $mb }
    $limit = [int]$H.Ctx.Config.restartMB
    if ($limit -le 0 -or $age -lt 60 -or $null -eq $H.Settled) { return }
    if ($mb -lt $limit -or $mb -lt $H.Settled + 50) { return }
    $H.MemRestart = "private $mb MB after the heap compacted, over overlay.restartMB $limit and $($mb - $H.Settled) over where this run settled - restarting to give it back"
}

function Show-ChatOverlayBalloon {
    <#
    The tray's balloon - the one place that shows one; a process with no
    tray, the console's or a step's, makes it an event for the native
    panel to show. -Kind says what a click on it means
    (ask: the chats the limit cut off, -Keys those asked about); the
    tray's handlers read it back, and clear it as it closes.
    Windows cuts the text itself past 255 characters, so it is cut here
    first, with an ellipsis. The tests' seam takes it in the tray's place.
    While a close by hand is on its way, only its own (-Kind close): the
    timer's passes run on meanwhile, and the ask, the tray's word or
    auto-continue's would put theirs over "Closed until you next sign in"
    before it is read. The console's window
    (Open-ChatOverlayHeadlessConsole) has no tray: its balloons are events
    of its own process's (Start-ChatConsoleHost), sent on to the Rust host
    in console-ui.json for the panel (Save-ChatConsoleUi).
    #>
    param($H, [string]$Text, [string]$Title = 'Mk.5', [int]$Ms = 6000, [string]$Icon = 'None', [string]$Kind = '', [string[]]$Keys = @())
    if (-not $H -or -not $Text) { return }
    if ($H.EventOwner) { $H = $H.EventOwner }
    if ($H.Closing -and $Kind -ne 'close') { return }
    if ($Text.Length -gt 250) { $Text = $Text.Substring(0, 249) + $script:ChatqEllipsis }
    $ks = @($Keys | Where-Object { $_ })
    # no tray: an event for the panel to show (Add-ChatOverlayEvent)
    if ($null -ne $H.Events) {
        $H.BalloonKind = $Kind
        $H.BalloonKeys = $ks
        Add-ChatOverlayEvent $H 'balloon' @{ title = $Title; text = $Text; ms = $Ms; icon = $Icon; click = $Kind; keys = @($ks) }
        return
    }
    if ($script:ChatOverlayBalloonSeam) {
        $H.BalloonKind = $Kind
        $H.BalloonKeys = $ks
        [void](& $script:ChatOverlayBalloonSeam @{ Title = $Title; Text = $Text; Kind = $Kind; Keys = $ks })
        return
    }
    if (-not $H.Tray) { return }
    $H.BalloonKind = $Kind
    $H.BalloonKeys = $ks
    $H.Tray.ShowBalloonTip($Ms, $Title, $Text, [System.Windows.Forms.ToolTipIcon]$Icon)
}

function Show-ChatOverlayMemory {
    # after a pass: Windows' memory gone low (Update-ChatOverlayMemory), or a
    # program growing fast (Update-ChatOverlayLeaks), said once in the tray
    # - a VS Code window may be about to die of it. Both in one pass, one
    # balloon says both: a second would cover the first before it is read.
    param($H)
    try {
        $m = $H.Ctx.MemNews
        $grow = @(@($H.Ctx.LeakNews) | Where-Object { $_ } | ForEach-Object { Format-ChatOverlayLeakText $_ }) -join '; '
        if (-not $m -and -not $grow) { return }
        $H.Ctx.MemNews = $null
        $H.Ctx.LeakNews = $null
        if (-not $m) {
            Show-ChatOverlayBalloon $H "$grow. Closing it gives the memory back before a VS Code window runs out and takes its chats down with it." `
                -Title 'Mk.5 - a program keeps growing' -Icon Warning -Kind leak -Ms 10000
            return
        }
        $t = (Format-ChatOverlayMemoryText $m) -replace '^memory low: ', ''
        if ($grow) { $t += ". $grow" }
        Show-ChatOverlayBalloon $H "$t. A VS Code window that runs out of memory takes its chats down with it - close what you can spare." `
            -Title 'Mk.5 - memory low' -Icon Warning -Kind memory -Ms 10000
    }
    catch { Write-ChatOverlayLog "memory: $($_.Exception.Message)" }
}

# Deferred: DEFERRED.md "The tray's ask items while the menu is open"
function Update-ChatOverlayAsk {
    <#
    After each pass, what the collector found about the chats the limit cut
    off ($H.Ctx.Ask): the tray's two answers put in step, a new ask said in
    a balloon once, an answer's outcome (AskSaid) said the same way, and a
    watcher an answer asked for followed until it is up.
    #>
    param($H)
    if (-not $H -or -not $H.Ctx) { return }
    $ask = $H.Ctx.Ask
    # Not while the menu is open: its items and their keys stay what it
    # showed, so a click never answers for a chat that joined meanwhile.
    $menuOpen = $H.Tray -and $H.Tray.ContextMenuStrip -and $H.Tray.ContextMenuStrip.Visible
    if ($H.Menu.AskGo -and -not $menuOpen) {
        $on = [bool]$ask
        # Available, not Visible: an item's Visible reads false whenever its
        # menu is closed - which is always, here - so once shown, a check of
        # Visible never hid them again. Available is what Visible sets.
        foreach ($i in $H.Menu.AskGo, $H.Menu.AskLeave, $H.Menu.AskSep) { if ($i.Available -ne $on) { $i.Available = $on } }
        if ($on) {
            $n = [int]$ask.Count
            $H.Menu.AskGo.Text = "Continue $n cut-off chat$(if ($n -ne 1) { 's' })"
            $H.Menu.AskGo.ToolTipText = (@(@($ask.Items) | Select-Object -First 10 | ForEach-Object { Format-ChatTitle ([string]$_.Title) 60 }) -join "`n")
            $H.Menu.AskLeave.ToolTipText = Format-ChatqAskLeaveTip $ask
        }
        # @() around the if: an empty array out of a branch would be $null
        $H.AskMenuKeys = @(if ($on) { $ask.Keys })
    }
    $news = $H.Ctx.AskNews
    if ($news) {
        $H.Ctx.AskNews = $null
        $a = $news.Ask
        $n = [int]$a.Count
        $names = @(@($a.Items) | Select-Object -First 3 | ForEach-Object { Format-ChatTitle ([string]$_.Title) 40 })
        $list = $names -join ', '
        if ($n -gt 3) { $list += " and $($n - 3) more" }
        Show-ChatOverlayBalloon $H "$(Format-ChatqAskCount $a) can continue: $list. Click to see them." -Title "Mk.5 - $(Format-ChatqAskHead $a)" -Ms 10000 -Kind ask -Keys @($a.Keys)
    }
    if ($H.Ctx.AskSaid) {
        $said = [string]$H.Ctx.AskSaid
        $H.Ctx.AskSaid = $null
        Show-ChatOverlayBalloon $H $said
    }
    if ($H.AskRequest) {
        # Ctx.Jobs holds each job with its first line: the state is the job's
        $queued = [bool](@($H.Ctx.Jobs | Where-Object { $_ -and $_.Job -and $_.Job.state -eq 'queued' }).Count)
        switch (Test-ChatqWatcherRequest $H.AskRequest $queued) {
            'up' { $H.AskRequest = $null }
            'none' { $H.AskRequest = $null }
            'failed' { $H.AskRequest = $null; Show-ChatOverlayBalloon $H 'the watcher did not start - chatqrun -Foreground shows why' }
        }
    }
}

function Test-ChatOverlayRowDeletable {
    # whether a row's delete chip takes a click: not on a chat at work or
    # waiting on you - cutting its transcript from under a turn loses the
    # turn - nor on one a terminal's claude holds, or a print-mode run (a
    # queued prompt), either of which writes it straight back.
    # Remove-ChatSessionById asks the registry again as it acts. Pure.
    param($Row)
    if ([string](Get-ChatField $Row 'kind') -ne 'session') { return $true }
    return ([string](Get-ChatField $Row 'status') -notin 'busy', 'waiting' -and
        [string](Get-ChatField $Row 'where') -notin 'terminal', 'run')
}

function Get-ChatOverlayDeleteSay {
    # the panel's said marker for a delete chip's outcome (Remove-ChatSessionById's
    # Done and Say), or with -Archive an archive's, as the open's is
    # (Get-ChatOverlayOpenSay). Pure.
    param([bool]$Done, [string]$Say, [switch]$Archive)
    $kind = if ($Archive) { 'archive' } else { 'delete' }
    if ($Done) { return @{ Kind = $kind; Text = $Say; Tone = 'dim'; Keep = 5 } }
    return @{ Kind = $kind; Text = $(if ($Say) { $Say } else { if ($Archive) { 'Nothing archived.' } else { 'Nothing deleted.' } }); Tone = 'warn'; Keep = 20 }
}

function Get-ChatOverlayReloadSay {
    # the panel's said marker for a reload chip's answer, as a delete's is
    # (Get-ChatOverlayDeleteSay). Pure.
    param([string]$Window, [string]$Answer)
    $w = if ($Window) { $Window } else { 'the VS Code window' }
    if ($Answer -eq 'reload') { return @{ Kind = 'reload'; Text = "$w reloads - within 2 s"; Tone = 'dim'; Keep = 6 } }
    return @{ Kind = 'reload'; Text = "left for later - the notice is still in $w"; Tone = 'dim'; Keep = 6 }
}

function Get-ChatOverlayOpenSay {
    <#
    The panel's said marker about an open from the chip: Kind, Text, Tone, and
    Keep - how many seconds it stays once said, 0 while the open runs.
    -State busy (-Seconds so far), done (-Code, its child's exit), behind
    (opened, but its window could not be brought to the front -
    Invoke-ChatOverlayRaise), late (no answer in 60 s) or nostart (its
    child did not start). Pure.
    #>
    param([string]$Title, [string]$State, [int]$Code = 0, [int]$Seconds = 0)
    $t = "'$(Format-ChatTitle $Title 40)'"
    switch ($State) {
        'busy' { return @{ Kind = 'busy'; Text = "opening $t"; Tone = 'dim'; Keep = 0 } }
        'behind' { return @{ Kind = 'done'; Text = "now tracking $t - VS Code's window could not be brought to the front - click it on the taskbar"; Tone = 'warn'; Keep = 20 } }
        'late' { return @{ Kind = 'late'; Text = "opening $t - no answer in 60 s; see data/logs/watcher.log"; Tone = 'warn'; Keep = 20 } }
        'nostart' { return @{ Kind = 'nostart'; Text = "could not open $t - its helper did not start; see data/logs/overlay.log"; Tone = 'warn'; Keep = 20 } }
    }
    if ($Code -eq 0) { return @{ Kind = 'done'; Text = "now tracking $t"; Tone = 'dim'; Keep = 5 } }
    # a queued run's live view, which opens in VS Code: no failure either
    # and a chat Claude Code never lists, which its window offers in a
    # terminal (21): asked for as it should be. Not brought forward as well
    # (26, 42, 43) is a warning, as 25, 40 and 41 are
    if ($Code -in 16, 21) { return @{ Kind = 'done'; Text = "$t - $(Get-ChatOverlayOpenBalloon $Code)"; Tone = 'dim'; Keep = 8 } }
    return @{ Kind = 'done'; Text = "$t - $(Get-ChatOverlayOpenBalloon $Code)"; Tone = 'warn'; Keep = 20 }
}

function Get-ChatOverlayOpenBalloon {
    # what the tray says when an open ends, by its child's exit code
    # (Show-ChatFresh); $null says nothing. Pure.
    param([int]$Code)
    switch ($Code) {
        15 { return 'A queued prompt is running in that chat - open it once it finishes.' }
        16 { return 'A queued prompt is running in that chat - its live view opens in VS Code.' }
        20 { return 'That chat is open in a terminal - not opened in VS Code as well.' }
        21 { return 'Claude Code does not list that chat, so its window offers to open it in a terminal instead of a tab.' }
        25 { return 'Shown in its window, which also has other folders open - bring it forward yourself.' }
        26 { return 'Claude Code does not list that chat, so its window offers to open it in a terminal - that window also has other folders open, so bring it forward yourself.' }
        30 { return 'That chat has not started yet.' }
        40 { return 'Asked its window to show it, but VS Code''s code command was not found, so the window was not brought forward.' }
        41 { return 'code failed - see data/logs/watcher.log.' }
        42 { return 'Claude Code does not list that chat, so its window offers to open it in a terminal - but VS Code''s code command was not found, so the window was not brought forward.' }
        43 { return 'Claude Code does not list that chat, so its window offers to open it in a terminal - but code failed, so the window was not brought forward; see data/logs/watcher.log.' }
        10 { return 'Asked its window to open it - the chat is at work, so VS Code may hold it until the turn ends.' }
        50 { return 'Not opened - its id or its folder is not right any more.' }
    }
    # 0 went; anything else - a crash of its child among them - is said too
    if ($Code) { return "Not opened - the open ended with code $Code; see data/logs/watcher.log." }
    return $null
}

function Remove-ChatOverlayRow {
    <#
    A row's chat deleted for good, as chatrm does (Remove-ChatSessionById,
    which asks the registry again as it acts): what both hosts' delete
    does once its "sure?" is answered - the WPF chip's
    (Invoke-ChatOverlayDeleteChip) and the native panel's verb
    (Invoke-ChatOverlayPanelVerb). -Archive moves it to data/archive
    instead (the same call, as chatarchive does), its open tab asked to
    close. Gone, it takes its unread dot with it, and the recent list is
    read again at the next pass, without it.
    Returns Remove-ChatSessionById's answer, Done and Say; throws as it does.
    #>
    param($H, $Row, [switch]$Archive)
    $sid = [string](Get-ChatField $Row 'sessionId')
    $home0 = if ($H.Ctx -and $H.Ctx.ClaudeHome) { [string]$H.Ctx.ClaudeHome } else { $script:ChatClaudeHome }
    $live = @(Get-ChatqLiveSessions $home0 -RegistryOnly)
    $r = Remove-ChatSessionById -SessionId $sid -Cwd ([string](Get-ChatField $Row 'cwd')) -Title ([string](Get-ChatField $Row 'title')) -ConfigDir $home0 -Live $live -Archive:$Archive
    $word = if ($Archive) { 'archive' } else { 'delete' }
    Write-ChatOverlayLog "$($word): $($sid.Substring(0, [Math]::Min(8, $sid.Length))) $(if ($r.Done) { if ($Archive) { 'archived' } else { 'deleted' } } else { 'kept' })" -Always
    if ($r.Done -and $H.Ctx) {
        if ($H.Ctx.Unread) { $H.Ctx.Unread.Remove($sid) }
        # the recent list read again at the next pass, without it
        $H.Ctx.RecentAt = [datetime]::MinValue
    }
    return $r
}

function Add-ChatOverlayEvent {
    <#
    One piece of news for a panel in a process of its own: in the
    snapshot's events until 10 minutes on (Update-ChatOverlayEvents). Ids
    run on from the host's start, so two hosts' never meet. -Data's keys go
    in sorted, so the snapshot of one event reads the same each time.
    #>
    param($H, [string]$Kind, [hashtable]$Data = @{})
    $H.EventN++
    $e = [ordered]@{ id = "$($H.EventBase)-$($H.EventN)"; at = (ConvertTo-ChatOverlayMs (Get-Date)); kind = $Kind }
    # PSBase: a key named keys (a balloon's) would answer $Data.Keys itself
    foreach ($k in @($Data.PSBase.Keys | Sort-Object)) { $e[$k] = $Data[$k] }
    $H.Events.Add([pscustomobject]$e)
}

function Update-ChatOverlayEvents {
    # each pass: the news the panel has seen, or 10 minutes old, dropped
    param($H, $Ui, [datetime]$Now = (Get-Date))
    $seen = @{}
    foreach ($s in @(Get-ChatField $Ui 'seen')) { if ($s) { $seen[[string]$s] = $true } }
    $cut = ConvertTo-ChatOverlayMs $Now.AddMinutes(-10)
    for ($i = $H.Events.Count - 1; $i -ge 0; $i--) {
        $e = $H.Events[$i]
        if ($seen[[string]$e.id] -or [int64]$e.at -lt $cut) { $H.Events.RemoveAt($i) }
    }
}

function Read-ChatOverlayUi {
    # The native panel's word back, data/overlay-ui.json (native/overlay/src/ui.rs):
    # { at; underWay; seen; done; rect }. Of it the console reads rect: where
    # the panel is, x y width height in screen pixels, which the console
    # opens over (Open-ChatOverlayHeadlessConsole). $null while there is none.
    return (Read-ChatqJson $script:ChatOverlayUiPath)
}

function Receive-ChatOverlayCheckLine {
    # The checker's stdin, its host's pipe (Start-ChatOverlayCheckHost): a
    # line if one has come, '' while none has, $null once it has ended - its
    # host gone, or telling it to go. Read as Receive-ChatConsoleLine reads
    # the console's: one ReadLineAsync, looked at, never waited on.
    param($S)
    if ($script:ChatOverlayCheckInSeam) { return (& $script:ChatOverlayCheckInSeam) }   # tests
    $l = $null
    try {
        # the raw stream's reader, as the console's: [Console]::In is a
        # synchronized reader whose ReadLineAsync can block on the open pipe
        if (-not $S.In) { $S.In = [System.IO.StreamReader]::new([Console]::OpenStandardInput()) }
        if (-not $S.Read) { $S.Read = $S.In.ReadLineAsync() }
        $t = $S.Read
        if (-not $t.IsCompleted) { return '' }
        $S.Read = $null
        if (-not ($t.IsFaulted -or $t.IsCanceled)) { $l = $t.Result }
    }
    catch { $l = $null }
    if ($null -eq $l) { return $null }
    return [string]$l
}

function Start-ChatOverlayCheckHost {
    <#
    The PowerShell host's collector beside the Rust host, on a check day
    (config.json overlay.hostCheck, native/SPEC.md 3.10): the process
    Get-ChatOverlayLaunch's twin in the Rust host (host/check.rs) starts,
    every default part loaded. A context that holds events - the snapshot
    carries ui and events, as the Rust host's does - that takes no command, saves no
    overlay.json, writes no host-work note, runs no crash continue or auto
    scan and sends no alert (-Peek passes), and asks no usage endpoint
    (NoFetch): it reads what the Rust host last had (Restore-ChatOverlayUsage),
    again every 30 s so its figures follow the host's. Each pass its snapshot
    is written whole to data/native/overlay-ps-check.json, for the Rust host
    to compare with its own. It never takes overlay.lock, writes overlay.pid
    or overlay.json, or reads overlay-cmd. config.json is read again when
    it changes. Gone once its stdin ends, its host gone or telling it to go,
    once -HostPid is gone (looked for on the first pass and every 5 s), or
    after -MaxCycles passes, the tests'. Returns why it ended: host, eof,
    max or failed.
    #>
    param([int]$HostPid = 0, [int]$IntervalMs = 2000, [int]$MaxCycles = 0)
    Set-StrictMode -Off
    $file = Get-ChatqNativeFile 'overlay-ps-check.json'
    $why = $null
    $S = @{ Read = $null }
    try {
        Write-ChatOverlayLog "check $PID started ($script:ChatVersion) for overlay $HostPid" -Always
        New-ChatqDir (Split-Path -Parent $file)
        $ctx = New-ChatOverlayContext
        $ctx.Events = [System.Collections.Generic.List[object]]::new()
        $ctx.RecentPool = $true
        $ctx.WantAsk = $true
        $ctx.WantAuto = $false
        $ctx.WantPhone = $false
        $ctx.NoFetch = $true
        Restore-ChatOverlayUsage $ctx
        $cfgStamp = (Get-Item -LiteralPath $script:ChatqConfigPath -EA SilentlyContinue).LastWriteTimeUtc
        $usageAt = Get-Date
        $hostAt = $null
        $n = 0
        # stdin drained: true once it has ended
        $ended = { while ($true) { $l = Receive-ChatOverlayCheckLine $S; if ($null -eq $l) { return $true }; if (-not $l) { return $false } } }
        while (-not $why) {
            $now = Get-Date
            if ($HostPid -and (-not $hostAt -or ($now - $hostAt).TotalSeconds -ge 5)) {
                $hostAt = $now
                if (-not (Get-Process -Id $HostPid -EA SilentlyContinue)) { $why = 'host'; break }
            }
            if (& $ended) { $why = 'eof'; break }
            $stamp = (Get-Item -LiteralPath $script:ChatqConfigPath -EA SilentlyContinue).LastWriteTimeUtc
            if ($stamp -ne $cfgStamp) { $cfgStamp = $stamp; $ctx.Config = Get-ChatOverlayConfig }
            if (($now - $usageAt).TotalSeconds -ge 30) {
                $usageAt = $now
                try { Restore-ChatOverlayUsage $ctx } catch { Write-ChatOverlayLog "check usage: $($_.Exception.Message)" }
            }
            $snap = $null
            try { $snap = Invoke-ChatOverlayCycle $ctx -Peek }
            catch { Write-ChatOverlayLog "check pass: $($_.Exception.Message)" }
            # every pass, not only on change: the Rust host judges it fresh by its `at`
            if ($snap) {
                try { Save-ChatqText $file (ConvertTo-Json $snap -Depth 6 -Compress) }
                catch { Write-ChatOverlayLog "overlay-ps-check.json: $($_.Exception.Message)" }
            }
            $n++
            if ($MaxCycles -and $n -ge $MaxCycles) { $why = 'max'; break }
            # the wait in slices, for stdin's end to be seen in 250 ms
            $until = (Get-Date).AddMilliseconds($IntervalMs)
            while (-not $why -and (Get-Date) -lt $until) {
                Start-Sleep -Milliseconds ([int][Math]::Max(1, [Math]::Min(250, ($until - (Get-Date)).TotalMilliseconds)))
                if (& $ended) { $why = 'eof' }
            }
        }
    }
    catch { $why = 'failed'; Write-ChatOverlayLog "check $PID failed: $($_.Exception.Message)" -Always }
    finally { Write-ChatOverlayLog "check $PID stopped ($why)" -Always }
    return $why
}

function Find-ChatOverlayRow {
    # the row a panel's verb names, by its key, in a snapshot: its rows,
    # Recent, and Recent's stretch past it; $null for none. Pure.
    param($Snap, [string]$Key)
    if (-not $Snap -or -not $Key) { return $null }
    foreach ($r in @(@($Snap.rows) + @($Snap.recent) + @($Snap.recentMore))) {
        if ($r -and [string](Get-ChatField $r 'key') -ceq $Key) { return $r }
    }
    return $null
}

function Add-ChatOverlaySaid {
    # the said marker, with no window to draw it in: an event of kind said
    # for the native panel to draw, as Set-ChatOverlayOpenSay draws it on the WPF one -
    # said, its Kind; text and tone; ms, how long it stays (its Keep); and
    # about, the key of the row it is about, whose card says it too
    param($H, $Say, [string]$About = '')
    if (-not $Say) { return }
    Add-ChatOverlayEvent $H 'said' @{ said = [string]$Say.Kind; text = [string]$Say.Text; tone = [string]$Say.Tone; ms = ([int]$Say.Keep * 1000); about = $About }
}

function Invoke-ChatOverlayPanelVerb {
    <#
    A click on the native panel, come in as a verb with its words
    (Test-ChatOverlayVerbArg), carried out here as the WPF host's own
    handlers do, and its outcome said back to the panel as a said event
    (Add-ChatOverlaySaid). -Snap is this pass's snapshot, where the key is
    looked for (Find-ChatOverlayRow); an open's row may have left it since
    the click, so $H.Snap, the pass's before, is looked in for it too.
      opened <key> <exit> [<look>]
                              the panel's open child ended so, and its
                              window was looked for (front, behind, none,
                              looking): the unread dot goes on 0, 25, 40 and
                              41 (as Update-ChatOverlayOpen), the tray's words
                              (Get-ChatOverlayOpenBalloon) a balloon, and
                              Get-ChatOverlayOpenSay's the said marker
      opened <key> behind|late|nostart
                              found later but left behind, no answer in 60 s,
                              or no child started: said so
      config <name> <value>   a setting of the panel's box saved
                              (Set-ChatOverlayConfig): opacity, maxRows,
                              theme or recent
      auto-chip <key> dont|continue
                              the chip's auto-continue answer
                              (Invoke-ChatOverlayAutoChip)
      delete <key>            the chat deleted (Remove-ChatOverlayRow) -
                              the panel asked "sure?" first - unless the row
                              has gone, or cannot be (Test-ChatOverlayRowDeletable)
      archive <key>           the same, archived (Remove-ChatOverlayRow
                              -Archive), its open tab asked to close
      reload-answer <pid>:<id> reload|later
                              the window's ask answered
                              (Write-ChatReloadAnswer), and its banner left
                              out until the window has taken it
      card <key>              the row's hover card, written to data/card.json
                              (Get-ChatOverlayCardModel)
    True when it said something, for the next pass to start at once. Never
    throws.
    #>
    param($H, [string]$Verb, $Snap)
    $w = @($Verb -split ' ')
    try {
        switch -CaseSensitive ($w[0]) {
            'opened' {
                $key = $w[1]
                $row = Find-ChatOverlayRow $Snap $key
                if (-not $row) { $row = Find-ChatOverlayRow $H.Snap $key }
                $title = if ($row) { [string](Get-ChatField $row 'title') } else { '' }
                # the panel's own word for an end that is not a code: a window
                # found later but left behind, no answer in 60 s, no child
                if ($w[2] -cin 'behind', 'late', 'nostart') {
                    if ($w[2] -ceq 'late') { Show-ChatOverlayBalloon $H 'The open got no answer in 60 s - see data/logs/watcher.log.' }
                    Add-ChatOverlaySaid $H (Get-ChatOverlayOpenSay $title $w[2]) $key
                    return $true
                }
                $code = [int]$w[2]
                # the panel's look for its window (open.rs, as
                # Start-ChatOverlayRaise): in front, an end that says its window
                # was not brought forward says what it does in front instead
                $look = if ($w.Count -gt 3) { $w[3] } else { 'none' }
                $sid = if ($row) { [string](Get-ChatField $row 'sessionId') } elseif ($key -like 's:*') { $key.Substring(2) } else { '' }
                Write-ChatOverlayLog "open: $($sid.Substring(0, [Math]::Min(8, $sid.Length))) ended $code" -Always
                if ($code -in 0, 25, 40, 41 -and $sid -and $H.Ctx.Unread) { $H.Ctx.Unread.Remove($sid) }
                $words = if ($look -ceq 'front') { (Get-ChatOverlayRaisePlan $code).Words } else { $code }
                $say = Get-ChatOverlayOpenBalloon $words
                if ($say) { Show-ChatOverlayBalloon $H $say }
                $line = if ($look -ceq 'behind' -and $code -eq 0) { Get-ChatOverlayOpenSay $title 'behind' } else { Get-ChatOverlayOpenSay $title 'done' $words }
                Add-ChatOverlaySaid $H $line $key
                return $true
            }
            'config' {
                # a setting of the panel's box, kept as the WPF box keeps it
                # (Save-ChatOverlaySetting): config.json's overlay section
                $name = $w[1]
                $value = switch -CaseSensitive ($name) {
                    'opacity' { [Math]::Round([Math]::Min(1.0, [Math]::Max(0.3, [double]::Parse($w[2], [cultureinfo]::InvariantCulture))), 2) }
                    'maxRows' { [Math]::Min(30, [Math]::Max(1, [int]$w[2])) }
                    'hudSize' { [Math]::Min(200, [Math]::Max(50, [int]$w[2])) }
                    'characterSize' { [Math]::Min(200, [Math]::Max(50, [int]$w[2])) }
                    'recent' { [Math]::Min(20, [Math]::Max(0, [int]$w[2])) }
                    default { $w[2] }
                }
                Set-ChatOverlayConfig @{ $name = $value }
                $H.Ctx.Config = Get-ChatOverlayConfig
                Write-ChatOverlayLog "settings: $name from the panel" -Always
                return $true
            }
            'auto-chip' {
                $row = Find-ChatOverlayRow $Snap $w[1]
                if (-not $row) { $row = Find-ChatOverlayRow $H.Snap $w[1] }
                if (-not $row) { Write-ChatOverlayLog "auto-chip: $($w[2]), for a row the panel has no more"; return $false }
                Invoke-ChatOverlayAutoChip $H $row $w[2]
                return $true
            }
            { $_ -cin 'delete', 'archive' } {
                $key = $w[1]
                $arc = $w[0] -ceq 'archive'
                $none = if ($arc) { 'Nothing archived' } else { 'Nothing deleted' }
                $row = Find-ChatOverlayRow $Snap $key
                if (-not $row -or -not [string](Get-ChatField $row 'sessionId')) {
                    Add-ChatOverlaySaid $H (Get-ChatOverlayDeleteSay $false "$none - that chat is not on the panel any more." -Archive:$arc) $key
                    return $true
                }
                if (-not (Test-ChatOverlayRowDeletable $row)) {
                    Add-ChatOverlaySaid $H (Get-ChatOverlayDeleteSay $false "$none - not while the chat works or waits on you, or while a terminal or a queued prompt has it open." -Archive:$arc) $key
                    return $true
                }
                $r = Remove-ChatOverlayRow $H $row -Archive:$arc
                if ($r.Say) { Show-ChatOverlayBalloon $H $r.Say }
                Add-ChatOverlaySaid $H (Get-ChatOverlayDeleteSay ([bool]$r.Done) ([string]$r.Say) -Archive:$arc) $key
                return $true
            }
            'reload-answer' {
                $ask = @($H.Ctx.Reloads | Where-Object { $_ -and "$($_.pid):$($_.id)" -ceq $w[1] }) | Select-Object -First 1
                if (-not $ask) { Write-ChatOverlayLog "reload: $($w[2]), for an ask no window has now"; return $false }
                $hostPid = [int]$ask.pid
                Write-ChatReloadAnswer -HostPid $hostPid -Id ([string]$ask.id) -Answer $w[2]
                Write-ChatOverlayLog "reload: $($w[2]), to the window of pid $hostPid" -Always
                if ($H.Ctx.ReloadAnswered -isnot [hashtable]) { $H.Ctx.ReloadAnswered = @{} }
                $H.Ctx.ReloadAnswered["${hostPid}:$($ask.id)"] = Get-Date
                Add-ChatOverlaySaid $H (Get-ChatOverlayReloadSay ([string]$ask.window) $w[2]) "reload:$hostPid"
                return $true
            }
            'card' {
                $key = $w[1]
                $row = Find-ChatOverlayRow $Snap $key
                $model = $null
                if ($row) {
                    $src = Get-ChatOverlayCardSource $H.Ctx $row
                    $tail = if ($src.Path) { Read-ChatOverlayCardTail $src.Path } else { $null }
                    $model = Get-ChatOverlayCardModel $row $tail $src ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
                }
                Save-ChatqText $script:ChatOverlayCardPath (ConvertTo-Json -InputObject ([ordered]@{ key = $key; at = (ConvertTo-ChatOverlayMs (Get-Date)); model = $model }) -Depth 6 -Compress)
                return $false
            }
        }
    }
    catch { Write-ChatOverlayLog "panel $($w[0]): $($_.Exception.Message)" }
    return $false
}

function Set-ChatOverlayCrashVerb {
    # crash-on or crash-off, from the panel or a shell, as the act step
    # takes it: config.json's autoContinueCrash set where $Ctx.Config
    # says otherwise (Set-ChatqAutoContinueCrash), the config read again and
    # the cut-off look made due. True once it was set. Never throws.
    param($Ctx, [string]$Verb)
    $on = $Verb -eq 'crash-on'
    if ([bool]$Ctx.Config.autoContinueCrash -eq $on) { return $false }
    $set = $false
    try {
        [void](Set-ChatqAutoContinueCrash -Value $on)
        $set = $true
        $Ctx.Config = Get-ChatOverlayConfig
        $Ctx.CutAt = [datetime]::MinValue
        Write-ChatOverlayLog "crash continue $(if ($on) { 'on' } else { 'off' }) from the panel" -Always
    }
    catch { Write-ChatOverlayLog "settings: $($_.Exception.Message)" }
    return $set
}

function Invoke-ChatOverlayActStep {
    <#
    An acting verb of the Rust host's (native/SPEC.md 3.10), run as an
    overlay step's op (Invoke-ChatOverlayStep): the verb as written,
    args.verb, carried out by this file's own code on a host state
    and context made of what the Rust host sent - nothing kept, nothing
    shown. Its news is that state's events, returned for the Rust host to
    say: Show-ChatOverlayBalloon's and Add-ChatOverlaySaid's, each {kind,
    ...} as Add-ChatOverlayEvent makes it; overlay-events.json is left to
    that host (Standalone). Done says the act happened, for its follow-up.
      delete, archive, reload-answer, config, auto-chip
                Invoke-ChatOverlayPanelVerb on a snapshot of args.row alone
                (none: the row has gone); args.claudeHome, args.reloads
                [{pid, id, window}], args.text {path, prompt, typedAt} and
                args.job the context's ClaudeHome, Reloads, Text and Jobs.
                Done: deleted, archived, answered, saved, the chip's answer acted on
                (Invoke-ChatOverlayAutoChip)
      auto-on, auto-ask, auto-off
                Invoke-ChatOverlayAutoVerbs; set on, the notice
                (Show-ChatOverlayAutoNotice) unless args.closing. Done: set
      auto-notice
                Show-ChatOverlayAutoNotice alone: the notice a switch set
                on while a close by hand was on its way left for later
                (-OnCycle's $ctx.AutoSet, kept while closing). Never done
      crash-on, crash-off
                Set-ChatOverlayCrashVerb against config.json as it stands
                (Get-ChatOverlayConfig): the Rust host's act steps run one at
                a time, so each sees the last one's write, as -OnCycle's
                verbs see $ctx.Config set by the one before. Done: set
      answered-jobs
                Close-ChatqAnsweredJobs' close, for the ids the Rust host's
                pass found answered in the chat (args.ids): each looked up
                again (Find-ChatqJob -Exact) and, still needs-input, skipped
                by Complete-ChatqJob and logged as the cycle logs it. Done:
                any skipped
      live-alert
                One live alert the Rust host's pass found due (its gates in
                native/overlay/collect/src/alerts.rs): args.sessionId,
                args.event, args.jobId, args.entries [{Cwd, Name,
                WaitingFor}] (the chat's registry entries), args.text
                {path, customTitle, sidecar, aiTitle, first} (the pass's
                text for it) and args.claudeHome. A done you stopped
                yourself (Test-ChatqLiveStoppedByHand) is logged as
                Update-ChatqLiveAlerts logs it, and nothing sent; else
                Send-ChatqLiveAlertFor, its last output the outcome, with
                args.auto {state, at, tag} the chat's auto-continue state
                ($Ctx.AutoStates) as the Rust host's last look had it.
                Done: sent. request {outcome}: sent, stopped or side
      phone-extras
                Update-ChatqPhoneExtras with args.usage (the snapshot's
                header.usage), the queue's jobs and args.claudeHome: the
                usage heads-ups, deduped in data/usage-alerts.json, and the
                held summary's kick. Done: always
    The Rust host's own acts, on a context of New-ChatOverlayContext's
    (WantAsk and WantAuto, WantPhone where args.phone):
      look-queue
                the two places the Rust host's look writes the job store
                (native/overlay/collect/src/lookqueue.rs): args.crash, the
                restart rows the crash continue would continue
                (Invoke-ChatqCrashContinue), and args.auto, the cut-off
                rows auto-continue's scan looks at
                (Update-ChatOverlayAuto -Scan), the first continue it
                queues said (Show-ChatOverlayAutoQueued); args.procs
                finds the live chats as the look did. The checks are
                PowerShell's own, so a candidate the Rust host is wrong
                about queues nothing. Done: anything queued. request
                {crash, auto}: how many each queued
      act-look  Invoke-ChatOverlayActLook - unused since the look moved to
                Rust (native/overlay/collect/src/host/lookscan.rs); the
                tests still run it. Done: always; request its answer
      ask-answer
                your answer to the reset ask (args.answer continue or
                leave, args.keys, args.source - timer for
                overlay.askAutoSeconds', logged as the cycle logs it) on
                args.ask, the ask the Rust host's pass had (Ask::to_step_json;
                none given, no ask: answered as stale, never an older one):
                Complete-ChatqResetAsk, its outcome
                said (AskSaid), and the watcher it asked for watched here
                (Wait-ChatOverlayAskWatcher), as Update-ChatOverlayAsk
                watches it. Done: not stale. request {stale, queued,
                watcher}
      ask-phone the reset ask's phone alert for args.keys, on that ask
                (args.ask as for ask-answer; Send-ChatqResetAskAlert).
                Done: sent. request {said}: off, wait or sent
      ask-watch the watcher the console's answer asked for ($H.AskRequest,
                args.alive and args.spawned), watched here as ask-answer
                watches its own. Done: always. request {watcher}
      startup   the Rust host's start: Start-ChatqReplyStanding, the
                watcher asked for when it stands, and the switch's notice
                (Show-ChatOverlayAutoNotice). Done: always. request
                {standing}
    Returns {done, say, request}; request is $null but for live-alert's
    and the own acts'.
    #>
    param([string]$Op, $A)
    # pwsh 7's ConvertFrom-Json makes a [datetime] of a text shaped like a
    # stamp, at any depth; the Rust host sent the text, which a host that
    # read its own row, prompt, ask and job would have. Made text again in the
    # round-trip form ('o'): a stamp sent in another form comes back changed
    # in its digits, not culture-formatted
    $norm = {
        param($o)
        foreach ($p in @($o.PSObject.Properties)) {
            $v = $p.Value
            if ($v -is [System.Management.Automation.PSCustomObject]) { & $norm $v }
            elseif ($v -is [array]) { $p.Value = @(foreach ($x in $v) { if ($x -is [System.Management.Automation.PSCustomObject]) { & $norm $x; $x } else { ConvertFrom-ChatqStepText $x } }) }
            else { $p.Value = ConvertFrom-ChatqStepText $v }
        }
    }
    if ($A -is [System.Management.Automation.PSCustomObject]) { & $norm $A }
    $verb = [string]$A.verb
    $row = $A.row
    $text = @{}
    $sid = if ($row) { [string]$row.sessionId } else { '' }
    if ($sid -and $A.text) { $text[$sid] = [pscustomobject]@{ Path = [string]$A.text.path; Prompt = $A.text.prompt; TypedAt = $A.text.typedAt } }
    $ctx = [pscustomobject]@{
        ClaudeHome = $(if ($A.claudeHome) { [string]$A.claudeHome } else { $script:ChatClaudeHome })
        Unread = @{}; RecentAt = (Get-Date); Text = $text
        Jobs = @(@($A.job) | Where-Object { $_ } | ForEach-Object { [pscustomobject]@{ Job = $_; First = '' } })
        Reloads = @(@($A.reloads) | Where-Object { $_ }); ReloadAnswered = @{}
        Config = $(if ($Op -cin 'crash-on', 'crash-off') { Get-ChatOverlayConfig } else { [pscustomobject]@{} }); AutoSet = $null; CutAt = $null
        JobsSig = $null
    }
    $H = [pscustomobject]@{
        Ctx = $ctx; Snap = $null; Events = [System.Collections.Generic.List[object]]::new(); EventBase = 'step'; EventN = 0
        Standalone = $true; Closing = [bool]$A.closing; EventOwner = $null; BalloonKind = ''; BalloonKeys = @()
    }
    if ($Op -cin 'act-look', 'look-queue', 'ask-answer', 'ask-phone', 'ask-watch', 'startup') {
        $ctx = New-ChatOverlayContext -ClaudeHome $ctx.ClaudeHome
        $ctx.WantAsk = $true
        $ctx.WantAuto = $true
        $ctx.WantPhone = [bool]$A.phone
        $H.Ctx = $ctx
    }
    $done = $false
    $request = $null
    if ($Op -cin 'delete', 'archive', 'reload-answer', 'config', 'auto-chip') {
        $said = Invoke-ChatOverlayPanelVerb $H $verb ([pscustomobject]@{ rows = @(@($row) | Where-Object { $_ }) })
        $done = switch -CaseSensitive ($Op) {
            { $_ -cin 'delete', 'archive' } { $ctx.RecentAt -eq [datetime]::MinValue }
            'reload-answer' { [bool]$ctx.ReloadAnswered.Count }
            'config' { [bool]$said }
            'auto-chip' { [bool]$said }
            default { $false }
        }
    }
    elseif ($Op -cin 'auto-on', 'auto-ask', 'auto-off') {
        [void](Invoke-ChatOverlayAutoVerbs $ctx @($verb))
        $done = [bool]$ctx.AutoSet
        if ($ctx.AutoSet -eq 'on' -and -not $H.Closing) { Show-ChatOverlayAutoNotice $H }
    }
    elseif ($Op -ceq 'auto-notice') { Show-ChatOverlayAutoNotice $H }
    elseif ($Op -cin 'crash-on', 'crash-off') { $done = Set-ChatOverlayCrashVerb $ctx $verb }
    elseif ($Op -ceq 'answered-jobs') {
        foreach ($id in @(@($A.ids) | Where-Object { $_ })) {
            # a reply may have requeued it since the pass looked
            $cur = Find-ChatqJob ([string]$id) -Exact
            if (-not $cur -or [string]$cur.state -ne 'needs-input') { continue }
            Complete-ChatqJob $cur 'skipped' ([pscustomobject]@{ kind = 'skipped'; reason = 'answered in the chat' }) 'answered in the chat'
            Write-ChatOverlayLog "job $id skipped: answered in the chat"
            $done = $true
        }
    }
    elseif ($Op -ceq 'live-alert') {
        $sid = [string]$A.sessionId
        $ev = [string]$A.event
        $entries = @(@($A.entries) | Where-Object { $_ })
        $pc = @{ ClaudeHome = $ctx.ClaudeHome; Text = @{}; AutoStates = @{} }
        if ($A.auto) { $pc.AutoStates[$sid] = [pscustomobject]@{ State = [string]$A.auto.state; At = [string]$A.auto.at; Tag = [string]$A.auto.tag } }
        $tx = $A.text
        if ($tx) { $pc.Text[$sid] = [pscustomobject]@{ Path = [string]$tx.path; CustomTitle = $tx.customTitle; Sidecar = $tx.sidecar; AiTitle = $tx.aiTitle; First = $tx.first } }
        $outcome = if ($ev -eq 'done' -and (Test-ChatqLiveStoppedByHand $pc $sid $entries)) {
            Write-ChatOverlayLog "phone: no done alert for $sid - you stopped it"
            'stopped'
        }
        else { @(Send-ChatqLiveAlertFor $pc $sid $ev $entries $(if ($A.jobId) { [pscustomobject]@{ id = [string]$A.jobId } } else { $null }) $null)[-1] }
        $done = $outcome -eq 'sent'
        $request = [ordered]@{ outcome = [string]$outcome }
    }
    elseif ($Op -ceq 'phone-extras') {
        Update-ChatqPhoneExtras @{ ClaudeHome = $ctx.ClaudeHome } @(@($A.usage) | Where-Object { $_ }) @(Get-ChatqJobs)
        $done = $true
    }
    elseif ($Op -ceq 'act-look') {
        $request = Invoke-ChatOverlayActLook $H $A
        $done = $true
    }
    elseif ($Op -ceq 'look-queue') {
        $request = Invoke-ChatOverlayLookQueue $H $A
        $done = [bool]($request.crash + $request.auto)
    }
    elseif ($Op -ceq 'ask-answer') {
        $carry = Import-ChatOverlayStepCarry 'act'
        $ctx.Ask = if ($A.ask) { ConvertFrom-ChatOverlayStepAsk $A.ask } else { $null }
        $ctx.AskState = Read-ChatqAskState
        $src = if ($A.source) { [string]$A.source } else { 'overlay' }
        $keys = @(@($A.keys) | Where-Object { $_ } | ForEach-Object { [string]$_ })
        # logged only for an ask it will act on, as the cycle logs it only
        # with the live ask in hand (Complete-ChatqResetAsk's own match)
        if ($src -eq 'timer' -and $ctx.Ask -and @(@($ctx.Ask.Keys) | Where-Object { $_ -and [string]$_ -in $keys }).Count) {
            Write-ChatOverlayLog "ask: no answer in $($ctx.Config.askAutoSeconds) s - continuing them (overlay.askAutoSeconds)" -Always
        }
        $answer = if ([string]$A.answer -eq 'leave') { 'leave' } else { 'continue' }
        $ans = Complete-ChatqResetAsk $ctx $answer $keys -Source $src
        # answered: the ask is done with until the next look finds one
        if (-not $ans.Stale) {
            $carry['AskLast'] = @{ Ask = $null }
            Export-ChatOverlayStepCarry 'act' $carry
        }
        if ($ctx.AskSaid) { Show-ChatOverlayBalloon $H ([string]$ctx.AskSaid) }
        $up = Wait-ChatOverlayAskWatcher $H $ans.Request
        $done = -not $ans.Stale
        $request = [ordered]@{ stale = [bool]$ans.Stale; queued = @($ans.Queued).Count; watcher = [string]$up }
    }
    elseif ($Op -ceq 'ask-phone') {
        $ask = if ($A.ask) { ConvertFrom-ChatOverlayStepAsk $A.ask } else { $null }
        $said = Send-ChatqResetAskAlert $ctx $ask @(@($A.keys) | Where-Object { $_ } | ForEach-Object { [string]$_ }) -Now (Get-Date)
        $done = $said -eq 'sent'
        $request = [ordered]@{ said = [string]$said }
    }
    elseif ($Op -ceq 'ask-watch') {
        $rq = [pscustomobject]@{ Alive = [bool]$A.alive; Spawned = [bool]$A.spawned; Respawned = $false; At = (Get-Date) }
        $up = Wait-ChatOverlayAskWatcher $H $rq
        $done = $true
        $request = [ordered]@{ watcher = [string]$up }
    }
    elseif ($Op -ceq 'startup') {
        $standing = $false
        try { $standing = [bool](Start-ChatqReplyStanding); if ($standing) { $null = Request-ChatqWatcher } } catch {}
        Show-ChatOverlayAutoNotice $H
        $done = $true
        $request = [ordered]@{ standing = $standing }
    }
    $say = @(foreach ($e in $H.Events) {
            $o = [ordered]@{}
            foreach ($p in $e.PSObject.Properties) { if ($p.Name -notin 'id', 'at') { $o[$p.Name] = $p.Value } }
            $o
        })
    return [ordered]@{ done = [bool]$done; say = $say; request = $request }
}

function Wait-ChatOverlayAskWatcher {
    <#
    The watcher an answer asked for (Complete-ChatqResetAsk's Request),
    followed as Update-ChatOverlayAsk follows it across the console's
    passes, here within an ask-answer step: Test-ChatqWatcherRequest every
    half second until up, or nothing to wait for, or failed - said in its
    balloon - and no more than 12 s: its own 10 s to failed and a little
    over, the rest of the step's 30 left for PowerShell's start and the
    answer, so a slow start is not a kill the lane's stall counts. A
    watcher still waiting then (one respawned, whose 10 s start again)
    answers waiting, said nowhere. Returns Test-ChatqWatcherRequest's last
    word.
    #>
    param($H, $Request)
    if (-not $Request) { return 'none' }
    $end = (Get-Date).AddSeconds(12)
    while ($true) {
        $queued = [bool]@(Get-ChatqJobs | Where-Object { $_ -and $_.state -eq 'queued' }).Count
        $w = Test-ChatqWatcherRequest $Request $queued
        if ($w -eq 'failed') { Show-ChatOverlayBalloon $H 'the watcher did not start - chatqrun -Foreground shows why' }
        if ($w -ne 'waiting' -or (Get-Date) -ge $end) { return $w }
        Start-Sleep -Milliseconds 500
    }
}

function ConvertFrom-ChatOverlayStepCutOff {
    <#
    One cut-off row as the Rust host sends it (ask::step_row) to the row
    the cycle's functions take (Get-ChatqCutOffChats, Get-ChatRestartCutOffs):
    times as dates; a restart's mid, host pid, cause and tasks.
    #>
    param($R)
    $o = [ordered]@{
        Id = [string]$R.id; Title = [string]$R.title; Group = [string]$R.group
        At = ConvertTo-ChatqDate $R.at; ResetsAt = ConvertTo-ChatqDate $R.resetsAt
        Why = [string]$R.why; Path = [string]$R.path; Cwd = [string]$R.cwd
        LimitUuid = [string]$R.limitUuid
    }
    if ([string]$R.why -ceq 'restart') {
        $o['Mid'] = [string]$R.mid
        $o['HostPid'] = $(if ($null -ne $R.hostPid) { [int]$R.hostPid } else { 0 })
        $o['Cause'] = [string]$R.cause
        $o['Tasks'] = @(@($R.tasks) | Where-Object { $_ } | ForEach-Object { [pscustomobject]@{ Kind = [string]$_.kind; Id = [string]$_.id; Note = [string]$_.note } })
    }
    return [pscustomobject]$o
}

function ConvertFrom-ChatOverlayStepAsk {
    <#
    The reset ask as the Rust host sends it (Ask::to_step_json) to the
    object Get-ChatqResetAsk answers.
    #>
    param($A)
    return [pscustomobject]@{
        ResetsAt = ConvertTo-ChatqDate $A.resetsAt
        Items    = @(@($A.items) | Where-Object { $_ } | ForEach-Object { ConvertFrom-ChatOverlayStepCutOff $_ })
        Keys     = @(@($A.keys) | ForEach-Object { [string]$_ })
        Count    = [int]$A.count
        Restart  = [int]$A.restart
        Cause    = [string]$A.cause
        Left     = @()
    }
}

function Invoke-ChatOverlayLookQueue {
    <#
    The look's two writes to the job store, a look-queue step
    (native/overlay/collect/src/lookqueue.rs picks the candidates): the
    crash continue on args.crash, and auto-continue's scan with args.auto as
    its rows, the first continue queued said. The live chats are found as
    Invoke-ChatOverlayActLook finds them, from args.procs. The checks are
    the cycle's own, so a candidate that does not pass queues nothing.
    Returns {queued, crash, auto}: what each queued.
    #>
    param($H, $A)
    $ctx = $H.Ctx
    $now = Get-Date
    $procs = @{}
    foreach ($p in @($A.procs)) {
        if (-not $p) { continue }
        $start = ConvertTo-ChatqDate (ConvertFrom-ChatqStepText $p.start)
        $procs[[int]$p.pid] = [pscustomobject]@{ Id = [int]$p.pid; ProcessName = [string]$p.name; StartTime = $(if ($start) { $start.ToLocalTime() } else { $null }) }
    }
    $entries = @(Read-ChatqSessionRegistry (Join-Path $ctx.ClaudeHome 'sessions') @{})
    $alive = @($entries | Where-Object { $_.SessionId -and (Test-ChatqSessionAlive $_ $procs) })
    $ctx.Jobs = @(Get-ChatqJobs | Where-Object { $_.state -in 'queued', 'running', 'needs-input' } | ForEach-Object { [pscustomobject]@{ Job = $_; First = '' } })
    $ctx.JobsSig = 'step'
    $jobs = @($ctx.Jobs | ForEach-Object { $_.Job })
    $held = @{}
    foreach ($e in $alive) {
        $kind = [string](Get-ChatField $e 'Kind')
        $ep = [string](Get-ChatField $e 'Entrypoint')
        if (($kind -and $kind -ne 'interactive') -or ($ep -and $ep -ne 'claude-vscode')) { $held[[string]$e.SessionId] = $true }
    }
    $ctx.AskState = Read-ChatqAskState
    $crashSent = 0
    $autoSent = 0
    $crash = @(@($A.crash) | Where-Object { $_ } | ForEach-Object { ConvertFrom-ChatOverlayStepCutOff $_ })
    if ($crash.Count -and [bool]$ctx.Config.autoContinueCrash) {
        try { $crashSent = @(Invoke-ChatqCrashContinue $ctx $crash $jobs $now -Held $held).Count }
        catch { Write-ChatOverlayLog "crash continue: $($_.Exception.Message)" }
    }
    $auto = @(@($A.auto) | Where-Object { $_ } | ForEach-Object { ConvertFrom-ChatOverlayStepCutOff $_ })
    if ($auto.Count) {
        try {
            $ctx.CutAt = $now
            $ctx.CutOff = $auto
            $ctx.Blocks = try { Get-ChatqBlocks } catch { @{} }
            if (-not $ctx.Blocks) { $ctx.Blocks = @{} }
            $eta = Get-ChatqEta $jobs $ctx.Blocks -SendAt @{}
            if (Update-ChatOverlayAuto $ctx $alive $now $eta -Scan:(Test-ChatqAutoWanted) -Rows $auto) {
                $autoSent = 1
                $jobs = @($ctx.Jobs | ForEach-Object { $_.Job })
                $ctx.Blocks = try { Get-ChatqBlocks } catch { @{} }
                if (-not $ctx.Blocks) { $ctx.Blocks = @{} }
                $eta = Get-ChatqEta $jobs $ctx.Blocks -SendAt @{}
                Update-ChatOverlayAutoStates $ctx $alive $now $eta
                $ctx.JobsSig = $null
            }
        }
        catch { Write-ChatOverlayLog "auto-continue: $($_.Exception.Message)" }
    }
    Show-ChatOverlayAutoQueued $H
    return [ordered]@{ queued = [bool]($crashSent + $autoSent); crash = $crashSent; auto = $autoSent }
}

function Invoke-ChatOverlayActLook {
    <#
    Unused by the Rust host since its look moved into Rust (lookscan.rs,
    lookqueue.rs); kept for the tests (tests/sections/overlay-act.ps1).
    The Rust host's cut-off look (native/SPEC.md 3.10), an act-look step:
    Invoke-ChatOverlayCycle's look, run as a host's own pass runs it once
    Test-ChatOverlayLookDue says look - the Rust host keeps that cadence -
    and what each pass does after it: the cut-off scan, the answered marks
    read, the restarts' cut-offs (their notes pruned), the crash continue,
    the 12 hours' keep, auto-continue's states and the scan that queues,
    the reset ask, and its announce - the .shown markers, the log line and
    the balloon (Update-ChatOverlayAsk), the first continue queued said
    (Show-ChatOverlayAutoQueued). On $H, the step's host state, whose Ctx
    is a fresh New-ChatOverlayContext; its caches, CutCache and
    RestartCache, and the ask found (AskLast, for ask-answer and ask-phone)
    kept in data/native/overlay-carry-act.clixml. Args: procs (as the peek
    look's), eta {job id: words} (the pass's Get-ChatqEta) and usage (the
    snapshot's header.usage, for the limit's hold). Returns {on, cutOff,
    autoStates, ask, announced, again, jobs, next, error}: on, whether
    anything the look serves is on (nothing else is looked at when not);
    the rows and the states by session id, times as ISO strings; the ask
    as the snapshot's header carries it, with its keys' restart count; the
    keys announced now; again, a window still waiting on VS Code's log (a
    look in 2 s); jobs, the queue changed here (read it again); next, epoch
    ms, the first limit row's reset or its ask's time
    ($script:ChatqAskAfterMinutes on) still ahead, or $null; error, the
    last throw in the cycle's words, with its lead.
    #>
    param($H, $A)
    $ctx = $H.Ctx
    $now = Get-Date
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $err = $null
    $carry = Import-ChatOverlayStepCarry 'act'
    foreach ($n in 'CutCache', 'RestartCache') { if ($carry[$n] -is [hashtable]) { $ctx[$n] = $carry[$n] } }
    $procs = @{}
    foreach ($p in @($A.procs)) {
        if (-not $p) { continue }
        $start = ConvertTo-ChatqDate (ConvertFrom-ChatqStepText $p.start)
        $procs[[int]$p.pid] = [pscustomobject]@{ Id = [int]$p.pid; ProcessName = [string]$p.name; StartTime = $(if ($start) { $start.ToLocalTime() } else { $null }) }
    }
    $entries = @(Read-ChatqSessionRegistry (Join-Path $ctx.ClaudeHome 'sessions') @{})
    $alive = @($entries | Where-Object { $_.SessionId -and (Test-ChatqSessionAlive $_ $procs) })
    $live = @($alive | Where-Object { -not $_.Kind -or $_.Kind -eq 'interactive' })
    $ctx.Jobs = @(Get-ChatqJobs | Where-Object { $_.state -in 'queued', 'running', 'needs-input' } | ForEach-Object { [pscustomobject]@{ Job = $_; First = '' } })
    $ctx.JobsSig = 'step'
    $jobs = @($ctx.Jobs | ForEach-Object { $_.Job })
    $eta = @{}
    if ($A.eta) { foreach ($p in $A.eta.PSObject.Properties) { $eta[$p.Name] = [string]$p.Value } }
    # as the cycle's $held: open where their own claude continues them
    $held = @{}
    foreach ($e in $alive) {
        $kind = [string](Get-ChatField $e 'Kind')
        $ep = [string](Get-ChatField $e 'Entrypoint')
        if (($kind -and $kind -ne 'interactive') -or ($ep -and $ep -ne 'claude-vscode')) { $held[[string]$e.SessionId] = $true }
    }
    $askOn = $ctx.Config.autoContinue -eq 'ask'
    $askAny = $askOn -or $ctx.Config.autoContinue -eq 'on'
    $autoWant = Test-ChatqAutoWanted
    $crashOn = [bool]$ctx.Config.autoContinueCrash
    $on = [bool]($ctx.Config.cutOff -or $askAny -or $autoWant -or $crashOn)
    $again = $false
    $announced = @()
    $next = $null
    if ($on) {
        $ctx.CutAt = $now
        $working = @($live | Where-Object { $_.Status -in 'busy', 'waiting' } | ForEach-Object { [string]$_.SessionId })
        try { $ctx.CutScan = @(Get-ChatqCutOffChats @() -Hours 168 -Cache $ctx.CutCache -Skip $working) }
        catch { $err = "cut off: $($_.Exception.Message)" }
        $ctx.AskState = Read-ChatqAskState
        if ($askAny -or $ctx.Config.cutOff -or $crashOn) {
            $pending = @{}
            try {
                $ctx.RestartScan = @(Get-ChatRestartCutOffs -Live $alive -Asked $ctx.AskState -Jobs $jobs -Cache $ctx.RestartCache `
                        -Pending $pending -Prune -Now $now)
            }
            catch { $err = "restart: $($_.Exception.Message)" }
            if ($pending.Count) { $again = $true }
            if ($crashOn) {
                $sent = @(Invoke-ChatqCrashContinue $ctx $ctx.RestartScan $jobs $now -Held $held)
                if ($sent.Count) { $ctx.RestartScan = @($ctx.RestartScan | Where-Object { (Get-ChatqCutKey $_) -notin $sent }) }
            }
        }
        $took = $sw.ElapsedMilliseconds
        if ($took -gt 250) { Write-ChatOverlayLog "the cut-off scan took $took ms" }
        $ctx.CutOff = @(if ($ctx.Config.cutOff) {
                $ctx.CutScan | Where-Object { $_ -and (($_.ResetsAt -and $_.ResetsAt -gt $now.AddHours(-12)) -or ($_.At -and $_.At -gt $now.AddHours(-12))) }
                $ctx.RestartScan | Where-Object { $_ -and $_.At -and $_.At -gt $now.AddHours(-12) }
            })
        try {
            $scanRows = @($ctx.CutScan | Where-Object { $_ -and $_.At -and $_.At -gt $now.AddHours(-13) })
            if (Update-ChatOverlayAuto $ctx $alive $now $eta -Scan:$autoWant -Rows $scanRows) {
                $jobs = @($ctx.Jobs | ForEach-Object { $_.Job })
                $ctx.Blocks = try { Get-ChatqBlocks } catch { @{} }
                if (-not $ctx.Blocks) { $ctx.Blocks = @{} }
                $eta = Get-ChatqEta $jobs $ctx.Blocks -SendAt @{}
                Update-ChatOverlayAutoStates $ctx $alive $now $eta
                $ctx.JobsSig = $null
            }
        }
        catch { $err = "auto-continue: $($_.Exception.Message)" }
        $ctx.Ask = $null
        if ($askAny) {
            $limited = $false
            $nowMs = ConvertTo-ChatOverlayMs $now
            foreach ($u in @($A.usage)) {
                if (-not $u -or [string]$u.provider -ne 'Claude') { continue }
                foreach ($w in @($u.windows)) {
                    if ($w -and $w.label -in '5h', 'week' -and $w.limited -and $w.resetsAt -and [int64]$w.resetsAt -gt $nowMs) { $limited = $true }
                }
            }
            try {
                $ctx.Ask = Get-ChatqResetAsk -CutOff (@($ctx.CutScan) + @($ctx.RestartScan)) -Held $held -Asked $ctx.AskState -Jobs $jobs -Limited $limited -Now $now `
                    -RestartOnly:(-not $askOn)
            }
            catch { $err = "reset ask: $($_.Exception.Message)" }
        }
        if ($ctx.Ask) {
            $ctx.AskShown = Read-ChatqAskShown
            $new = @($ctx.Ask.Keys | Where-Object { -not $ctx.AskShown[$_] })
            if ($new.Count) {
                $ctx.AskNews = [pscustomobject]@{ Ask = $ctx.Ask; Keys = $new }
                Add-ChatqAskShown -Keys $new
                $n = [int]$ctx.Ask.Count
                $ids = (@($ctx.Ask.Items | ForEach-Object { $s = [string]$_.Id; $s.Substring(0, [Math]::Min(8, $s.Length)) }) -join ' ')
                $rn = [int]$ctx.Ask.Restart
                $after = if ($rn -le 0) { "the $(Format-ChatOverlayAskAt $ctx.Ask.ResetsAt $now) reset" } elseif ($rn -ge $n) { 'a VS Code restart' }
                else { "the $(Format-ChatOverlayAskAt $ctx.Ask.ResetsAt $now) reset and a VS Code restart" }
                Write-ChatOverlayLog "ask: $n cut-off chat$(if ($n -ne 1) { 's' }) can continue after $after - $ids" -Always
                $announced = $new
            }
        }
        Update-ChatOverlayAsk $H
        Show-ChatOverlayAutoQueued $H
        # the cycle redoes the states and the ask each pass; this host holds
        # them to the next look, made due when the clock alone would change
        # them: a limit row's reset, and its ask's time after it
        foreach ($r in @($ctx.CutScan)) {
            if (-not $r -or [string]$r.Why -ne 'limit') { continue }
            $rs = $r.ResetsAt
            if ($rs -isnot [datetime]) { $rs = ConvertTo-ChatqDate $rs }
            if (-not $rs) { continue }
            foreach ($t in $rs, $rs.AddMinutes($script:ChatqAskAfterMinutes)) {
                if ($t -gt $now -and (-not $next -or $t -lt $next)) { $next = $t }
            }
        }
    }
    if ($on) {
        $carry['CutCache'] = $ctx.CutCache
        $carry['RestartCache'] = $ctx.RestartCache
        $carry['AskLast'] = @{ Ask = $ctx.Ask }
        Export-ChatOverlayStepCarry 'act' $carry
    }
    $states = [ordered]@{}
    foreach ($k in @($ctx.AutoStates.Keys)) {
        $st = $ctx.AutoStates[$k]
        $states[[string]$k] = [ordered]@{
            state = [string]$st.State; words = [string]$st.Words; long = [string]$st.Long; why = [string]$st.Why
            seq = $st.Seq; jobId = $st.JobId; at = [string]$st.At; tag = [string]$st.Tag
        }
    }
    $ask = $ctx.Ask
    return [ordered]@{
        on         = $on
        cutOff     = @($ctx.CutOff | Where-Object { $_ } | ForEach-Object {
                [ordered]@{
                    id = [string]$_.Id; title = [string]$_.Title; why = [string]$_.Why
                    resetsAt = ConvertTo-ChatOverlayStepTime $_.ResetsAt; at = ConvertTo-ChatOverlayStepTime $_.At
                    cwd = [string]$_.Cwd; path = [string]$_.Path; cause = [string](Get-ChatField $_ 'Cause')
                }
            })
        autoStates = $states
        ask        = $(if ($ask) {
                [ordered]@{
                    count = [int]$ask.Count; resetsAt = (ConvertTo-ChatOverlayMs $ask.ResetsAt); keys = @($ask.Keys)
                    restart = [int]$ask.Restart; cause = [string]$ask.Cause
                    titles = @($ask.Items | Select-Object -First 5 | ForEach-Object { Format-ChatTitle ([string]$_.Title) 60 })
                    left = @($ask.Left | ForEach-Object { "$(Format-ChatTitle ([string]$_.Title) 60) - open in a terminal; its own claude continues it" })
                }
            }
            else { $null })
        announced  = @($announced)
        again      = $again
        jobs       = $null -eq $ctx.JobsSig
        next       = $(if ($next) { ConvertTo-ChatOverlayMs $next } else { $null })
        error      = $err
    }
}

function New-ChatOverlayHeadlessState {
    # what the console's process keeps (Start-ChatConsoleHost): the names the
    # moved news functions read off a WPF host's (New-ChatOverlayHostState),
    # and its own
    $now = Get-Date
    @{
        Ctx = $null; Tray = $null; Menu = @{}; Closing = $false
        BalloonKind = $null; BalloonKeys = @(); AskRequest = $null; AskMenuKeys = @()
        Events = [System.Collections.Generic.List[object]]::new(); EventBase = (ConvertTo-ChatOverlayMs $now); EventN = 0; Snap = $null
        # the console's own process keeps this state too, Standalone: its
        # window (Console), its waits' timer (ConWake)
        Standalone = $false; Console = $null; ConWake = $null
    }
}

function Start-ChatOverlayHeadlessHost {
    <#
    What a copy older than 0.12.0 runs to start its headless host again
    onto this code: the launch text it sends (Get-ChatOverlayLaunch -UiExe)
    names this, and a running overlay cannot be told to send another. There
    is no headless PowerShell host any more: the Rust host is the only one
    on Windows, so this starts it (Start-ChatOverlayProcess) - -UiExe, the
    exe the old code found, is ignored, as that looks for the one of this
    version - and returns, ending the process.
    #>
    param([string]$UiExe = '', [string]$Open = '')
    [void](Start-ChatOverlayProcess -Open $Open)
}

#endregion
