# Chat Session Agent Mk.5 one-line installer
#
#   iex (irm https://raw.githubusercontent.com/phal40lax78/Chat-Session-Agent-Mk5/main/install.ps1)
#
# Downloads the tool - Chat-Session-Agent-Mk5.ps1 and the src/ folder it loads -
# to a real folder and dot-sources it from there. It has to reach disk first:
# the script finds data/ and the line it writes into $PROFILE from its own file
# path, and the background watcher it starts re-loads the file by that path -
# running it out of memory leaves all three empty.
#
# One zip of the repo, never the files one by one: raw.githubusercontent.com
# caches each file on its own for minutes after a push, so files fetched singly
# can come from two versions - and a loader from one with parts from the other
# fails in ways that point nowhere near the cause. A zip is one commit.
#
# Under iex this runs in the caller's scope, which is the point - the dot-source
# at the end then lands the commands in the session you typed from. That also
# means it must not set $ErrorActionPreference or leave variables behind, and it
# cannot wrap itself in & { }, which would dot-source into a scope about to go.
#
# Set CHAT_MANAGER_DIR beforehand to install somewhere other than
# ~/Tools/Chat-Session-Agent-Mk5. Where that does not exist and the folder
# from before 0.11.11, ~/Tools/Charlie-and-the-chat-factory, holds the tool,
# that one is updated, data/ and all (Get-ChatDefaultRoot decides the same).

$chatManagerUrl = 'https://github.com/phal40lax78/Chat-Session-Agent-Mk5/archive/refs/heads/main.zip'
$chatManagerDir = if ($env:CHAT_MANAGER_DIR) { $env:CHAT_MANAGER_DIR } else { Join-Path (Join-Path $HOME 'Tools') 'Chat-Session-Agent-Mk5' }
$chatManagerWas = Join-Path (Join-Path $HOME 'Tools') 'Charlie-and-the-chat-factory'
if (-not $env:CHAT_MANAGER_DIR -and -not (Test-Path -LiteralPath $chatManagerDir) -and
    @('data', 'Charlie-and-the-chat-factory.ps1', 'Chat-Session-Agent-Mk5.ps1' | Where-Object { Test-Path -LiteralPath (Join-Path $chatManagerWas $_) })) {
    $chatManagerDir = $chatManagerWas
}
$chatManagerFile = Join-Path $chatManagerDir 'Chat-Session-Agent-Mk5.ps1'
# in data/, like every file the tool writes, and gone once copied out
$chatManagerTmp = Join-Path (Join-Path $chatManagerDir 'data') 'download'

# an untouched 5.1 may still default to TLS 1.0, which GitHub refuses - add
# 1.2 rather than replacing whatever is already enabled
if ([Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12') {
    [Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

if (Test-Path -LiteralPath $chatManagerTmp) { Remove-Item -LiteralPath $chatManagerTmp -Recurse -Force -ErrorAction Stop }
New-Item -ItemType Directory -Path $chatManagerTmp -Force -ErrorAction Stop | Out-Null
Write-Host "  downloading Chat Session Agent Mk.5 -> $chatManagerDir" -ForegroundColor DarkGray
Invoke-WebRequest $chatManagerUrl -OutFile (Join-Path $chatManagerTmp 'main.zip') -UseBasicParsing -ErrorAction Stop
Expand-Archive -LiteralPath (Join-Path $chatManagerTmp 'main.zip') -DestinationPath $chatManagerTmp -Force -ErrorAction Stop
# src/ before the file that loads it: stopped between the two, a copy from
# before src/ existed still loads whole, since it reads nothing there. The
# zip's one folder is the repo's name and the branch, whichever name the
# repo has had.
$chatManagerFrom = @(Get-ChildItem -LiteralPath $chatManagerTmp -Directory -ErrorAction Stop)[0].FullName
New-Item -ItemType Directory -Path (Join-Path $chatManagerDir 'src') -Force -ErrorAction Stop | Out-Null
Copy-Item -Path (Join-Path (Join-Path $chatManagerFrom 'src') '*.ps1') -Destination (Join-Path $chatManagerDir 'src') -Force -ErrorAction Stop
Copy-Item -LiteralPath (Join-Path $chatManagerFrom 'Chat-Session-Agent-Mk5.ps1') -Destination $chatManagerFile -Force -ErrorAction Stop
Remove-Item -LiteralPath $chatManagerTmp -Recurse -Force -ErrorAction SilentlyContinue
# The loader's name before 0.11.11, there from an older install: a stand-in
# that loads this one, as extension/setup.js writes, so whatever still names
# it - a watcher of the old version starting itself again, a profile line
# chatinstall below has not rewritten yet - loads this copy
# Deferred: DEFERRED.md "The old name's alias and loader"
$chatManagerWas = Join-Path $chatManagerDir 'Charlie-and-the-chat-factory.ps1'
if (Test-Path -LiteralPath $chatManagerWas) {
    $chatManagerVer = [regex]::Match([System.IO.File]::ReadAllText($chatManagerFile), '(?m)^\$script:ChatVersion = ''(\d+\.\d+\.\d+)''').Groups[1].Value
    [System.IO.File]::WriteAllText($chatManagerWas, (@(
                "# Charlie-and-the-chat-factory.ps1 was the loader's name until 0.11.11; it is Chat-Session-Agent-Mk5.ps1 now.",
                '# This stand-in, which every update writes, loads that one for whatever still',
                '# names this file. chatinstall rewrites a profile line to the new name.',
                "`$script:ChatVersion = '$chatManagerVer'",
                ". ([System.IO.Path]::Combine(`$PSScriptRoot, 'Chat-Session-Agent-Mk5.ps1'))", '') -join "`r`n"))
}

. $chatManagerFile
chatinstall

Remove-Variable chatManagerUrl, chatManagerDir, chatManagerFile, chatManagerTmp, chatManagerFrom, chatManagerWas, chatManagerVer -ErrorAction SilentlyContinue
