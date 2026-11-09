# Changelog

## 1.2.3 — Questions answered from the phone by default, no stale plan rows

- **Answering Claude's questions from the phone is on by default.** It
  was off unless `chatnotify -Ask on`, so a reply typed on the phone as
  the answer went in as a prompt instead. Now `ask.on` counts as on
  unless switched off, and the watcher installs the `chatq-ask` plugin as
  it starts, or updates it when it is an older chatq's
  ([Sync-ChatqAskHook](src/ask.ps1)). Reload a VS Code window for the
  chats open in it. `chatnotify -Ask off` still turns it off; it stays
  the way out when Claude Code's hook behaviour, undocumented for this
  tool, changes.
- **A queued plan-mode run ends `done`, not `plan ready - approve it in
  VS Code`.** A `-p` run gets no `ExitPlanMode` (nor `AskUserQuestion`),
  so there never was a plan to approve: the run had replied. Parked on
  needs-input, its row stayed on the overlay until something was typed
  into a chat that might not even be open - 6 h 40 min, once
  ([Get-ChatqClaudeOutcome](src/queue.ps1)).
- **A phone prompt sent behind a question asks before it goes.** Typed
  while the chat waited on a question at the PC, it could only run once
  the PC had answered, and then went in as a new turn on top of that
  answer. Such a prompt is now marked ([Set-ChatqBehindAsk](src/ask.ps1))
  and, once the chat is free, parked on needs-input: `the question it was
  sent behind was answered at the PC - send it still?`. Continue sends it
  whole, never as "continue" ([Reset-ChatqJob](src/commands.ps1));
  anything typed in the chat skips it. The phone's reply says so, and the
  page's box reads `A new prompt - not the answer`
  ([docs/reply.html](docs/reply.html)).

## 1.2.2 — The phone's alert page in Character view's look

- **An alert opened from a push looks like the chat view.** 1.1.10 gave
  the look to the chat view alone; the page a push opens kept the green
  event pill and round boxes. It is now headed as a quest row (the event
  the yellow line, the badge done green, working yellow, waiting red),
  Claude's answer sits in the red box headed `MESSAGES › CLAUDE`, the
  boxes are square with a cut corner, and Send is the cyan key. As in the
  chat view, the answer shows whole, with no Show all or Copy
  ([docs/reply.html](docs/reply.html)).

## 1.2.1 — OPEN blinks, no toasts in Character view, slower RAM drop

- **OPEN blinks when clicked, the quest row no longer does.** Opening a
  chat holds the overlay about half a second, longer than a key's whole
  blink, so OPEN's blink was over before it was drawn and only the quest
  row's longer blink showed. A key's blink now runs from its first frame
  and at most a step a frame
  ([App::key_catch_up](native/overlay/src/app/pointer.rs)); the quest
  row's blink on an open is gone, and a click on the card blinks OPEN as
  the key does ([App::card_hit](native/overlay/src/app/pointer.rs)).
- **ARCHIVE and DELETE blink after their ring.** Held to the end, the
  row is sent away at once as before, but the card stays for the key's
  blink, taking no more clicks, and goes after it
  ([App::key_click](native/overlay/src/app/pointer.rs)).
- **Character view shows no alert toasts either.** A chat's done or
  needs-input alert popped a Windows toast even with the HUD up, past
  1.2.0's balloon drop. While Character view shows (overlay-ui.json's new
  `hud`, written in the last 10 s) the toast is skipped, the phone and
  your command still go; panel view keeps it
  ([Test-ChatqCharacterView](src/alerts.ps1), [App::write_ui](native/overlay/src/app.rs)).
- **The RAM's drop plays four times slower, each pip emptying top
  down.** The health and stamina keep their 1.1 s; the RAM's fill holds
  1.2 s and sinks over 3.2 s, and the pip it is leaving loses its cyan
  from the top, so the pips can be seen going one by one
  ([bars::RAM_SLOW](native/overlay/src/bars.rs)).

## 1.2.0 — Status boxes, smoother HUD, bars fill on a drop

- **A usage drop fills the bars to the top and back.** When a window's
  share falls, its bar snaps to the new value and a cyan fill stands
  from the new edge to the top at once, holds (0.3 s) and sinks back
  onto the edge (0.8 s): the health bar, each stamina line and the
  RAM's used pips alike. It replaces the 10 % pale block, white sliver
  and red pip ripple; a bar that rises (a reset) snaps without it
  ([bars::drop](native/overlay/src/bars.rs)).
- **Alerts are status boxes, the stage has no tags.** In Character view
  the tags down the character's left (AUTO, ASK, USAGE, MUTE, NEXT, NOTE,
  MEMORY, LEAK, `RLD n`, WATCHER, ERROR) are gone, all still in the
  panel, the tray and the notes; right of the bars (or at the window's
  left with no gauges: the window now shows for the boxes alone) stand
  cut-corner boxes with an icon, a short text above it and a ring round
  it sweeping clockwise, in the order MEM, RLD, `!`. MEM shows above 85%
  used (the ring the percent, the text `NN%`, red above 90%), or while a
  program leaks: its icon red, the text `LEAK` at or under 85% (the ring
  empty when the percent is unknown), and a hover card naming the
  leaking programs. RLD is the first reload ask for its 30 s (the ring
  the time gone, the text the seconds left, the box gone at a whole
  turn). `!` is a watcher or an error note: a whole red ring, a red `!`,
  no text, a hover card with the note. The memory note and the tray's
  balloon still come at
  `memoryWarn` (95). The snapshot's header gains `memoryPct` (the last
  look's percent while above 85, or at any level while a leak is
  active; read even when `memoryWarn` is 0, which still means no note,
  no balloon and no top-programs listing) and each `reload` item `seenAt` (epoch
  ms), in both collectors
  ([hud.status_boxes](native/overlay/src/hud.rs),
  [Update-ChatOverlayMemory](src/overlay-data.ps1),
  [memory.update_memory](native/overlay/collect/src/memory.rs),
  [reloads.reload_json_seen](native/overlay/collect/src/reloads.rs)).
- **A delete says so on the panel only.** Deleting a chat no longer
  pops a Windows tray balloon; its row's said marker tells the result,
  a warning when kept. Archive keeps its balloon
  ([remove.answer](native/overlay/collect/src/remove/mod.rs),
  [Invoke-ChatOverlayPanelVerb](src/overlay-host.ps1),
  [Invoke-ChatOverlayDeleteChip](src/overlay-windows.ps1)).
- **Character view shows no tray balloons.** While the HUD is up,
  every Windows tray balloon - the host's and the panel's own - is
  dropped (logged as `ui: balloon <kind> (character view, dropped)`);
  panel view still shows them
  ([App::show_balloon](native/overlay/src/app.rs)).
- **Korean titles bend with the visor.** A line with a letter the HUD
  face lacks (Hangul, kana, Chinese, an arrow) fell back to text lifted
  in whole-pixel steps instead of following the visor's curve. Such a
  letter now takes its outline from the first of Malgun Gothic, Yu Gothic,
  Microsoft YaHei and Segoe UI Symbol that has it; invisible marks
  (variation selectors, joiners) draw nothing. Emoji still step
  ([glyphs.letters](native/overlay/src/glyphs.rs)).

## 1.1.10 — The phone's chat view in Character view's look

- **The phone's chat view looks like the PC card in Character view.**
  The chat is headed as its quest row on the board: the project line in
  yellow capitals, then the title behind the tracker's badge, cut at its
  bottom-left corner (an empty yellow outline while it works). Your
  prompt and Claude's answer share one red-outlined box headed
  `MESSAGES › CLAUDE`, as the game's phone does: no name over each
  message, the side says who sent it. Boxes are square with a cut
  corner, labels condensed capitals in cyan, the text in the HUD face
  (Bahnschrift, else the phone's condensed sans). Send is a key as the
  game phone's CALL and CLOSE: a cyan disc, its name in red capitals
  ([docs/reply.html](docs/reply.html)).
- **The whole answer shows, asked for as the chat opens.** Show all,
  Copy, Status and Read the last answer are gone from the chat view;
  opening a Claude chat asks the PC for its last answer at once
  ([openChat](docs/reply.html)), and the answer is never cut to part of
  the screen. The prompt box is two lines tall.

## 1.1.9 — Demo mode is easier to stop

- **Demo mode is easier to stop.** Its console takes keys: Space pauses
  and resumes, R plays the scene again, Q or Esc ends it. Closing the
  console now ends the scene too; before, the box, mood and patches
  stayed and the skin stayed quiet until `--end`. While a scene is on,
  the tray's Demo mode item reads End demo and ends it, the console's
  director stopping with it
  ([Director.keys_tick](tools/overlay_scene.py),
  [end_on_close](tools/overlay_scene.py),
  [App::demo_end](native/overlay/src/app.rs)).

## 1.1.8 — Smoother animations

- **Character view no longer drops frames.** Each HUD redraw took about
  290 ms: every prim counted as changed, so every window was painted
  whole again, and every bent text was cut into its letters' outlines
  anew. Slint's image never compares equal, not even two empty ones, so
  a prim never equalled itself; prims now compare field by field
  ([scene.same](native/overlay/src/scene.rs)), and each window keeps its
  last bend and bends again only what changed
  ([visor.WarpCache](native/overlay/src/visor.rs)). A redraw now takes
  about 2 ms.
- **The view switch fades on Slint's own frame clock.** The cross-fade
  between Panel and Character view no longer redraws the window from a
  16 ms timer: both looks are drawn once and the scene fades them
  ([fade.tagged](native/overlay/src/fade.rs),
  [App::fx_start](native/overlay/src/app/stage.rs)).
- **The panel's log times the UI thread.** A call into the panel that
  takes 50 ms or more is a `ui slow:` line, with where it was made; once
  a minute a `ui` line gives the time taken, the slow calls and the five
  callers that took the most, each with its longest wait between ticks
  ([uitime](native/overlay/src/uitime.rs)), in
  `logs/overlay-panel.log` in the data folder.

## 1.1.7 — The card's keys blink when clicked

- **The card's keys blink when clicked.** Only a key the chat could not
  take blinked; a taken one, as F ASK on a gauge's card, did its work
  with no sign. Every click or key press now blinks the key three times,
  50 ms out and 50 back; a taken key is lit again after, a refused one
  stays dim ([App::key_click](native/overlay/src/app/pointer.rs),
  [App::key_lit](native/overlay/src/app/pointer.rs)).

## 1.1.6 — Claude chats in tabs, asked

- **Character view's buttons show on hover.** The bar of buttons over
  the character was always up; it now shows only while the pointer is
  on the character, on the bar or between them, or while the menu is
  open. Panel view's bar is unchanged
  ([App::hud_bar_check](native/overlay/src/app/pointer.rs),
  [App::bar_on](native/overlay/src/app/stage.rs)).
- **Folded Character view's buttons always show.** Folded, Character
  view takes Panel view's stack, the bar over the card and the chip; a
  card or chip already up at the fold stayed over the bar until the next
  restack seconds later. The fold now restacks at once
  ([App::switch_look](native/overlay/src/app/stage.rs)).
- **The bar's buttons stay after a move to a monitor at another scale.**
  Unfolding just after a drag to such a monitor moved the window to its
  new corner at the old look's width first, where it stood mostly on the
  other monitor: Windows flipped its scale there and back, and the bar,
  drawn in between, lost its icons on hover. The switch now moves and
  sizes the window in one go ([App::switch_look](native/overlay/src/app/stage.rs)).
- **Asks to open Claude chats in tabs.** With
  `claudeCode.preferredLocation` unset in every settings scope (a new
  install), the extension asks at startup to set it to `panel` in your
  user settings: a chat held in the side bar gets a second process when
  the overlay opens it as a tab. **Not now** asks again next start;
  **Don't ask again** stops it. Set to anything, `sidebar` too, it is
  never asked or touched.
- **Character view's lines lean with the visor.** A bent line 14 px and
  up (quest titles, the heads, the speech box) is drawn as its letters'
  outlines through the visor's map, so it shears smoothly as the game's
  HUD does instead of stepping a pixel at a time; smaller text, as the
  usage gauges' words, is turned whole to the visor's slope ([glyphs](native/overlay/src/glyphs.rs),
  [visor::bend_text](native/overlay/src/visor.rs)).
- **A BREACHING... loading screen while Character view starts.** At the
  overlay's start, the stage holds out and the bottom centre of the screen
  the overlay is on (its work area, a window of its own, clear of the
  character and never cut by it) shows a red ring
  around a turning two-armed disc over a thin red bar. The bar eases toward 90% while
  the first snapshot is awaited, and fills in 0.2 s once that and 1.5 s have
  passed. Ring and bar then give way, in the same spot, to a dark chip with
  a red outline and `BREACHING...` in cyan (its dots count), held 0.7 s,
  then faded, and the stage boots in as it does on show. Its clock starts
  at the overlay's first show, not the process's start, so a start from
  PowerShell after a Quit shows it too, however late the host shows the
  window ([App::stamp_loading](native/overlay/src/app.rs)). Not on a
  later show, not on unfold, not in Panel view; with Windows' animations off nothing turns
  or fades, and the two phases still follow each other
  ([hud::loading](native/overlay/src/hud.rs),
  [hud::loading_screen](native/overlay/src/hud.rs),
  [App.loading_at](native/overlay/src/app.rs)).

## 1.1.5 — The reset ask, startup and the watcher wait in Rust

- **A "leave" on the reset ask, a stale answer, the wait for the watcher
  and a start with no reply standing run in Rust**
  ([actions](native/overlay/collect/src/actions.rs): `ask_leave`,
  `ask_watch`, `startup`). No PowerShell starts for them: the chats you
  leave are marked answered in `data/auto` as before, the log lines, the
  balloon and what the host does after are the step's.
- **A watcher that went away is started again by the host.** The wait
  that follows an answer to the reset ask (or the console's request) used
  to hand the step over when a watcher that was up had gone with a job
  still queued. The host now starts it itself, once, as the step did:
  the engine is chosen by the same rules chatqd's own restart uses
  (native `chatqd` if it is there, passed its check and the fuse is not
  blown; else the PowerShell watcher), and the launch is the step's -
  the same exe, arguments, hidden window and start in your home folder
  ([respawn](native/overlay/collect/src/respawn.rs)). Its 10 seconds to
  come up begin at that start, and `failed` is said in the same balloon.
- **A phone reply that changes something is taken for an hour, not half
  an hour** ([ChatqReplyActAgeDefault](src/phone.ps1), the board's
  [ChatqComposeActs](src/phone-board.ps1)): a reply or a board act sealed
  on the phone, then held up on the way - the PC asleep, the watcher down,
  the phone offline - still runs if it arrives within the hour. A look
  (status, ping, read, board, list) stays at 10 minutes, and no reply
  outlives its alert's `reply.hours`. The phone page says so.
- **Still PowerShell, on purpose.** A "continue" (it queues jobs and
  starts the watcher), the reset ask's own timer answer, a reply standing
  to keep (`reply.listen` always), and `phone-extras` (the usage
  heads-ups, their `usage-alerts.json` and the phone sends) stay the
  step's. The host decides as the job starts, so one that turns out to
  need the step goes to it
  ([act::needs_step](native/overlay/collect/src/host/act.rs)).
- **Where it differs, on purpose.** The ask's carry file is not cleared by
  a native answer (nothing reads it any more), and the markers are written
  as the other native files are, not as ConvertTo-Json words them; read
  back they are the same. A native watcher the host starts is told your
  Windows locale (name, time and digit separators) as `--culture`, where
  the step passed its PowerShell's; its `pending.json` is written before
  the child runs, as chatqd's own restart writes it; and the fuse alert a
  third failed start would send waits for the next launch from PowerShell,
  as it does after chatqd's own restart
  ([DEFERRED](DEFERRED.md): "A watcher's culture read by the host, not the
  step").

## 1.1.4 — Demo mode, and triggers for what comes by itself

- **Record mode is Demo mode, and triggers what comes by itself.** The
  menu item is renamed. A demo can now set off what you would otherwise
  wait for: a gauge moving, the 75 and 90% lines, usage running out, a
  chat starting, waiting or finishing (QUEST COMPLETE), the reload ask,
  the weekly report, the morning line. A `patch` laid over the host's
  overlay.json changes the data, so the overlay answers through its own
  code; `fire` says one event now; `lines on` lets the skin speak in a
  scene, every event then said rather than diced. One-shot options:
  `--usage claude 5h 91`, `--limit claude`, `--chat billing done`,
  `--fire morning`. The promo now shows only its own chats. The manual is
  [docs/overlay-demo.md](docs/overlay-demo.md)
  ([app/demo.rs](native/overlay/src/app/demo.rs), [cue](native/overlay/src/app/cue.rs),
  `tools/overlay_scene.py`).
- **Nothing else changes.** With no scene, the overlay runs as before.

## 1.1.3 — Settings, the chip and the switches in Rust

- **The panel's settings, the chip's reload answer and the switches run
  in Rust** ([actions](native/overlay/collect/src/actions.rs)): `config`
  (the clamps and rounding of opacity, rows and sizes), `reload-answer`,
  the crash continue's on and off, auto-continue's on, ask and off with
  its one-time notice, and closing the jobs you answered in the chat. No
  PowerShell starts for them; the balloons, the log lines and what the
  host does after are the same as the step's.
- **The chip's "don't continue" and "continue" still start PowerShell**
  (`auto-chip`): they take a job and its files away or queue one and start
  the watcher.
- **Where it differs, on purpose.** A config.json that will not read,
  holds a date or is no object is left as it is and the setting is said
  to have failed, where the step wrote `{}` over it. An opacity of `NaN`
  is refused. Closing an answered job no longer writes back a job file
  removed meanwhile.
- The shared job writer ([jobs::finish_job](native/crates/chatq-core/src/jobs.rs))
  now serves the failed pick and the answered close alike.

## 1.1.2 — Queue numbers start again at #1

- **A job's number counts only the open jobs** - queued, running,
  needs-input or failed ([New-ChatqSeq](src/commands.ps1)), so once
  nothing is open the next one is #1 again, not one past every job the
  queue folder still holds. A done job keeps its old number.
- **`#n` finds the open job first** ([Find-ChatqJob](src/queue.ps1)):
  where a done job shares the number, `chatqrm 3` and the rest act on the
  open one, then the newest.
- **A done job's prompt file is never taken.** A new job whose number and
  chat title would name the same `#n <title>.md` takes the next number
  ([New-ChatqJobSlot](src/commands.ps1)).
- A failed job left in the queue still counts as open, so the numbers go
  on from it until it is removed.

## 1.1.1 — The look, delete and archive in Rust

- **The cut-off look needs no PowerShell.** The Rust host scans for
  chats the limit or a restart cut off on a thread of its own, once a
  minute as before, and works out the rows, auto-continue's states and
  the reset ask itself; the `act-look` step is gone, and so is the
  "look keeps failing" fuse. A scan that runs past 30 s or dies shows
  `cut off: ...` in the header and the host runs on
  ([host::lookscan](native/overlay/collect/src/host/lookscan.rs)).
- **The look's own writes are Rust's.** Answered marks over 8 days old
  and the restart notes' pruning, the `.shown` marks and the one `ask: N
  cut-off chat(s) can continue after ...` line with its balloon
  ([marks](native/overlay/collect/src/marks.rs),
  [restarts::cutoffs](native/overlay/collect/src/restarts.rs)).
- **PowerShell starts only to queue.** The crash continue and
  auto-continue's scan are sent to a `look-queue` step, and only where
  Rust finds a candidate, never the same set within 5 minutes
  ([lookqueue](native/overlay/collect/src/lookqueue.rs)). The
  `auto-continue: ... not queued - ...` lines are logged once a host.
  The ask's answers (`ask-answer`, `ask-phone`) carry the ask with them.
- **Delete and archive of a chat run in Rust**
  ([remove](native/overlay/collect/src/remove/mod.rs)): the files, the
  index, the tombstone, the open tabs and the reload ask, as the step
  did. A chat with a prompt queued or running still goes to the step; a
  delete that errors, panics or runs past its time is listed as
  unfinished.
- **Review fixes to the port.** A process table that will not read
  refuses a delete or archive (an unfinished one) instead of reading as
  no chat working. The look-queue's 5-minute guard is kept, and the crash
  rows taken out of the scan stay out, only once the job is queued; one
  dropped (lane busy or stalled) loses no continue, and a step that
  failed lets the set go again at the next scan. A scan or a delete past
  30 s is ended as failed, but no other starts until its thread does. The
  ask's answers with no ask given answer as stale, never an older one.
- **Found by a vector:** the crash continue's marker check read `source`
  with case, where PowerShell's does not (`overlay-lookqueue`).

## 1.1.0 — Cards and usage asks in Rust

- **A row's card comes at once.** The Rust host reads the transcript's
  end itself, in a thread of its own, instead of starting PowerShell for
  it: some 3 s a card before, up to 30 s on pwsh 7.4. The last card
  asked for wins, and no act waits for it
  ([card::answer](native/overlay/collect/src/card/mod.rs)).
- **ASK on a gauge needs no PowerShell.** The usage fetch that ASK
  and the timed asks start - Claude's endpoint, `gh api` and
  `codex app-server` - now runs in the Rust host, each provider on a
  thread of its own to its own deadline (15 s, 20 s, 20 s), where
  PowerShell started for every ask: the gauge spins and updates with no
  step process between. A provider that fails, runs late or panics fails
  alone, and the host's end stops the fetches that are out
  ([usage_fetch::ask](native/overlay/collect/src/usage_fetch/mod.rs),
  [usage::Net](native/overlay/collect/src/host/usage.rs)). The login's
  token is read in the fetch alone, and Claude's endpoint is asked
  through Windows' own curl.exe with the request on its stdin: a
  firewall that blocks outbound by default lets curl out, not
  chatq-overlay.exe ([sys::http](native/overlay/collect/src/sys/http.rs)).
  The `usage` step and its
  `ostep-usage` role are gone; the PowerShell host's own fetches are
  untouched.
- **Resting on a gauge brings only its keys.** Since 1.0.2 it brought a
  copy of the gauge itself; the gauge already says it, so now only the
  keys row stands beside it, ASK and the rest
  ([App.card_target](native/overlay/src/app.rs)).
- **F works where the card was brought up.** The card's letters were the
  keyboard's only with the pointer on the card itself, so F on a gauge
  card - where the pointer is when its hover card comes - did nothing.
  They now are with the pointer on the card, on a gauge card or on a
  quest row while its card is up; anywhere else typing keeps them
  ([App::card_letters_at](native/overlay/src/app/pointer.rs)).

## 1.0.2 — Chats by their titles, and "now tracking"

The overlay names a chat by its title, not its folder, says less of what
it already shows, and an open ends on the quest tracker's word.

- **NEW QUEST waits for the AI's title.** A new chat's banner would show
  its first prompt when it reached the list before Claude named it. A
  Claude row carries `titled` (false while its title is the first
  prompt; Get-ChatOverlayRows in [overlay-data.ps1](src/overlay-data.ps1),
  [rows.rs](native/overlay/collect/src/rows.rs)), and the banner waits for
  it, up to 10 s ([card::titled](native/overlay/src/card.rs),
  `card::TITLE_WAIT`), then shows the first prompt as before.
- **An open says "now tracking".** The line once an open is done reads
  `now tracking '<title>'`, and the character says `Now tracking: {chat}.`,
  where both said "opened" (Get-ChatOverlayOpenSay in
  [overlay-host.ps1](src/overlay-host.ps1),
  [says::open_say](native/overlay/collect/src/host/says.rs), `status.opened`
  in [lines.json](skins/default/lines.json)).
- **No line while it opens.** The panel's `opening '<title>'` line is
  gone: the character already says `Opening {chat}.`
  ([App.open_row](native/overlay/src/app/opening.rs),
  Invoke-ChatOverlayOpen in [overlay-windows.ps1](src/overlay-windows.ps1)).
- **The character names the chat, not the project.** The default skin's
  twelve lines that said `{project}` - started, its minutes, waiting,
  permission, a question, finished, a queued prompt sent, resumed, stopped -
  say `{chat}`, the chat's title, so two chats of one folder are told apart
  ([lines.json](skins/default/lines.json),
  [make_default.py](skins/tools/make_default.py)). A pack's own `{project}`
  still fills as before.
- **The quest card says its state once.** Character view's hover card
  dropped the words line under its head; the badge and the NOW line say
  the same ([card::chat](native/overlay/src/card.rs)). Panel view's card
  keeps it.
- **A bar a window, its words at its right.** The grey line on top counts
  to the next reset: lit by the share of the 5 h window gone, with
  `resets at 10:53` beside it; when the week resets first it counts to
  the week's. The red health bar is the 5 h window (`5H 70%`), the 36
  pips of RAM the week (`WEEK 19%`), and a gold stamina line under them
  each model's own week (`FABLE 60%`), one line per model week, none
  when there is none. The reset row under each bar and the status line
  are gone ([card::ram](native/overlay/src/card.rs),
  [card::next_reset](native/overlay/src/card.rs)).
- **A change drops each bar from 10 % above.** When a window's share
  moves, its bar shows the game's hit: a pale block over the last 10 %
  lost (from the new share plus 10 %, at most full) holds, closes to a
  white sliver at the new edge and fades, about 0.36 s. The RAM pips the
  change took go red from the top down, one after another, the filling
  run backwards ([bars::after](native/overlay/src/bars.rs),
  [bars::drop](native/overlay/src/bars.rs),
  [bars::pip_at](native/overlay/src/bars.rs)).
- **An empty 5 h window flatlines.** At 0 % the health bar becomes the
  game's FLATLINED: a glitch, a red `CRITICAL SYSTEM FAILURE` tag, then a
  skull and `FLATLINED` typed out in a cut box, about 1.1 s, held after
  ([bars::flatline](native/overlay/src/bars.rs)).
- **And the screen flatlines with it, as in the game.** In Character
  view, when a 5 h window runs out (it had some left, now none; never at
  start), the whole screen of the HUD's monitor plays the game's death:
  the screen tears red and goes black, `CRITICAL SYSTEM FAILURE` and its
  panels, a skull and `FLATLINED` in the TNC box, then they slide left
  over a red glow, with the reset time under the word. Its menu asks what
  to do about the limit: **REBOOT AT RESET** (auto-continue on), **ASK PER
  CHAT** (auto-continue asks per chat) or **JACK OUT** (just close); the
  setting in force wears the bracket. A click off the menu is JACK OUT,
  and after 60 s, counted down at the bottom right, it closes and the
  setting stays ([flatlined](native/overlay/src/flatlined.rs),
  [App::flat_start](native/overlay/src/app/stage.rs),
  [App::flat_hit](native/overlay/src/app/pointer.rs)).
- **A usage ask makes the cards vanish and come back, no blink.** While
  usage is asked the cards no longer pulse; they go and come back in with
  the dialog options' entrance ([hud::gauges](native/overlay/src/hud.rs)).
- **The red drawings round the bars.** Left of each card, as in the
  game: a `HEALTH INDICATOR` caption over the bars, a column of small red
  readouts, a crosshair and a gold bolt at the stamina line's left, the
  line itself starting under the badge, as the game's does; the gauge
  window only, not the hover card
  ([bars::decor](native/overlay/src/bars.rs)). New look tokens `exp`,
  `stamina`, `drop`, `drop-edge` (`hudExp`, `hudStamina`, `hudDrop`,
  `hudDropEdge`).
- **The gauges let clicks through too; their card has an ASK key.** A
  click on Character view's gauge window no longer asks for usage: it
  lands on what is under it. Resting on a gauge card brings the gauge's
  hover card back (gone since the gauge window came in 0.12.8), standing
  off the gauge window, with one key under it in the card's look: ASK,
  which asks for usage now, as the click did. A click on that card opens
  nothing ([App::entries](native/overlay/src/app/pointer.rs),
  [App::card_keys](native/overlay/src/app/pointer.rs),
  [App::start](native/overlay/src/app.rs)). The drive's `gauge-click`
  now clicks that ASK key.
- **A rest on a gauge or a quest is seen sooner, for less.** The pointer
  was looked at every 120 ms, and each look copied every row's data to
  find the one under it. Within 64 px of the gauge window, the quest
  window or the card it is now looked at every 30 ms, and only when it
  has moved; the rest of the poll (scenes, the drive, screens, tips, the
  menu, talks) stays at 120 ms, and away from them so does the pointer's.
  A look now copies only the row under the pointer
  ([App::hover](native/overlay/src/app/pointer.rs),
  [App::near_lists](native/overlay/src/app/pointer.rs),
  [App::entries_at](native/overlay/src/app/pointer.rs)).
- **A chat's card holds ten turns, and scrolls.** The open card showed
  your newest prompt and Claude's reply alone. It now shows up to ten:
  each turn's prompt and its reply (a turn's last text; what Claude said
  on the way is left out), from the transcript's last 256 KB, read
  four times further back, up to 4 MB, while that holds fewer - a
  tool-heavy chat's 256 KB can hold one prompt. The card stays as tall as
  the newest two turns made it: past two, the talk is cut to that view,
  which opens on the newest at its foot, as the phone's messages do,
  with a scroll bar at its right - in Character view the game's, a dim
  red line with a red thumb - and the wheel over the card scrolls it
  back and forth. Both views
  ([Read-ChatOverlayCardTail](src/overlay-data.ps1)'s Talk,
  [card::Talk](native/overlay/src/card.rs),
  [App::card_wheel](native/overlay/src/app/pointer.rs)). The WPF card
  keeps its two.
- **READ or UNREAD on a quest's card no longer brings its titles.** The
  key re-sorts the quest list, moving the row; the card took the moved
  row for a stage tag and grew the project and title over it, standing
  by the character. A quest is now known by its key, and its card stands
  off where the row is now ([App::quest_now](native/overlay/src/app.rs)).
- **The card's keys are the keyboard's; ARCHIVE and DELETE are held.**
  The keys under Character view's card take the game's letters - F
  OPEN (F ASK on a gauge's card), R READ or UNREAD, Z ARCHIVE, X DELETE -
  and the keyboard's keys of those letters press them, but only while
  the pointer rests on the card: elsewhere they type as ever. ARCHIVE and
  DELETE, by the mouse or the key, are held 0.8 s, a cyan ring filling
  round the disc; let go before, nothing is done
  ([App::card_shortcut](native/overlay/src/app/pointer.rs),
  [App::card_shortcuts](native/overlay/src/app/pointer.rs),
  [App::hold_tick](native/overlay/src/app/pointer.rs),
  [card::keys](native/overlay/src/card.rs)).
- **UNREAD on a chat only a tab holds.** Mark unread, on the card or
  Panel view's row menu, was greyed for a chat open in a VS Code tab with
  no Claude process - most quests. Its dot is now kept while the tab is
  open, cleared by READ or by the tab coming to the front
  ([update_unread](native/overlay/collect/src/unread.rs),
  [trayicon::row_menu](native/overlay/src/trayicon.rs)).

## 1.0.1 — A quicker open, keys under the card, QUEST COMPLETE at the left

A click on a chat's open chip brings its tab up to about two seconds
sooner: three waits that took their whole time now end as soon as there
is something to see. In Character view the quests let clicks through,
the card opens its chat and carries keys, QUEST COMPLETE moves to the
screen's left in the game's look, and the character has its own size.

- **The open request is heard at once.** The extension looked at
  `data/open-request` every 2 s, so a chip's open waited a second on
  average, two at worst, before VS Code did anything. It now has Windows
  tell it of the write (a watch on the data folder), which costs nothing
  while idle; the 2 s look stays behind it, for a watch that fails
  ([activate](extension/extension.js)).
- **The tab is looked for, not slept on.** After the open the extension
  slept 400 ms, looked for a new tab, and where none had come slept
  1.5 s more before bringing the chat's group forward and unlocking it -
  the usual case for a chat whose tab was there already. It now looks
  every 50 ms and stops at a new tab, or at the chat's own tab come to
  the front; the limits are as they were. A tab already in front before
  the click still gets the whole look, since a new one may yet come
  ([openCore](extension/extension.js), [waitFor](extension/extension.js),
  [frontChatTab](extension/extension.js)).
- **The overlay sees the open's end at once.** It looked at the open's
  PowerShell, and then for the chat's VS Code window, once a second on
  its tick. It now looks every 100 ms while an open is under way, and
  not at all otherwise ([App::open_poll](native/overlay/src/app/opening.rs)).
- **A delete from the overlay closes the chat's tab again.** Before a
  chat goes, its leftovers are listed, and a plan file is kept when
  another chat of the folder shares its slug. That check read every
  other transcript of the folder whole: in a folder of a gigabyte, a
  minute or two, so the overlay's delete step was killed at its 30 s
  before the chat went or its tab was asked to close, while the row
  had already left the panel. Either view, any chat with a slug. The
  check now runs only when a plan file of that slug exists, and reads
  each other chat's head and tail, where Claude Code stamps the slug
  on every record; worst here 0.5 s, from 113 s
  ([Get-ClaudeLeftovers](src/providers.ps1)).
- **A delete that does not finish says so.** The row leaves the list at
  the click, before the host's step has run; a step killed or failed
  was only logged, so the chat looked deleted while it and its tab
  stayed. Now the panel's line and a warning balloon say `"<title>"
  may not be deleted - the delete did not finish (<why>)`, the recent
  list is read again, and the row comes back at once - as it now does
  too on a refusal the host gives, which hid it for 45 s
  ([act::unfinished_delete](native/overlay/collect/src/host/act.rs),
  [App::keep_dropped](native/overlay/src/app/pointer.rs)). Panel view's
  bin and Character view's DELETE key are one call
  ([App::delete_row](native/overlay/src/app/pointer.rs)).
- **Panel view's buttons always show.** A row's card, held on the screen,
  could stand over the panel's top strip and cover its buttons; the bar
  is now stacked over the card and the chip in Panel view
  ([stack_order](native/overlay/src/app.rs)).
- **The quests make way for the stage.** In Character view the stage,
  left at its first place (the screen's top right), stood over the quest
  window. Where the stage's character or tags meet the quest window, the
  quests now start below them, or, with more room above, end over them;
  the quests move again when the stage is dragged and let go
  ([hud::quests_clear](native/overlay/src/hud.rs)).
- **QUEST COMPLETE moves to the screen's left, and takes the game's
  look.** 1.0.0's banner sat under the quest list, a flat plate that
  popped in. Compared again with the capture at 30 fps, it is now a
  window of its own at the work area's left edge, 44 % down, bent by the
  visor like the other HUD windows, and it never takes the pointer, so
  the quest window no longer keeps a strip for it. Its plate is a gold
  card turned in perspective, with its edge showing, carrying our own
  ring-and-tick seal (not the game's emblem). The entrance: the words
  flash a frame, the card and the seal build up in flickering pieces, an
  outline of the card swings in from the left and lands, the badge pops
  in large and settles into a soft square glow, the label types a letter
  every two frames behind a cursor, and the title comes in glowing green.
  The exit: the title flickers out, label and badge fade to a ghost, the
  badge drops to its outline, the label is cut to `QUEST COM`, a bright
  block is left, and the card goes last; 7.3 s in all, held still with
  Animations off. The red bar is gone: in the capture it belonged to
  another of the game's elements
  (since redrawn: see "QUEST COMPLETE takes NEW QUEST's look" below).
- **NEW QUEST, as the game starts a job.** A chat new to the quest list
  in Character view brings a banner in QUEST COMPLETE's window, from the
  user's capture of the game's "new job" read at 30 fps and measured to
  the pixel at 1080p. A red `CONNECTION` header types out behind a red
  block, its number the chat's own; a gold data shard's shell comes in
  and its plate, disc, hub and face fly in from the left and seat; a plus
  pops in large in a glowing cross and an outlined shield closes round
  it; `NEW QUEST` types behind a yellow block and the title comes in
  white. It holds, then the title flickers out, a block eats the label,
  the shield fades, a red bar eats the header back and the shard dims
  last; about 6 s, held still with Animations off. The capture's TRACK
  JOB prompt is left out, as the window takes no clicks. The chats a
  snapshot brings on start or on the way back to Character view bring
  none; either banner takes the other's place
  ([banner::frame_new](native/overlay/src/banner.rs),
  [banner::prims](native/overlay/src/banner.rs),
  [card::arrived](native/overlay/src/card.rs),
  [App::begun_start](native/overlay/src/app/stage.rs)).
- **QUEST COMPLETE takes NEW QUEST's look.** Set beside the user's two
  "job complete" captures, the game's done banner turned out to be the
  new job's own choreography: the same red header and box, the same gold
  shard flying together, then a green shield instead of the plus. The
  ring-and-tick card, its swinging outline and the cursor are gone. Now
  the shield pops in large and solid, settles, and opens to an outline
  round an inset as a glow square fades; `QUEST COMPLETE` types behind a
  green block and the title comes in green, a size up from NEW QUEST's.
  The parts stand where the capture's do, measured at 1080p: a larger
  shard, the text set right of it. The exit is the capture's: the shield
  loses its inset a frame, the title flickers out, label and shield fade
  to ghosts, the label is cut, a green block takes its start, a red bar
  eats the header and the shard and the red box go last; about 7.9 s,
  held still with Animations off. Both banners are one module now
  ([banner::frame_done](native/overlay/src/banner.rs),
  [banner::draw](native/overlay/src/banner.rs)).
- **QUEST FAILED, as a quest is archived.** The ARCHIVE key under a
  quest's card in Character view now leaves a banner too, from the user's
  capture of the game's "job failed": NEW QUEST's choreography, frame for
  frame and part for part, all in red, a red shard and a cross in the
  shield in place of the plus. The cross pops in large, shrinks, and the
  shield closes round it; `QUEST FAILED` types out and the title comes in
  red; about 5.7 s, held still with Animations off. A delete still brings
  QUEST COMPLETE; an archive from Panel view's row menu brings none, as
  its bin's delete brings none
  ([banner::frame_failed](native/overlay/src/banner.rs),
  [App::failed_start](native/overlay/src/app/stage.rs)).
- **Settings → Character size, apart from HUD size.** HUD size scaled
  the whole of Character view as one. The character now has its own
  size, 50, 100, 150 or 200 % (150 the default, `characterSize` in
  config.json): it scales the stage (the character and its tags) and
  the bar over it. HUD size keeps the speech box, the card, the gauges,
  the quests and the QUEST COMPLETE banner. The speech box still finds
  the character's mouth at either size ([App::want_scale](native/overlay/src/app.rs),
  [App::say_layout](native/overlay/src/app/stage.rs)).

### The quests let clicks through; the card opens the chat and has keys

- **The quest list takes no click.** Character view's quest window is
  large, and a click on it no longer stops there: it lands on what is
  under it. A quest row has no chip and no open hit; resting on it still
  brings its card ([App::start](native/overlay/src/app.rs),
  [chip::Chip::place](native/overlay/src/chip.rs)).
- **A click on the card opens the chat.** The hover card took no pointer;
  a click on it now opens its chat as the chip's open did, and a quest
  row blinks again as it opens ([App::card_hit](native/overlay/src/app/pointer.rs)).
- **Keys under the card.** In Character view a row of keys hangs under
  the card, as the game's phone puts CALL and CLOSE under a message
  (the "Message received & opened" capture): a cyan disc with a
  letter, the name in red capitals. OPEN, READ or UNREAD, ARCHIVE and
  DELETE: Panel view's row menu without Snooze, and the bin's delete.
  A quest deleted here leaves the QUEST COMPLETE banner. A key the chat
  cannot take sends nothing; it blinks three times, 50 ms out and 50 back,
  and stays dim while the card is up ([card::keys](native/overlay/src/card.rs),
  [App::card_keys](native/overlay/src/app/pointer.rs),
  [App::key_click](native/overlay/src/app/pointer.rs),
  [App::key_lit](native/overlay/src/app/pointer.rs)).
- **The hover card is 25 % larger.** Text, padding and width grow
  together, in both views, at every HUD size; the card still stands
  where it did beside the row and the character. The keys under it keep
  their size, already large beside it
  ([App::want_scale](native/overlay/src/app.rs), `CARD_ZOOM`,
  [card::keys](native/overlay/src/card.rs)).
- **No quest swipe.** With the list click-through a quest row cannot be
  pressed: swipe-to-delete on it is gone, DELETE taking its place. Panel
  view's tiles swipe as before.
- **Skippy reports the week every 5%.** Each time a week window passes
  a new 5% step he opens a talk of his own: "Hello, user. I have prepared
  a usage data report for you." / "Please say anything to continue.",
  with one gold "Anything." row for 5 s. Picked, it gets the game's
  canned laugh ("It looks like you're trying to be funny..."); either
  way he then says the week's percent. Not while muted, over another
  talk or a scene, or outside Character view; the step the panel starts
  at is not news ([Watch.diff](native/overlay/src/events.rs),
  [App.talk_weekly](native/overlay/src/app/dialog.rs),
  [Talk.at](native/overlay/src/talk.rs); skin-pack.md "dialog").
- **"Still got eddies to burn?" goes straight to the report.** The
  usage row's opener and its "Anything." joke moved to the weekly talk;
  the row now says "Processing request." and the windows.
- **Record mode plays on the real overlay.** It used to stop the
  overlay and start a second one on a made-up data folder, whose chats,
  gauges and settings were written by the scene tool by hand and fell
  further behind the real ones with each change. Record mode now plays
  the scene's lines and replies on the overlay already running, as it
  is: the scene's own chats and usage are not applied. The overlay turns
  a scene on when `data/scene-in` comes and off at its `end` line, which
  the tool sends when the scene ends or on Ctrl+C; the skin's own lines
  wait in between. One line at a time:
  `py tools/overlay_scene.py --say "text" --mood smug`, then `--end`.
  A pick now goes back in `data/scene-out`, not `overlay-cmd`
  ([App.cue_poll](native/overlay/src/app/cue.rs),
  [App.record](native/overlay/src/app.rs), `tools/overlay_scene.py`).
- **The unread dot goes by the chat's tab, not by VS Code.** A chat that
  finished while VS Code was in front got no dot, even with another tab
  in front of it: the overlay could only tell which program was in
  front. The extension now marks, in `data/open-tabs`, the Claude tab in
  front of a focused window once it has stayed there a second, so a chat
  whose tab is listed gets its dot unless that tab was in front, and
  loses it when its tab comes to the front - reading it in VS Code
  clears it, as VS Code's own tab dot clears. A Mark unread on the tab
  in front holds until you leave it and come back. Tabs that share a
  label, and terminal chats, go by the program as before
  ([lookFront](extension/extension.js),
  [update_unread](native/overlay/collect/src/unread.rs),
  [Update-ChatOverlayUnread](src/overlay-data.ps1)).

## 1.0.0 — Character view at the game's size

Character view takes the game's HUD whole: the character stands at the
game's size, the HUD bends on its visor and scales by Settings → HUD
size, a quest swiped away ends in a banner, and the overlay's motion
has its own switch.

### Skippy jabs by form, and the open's line stops counting

- **The open's line has no countdown.** The panel's marker while a chat
  opens reads `opening '<title>' in VS Code`, and the chip's hint
  `opening`, for as long as the open runs; the seconds that ticked after
  them are gone ([model::open_busy_text](native/overlay/src/model.rs),
  [App::open_tick](native/overlay/src/app/opening.rs),
  Get-ChatOverlayOpenSay in src/overlay-host.ps1, the overlay-panel
  vectors).
- **Skippy's voice, narrowed.** The bible
  ([design/skippy/voice/bible.md](design/skippy/voice/bible.md), Decisions
  on record 5, section 4 "Jabs by form only", checks 8 to 11) withdraws
  the roast bank's verdict tails ("Priorities.", "Unlike some.", "Bold."):
  a jab is a readout, a lookup, a note to self or a fun-fact tag. "Automated
  response: Ha ha ha." lives only in the Clippy bit, "I'm so glad I could be
  of assistance." is its own box after he overrides or ignores the user,
  fun facts are about the world off the screen (none about bugs or code),
  and the Disturbia hum is also rare small talk (`talk[]` topic `melody`).
  The Skippy pack (`data/skins/skippy`, its own repo) is swept to match.
- **Known gap.** The pack's `status{}` lines are loaded but not said
  (FUTURE_WORK.md, "The pack's status lines are not said").

### The overlay animates on its own say

- **Settings → Animations.** The native menu's Settings has
  **Animations**: On (the default), Off, or As Windows. Until now the
  overlay's motion followed Windows' own "Animation effects"
  (Accessibility → Visual effects) alone, so a PC with it off - turned off
  for the rest of Windows - never saw the HUD's box slide, its loops, the
  glitches, the boot-in or the quest banner play. On plays them whatever
  Windows says, Off holds them still, As Windows is the old behaviour. A
  pick takes effect at once, no restart
  ([win32::animations_on](native/overlay/src/win32.rs),
  [App::animations](native/overlay/src/app.rs)).
- **Kept in config.json** as `overlay.animations` (`on`, `off` or
  `windows`; anything else is on), read by Get-ChatOverlayConfig and its
  Rust port alike. The hosts take `config animations <word>` from the
  panel, and now `config hudSize` with the menu's four sizes too, which
  their verb checks had refused.

### A quest swiped away ends in a banner

- **QUEST COMPLETE under the list.** A quest row swiped to the right past
  the kill distance in Character view, and so deleted, leaves a banner
  under the quest list, timed frame by frame (30 fps) from a capture of
  the game's "job complete": the words flash for a frame, then a yellow
  plate flickers up at the left and glitches, a green badge pops in large
  and settles, `QUEST COMPLETE` types out beside it and the chat's title
  comes under them in green capitals, two lines at most. It holds, then
  goes broken - the title flickers out, the label comes back scrambled
  and cut over a red bar, the badge pops and goes, the plate fades last -
  7.7 s in all ([card::done_frame](native/overlay/src/card.rs),
  [card::done_banner](native/overlay/src/card.rs)). The plate and its mark
  are drawn in code; nothing of the game's art or sound is used.
- **When it plays.** It starts at the swipe's release
  ([App::done_start](native/overlay/src/app/stage.rs)), a later delete's
  replacing it, and a fold to Panel view ends it
  ([App::switch_look](native/overlay/src/app/stage.rs)), so it never comes
  back mid-way. Panel view's deletes, a refused swipe and `chatrm` from a
  shell bring none. With Windows' animations off the banner shows held,
  still, for the same 7.7 s. The list keeps room for it under its cap, and
  with the last quest gone the banner is the window alone.
- **A chat's state in the quest list.** Each chat row's badge and ink
  now say six things ([card::Sign](native/overlay/src/card.rs), chosen by
  [hud::row_sign](native/overlay/src/hud.rs)): at work, a yellow empty box,
  lit; needs you (waiting, or Claude or a chatq job asks), a yellow filled
  badge with a `!`, lit; finished and unread, a red badge with a `!`;
  finished and read, a red empty box; cut off, a green badge with a
  `!`, half lit; queued, green text and no badge. A status beats unread, so
  a cut-off chat stays green until it clears. The order of the rows is as it
  was, and the Panel view's colours are untouched. The card's head wears
  the same look. The old filled-badge tick is gone from the rows; the
  banner above keeps its own.
- **It blinks when it changes.** A row whose state changes, or that
  appears after the list is up, blinks as a todo does when it finishes, and
  the blink is a lit row, as the game's: a teal bar from 4 left of the
  badge to 14 past the longest line, 10 over the badge to 2 under the last
  baseline, its edges falling off over 6 units so no border shows; the text
  and the filled badge bloom in the teal and move half way to it while lit.
  Teal on every row, whatever its sign. It runs 110 ms on, 50 off (a 160 ms
  period) for six cycles to 0.96 s, a no-badge state's box fading out to
  1 s, then flickering to rest at 1.25 s
  ([card::signs_after](native/overlay/src/card.rs),
  [card::sign_pose](native/overlay/src/card.rs),
  [card::completion_bar](native/overlay/src/card.rs),
  [card::badge_bloom](native/overlay/src/card.rs),
  [card::lit_toward_bar](native/overlay/src/card.rs)). Rows there at the
  start never blink, and with Windows' animations off the new look shows at
  once.
- **It blinks when clicked.** The click that opens a quest row blinks it
  again, the same blink from the click, its state kept
  ([card::restamp](native/overlay/src/card.rs), from
  [App::clicked](native/overlay/src/app/pointer.rs)); a swipe is no click,
  and with Windows' animations off nothing blinks. The cyan rectangle that
  stood round a quest row under the pointer is gone
  ([chip::Entry.quest](native/overlay/src/chip.rs)): the row opens on a click
  as before, and the "click again" and "opening" words stay. Panel view's
  tiles and the stage's tags keep their ring.

### The HUD bends on the game's visor

- **The character stays over the HUD.** The panel's window, the
  character on it, is now stacked over the speech box, the quest list and
  the gauges ([App::stack](native/overlay/src/app.rs)); dragged under one
  of them, it could not be grabbed again without the keyboard. The card,
  the chip, the bar, the edges and the menus are still over it.
- **The Character view HUD curves like the game's.** The game draws its
  HUD on a curved visor: a point's height is stretched about the monitor's
  middle row by `1 + A u^2`, `u` the point's distance from the monitor's
  centre in halves of its 16:9 width, `A` = 0.093
  ([visor::A](native/overlay/src/visor.rs),
  [Visor::map](native/overlay/src/visor.rs)). x is not changed, so the
  centre column is flat and the edges lean toward the middle row: 1.0 at the
  centre, 1.023 a quarter in, 1.093 at the monitor's edge. The constant and
  the quadratic are a fit to the game's own frames, 0.37 px rms. On a
  monitor wider than 16:9 the visor is taken as 16:9 about the centre
  (`half` in [Visor::new](native/overlay/src/visor.rs)); the game's HUD
  there is unmeasured, so that is a choice, not a fit.
- **What bends, and what does not.** The gauges, the quest list, the speech
  box and the bar of buttons are bent; the character's art (the stage's
  image prim and its `character` hit) is only moved, never bent, and Panel
  view, the menus, the popups and the chip ring are flat. Nothing bends
  when the monitor is not known
  ([App::visor_at](native/overlay/src/app/bend.rs)).
- **The character stands at the game's size.** The game's hologram of
  Skippy is about 300 px tall at 1080p; on the stage he stood about 125.
  The character's box ([hud::character_rect](native/overlay/src/hud.rs))
  grows 2.4 times, 200 x 160 to 480 x 384, so a 160 x 128 frame is drawn
  3 up and Skippy's figure, 78 % of his frame's height, stands about 300.
  Every skin grows with it. The stage keeps its margins round the box and
  grows to 596 x 468; the tags, the speech box and the card stay where
  they stood against the character. A 320 x 256 atlas is now drawn larger
  than its pixels at 100 % scale; 480 x 384 frames (`scale` 3) are 1:1.
- **HUD size: 50, 100, 150 or 200 %.** Settings → HUD size scales all of
  Character view: the stage and its character, the bar, the card, the
  speech box, the gauges and the quests. 150 % is the look above and the
  default; 100 % is two thirds of it. Each window's Slint scale factor is
  the monitor's times size / 150 ([App::want_scale](native/overlay/src/app.rs)),
  so mouse hits scale with the picture; the stage keeps its top right.
  Panel view, the menus and the chips stay at the monitor's scale. It is
  `hudSize` in config.json (50–200).
- **A mood sheet may hold 64 MiB decoded** (was 24), the whole 4096 x
  4096 sheet, so a 6 s loop of 480 x 384 frames fits whole
  ([skin::MAX_DECODED_BYTES](native/overlay/src/skin.rs)). One sheet is
  held at a time, so the overlay grows by at most 64 MiB while such a face
  shows. The on-disk cap stays 8 MiB. The private Skippy pack (4.16.0) is
  rebuilt at 480 x 384 from its 640 x 512 keyed loops.
- **A rect or a path becomes a bent path.** [visor::warp](native/overlay/src/visor.rs)
  takes a window's prims as the layout drew them and gives prims that draw
  the bent picture, as the Slint scene has no transforms. A rect whose
  bend differs by under a quarter of a device pixel across it is only
  moved, so its edges stay crisp; a wider one becomes a fill path (and a
  ring path for a visible stroke), corners in 8 segments, lines cut to 4
  units. A path is flattened, cut, mapped and rebuilt
  ([Shape::figures](native/overlay/src/art.rs),
  [Shape::from_figures](native/overlay/src/art.rs)). A cut keeps to the
  bent box of the old one.
- **Text is moved in whole-pixel runs, and is not stretched.** A one-line
  text that the bend lifts differently across its width is split into runs
  of letters where the lift, rounded to a device pixel, changes; each run
  is a text of its own, so letters stay sharp and keep their size and
  shape. Glyph height is not stretched, and kerning across a run's end is
  lost. A wrapped, elided or multi-line text is moved whole.
- **The windows stay on the screen, and the items follow.** A bent window
  grows up and down by the bend's reach in whole device pixels
  ([App::bend](native/overlay/src/app/bend.rs), `Bent`), the gauges and the
  quests are moved back inside the work area's rows after it
  ([App::redraw_hud](native/overlay/src/app/stage.rs)), and the window's
  region, the hit rects of the rows and the speech box's reply rows are
  bent with the picture, so a click lands on what is drawn. A row's hit
  rect is its extent at its middle column, so neighbouring rows meet edge
  to edge on a slant. The hover card is not bent: it stays flat, beside the
  row as it is drawn.
- **The HUD windows are drawn at the game's size.** The game's 1080p pixel
  sizes are our layout units, so on a 1440p monitor the HUD is 0.75 of the
  game's relative size (it was about 0.44 for the quests and speech, 0.62
  for the gauges); on a 1080p monitor it is 1:1. The hover card keeps its
  size.
- **Gauges.** 36 pips span the bar, each cut at its bottom-left; the
  health bar, its gaps, the badge (size, cut, stroke) and the texts
  (labels, shares, resets, in the HUD face, no longer Segoe) take the
  game's proportions. The gauges stand 57 from the left and 40 from the
  top of the work area.
- **Quests.** Sizes, indents, pitches, badge, crosshair (four L brackets,
  a diamond and a dot lattice) and `+N more` at the game's values; the
  text outline is the game's near-black, the tracker has a bigger haze of
  its own (the speech box's is unchanged), and the empty box has its inner
  black line. The right margin is 24.
- **The quest clock is smaller, and the stopwatch is gone.** The game's
  tracker has no clocks, and the clock's column made ours about 30 %
  wider than the game's. The clock is 17 (the objective 21), on the
  objective's baseline, with no stopwatch before it; its column is 52 (was
  84), and the window 426 wide (was 458), the objective's column still the
  game's 293 ([card::clock_font](native/overlay/src/card.rs),
  `TIMER_W`, `QUEST_W`). The face is not the cause: at the game's cap
  height our Bahnschrift is 6.5 % wider than the game's text (Slint draws
  its wdth 100; the game's is about 94), and Rajdhani would be 5 % wider.
- **Speech and tags.** The subtitle line is the game's 29 px; the subtitle
  plate is black at 40 % (the game's 27 %, turned up to read over any
  wallpaper), its feather 9, the reply rows' left rule 2 at 0.6 with the
  dark line either side, the speaker tag's font 20. The stage's tags
  (AUTO, ASK, RLD and the rest) are 27 high on a 31 pitch with a 20 px
  face, and the stage is 316 wide.
- **A quest row's card has no titles.** The quest window shows the row's
  project and objective already, so its hover card is the box under them
  alone, from the top, and comes only once it has a box (`In::bare`,
  [card::build](native/overlay/src/card.rs)). It is open from the start
  ([App::card_tick](native/overlay/src/app.rs)): shut, it would draw
  nothing for the pointer to come onto, and never open. A chat's card
  from the stage keeps its titles.
- **Character view has no tooltips.** The game's HUD shows none: a
  tooltip asked for there is dropped, and one asked in Panel view goes
  when Character view comes ([App::want_tip](native/overlay/src/app/pointer.rs)).
- **An unused window no longer says `reset`.** A window nobody has used
  reads its reset as now plus its length at every ask - Codex's free
  `month` at 0% moves 30 days on each time - so the overlay took each ask
  for a rollover and said the Codex reset line. A window says `reset` now
  only once the reset it had is past ([Watch::diff](native/overlay/src/events.rs)).
- **Tests.** Cargo: `usage_says_75_90_and_the_reset` also checks a reset
  that rolls on before it comes says nothing. The visor `the_centre_column_and_a_flat_visor_change_nothing`,
  `the_stretch_has_the_measured_numbers`,
  `a_rect_near_the_centre_stays_a_rect`,
  `a_wide_rect_at_the_left_edge_becomes_a_path_sloping_to_the_middle`,
  `a_stroke_is_a_ring_with_a_hole_and_comes_after_the_fill`,
  `a_text_at_the_edge_splits_into_runs_that_step_toward_the_middle`,
  `a_text_at_the_centre_stays_one_prim`,
  `a_wrapped_or_cut_text_is_moved_whole`, `a_path_has_its_points_mapped`,
  `a_hits_box_covers_the_warped_rect`,
  `what_is_kept_is_untouched_and_at_maps_the_indices` and
  `a_cut_follows_the_bend`; the windows
  `the_quests_at_the_right_edge_are_bent_held_in_and_found`,
  `the_gauges_at_the_top_left_stay_on_screen`, `panel_view_is_not_bent` and
  `the_mascot_is_untouched_and_its_index_steps`; the card's
  `every_quest_row_has_its_clock_and_stopwatch` is now
  `every_quest_row_has_its_clock` (and no stopwatch); new
  `a_quest_rows_card_is_its_box_alone`, `a_quest_rows_card_opens_at_once`
  and `character_view_has_no_tooltips`.
  Goldens new
  `hud-quests-visor`, `hud-gauges-visor` and `hud-say-visor`, each looked
  at; the HUD goldens (gauges, quests, speech, tags, stage, boot, glitch
  and the card heads) are rewritten for the new sizes.
  500 overlay tests pass, fmt and clippy clean.

## 0.12.9 — The phone page takes the quest tracker's look

- **The phone page in the quest tracker's look.** The board's rows are
  the tracker's quests ([rowEl](docs/reply.html)): a badge first - a
  yellow square with a `!` for work, a red empty box for a chat waiting on
  you or cut off, a green box with a tick for a recent one, a dim empty box
  for the queue, the idle and the older
  ([B.rowSign](docs/reply.html)) - the folder as a small yellow line of
  capitals above the title, which is the objective (two lines at most), and
  the age at the right, tabular. Corners are cut, not rounded, in both
  modes. The section heads are HUD headers - capitals, spaced, a diamond
  before and a rule fading out after, drawn in CSS. The folder left the
  row's small line, which keeps the rest
  ([B.rowView](docs/reply.html) gains `proj`).
- **Claude's turn is split into messages.** Claude writes many more chats
  than you do, so the whole answer is drawn as the game's phone does, not
  as one block ([B.bubbleModel](docs/reply.html),
  [drawBubbles](docs/reply.html)), on an alert's page and in a chat's view
  alike. The rule: each paragraph is a message of its own; a heading goes in
  the message of the block right after it, a heading with nothing after it
  in one alone; a code fence or a table is one message, never split at a
  blank line; a part with no blocks makes none; the split is per part. A
  tool line, a `-> N tools` fold (three or more in a row) and a note sit
  between the messages as before. `CLAUDE · 14:02` heads the turn once,
  above any tools it began with. A message has cut corners and a small
  tail at the foot - at the left for Claude's; the chat view's newest
  prompt is a sent message, `YOU`, on the right, its tail there. **Copy**
  still copies the text as it was.
- **Dark mode is the game's HUD palette.** The pink, gold and wine-black
  look and its serif and flourish are gone: near-black, dark teal panels,
  yellow for the headers, the accent and **Send** (a chamfered plate with
  near-black text), HUD red for a row's age and what is cut off, mint for
  what works, thin teal-grey lines, and condensed titles from the phone's
  own fonts (Bahnschrift, Roboto Condensed, none loaded). The messages
  take the overlay's own colours: Claude's a dark fill, teal-grey edge and
  pale ink; the sent one green. **Light mode keeps its colours** and has
  the shapes alone. The browser's bar is `#0a0c10` in dark.
- **Nothing on the wire changed.** Only `docs/reply.html`'s looks: the
  crypto, the compose acts, the CSP and the page's requests are as they
  were. `tests/reply-page-check.js` now lets the CSS hold no `data:` image
  (the flourish was the last) and `tests/board-page-check.js` holds the
  split, the drawn messages, the badges and the project line.

## 0.12.8 — The gauges and the quests take the screen's corners

- **Character only is gone; its look is Character view's.** The menu's
  **Character only** item, the `character-only` verb, the drive's `bare` and
  `Place.bare` ([app::read_place](native/overlay/src/app.rs),
  [app::place_json](native/overlay/src/app.rs)) are removed, with
  `hud::stage_bare` and the `bare` argument of
  [hud::draw_stage](native/overlay/src/hud.rs). The HUD bar and the alert
  tags stay in Character view. An old `bare` key in
  `data/overlay-state.json` is read past and dropped at the next save, as
  the lock keys were.
- **The usage arcs, the data noise, the dials and the flatline are gone.**
  What the stage draws now is the character, the tags and the bar. The
  bulging arcs (`hud::usage`), the faint noise of data (`hud::noise`), the
  column of job dials (`hud::draw_dial`, its seats and its colours in the
  look) and the drag-a-dial-to-flatline (`Drag::Flatline`, the ghost, the
  death card, the `dial-*` drive words) are removed with their tests and
  goldens. A dial's colours per state live on as
  [hud::row_tone](native/overlay/src/hud.rs), which the card's head uses.
- **A gauge window sits at the top left of the screen.** One card per
  provider with a usage window open, Claude first, stacked edge to edge, in
  a window of its own at a margin in from the work area's top left, on the
  monitor the stage is on ([hud::gauges](native/overlay/src/hud.rs),
  [hud::gauge_corner](native/overlay/src/hud.rs), `GAUGE` in
  [app.rs](native/overlay/src/app.rs)). It follows the panel's opacity, is
  hidden whenever Character view is not shown, takes the pointer only on its
  cards, and a click on a card still asks for usage
  ([App.gauge_hit](native/overlay/src/app/pointer.rs)).
- **A card's three gauges read the share left.** Stamina is the `5h` window,
  a thin line across the card in the new look token `stamina`; health is the
  `week` window, the red bar with the cut corner; RAM is the model's week
  (`Fable week`), the 15 teal pips, with no row when there is none (Codex's
  month is not shown). Each is lit by what is left, 100 minus the percent,
  where health was the reset time's share before
  ([card::ram](native/overlay/src/card.rs),
  [card::health_bar](native/overlay/src/card.rs),
  [look.HUD_CARD](native/overlay/src/look.rs)).
- **A gauge's text no longer runs past the card or over other text.**
  The reset time, which ran off the right edge, and the status, which was
  drawn over the `WEEK` share, now sit in a row per gauge, in the bars'
  order: `5H`, `WEEK`, then the model's name (`FABLE`), each share left in
  one column and each reset right-aligned at the card's edge, elided to the
  room left. The status has a line of its own under them, and a label past
  80 units is elided ([card::ram](native/overlay/src/card.rs)). The pips
  carry no text of their own. The Character view head of a usage card has
  no reset bar any more: the gauges say it.
- **A cut moves with its layer.** [fade::layer](native/overlay/src/fade.rs)
  moved a prim but not the box a cut keeps it to, so a swiped row drawn at
  an offset lost the part of it the box had slid off (seen in a golden; the
  look switch's slide had the same flaw).
- **A quest window sits at the right edge.** The chats are the quests of
  the game's tracker, in a window of its own at the work area's right edge,
  below the top: a yellow caps header and crosshair per project (rows
  grouped by `cwd`, else `project`; no folder is `OTHER`), the most urgent
  group first, and under each a row per chat, its sign badge and title in
  up to two lines, tinted by tier as the hover card's head is. Recent lines
  are not quests. Past the height the list stops with `+N more`
  ([card::quest_list](native/overlay/src/card.rs),
  [hud::quests_corner](native/overlay/src/hud.rs),
  [hud::row_sign](native/overlay/src/hud.rs)).
- **Every quest row has a timer.** At its right, a red stopwatch and the
  time Panel view's tile shows ([model::format_row_clock](native/overlay/src/model.rs)),
  always, not on hover ([card::stopwatch](native/overlay/src/card.rs)). A
  title wraps short of it.
- **Swipe a quest right to delete it.** The panel's swipe, only to the right:
  the row slides over the red block, and a release past the kill distance
  deletes the chat as the panel's does (`delete <key>`). A chat in use says
  IN USE at the foot and stays. A move up or down moves nothing, where it
  used to move the stage ([App.quest_hit](native/overlay/src/app/pointer.rs),
  [App.swipe_let_go](native/overlay/src/app/pointer.rs),
  [App.in_use_said](native/overlay/src/app/pointer.rs)). Resting on a row still
  puts up the chip and card, now beside the quest list
  ([App.entry_frame](native/overlay/src/app.rs)).
- **The say box and the hover card hang from the character.** With the
  dials gone, the box is placed by the character's own rect and the card's
  pull is measured from the character's right edge plus 5, as Character only
  did ([hud::Stage](native/overlay/src/hud.rs) `say_at` and `marks_right`,
  [Card.hud_pull](native/overlay/src/card.rs)).
- **Tests.** Cargo: `an_old_bare_key_is_read_past_and_written_away`;
  the gauges `gauges_stack_claude_first_one_card_each`,
  `a_provider_with_no_open_row_has_no_gauge`,
  `the_gauge_keeps_to_the_work_areas_top_left`,
  `the_gauge_card_lights_stamina_health_and_ram_by_share_left`,
  `a_gauge_has_no_ram_row_without_a_model_week`,
  `a_gauges_text_never_overflows_or_overlaps` and
  `a_click_on_a_gauge_card_asks_for_usage_and_a_release_off_it_does_not`;
  the stage `the_stage_says_at_the_character_and_takes_only_its_region_and_the_tags`;
  the quests `the_quests_keep_to_the_work_areas_right_edge`,
  `quests_group_by_folder_and_order_by_the_most_urgent_row`,
  `every_quest_row_has_its_clock_and_stopwatch`,
  `the_quest_list_caps_to_its_height_with_more`,
  `a_quest_title_wraps_to_two_lines_and_never_reaches_the_clock`,
  `a_recent_row_is_not_a_quest`,
  `a_swiped_quest_row_slides_right_over_red_past_the_kill` and, in the
  pointer, `a_quest_row_swiped_right_past_the_kill_is_deleted`,
  `a_quest_row_swiped_left_or_short_deletes_nothing`,
  `a_quest_row_in_use_swiped_past_the_kill_says_in_use_and_stays`,
  `a_quest_row_moved_up_or_down_moves_nothing` and
  `a_quest_row_is_an_entry_for_the_chip`; `a_layer_moves_a_cut_with_its_prim`.
  Gone with what they held: the
  bare, dial, arc, noise and flatline tests. Goldens new `hud-gauges`,
  `hud-gauges-long`, `hud-quests`, `hud-quests-capped` and
  `hud-quests-swiped`; redrawn `hud-stage-busy`, `hud-boot-mid`,
  `hud-glitch`, `hud-tags-four-fold`, `hud-builtin`, `card-hud-usage`,
  `menu-dark` and `menu-light`; deleted `hud-stage-bare`,
  `hud-builtin-bare`, `hud-stage-five-plus` and `hud-flatline-*`. Each
  looked at. 476 overlay tests pass, fmt and clippy clean.

## 0.12.7 — The card takes the game's shapes

- **A dragged row shows both blocks from the first move.** In Panel view
  the space a swiped row uncovers is no longer bare until the kill
  distance, nor whole only once the row is let go open: the grey block
  with the three dots uncovers first, beside the row, and the red block
  with the bin grows outside it once the grey is full, each glyph riding
  with its block ([hud::swipe_ground](native/overlay/src/hud.rs),
  `Ground::split`). Only
  a row on its way out slides over one block - red for a delete, grey for
  a snooze or an archive ([panel::Swipe](native/overlay/src/panel.rs)
  `out`, which replaces `springing`).
- **A chat in use shows its bin locked while dragged, too.** The dimmed
  red block and bin replace the IN USE that stood on the bare ground; a
  click on that bin still says IN USE at the foot.
- **Panel opacity reaches Character view.** The dials, tags, usage marks,
  data noise, flatline and the bar of buttons now fade with it, as the
  panel does; the character stays at full strength
  ([hud::StageIn](native/overlay/src/hud.rs) `opacity`,
  [controls::hud_bar](native/overlay/src/controls.rs)). The speech box
  and the hover card are as they were.
- **Tests.** Cargo: the panel's swipe tests now pull to a split and send
  rows out with `going_out`; `a_swiped_tile_slides_and_its_two_blocks_show_from_the_first_move`,
  `a_refused_tile_slides_and_shows_its_bin_locked` and
  `a_row_not_held_open_keeps_its_split_look_at_the_kill_and_takes_no_click`
  renamed. Goldens `panel-swipe-damage`, `panel-swipe-kill` and
  `panel-swipe-refused` redrawn,
  each looked at. New `the_opacity_fades_all_but_the_character`; the HUD
  bar's strip test checks it at 0.6. 494 overlay tests pass, fmt and
  clippy clean.
- **A gauge's card is the deck's RAM.** In Character view a usage gauge's
  card has no title: its letters (`CL`) sit in a level badge in the RAM's
  teal, cut at the bottom left. Under it the window's share left is the
  game's health bar across the card - a grey line of the whole, the red
  under it - and each window is a row of 15 teal pips of what is left, its
  label, its share and, on the one that resets first, the reset time
  ([card::ram](native/overlay/src/card.rs), the look's `ram`, `health`
  and `health-max`). Golden `card-hud-usage` redrawn.
- **The box under the floating titles is the game's window.** Cut at the
  top left only, the other corners square, its top edge twice the
  sides' (the inbox's own: two units of `trim` along the top, one on the
  sides), where the first cut was a shape of ours, chamfered at two corners
  ([card::face_hud](native/overlay/src/card.rs)). The 'frame' fill and
  'trim' edge are the look's, so skins still colour it.
- **A message is the phone's bubble.** A nick at each top corner, a bevel
  at the foot corner away from the speaker, and at the near one a tail:
  the side runs on four units below the foot and slants back to it. Claude's
  is at the left with the tail at its bottom-left; yours mirrors it at the
  right. The tail's height is part of the turn's, so the next one never
  touches it ([card::msg_bubble](native/overlay/src/card.rs)).
- **The titles are cleaner.** The old dark outline was eight copies of
  the text, shifted by fractions of a unit, which landed on different
  pixels and left an uneven rim that fattened the letters. In its place
  is a dark ring of four copies one whole unit out, in the badge's dark at
  four fifths of the ink's strength: they fall on the ink's own pixels, so
  the strokes stay thin, and the game's `#FFF850` still reads on a
  near-white wallpaper (bare, it was 1.05:1). Over it a faint haze, three
  rings of eight copies 1.5, 3 and 4.5 units out, each turned a third of a
  step on the one inside it, in an orange where the red read as a dark
  fringe: it fades out, with no rectangle's edge, and does not wash a light
  scene pink. Every line sits on a whole unit (the row pitch is 19 and a
  wrapped line's 17, where they were 19.25 and 16.5), so the objective is
  as sharp as the caps line. The face is Bahnschrift at 13 units and
  weight 350, not 12.5 at 400, whose strokes were two pixels thick
  ([card::quest_text](native/overlay/src/card.rs),
  [hud::haze_text](native/overlay/src/hud.rs)).
- **The speech box's replies are crisp and alike.** The choices are set
  in Bahnschrift as the card's titles get it, Regular at 15 units, on the
  plate and off it, not the dialogue's Rajdhani. The rows sit on whole
  units: a 21-unit pitch, each row's top and its text rounded
  ([hud::row_top](native/overlay/src/hud.rs),
  [hud::row_text_top](native/overlay/src/hud.rs)). The spec's 20.52 pitch
  put each row on its own pixel phase, so one row's shadow came out clear
  and the next one's did not. An unlit reply is its ink in its own colour
  over a halo of eight black copies 1 unit out at 0.35, no colour haze and
  no drop shadow, the same for yellow and cyan rows; the lit plate's text
  is plain ([hud::reply_text](native/overlay/src/hud.rs),
  [hud::row_font](native/overlay/src/hud.rs)). The quest tracker's
  look is unchanged. At a screen scale above 100 % a whole unit is not a
  whole pixel (125 %: 1.25), so the rows' tops and text tops, and the
  card titles' line tops (the badge and the objective rows with them),
  are rounded to whole device pixels instead
  ([hud::dev](native/overlay/src/hud.rs), `round(v * scale) / scale`,
  with the window's scale factor in `hud::SayIn` and `card::In`): the
  steps between rows are then 26 or 27 pixels at 125 %, in a fixed
  pattern, and every row meets the pixel grid alike. The windows' own
  places are whole physical pixels and the drawing's corner in them is
  rounded up to one, so the rounding holds on screen. The picker's slide
  in from the left moves a whole device pixel a step above 100 %
  ([hud::fine](native/overlay/src/hud.rs)), so the text stays on the
  grid every frame; the fade is only opacity. At 100 % the output is
  what it was.
- **The card is narrower.** 280 units, not 330, in both views
  (`model::CARD_WIDTH`); Character view's card is that and its icon column.
- **The card is on the panel's right.** It goes on the left only where it
  does not fit on the right; where it fits on neither, on the roomier side
  as before. The chip's words still go on the roomier side, and the card
  goes past them only if it is on theirs
  ([model::card_left](native/overlay/src/model.rs),
  [model::card_placement](native/overlay/src/model.rs)).
- **The card on the right sits close to the dials.** Three offsets
  stacked there: the stage's window is 16 units wider than its top dial's
  brackets, the card's gap is 5, and a chat's card had a 30-unit icon
  column it never draws in. A chat's card (short or boxed) now has no icon
  column, its text at the padding, and on the right it reaches back over
  the stage's clear margin - it takes no pointer. The titles stand 8
  units from the top dial's brackets, short or expanded, and stay put when
  the card expands: the box's outline, 12 before them, reaches a few
  units over the brackets' line. (On either side, and in the panel's card
  too, only the screen's foot moves them: an expanded card that no longer
  fits under its row is held up to the foot.) The fit on the right is asked with
  that reach, so a card that needs it near the screen's edge is not sent
  to the left. The lower dials' marks are no wider than the top one's, so
  a lower dial with no hour ticks shows a few units more. A card on the
  left is not moved by this reach (see the next entry), nor is a gauge's,
  nor one past the chip's words
  ([card::Card::hud_pull](native/overlay/src/card.rs),
  [model::card_placement_pulled](native/overlay/src/model.rs)).
- **The card on the left stands off the character, not the stage.** The
  character is fit in a 200 x 160 box and a narrow picture leaves most of
  its box empty, so the card, put a gap off the stage's edge, floated 100
  pixels or so from the character. Where it goes on the left it now
  reaches back over that empty room, until its crosshair, the rightmost
  thing it draws, stands 8 units from where the character's art begins.
  That edge is the leftmost column with any alpha (16 or more) in any
  frame of any of the skin's atlases, one at a time and let go, so it is
  the same whatever the face is doing and the card never moves with it;
  it is worked out once per skin worn, the first time a card is placed in
  Character view, and a skin with no art in it (or that cannot be read)
  gets no reach. As on the right, the fit on the left is asked with the
  reach taken, the titles stand in the same place short or expanded, and
  the window takes no pointer over the room it reaches into
  ([anim::art_left](native/overlay/src/anim.rs),
  [hud::art_edge](native/overlay/src/hud.rs),
  [card::Card::hud_pull_left](native/overlay/src/card.rs),
  [model::card_placement_pulled](native/overlay/src/model.rs)). The room
  the alert tags and the stage's other marks keep at the left of the
  stage is not asked about: a card on the left can cover a tag.
- **The card waits half a second before it goes.** The pointer that leaves
  the row and the card, onto the gap between them or off the panel, finds
  the card still there for 500 ms (it was 300): back on the row or the
  card within that, it is the same card - not shut and asked for again, so
  nothing flickers. A press, the panel hiding, a theme or view switch, or
  another row under the pointer still take it down at once
  ([model::CARD_GRACE_MS](native/overlay/src/model.rs),
  [model::chip_target](native/overlay/src/model.rs),
  [Chip::update](native/overlay/src/chip.rs)). The chip's ring, which goes
  with the card, waits as long; the shared vectors keep the WPF overlay's
  300.
- **An idle chat's objective is the game's red.** A chat that is queued
  or idle was the theme's dim teal-grey under the tracker's dark-red ring,
  which read as a pink rim. It is now `QUEST_RED`, the ink of the todo rows
  and the alert's, unlit, with the hollow badge it had: the game's
  objective that is not active
  ([card::quest](native/overlay/src/card.rs)).
- **The cards appear as the speech box's dialog does.** A chat's card
  (short: its titles) and a gauge's card play the dialog line's appear in
  30ths of a second ([hud::step](native/overlay/src/hud.rs),
  [hud::line_at](native/overlay/src/hud.rs)): the project in capitals,
  with its crosshair, is the name - it slides in from the left over 9
  steps, with the dialog's strength and its bloom - and the objective with
  its badge is the text, which dips at steps 3 and 4 as the dialog's does;
  a gauge's badge and letters are its name. The bloom goes at the last
  step, where the dialog keeps a faint one: the caps keep their haze alone,
  so a card at rest is the drawing it was. Expanding a chat's card, by the
  pointer coming onto it, plays the reply picker's entrance on its body
  alone ([hud::hub_at](native/overlay/src/hud.rs)): the box wiped in from
  the left in 4 steps, and everything in it faded in and slid in from the
  left over 7; the titles stay put. A gauge's body (its bars and rows)
  takes the same entrance with its titles, in one step: its letters
  (`CL`) and the rest come in together.
  Every offset is on a whole device pixel at the window's scale
  ([hud::dev](native/overlay/src/hud.rs)). Like the box, the cards play
  whatever Windows' animations say, and the card asks for a frame only
  while a step is due ([card::appear](native/overlay/src/card.rs),
  [card::appear_wake](native/overlay/src/card.rs)). The old 500 ms fade
  and pale tint of the tracker, and the 150 ms slide of the whole card, are
  gone for these cards (a marker's card still slides in); a row's own
  arrival and a completed row's blink are as they were. Tests: the
  titles' steps, the body's, the gauge's, the clock and the wake in
  card.rs, the animations-off card and its frames in the pointer tests.
- **A gauge has no tooltip.** Resting on a usage gauge, in the panel or
  on the HUD's arcs, no longer brings up "Click to ask Claude, Codex and
  Copilot for usage now" over its card; a click still asks
  ([App.panel_hit](native/overlay/src/app/pointer.rs)).

## 0.12.6 — A row swiped open has a menu

- **A row let go open shows two blocks, not one.** In Panel view the open
  distance is split in halves: the red bin block outermost, a grey block
  with three dots beside the row (mirrored for a swipe to the right). While
  the row is dragged the look is as before (bare, then full red past the
  kill); the split shows only once it is let go
  ([hud::swipe_ground](native/overlay/src/hud.rs),
  [panel::bin_rect and more_rect](native/overlay/src/panel.rs)). Its hits
  are `bin:<key>` and `more:<key>`, over the row's own. A row springing
  back from open keeps the split for its first frame instead of flashing
  full red, or IN USE.
- **A chat in use swipes open too.** The rubber band is gone
  (`SWIPE_RUBBER`): a refused row follows the pointer one to one, says IN
  USE past the kill while dragged, and let go it stays open with its red
  block and bin dimmed to 0.4. A click on that bin sends nothing and puts
  a dim IN USE at the panel's foot for 5 s
  ([App::bin_click](native/overlay/src/app/pointer.rs)).
- **The dots open the row's menu**, under the grey block, the row staying
  open: Mark read or Mark unread, Snooze (1 hour, 4 hours, Until tomorrow,
  08:00), Open and Archive
  ([trayicon::row_menu](native/overlay/src/trayicon.rs),
  [App::open_row_menu](native/overlay/src/app/popup.rs)). What the row
  cannot take is greyed with a tip that names the cause: Mark read for a
  chat at work, a tab-only one or a Recent line; Snooze and Archive for a
  job or a line with no session; Archive for a chat in use or not
  Claude's. However the menu shuts - Esc, a press outside, the dots again,
  a pick - its row springs back, and the row shut or gone shuts the menu.
  One click on the bar's gear shuts the menu and opens no other.
- **Snooze.** A snoozed chat leaves the rows, the counts, the tray, the
  HUD and the phone board until it wakes: when its time is up (1 h, 4 h,
  or 08:00 on the next calendar day), when it starts waiting on you, or
  when it goes from busy or waiting to idle. Recent fills its place. The
  list is `data/overlay-snooze.json`, kept across a restart
  ([snooze](native/overlay/collect/src/snooze.rs)); live alerts and
  pushes still fire. A snooze says `snoozed '<title>' until HH:mm` at the
  foot. The tray's **Snoozed (n)** submenu lists them, a pick wakes one
  (`unsnooze s:<sid>`); it is absent with none snoozed.
- **Mark read and Mark unread** are the host's `read` and `unread` verbs
  (Mark read for any chat, Mark unread for a live chat only; the dot stays
  in the overlay's memory as before).
- **Archive acts like delete on an open chat.** `chatarchive` and the
  menu's Archive close the chat's VS Code tab where a window names it, and
  refuse a chat open in a window where its tab cannot be told apart
  ([Remove-ChatSessionById](src/chatrm.ps1),
  [Invoke-ChatTake](src/chatrm.ps1)). A row sent away slides out over
  grey; a delete's goes over red. The PowerShell host carries `archive` as
  an act step too ([Invoke-ChatOverlayActStep](src/overlay-host.ps1)).
- **New words.** The foot and the log say ARCHIVED or NOT ARCHIVED for an
  archive and SNOOZED for a snooze
  ([model::say_word](native/overlay/src/model.rs),
  [Get-ChatOverlaySayWord](src/overlay-windows.ps1)); the extension says
  "archived" in place of "deleted" for a tab it closes or leaves open for
  an archived chat.
- **`menu <name|verb>`, `bin-click` and `more-click` on the drive**
  ([App::drive_line](native/overlay/src/app/pointer.rs)); a greyed item
  is passed over, as a click on it is.
- **Tests.** Cargo: the panel's blocks, hits and centring, the row menu's
  open, shut, pick and greyed cases, the gear's one-click rule, the exit
  over grey, the snooze pass and its wake rules, the verbs' grammar. Goldens:
  `panel-swipe-open` and `panel-swipe-refused` redrawn, `panel-swipe-open-in-use`
  and `menu-row` new. The tray goldens are unchanged. 894 cargo tests (460
  overlay, 355 collect, 79 in the crates' `tests/`), 523 extension checks, 2015
  PowerShell checks on 5.1 and 2016 on 7, 49 vector files agreeing under both
  shells. See TESTING.md, "The row menu and snooze".

## 0.12.5 — Skin packs as .zip files

- **Skin > Import pack... and Export pack (Windows).** Import opens a
  Windows Open window for a .zip, checks it, adds it to `data\skins\` and
  puts it on the character. Export saves a pack you have as a .zip to
  share or keep. The zip work runs in a child of the overlay exe, so a
  damaged or hostile zip cannot stall the panel; a refusal shows in a box
  from that child, a success in a balloon.
- **Two VS Code commands (Windows only):** "Skin pack: import a .zip..."
  and "Skin pack: export as a .zip..." in the Chat Manager category. They
  run the same exe from the extension's own `payload\bin\`, say whether the
  running overlay took the pack by itself (it does when it is this
  version; otherwise Skin > Refresh, or a restart), and offer Show pack
  folder and Pack format.
- **A replace asks first and loses nothing.** A pack with the same id as
  one already there is replaced only on a Yes (`--replace` on the command
  line), after every check has passed; the old folder is kept in
  `data\skins\.replaced\<id>-<time>\`. A folder that holds anything a pack
  does not (`.git`, `drafts\`, a `.webm`, a README, a link) is an author's
  working copy and is never replaced; the refusal names what it found.
- **Default exports as a starter.** Skin > Export pack > Default (as a new
  pack)... writes the built-in skin with an id and name taken from the
  file name you give, version 0.1.0 and no author, to import and edit.
- **A refusal says what to do, and where the format is.** Each refusal
  gives the absolute folder it means and, where fixing the zip helps,
  offers the format page (docs/skin-pack.md, "A pack as a .zip"). Only
  Stored and Deflate zips are read; Deflate64, ZIP64, split and
  password-protected ones are refused with their own words.
- **A pack of a newer format says to update Mk5.** A `skin.json` with a
  `format` above what this overlay reads is refused with "Update Mk5, then
  import again" and the format page, once the zip itself reads, before
  the id and loader checks.
- **Export refuses an id over 64 characters** (an import would), before
  writing anything; the refusal says to rename the folder and its `id`.
- **A failed Open or Save window is a refusal, not a cancel.** The panel's
  balloon says the window could not be shown, with the Windows error code. The picker is
  per-monitor DPI aware.
- **A OneDrive placeholder is not a link.** Only a symlink or junction
  stops an export or an import's replace.
- **The starter's balloon names the format page** (its URL, first, so no
  long name or path cuts it), then the .zip to import and where to edit
  the new pack.
- **`moodmap.json` is limited:** a .zip import refuses a `moodmap.json`
  over 64 KB. At every load at most 256 regexes are tried, each held to
  256 KiB of compiled size, and the rest are skipped with a note in the
  log. The built-in map is 110 bytes.
- **New command line on `chatq-overlay.exe`:** `--skin-import`,
  `--skin-export` and `--skin-list`, each ending in one JSON line; the
  panel's host takes one new verb, `skin <id>`, so VS Code can have the
  running overlay wear the pack it just imported.

## 0.12.4 — The card comes short, and its titles float

- **A chat's card comes short, and opens when the pointer moves onto it.**
  Resting on a row brings the chip and a short card: the chat's head
  alone, no todo list and no body. Move the pointer onto the card and it
  expands; it stays expanded until the pointer leaves both the row and
  the card, then both go. The head does not change on expand, so nothing
  jumps. `card <key>` is asked once when the short card shows (the model
  is ready by the time it opens) and again every `CARD_AGAIN`, 2 s, only
  while expanded. Usage, notice, ask and reload cards are unchanged. The
  card window is still click-through
  ([card::build](native/overlay/src/card.rs), [card::chat_head](native/overlay/src/card.rs),
  [App::card_open](native/overlay/src/app.rs), [App::card_tick](native/overlay/src/app.rs),
  `chip::Check.on_card`).
- **The Character card follows the quest canon.** The project is the
  quest title: capitals, yellow, outlined and glowing, no badge, one line.
  The chat's title is the objective row under it, with the state's badge
  on its first line, wrapped to two lines. Ink per state: working yellow,
  needs you or cut off red, done green, queued or idle dim. The crosshair
  is at the top right, and the todo rows follow the objective
  directly ([card::quest](native/overlay/src/card.rs)). The titles float
  with no box behind them, as the game's tracker does; what an open card
  adds sits in a box of its own under them, so the short card has no box
  at all (`Card.boxed`, [card::face_hud](native/overlay/src/card.rs)).
  Your prompt and Claude's reply are the phone's messages
  (design/cp-ui/ref/message): Claude's a received one at the left, dark
  with a teal-grey edge, yours a sent one at the right in green, each cut
  at its bottom-right corner.

## 0.12.3 — The answers wait for the line

- **No reply comes with its line.** Every box with replies - the dialog
  hub's rows, a node's `ask`, a scene's replies and the reset ask's
  Continue / Leave them - shows its line first and its rows once the
  line has been said: `max(800, 70 x characters)` ms after it, the game's
  pace measured off its footage (17 onsets in the Skippy and Regina
  clips: 0.87 s after "V.", 2.4 s after 32 characters, 4.5-4.8 s after
  56; never with the line). This replaces the `ask`'s fixed 600 ms
  (`ASK_WAIT_MS`), and the hub, a scene and the reset ask, whose rows
  came with their line. A click on the box brings them at once; keys
  reach no row before they show. The wait is pacing, not motion, so it
  holds with Windows' animations off too. [hud::rows_wait_ms](native/overlay/src/hud.rs),
  [App::rows_at](native/overlay/src/app/stage.rs).
- **A scene's replies wait for its last turn.** A `say` of several turns
  showed its replies under the first; they now come under the last.
- **An `ask` stays up 5 s from when its row comes**, not from its line
  ([Talk::due](native/overlay/src/talk.rs)), so the wait takes nothing
  from the time to answer.
- **The Overlay task no longer writes into `bin/`.** It built the
  working tree and copied it over `bin/<version>/`, so a dev build sat
  where the release's exe goes and the two could not be told apart. It
  now builds into `native/overlay/target/x86_64-pc-windows-msvc/release/`
  and the launcher starts that build over `bin/<version>`'s while it says
  the same version and is the newer ([Find-ChatOverlayPanelExe](src/overlay.ps1));
  `bin/` holds only what `native/stage.ps1` stages. The running exe's
  path says which it is.
- **A new face pops in.** A mood that changes the character's face on
  the stage no longer cuts straight to it: the picture is gone for a
  step, then stretches tall, shrinks, goes again and squashes flat
  before it settles, scaled about its foot, about 200 ms in the box's
  30ths. This is the game's own pop between its hologram's poses, read
  off its footage (a one-frame blank at every pose switch, the stretch
  and squash at many); it has no colour split or slices. Not over a
  boot-in, nor with Windows' animations off
  ([hud::SWAP](native/overlay/src/hud.rs), [App::swap_start](native/overlay/src/app/stage.rs)).
- **The picker builds in as the game's.** The rows' entrance is the clip's,
  measured at its 30 fps: the lit row's bar is a solid stub 2/9, 4/9, 6/9
  and 8/9 wide over four steps with its text dark along the whole row,
  then the full plate; the whole cluster (rows, rules, key badge,
  pointer, not the speaker's tag) fades in at 0.55, 0.72, 0.90 and slides
  in from 12 px left over seven steps, about 233 ms, no vertical motion.
  It replaces the see-through plate and the dim flicker
  ([hud::HUB_WIPE](native/overlay/src/hud.rs), [hud::HUB_REST](native/overlay/src/hud.rs)).
- **The box moves with Windows' animations off too.** The line's flicker,
  the picker's entrance, a hover's wipe and the ask timer's smooth drain
  all play whatever Windows' "animations" setting says: the box is the
  game's look, and that is the user's call. The rest of the overlay (the
  stage's boot-in and glitch, the pointer, the cards) still follows
  Windows. The rows' wait is unchanged
  ([App::motion_now](native/overlay/src/app/stage.rs), [App::say_wake](native/overlay/src/app/stage.rs)).
- **A pick is the clip's: no glitch.** The chosen bar is held 60 ms, the
  box is cut, it stays empty 100 ms, then the next line comes
  (`PICK_HELD_MS`, `PICK_BEAT_MS`; it was 0.7 s, a 0.7 s glitch and 1 s).
  The pick's glitch is gone ([Talk](native/overlay/src/talk.rs)).
- **The bar goes with the mouse.** When the mouse leaves the lit row its
  bar goes, and no row is lit until it enters a row again (the plate
  wipes in) or a key is pressed - a key only lights a row, Enter too, and
  never picks ([App::say_hit](native/overlay/src/app/stage.rs), `SayUp::away`).

## 0.12.2 — alerts.log rolls, and the arrows keep their binding

- **alerts.log rolls** to `alerts.log.1` past 1 MB, as watcher.log and
  the other logs do: [Send-ChatqAlert](src/alerts.ps1) and chatqd's
  [log::add_alert_line](native/crates/chatq-core/src/log.rs), through the
  one `roll` it now shares with `add_log_line_in`. The tool never reads
  the file back, so a roll loses nothing it uses.
- **The arrows keep their binding on a second `. $PROFILE`.** Run again
  in a shell that had the tool loaded, it recorded its own
  `ChatCycleOrHistory` as what Up and Down did before, and a binding of
  the user's own (`HistorySearchBackward`, say) was gone until a new
  shell. [Get-ChatArrowWas](src/shell.ps1) keeps what the first load
  recorded, and [core.ps1](src/core.ps1) no longer clears it on a reload.
- **A damaged held.jsonl no longer holds back the quiet-hours summary.**
  A held alert whose `at` does not read stopped
  [Get-ChatqHeldItems](src/phone-extras.ps1), and every summary after it;
  it is now kept and listed first, as `--:--`.
- **The alert page's usage line wraps.** It took the board's usage grid
  (`docs/reply.html`), so a long footer ran past a phone's right edge; the
  grid is `#bUsage`'s alone.
- [Test-ChatIdle](src/chatrm.ps1) reads a live session's start through
  [Get-ChatqEntryStart](src/live-chats.ps1), so a `StartedAt` that is not
  epoch milliseconds falls back to the process's start instead of writing
  an error.
- **Tests.** Two self-test runs at once, 5.1 and pwsh, both pass, each in
  its own sandbox. The `overlay-hostwork` vector no longer flakes under
  5.1: [Invoke-NvOverlayHostWork](tests/vectors/overlay-hostwork.ps1)
  gives a rewrite a write time past the old one, as the Rust harness
  does. A queued Codex job the suite cannot find fails one check naming
  the sandbox's job files instead of ending the run.
- **A Ferris skin pack, drawn from code.** `skins/tools/make_ferris.py`
  writes `data/skins/ferris/`: Ferris the crab (public domain), drawn
  with PIL and CC0, seven moods of 24 frames each, a tray icon cut from
  the shell, and the default lines under the voice `FERRIS`.
- **No more STATUS lines.** A host's said (a chat done, busy, late, a
  delete) and the reset ask were headed `STATUS` in a dim label; the
  character says them in the skin's voice, as its own lines
  ([App::say_content](native/overlay/src/app/stage.rs)).
- **A beat before the answer.** A dialog node's `ask` row ("Why not?"
  under "No.") comes 600 ms after its line, `ASK_WAIT_MS` in
  [hud](native/overlay/src/hud.rs), so the line lands before the answer is
  offered; with motion off it comes at once. The hub's rows, a scene's
  and the reset ask's come with their line as before.
- **Every clock turns to days at a day.** A panel tile's clock read
  hours up to 99 (`91h12`) and only then days; it now reads `1d01` from
  24 hours, as a chat's age does
  ([model::format_row_clock](native/overlay/src/model.rs), and the
  console's [Format-ChatOverlayRowClock](src/overlay-data.ps1)). A HUD
  dial at work, which counted hours with no end, and a countdown, which
  turned at two days, both turn at one
  ([hud](native/overlay/src/hud.rs)). Seven `panel-*` goldens redrawn.
- **The rows sit closer under the line:** 4 units below the box's plate,
  not 10 (`ROWS_GAP`), and the plate ends 17 units under the last
  baseline, not 27 (`PAD`), so every box is shorter and its text sits
  even in it. Twelve `hud-*` goldens redrawn.
- **The box sits closer under the character:** placed under the stage,
  it is 10 units below it, not 40 (`SAY_BELOW` in
  [hud::place_say](native/overlay/src/hud.rs)); the stage's foot already
  stands clear of the arcs.
- **No version line on the stage.** The `SYS.OVR v…` line under the
  usage arcs' right end is gone from the data noise
  ([hud::noise](native/overlay/src/hud.rs)): at a character's size it was
  too small to read and showed as a stray chip. The tray menu still
  names the version. Nine `hud-*` goldens redrawn.
- **Skippy pack** (private): "It looks like you're trying to be funny" is
  only the answer to "Anything." after "Please say anything to continue."
  in the usage report of the dialog hub, no longer a click line or a
  reload roast; the voice bible says so. The faces' base is cut in a
  downward arch, not flat.
- Deferred (DEFERRED.md): a chat open in a bare root (`/`), and the
  overlay's cached usage with `CLAUDE_CONFIG_DIR` set to `~/.claude`.

## 0.12.1 — The character talks back, and a pack can ship five faces

- Click the character (press and let go) and it talks: a box of up to five
  questions. Gold: the usage the usage bar shows (the providers a chat is
  open for) with each window's reset, the chats that need you,
  are cut off or are working, and the machine's memory and the data drive.
  Blue: two of Skippy's own scenes. A click elsewhere, even a quick one, or
  Esc with the pointer on it closes it. It replaces the click poke; a rest
  on the character still pokes.
- Every skin has it: the built-in one asks the first three plainly, and a
  pack writes its own in a new `dialog` section of lines.json
  (docs/skin-pack.md).
- **The talk is a monologue, and slower.** The hub's questions are the only
  choice: a pick lights its row for 0.7 s, glitches it for 0.7 s, cuts the
  rows, and the box stays empty for 1 s before the character talks on by
  itself, node to node along `go`, and the talk closes at the end of the
  chain. Keys and clicks are ignored while the pick runs. The talk's boxes
  have no Next: each is held `max(1300, 150 + 90 x characters)` ms, then
  cut, and the box is empty for 0.13 s before the next (a click on a box
  hurries it). Skin lines, scene cues and the reset ask keep their pacing.
- **A scene can ask you something, once.** A node's `ask` puts one cyan
  row under its last box for at least 5 s: pick it and the character
  answers, leave it and the row is cut and the answer skipped.
- **`dialog` in lines.json changes:** `opts` and `again` are gone (the
  loader refuses them); a node's `say` is a list of turns, each a string
  or `{"you": "text"}`; a top-level `"you": "V"` names the user's
  character, echoes the picked row as a box of theirs and labels the
  you-turns (with no `you`, no echo, and a you-turn is refused). Skippy's
  dialog is rewritten on it with no `you`: after the pick only Skippy
  talks, and V's two questions in the diagnostics and the volume scenes
  are asks.
- **Character only** in the menu hides everything but the character; the
  menu, tray and hotkey stay as ways out, and it survives a restart.
- The host writes `header.sys` (memory and the data drive's free space)
  on every pass, read every 10 s and held within a small slack.
- **`ready` may fall back to `idle`.** A pack that sets
  `"fallback": { "ready": "idle" }` need not ship `moods/ready`, so it can
  carry `idle pleased sad angry scared` alone; a mood with no face of its own
  wears its fallback's, else `ready`'s if there is one, else `idle`'s, and the
  tray's default mood is `idle` where there is no `ready`. `fallback.ready`
  naming anything but `idle` is an error. The built-in skin and every pack
  that ships `ready` load as before. See `docs/skin-pack.md`.
- **Every usage window that rolls over says `reset`.** It used to need the
  window to have reached 90% or its limit first; now any window seen before
  whose reset moves on says it, once a window, so a skin can greet each
  refill. A window the overlay sees for the first time is not a rollover.
- **The menu stays over the panel.** A window of the panel's shown while
  the menu was open - the edges and the bar on hover - landed on top of it,
  and the menu sat behind the character or the panel for a few seconds.
  Showing one now puts the menu back on top, and a check every 120 ms
  restacks and logs `ui: menu under <windows>` should anything else lift
  above it. Every shut now logs why: `ui: menu shut: <reason>`.
- **Character view's chat card heads like a quest tracker.** In the
  style of Cyberpunk 2077's, its top line is the chat's title in yellow
  capitals, its project small under it, with a dim decoration at the top
  right (no data). The state word (`WORKING`, `IDLE` and the rest) is
  gone: the badge left of the title says it, a yellow filled `!` at
  work, a red empty box when it needs you or is cut off, a green badge
  with a tick when done, a dim box queued or idle. A todo list shows
  under the title, one row per todo. The one in progress
  is yellow with a filled badge and a `!`; a pending one is red with an
  empty outlined box; a done one is plain green, no badge. All but the
  green have a dark outline and a faint red glow. Long rows wrap under
  their text; past seven rows the done ones go first, then the last
  pending, and `+N more` says how many. A todo that turns done blinks a
  green bar and badge for 2 s, flickers and settles to green; a new or
  newly started one slides in from the right, pale, over a quarter
  second; the whole tracker fades in over half a second. With Windows'
  animations off it is simply there. Panel view's card keeps its
  `TASKS` line. The card model gains `Todos`
  ([Get-ChatOverlayCardModel](src/overlay-data.ps1)), drawn by
  [card.quest](native/overlay/src/card.rs) and driven by
  [card.Quest](native/overlay/src/card.rs).

## 0.12.0 — The Windows overlay is the Rust host alone

On Windows the overlay is `chatq-overlay.exe` and nothing else. The
PowerShell host, the WPF panel, the fuses that fell back to them and the
switches that chose them are gone; macOS, the console, phone setup and the
steps are unchanged.

- **Gone: the PowerShell host and the WPF panel.** `chatoverlay -Host` and
  `-Panel` (PowerShell now says the parameter cannot be found),
  `CHATQ_RUST_HOST=0`, `CHATQ_RUST_HOST_HANDOVER`, the host fuse, the panel
  fuse and the shadow collector (`chatq-overlay.exe --shadow`) are removed,
  with the headless host's code and the WPF panel's tiles, gauges, tray,
  settings box and hover card. What the console and phone setup draw with
  stays. `"host": "ps"` and `"shadow"` and `"panel": "ps"` in `config.json`
  are read as before on macOS and ignored on Windows, where
  `data/logs/overlay.log` says so once a version.
- **A host that keeps dying gives up, it does not hand over.** Ending
  unasked 3 times in 10 minutes under one version, the Rust host logs the
  time it may start again and starts nothing; so does a native panel that
  exits 3 times in 10 minutes or will not start. A new shell or VS Code
  window tries again after the 10 minutes, a new version starts with a clean
  count, and `chatoverlay` by name always tries (it forgets
  `data/native/host-starts.json` first). A start that dies before it takes
  the lock is one line in `overlay.log` and nothing more.
- **Failing auto-continue looks are said once.** When the act lane's looks
  fail 3 times in a row the host logs why, shows one balloon and keeps
  running, as it used to hand over to PowerShell for it.
- **A zip install or `chatinstall` has no overlay on Windows.** Without a
  `chatq-overlay.exe` for the version (a zip, a checkout not rebuilt since a
  version bump, an antivirus that took the exe) nothing is started: one line
  in `overlay.log` a version and in the shell, the fix beside it, and
  `Start-ChatOverlayAuto` reports off, not failed. `chatinstall` ends with
  that line where it applies. The VS Code extension stages the exe first.
  Auto-continue, live phone alerts and usage heads-ups run in the host, so
  they go with it.
- **Updates from older copies keep working.** A running copy's restart
  text - `Start-ChatOverlayProcess -Wpf`, `Watch-ChatOverlayRustStart
  -Fallback`, `Start-ChatOverlayHeadlessHost -UiExe`, `Start-ChatOverlayHost`
  - is accepted and starts the Rust host.
- **Kept:** the hidden `powershell.exe` that starts the exe and logs its
  failed start, the Rust host's restart through it, the steps, the
  console, phone setup and the opt-in checker (`hostCheck`).
- **Tests.** The PowerShell host and WPF panel checks are deleted with
  their code; the JSON goldens their oracles wrote stay frozen and the Rust
  tests still read them. `gate-old` now covers the old launch text above.
- Leftover `data/native/host-fuse.json` and `panel-fuse.json` can be
  deleted; nothing reads them.

## 0.11.48 — Swipe a tile away to delete it, and no lock

- **In the Rust host's Panel view, a tile or a Recent line is deleted by
  swiping it sideways.** Press anywhere on it and drag it to either side:
  the row slides with the pointer and the space it uncovers stays bare, no
  tint, no stripes. Past 45% of the panel's width that space is a solid red
  block, Gmail's delete red, with a black bin on it; drag back under it
  and the block is gone.
- **Let go past that and the row stays open**, the block and the bin
  showing, nothing sent yet. The row eases to that distance and holds
  there (with Windows' animations off it just is); no frames run while it
  waits. **Click the block and the chat is deleted for good**, as the bin
  did, with no second ask: the click is the decision. The row slides out
  and the rows below close up; with animations off it just goes. Let go
  short of the red and the row springs back, nothing sent.
- **An open row is shut by anything else.** A press anywhere off the block
  (another row, the open row's own tile, the frame, empty space, the bar), Esc, a
  swipe begun on another row, or a snapshot that makes the chat busy
  shuts it: it springs back, nothing sent, and only one row is open at a
  time. A snapshot that no longer has the chat just lets it go. A press on
  the open row itself shuts it, and a drag from there swipes it afresh
  from rest. A release off the block is no click.
- **A chat that cannot be deleted never dies.** One at work, waiting on you,
  open in a terminal or with a queued prompt running resists like a rubber
  band, stops short of the kill distance, says a muted IN USE, and a release
  deletes nothing.
- **A press that moves mostly up or down still moves the panel**, and one
  that does not move still opens the chat.
- **The swipe starts at once**, the chip up or not, as a dial's drag does:
  each row takes the press itself.
- **A row slid aside stays in its slot.** The row and the ground it
  uncovers are cut to the row's place in the stack, so it never lies over
  the frame's edge or runs off the window.
- **The bin is one size** whichever way the row went and however far. It
  is black, stands at the slot's own edge and shows as far as the row has
  uncovered it - cut, never shrunk.
- **A deleted row stays gone.** It no longer comes back for the seconds
  the host takes to delete the chat: the panel keeps it off the list until
  the host's list drops it too (or 45 s pass, for a delete the host did
  not carry out). The host also runs a delete ahead of its own waiting
  background steps, so the chat goes sooner - before, it could wait 10 s
  or more behind them.
- **The chip's `click again` and `opening 3s` show again**, on the tile's
  right part where the bin's room was (past the ring's end on a short Recent
  line); a press on them is a press on the ring.
- **The bin is gone from the tile panel**, and with it the two-click
  `sure?`, the bin's tooltip and its column: every tile and Recent
  line is 26 units narrower, as is the panel (136 wide). The chip shows the
  ring, its word chips and what it says. The PowerShell panel keeps its bin.
- **The drive file gains `row-press <key>`, `row-move <key> <dx> <dy>`,
  `row-release` and `bin-click`**, for a test to swipe a row and click its
  red block without the real mouse: on the row's own hit, and on the
  block's own (`bin:<key>`).
- **Any dial takes the drag, anywhere on its disc.** Idle or at work, with
  its chip up or not, and on a row with nothing to open: press the dial
  and move it. The press is the dial's own, not the chip's ring's, so no
  rest delay is waited for. A press that does not move is a click, as it
  was: the ring opens the chat once it shows. The hover chip over a dial
  has no bin now, in Character view the drag being the delete.
- **The drive file gains `dial-press <x> <y>`, `dial-move <x> <y>` and
  `dial-release`**, for a test to drag a dial without the real mouse: the
  points are stage units from the panel's corner, and the lines go the
  way of a real press, frame and release.
- **The native panel has no lock.** It always takes the mouse: a press on
  a tile or a Recent line opens it or swipes it away, a press on its frame,
  bar or empty space drags it, and in Character view the character and the
  dials always move and drag. Nothing clicks through it any more, so what
  is under it is reached by moving or hiding it. The red (blue in the light
  look) edge, the open padlock marker at the foot with its UNLOCKED card, the
  2 minute relock and Character view's own lock are gone, and the panel is a
  row shorter without the marker. A `locked` or `stageLocked` in
  `data/overlay-state.json` is ignored and dropped at the next save.
  The WPF panel keeps its lock, and `chatoverlay -Lock` and `-Unlock` set
  that alone: with the overlay not running they no longer write a
  `stageLocked`.
- **The menu drops the items the panel already has.** The tray's and the
  panel's menu lose **Lock** (Unlock to move), **Hide** (Show),
  **Collapse to one line** (Expand), **Refresh usage**, **Move to top
  right** and **Quit**: hide, collapse and quit are the bar's buttons, a
  click on a gauge refreshes the usage, the tray's click and
  Ctrl+Alt+Shift+O hide and show the panel, and the hotkey, which unlocked
  the panel before, now just hides and shows it. A panel hidden by the
  hotkey or the tray is shown again the same way before its × quits it.
  Nothing in the native panel moves it back to the top right now:
  `chatoverlay -Reset` still does.
- **A locked tile panel's swipe waits for the chip** is closed in
  FUTURE_WORK.md: with no lock, no press waits for the chip's ring.
  The golden `panel-light-unlocked-said` is `panel-light-said`, and the two
  menu goldens lose the six items.

## 0.11.47 — The panel lets the character's art go

The overlay window holds less memory; nothing on screen changes.

- **Panel view holds no character art.** The mood's decoded sheet - 7.5
  MiB for the built-in skin, up to 22.5 MiB for a large pack - was held
  for the window's whole life, though only Character view draws it. It is
  now decoded at Character view's first draw and let go on the switch to
  Panel view. Measured off screen, the window's own part in Panel view
  went from 11.2 to 3.7 MB.
- **Putting on a skin no longer decodes a whole sheet for its tray
  icon.** A pack with no `stills/tray.png` has its icon cut from a mood
  sheet; only the rows down to the crop's foot are read now, so the spike
  of decoding the whole sheet (up to 20 MiB) is gone. The icon is the same
  to the byte.
- **The last snapshot is held once**, not copied, and the skin's lines
  are shared, not copied at each lookup: a few hundred KB less.
- A pack's sheet that does not decode is now logged at its first draw in
  Character view, not when the skin or face changes; the default's sheet
  plays in its place as before.

## 0.11.46 — The shadow works out the reset ask

S6d of the native collector's plan.

- **Which chats the reset ask offers is worked out in Rust.** The shadow
  now builds `header.ask` itself - the limit's chats five minutes after
  their reset and under 12 hours old, and a window's restart rows - held
  against the answered marks (read at the look), the queue's busy chats
  and the chats open in a terminal, and nothing while Claude is at its
  limit. It was taken from PowerShell until now.
- **The ask's wait is counted by the pass.** Only the `deadline` of an
  ask that PowerShell also has, with the same chats, stays PowerShell's.
- **With the crash continue on**, an ask of PowerShell's with a restart in
  it is taken whole, as the restart rows are PowerShell's then
  (FUTURE_WORK.md "The reset ask's edges").
- **Twenty chats cut off at once sort as pwsh 7 sorts them.** The cut-off
  rows' order of ties past 16 rows now follows pwsh 7's introsort, which is
  stable only up to 16 (the vector found it).
- **PowerShell's `reset ask:` error is no longer taken** while the pass
  makes the look.
- **New vector `overlay-resetask`** (84 cases) pins the ask, its cause,
  title and terminal words and the deadline rule, compared under 5.1 and 7.

## 0.11.45 — The shadow works out the auto states

S6c of the native collector's plan.

- **What auto-continue does with each cut-off is worked out in Rust.**
  The shadow now gives every cut-off row its `auto` state (ready, off,
  never, terminal, stopped, declined, failed, far, late, restart, and the
  armed, due or running of a queued continue) and the header's
  `counts.auto`, from `config.json`, `data/auto-continue.json` and the
  markers in `data/auto`, and holds them against PowerShell's. They were
  taken from PowerShell until now.
- **Markers are read once a look**, as PowerShell does; the states move
  on the pass in between. A marker over 8 days old is not read (the shadow
  deletes nothing).
- **A setting it cannot cast** (a streak that is not a number) gives
  `auto-continue: ...` in `header.error`, and the states stay as they were.
- **The Rust host keeps PowerShell's states**, so the checker masks
  `rows[*].auto` and `counts.auto` (FUTURE_WORK.md "The auto states'
  edges").
- **New vector `overlay-autostates`** (251 cases) pins the state, the
  config read, the held tests, the time words, the markers and the pass,
  compared under 5.1 and 7.

## 0.11.44 — The Rust host by default

The Rust host's plan, 3.3.

- **The Rust host is the default on Windows.** With the native panel,
  `chatq-overlay.exe` is the overlay's host unless you say otherwise
  (`"host": "ps"`, `chatoverlay -Host ps`). PowerShell's host is
  deprecated there and kept as the fallback: when the Rust host has
  ended unasked 3 times in 10 minutes or died before it took the lock
  (until the next version, or `chatoverlay -Host rust`; the hand-over is
  marked with the version), with `CHATQ_RUST_HOST=0`, where the panel is
  the WPF one or no `chatq-overlay.exe` is staged for the version (a zip
  install has none), and on macOS, which stays as it was. The days of
  real use were waived for this. A word `overlay.host` does not know now
  reads as the default.
- **`chatoverlay -Host` restarts the overlay that is running the wrong
  host.** It used to restart only if config.json said something else, so
  `chatoverlay -Host rust` on a running PowerShell host that config.json
  already called `rust` only reloaded it. It now finds the host running
  (from `overlay.pid`) and restarts unless it is the one you chose, and
  says why a shell would start PowerShell's instead (the panel `ps`, no
  exe for the version, `CHATQ_RUST_HOST=0` in the shell). `-Host rust`
  onto a running PowerShell host now stops it and starts the Rust host
  from your shell, since its own restart would choose in its own
  environment; it also clears the starts the fuse counted, blown or not.
- **The hand-over's opt-out is its version's.** Where the Rust host's
  fuse cannot be written it handed over to PowerShell's host with
  `CHATQ_RUST_HOST=0`, which that host and everything it started
  inherited, so no restart of it ever picked Rust again, version bumps
  included. It is now `CHATQ_RUST_HOST_HANDOVER=<version>`: PowerShell's
  host for that version only, and a new version tries the Rust host
  again. `CHATQ_RUST_HOST=0` set by you in a shell stays the opt-out.
- **A Rust host that dies before it takes the lock falls back.** An exe
  that was there but died early (a missing DLL, an early panic, a
  quarantine) left nothing running, and every later start repeated it.
  Every start of the Rust host is now watched for 15 s, in a hidden
  PowerShell (never in your shell): one that exits before it holds
  `overlay.lock`, will not start or takes none blows the host's fuse for
  the version and PowerShell's host starts. The hand-over from an update
  gives way only once the Rust host holds the lock or exits 0; it watches
  in place for up to 15 s before it takes its own lock, and the kill of a
  hung exe is best-effort.
- **An update starts the Rust host at its first restart.** The restart
  onto new code was chosen by the old code, so a change of host in a new
  version came a restart late. The new PowerShell host now asks its own
  code's choice before it starts, and hands over to the Rust host.
- **The Rust host's memory restart has its own limit.** 100 MB, since
  `overlay.restartMB`'s 300 was set on PowerShell's figure and a host of
  about 10 MB never reached it. `overlay.restartMB` in config.json
  overrides it (0 for never), and the log line says which limit it was,
  no longer "after the heap compacted".
- **A memory restart held by something under way is taken after 10
  minutes**, in both hosts, as the update's is: a pointer left on the
  panel no longer keeps a grown host from restarting, and the log says
  once that it waits. A hover card can vanish once then.
- **A PowerShell host chosen by name says once a version that it is
  deprecated**, in `overlay.log`, no balloon.

## 0.11.43 — The shadow reads the restart rows itself

S6b of the native collector's plan.

- **The chats a reload cut off are found in Rust.** The Rust host reads
  PowerShell's host-work notes (`data/host-work`), works out which chats
  a VS Code reload, a crash or an out-of-memory cut off, and shows them
  as PowerShell did: the last message owing an answer, or background
  work (a workflow, an agent) that never saw its end. The cause comes
  from VS Code's own log, as before. The shadow holds these rows against
  PowerShell's as it does the limit rows.
- **Only while the crash continue is off.** With `autoContinueCrash` on,
  the continue runs in PowerShell with a scan of its own, so the restart
  rows stay PowerShell's, as they were.
- **A restart's look is two seconds on while a window waits for VS
  Code's log**, as PowerShell's is.
- **What the Rust look leaves** (FUTURE_WORK.md "The restart rows'
  edges"): the continue itself, a pass that runs `-Once`, and a UTF-16
  mark in VS Code's log. Where PowerShell's host does not prune its
  notes (no ask), a row's time can drift in Rust.
- **New vector `overlay-restartrows`** (194 cases) pins the rows pass by
  pass, the cause from the log, the last message's tests and the ask's
  marks, compared under 5.1 and 7. `overlay-cutoff` gains the last
  message's kind, text and stop reason.

## 0.11.42 — Drag a dial away to flatline its chat, and /clear's empty session is not listed

- **Drag a dial away from its seat to delete its chat, the way the game
  kills you.** In the Rust host's Character view, press a dial and move it
  past a few pixels: a ghost of the dial follows the pointer and takes
  hits. The farther from its seat, the redder it goes, and red scanlines
  tear it sideways, more and wider. Past a quarter of the stage's width
  its plate falls to black with only a red arc of its rim lit and a red
  ATTENTION triangle by it; move back under that and it recovers.
- **Let go past that and the chat is deleted for good**, as the bin does in
  Panel view, with no second ask: the release is the decision. The dial's
  seat plays a short Flatlined card, about three dials wide and held inside
  the window: ATTENTION, CRITICAL SYSTEM FAILURE on
  a red plate, then the skull, FATAL BRAIN DAMAGE and FLATLINED in its box,
  in about a second, taken from the game's own clip. With Windows'
  animations off the dial just goes. It works with the HUD locked or
  unlocked. Let go short of the kill distance, or press Esc, and the dial
  goes back and nothing is sent.
- **A chat the bin refuses never dies.** One at work, waiting on you, open
  in a terminal, or with a queued prompt running takes damage only up to a
  point, never falls to black, says a muted IN USE where ATTENTION would
  be, and a release deletes nothing. A chat that is gone while you drag
  counts as refused. A press on a tag, and any press in Panel view, still
  move the panel, as before.
- **A dial takes the drag only from its chip's ring.** The ring shows
  after the rest delay, as for a click to open, and a press before it
  appears, or on a row with nothing to open, drags nothing.
- **The speech box reads larger, on a darker plate.** Its text is the
  game's larger subtitle size (a 17-unit line), over a black plate at 70 %,
  so it reads over any scene. A skin worn anew also takes the old skin's
  line off the box.
- **A /clear's empty session is not listed.** Claude Code's `/clear`
  starts a new session that holds only the command and its noise. The
  overlay no longer lists that session as a chat; the chat from before
  the clear stays listed, and the new session appears once you type a
  real prompt in it. A session with a custom or AI title still lists.
  The Rust collector and the PowerShell host agree on it.


## 0.11.41 — The HUD's bar is one strip, usage is bulging arcs, the HUD moves, a click on a gauge asks

- **A click on a usage gauge asks for usage now.** In the Rust host,
  press and let go on a gauge, without moving, and it sends `refresh`;
  drag from it and the panel moves, as before. It works in Character
  view locked or not, and in Panel view unlocked. Panel view locked is
  click-through, so the menu's Refresh usage is the way there.
- **The refresh button is gone from the bar.** The Rust host's controls
  bar and the HUD's bar have five buttons now: fold, gear, min, max and
  close. The tray menu's Refresh usage stays.
- **The gauges pulse while an ask is out.** Their fill fades between
  about half and full over 900 ms, and stands still when the answer is
  in. A gauge's hover says it is a click to ask.
- **The bar is one strip.** Character view's buttons no longer sit on
  separate plates a gap apart: one chamfered strip holds them edge to
  edge, with a thin divider between neighbours.
- **Usage is segmented, bulging arcs.** They replace the cradle of
  arcs: one arc per usage window under the character, its middle the
  highest, lit from the left to its percent, a tick across it at how far
  through the window it is. No letters and no percent beside them: the
  hover card names the provider and its windows.
- **Faint decoration under the stage.** A tick ruler down the right
  edge, a barcode and two serial lines at the top left, and the version
  at the bottom right, in a dim red over a dark halo, so a light
  wallpaper shows them too, and under every mark. None of it is data,
  and none of it takes a click.
- **The HUD boots in.** On start, on show and on unfold the red marks
  flicker in first, the cyan and gold ones 50 ms later, and the
  character fades in over 450 ms; the bar comes in with the red.
- **Labels decode.** A tag, a dial's number or a usage label that is
  new or changed runs through random glyphs for about 200 ms, then
  settles. ASK 2 becoming ASK 3 decodes.
- **A glitch on a finished job or a new alert.** The character splits
  into a red and a cyan copy a few units apart for 100 ms. A new tag
  counts; AUTO and MUTE, the menu's toggles, never do.
- **The hover card in the HUD's style.** In Character view the card
  has cut corners and the HUD's colours on either theme, an icon box
  and a label in the item's colour, and a draining bar for an ask's
  timer, a usage window or a cut-off's countdown. It slides in from the
  left over 150 ms. Panel view's card is unchanged.
- **The motion plays only with Windows' animations on.** With them off,
  the boot-in, decode, glitch and slide show their last frame at once.
- **The HUD keeps to red at rest.** Idle dials and the unlit usage
  segments are a dim red now, so the HUD is red at rest, cyan live and
  yellow on a warning.

## 0.11.40 — The shadow reads the cut-off chats itself

S6a of the native collector's plan.

- **The cut-off look runs in Rust.** The Rust host now finds the chats a
  limit cut off, reads their last turn and title, and keeps those under
  12 hours old, where it ran a PowerShell step for it before. A look is
  still about a minute apart, and again when a limit comes or goes.
- **A restart's rows stay PowerShell's.** Rows for a chat that stopped
  by an out-of-memory, a crash or a restart come from PowerShell, as do
  the auto continue and the reset ask.
- **The shadow checks the ask too.** It compares the reset ask's chats
  with PowerShell's and logs each one that is new or gone. An ask that
  has restarted is left unchecked.
- **A restart's rows show only while the cut-off setting is on**, as
  PowerShell's list does.
- **New vector `overlay-cutoff`** pins the last turn, the title, the
  scan, the key and the 12 hour filter, compared under 5.1 and 7.

## 0.11.39 — The Rust host, opt-in

H7 of the Rust host's plan.

- **No environment variable to turn the Rust host on.** `chatoverlay
  -Host rust` is enough; `CHATQ_RUST_HOST=0` stays as the opt-out, and
  is what the handover sets where the fuse cannot be written. It is
  still off by default.
- **`overlay.hostCheck` and `chatoverlay -HostCheck on|off`.** On a check
  day the Rust host starts a PowerShell checker beside it (about 130 MB
  while it runs). The checker reads nothing it could change and writes
  its look to `data/native/overlay-ps-check.json`; the host compares it
  with its own and logs differences that held to
  `data/logs/overlay-check.log`. A checker that keeps ending is left off
  for the run, with no fuse.
- **An hourly `sample` line in overlay.log** on the Rust host: private
  bytes, threads and the act and read lane step times.

## 0.11.38 — A held restart onto new code ends in 10 minutes

- **The Rust host no longer waits for ever to restart on new code.** It
  waited while the panel said something was under way, and on 10-30 one
  hold lasted 22 hours: every step refused the new version, so no alert
  or look ran. Now it says once that the restart is held, takes it
  anyway after 10 minutes, and looks at the code at once when a step
  refuses its version. The headless PowerShell host has the same bound.
- **A panel that hides or can't read the cursor counts the pointer as
  gone,** so a locked PC no longer keeps it "under way".
- **The panel logs each change of its under-way answer,** naming what
  is on, so a long hold can be traced.

## 0.11.36 — The Rust host's alerts, cut-off look and reset ask

H5 of the Rust host's plan. Still behind `CHATQ_RUST_HOST=1`.

- **Phone alerts are sent again on the Rust host.** From 0.11.32 to
  0.11.35 it only logged each live alert `due - not sent`; now it sends
  them, and the usage heads-ups and the held kick too.
- **The Rust host acts on cut-off chats itself.** The cut-off look, auto
  continue and the reset ask run as PowerShell steps, a look about
  every minute and again when a limit comes or goes; the ask answers
  from the panel, the console and the phone.
- **A look that keeps failing hands over.** After 3 failed looks in a
  row, or 5 minutes without a good one, the PowerShell host takes over.
- **Two new vectors, `overlay-lookcadence` and `overlay-asktimer`,** pin
  when the look runs and the ask's timer, compared under 5.1 and 7.

## 0.11.35 — One menu for both views, no quiet hours for the character

- **One menu, everywhere.** The native panel's menu now holds
  everything its bar and settings box did. It opens from the tray icon,
  from a right click on the panel, its bar or the character, and from
  the gear, in both views (Panel view had no right click before, and
  its gear opened a settings box). It is regrouped:
  - the ask, then Open console and Phone alerts;
  - the two views, Skin and Record mode;
  - Settings;
  - the window's own items;
  - the version, then Quit.
- **Settings in the menu.** The native panel's settings box is gone
  (the WPF panel keeps its own). Theme, Recent chats and Cut-off chats
  work as its chips did, and the panel's opacity and rows come in steps
  (its sliders are gone). The crash item moved under Settings. Cut-off chats replaces
  the old Auto-continue tick, which offered only on or ask, never Leave.
- **A bar in Character view.** The bar's six buttons stand along the
  HUD's top, always, drawn in the HUD's style (cut corners, red edges,
  cyan glyphs), with the dials moved down 12 units clear of it. Its
  gear opens the menu, as in Panel view.
- **The overlay's own menu.** The menu is drawn by the overlay, not by
  Windows, in the look the settings box had: the panel's frame and
  edge lines, a lit row under the pointer, dots and ticks in the accent
  colour, greyed items dim, and a `›` on the ones that open a submenu.
  It is dark in Character view and follows the panel's theme in Panel
  view. Items show their tips; Up, Down, Left, Right, Enter and Esc
  work it, and a click elsewhere, losing focus or the panel hiding
  closes it. It flips to stay on screen.
- **The panel no longer freezes under the menu.** Windows' menu ran its
  own loop, which stopped the character, the card and the timers while
  it was open. The overlay's menu is a few windows of its own, so they
  go on. The drive file gains `menu-open`, `menu-key <k>` and
  `menu-close`.
- **Record mode.** In a checkout, the menu's Record mode closes this
  overlay and plays `design/skippy/demo/promo.json` with
  `tools/overlay_scene.py` in a console of its own. Ctrl+C there ends
  it.
- **A hover always gets a line.** Resting the pointer 1.5 s on the
  character has him say something, every time, 15 s apart at most
  (it was once in 10 minutes, and the hour's caps, the dice and three
  quick clicks' sulk could drop it too). Only mute, or an urgent line
  or a host's message on show, holds it back.
- **An urgent line stays while its state does.** A line about a chat
  waiting for you (input, a permission, a question) or the reload ask
  stays up until the chat moves on, as his face already did, instead
  of going after 30 s. A click still dismisses it; its "still waiting"
  repeat is dropped once you answer.
- **A looped face plays its whole clip.** A mood sheet may now hold
  24 MiB decoded (was 8 MiB), so a 6 s loop fits at 12 fps: about 70
  frames instead of a 25-frame cut that jumped back every 2 s. One
  sheet is held at a time, so the overlay grows by at most 24 MiB while
  such a face shows. Packs are rebuilt by their own tools; the default
  skin is unchanged.
- **Character view's usage is a cradle of arcs.** The thin 2-unit bars
  under the character are now segmented arcs curving under it, one per
  usage window, 3 units thick on a dark teal track that shows on the
  halo, with the provider's letters and its fuller window's percent at
  the left ends. The dials read better too: brighter unlit segments, a
  thicker band, a thin rim in the dial's colour and a lighter idle
  ring.

- **The character talks at any hour.** From 23:00 to 08:00 the line
  picker let only urgent (P1) lines through, so pokes, finished chats
  and small talk went unsaid at night. The rule came from the
  prototype, not from a request, and the lines make no sound; it is
  gone. Mute and the chatter level still quiet him.
- **The morning line still waits for 08:00**: the first look of a day
  from then on.
- The phone's quiet hours (`chatnotify -QuietHours`) are unchanged.

## 0.11.34 — One firewall rule for every release

W3 of the watcher plan. Where outbound is blocked by default, as on
this PC, each release's `bin/<version>/` chatqd needed an allow of its
own, and until it was given every reply window fell to the PowerShell
watcher.

- **chatqd has a path that does not change**:
  `native/stage.ps1` also stages it at
  `bin/current/x86_64-pc-windows-msvc/chatqd.exe`. Allow that path
  outbound once and the rule lasts across releases; the script says so
  when it stages a new chatqd.
- **The watcher takes that copy first** when its `chatqd version` says
  this version, else `bin/<version>/` as before. A stable copy of
  another version is passed over quietly: no strike, fuse or alert.
- **A running watcher never blocks a release.** A stable copy that
  differs is renamed aside to `chatqd.old-<n>.exe`, which a later run
  deletes once nothing runs it.
- **An exe is asked again after a bump**, even unchanged:
  `verified.json` now records the version each pass was for.
- Whether the firewall keeps the rule once the file at that path
  changes is still to be seen on this PC (TESTING.md, Tier 1 W3).

## 0.11.33 — One command stages the native exes

W1 of the watcher plan. On this PC no watcher had run native since
0.11.11: nothing was staged at the version's path.

- **`native/stage.ps1`** builds chatqd and the native panel (release,
  `--locked`, the msvc target), writes the panel's notices with
  cargo-about and copies all three into
  `bin/<version>/x86_64-pc-windows-msvc/`, where the watcher and the
  overlay look for them. `-NoBuild` stages a build already made,
  `-NoOverlay` chatqd alone.
- **Nothing half staged.** Each exe is asked its version first; one
  that does not say the loader's version stops the script with nothing
  copied. A file with the same bytes is left as it is, and one in use
  that differs stops it before anything is copied.
- **Each version's path needs its own firewall allow** where outbound is
  blocked by default; without it a reply window falls to the PowerShell
  watcher (TESTING.md S59 step 8).

## 0.11.32 — The Rust host's watcher word, host-work notes and alerts

H4 of the Rust host's plan. Still behind `CHATQ_RUST_HOST=1`.

- **The watcher's word comes from the host itself**, asked every 10 s
  as the PowerShell host asks it; the shadow compares it too.
- **Jobs answered in the chat are closed** `skipped` by a new
  `answered-jobs` step on the act lane. One a step did not close is
  tried again a minute on, not every pass.
- **The host-work notes are written** to `data/host-work`, as the
  PowerShell host writes them, so a VS Code window that goes down still
  leaves its cut-offs. The shadow writes its own to
  `data/native/host-work-shadow` and logs where they differ.
- **Live alerts are found but not sent**: each is logged `due - not
  sent`; the send, usage alerts and the held kick come with H5. Two new
  vectors, `overlay-hostwork` and `overlay-livealerts`, pin the notes
  and the alerts under 5.1 and 7.

## 0.11.31 — The Rust host's usage

H6 of the Rust host's plan. Still behind `CHATQ_RUST_HOST=1`.

- **The Rust host asks for usage itself.** Claude, Codex and Copilot are
  asked when PowerShell would ask them: more often while a chat is
  busy, at once 5 s after a window resets, never inside a backoff or a
  server's hold, whose `retry HH:mm` shows on the line. Each ask is a
  usage step on a lane of its own, so a slow fetch never holds an act or
  a card; the shadow and the Mac never ask.
- **`refresh`** asks each provider again, none more than once in 20 s,
  with its note on the line and the panel's spinner while an ask is
  out. The
  figures and a server's hold are read back from `overlay.json` when the
  host starts.
- **A killed step takes its children with it**: every step runs in a
  job object, so a kill also ends its `gh` and `codex app-server`.
- **A new vector, `overlay-usage-live`,** pins when each provider is
  asked, compared under 5.1 and 7. Usage alerts and the held kick come
  with H5.

## 0.11.30 — Steps that stop starting

From the H1 gate day: on 2026-10-28, once Windows ran out of memory,
every new PowerShell on the PC stalled 10-15 minutes at startup until
Windows was restarted, and the shadow's looks were killed at 30 s, 341
in a row. The step runner was fine; this release notices such a night.

- **Three kills in a row are a stall.** The shadow logs once
  `steps: PowerShell is not starting (...) - Windows may need a
  restart`, looks every 10 minutes instead of every minute meanwhile,
  and logs `steps: PowerShell starts again` once a step ends by itself.
- **The Rust host says it** (behind `CHATQ_RUST_HOST=1`): the click
  whose step turned the stall shows a balloon, "PowerShell is not
  starting - <verb> was not done. Windows may need a restart."; the acts
  and cards waiting behind it are dropped and logged instead of taking
  30 s each, and a new click still gets one try, so recovery is seen.
- **A killed step's line** now ends `exit=<code> cpuMs=<ms>`: a stalled
  step shows next to no CPU.
- **The gate day's numbers** (pwsh 7, 761 looks): a median look of
  821 ms and a peak of 116 MB, inside the 1.5 s and 120 MB gate, with no
  compile.

## 0.11.29 — The Rust host's console

H3e of the Rust host's plan, which ends H3. Still behind
`CHATQ_RUST_HOST=1`.

- **The console opens under the Rust host.** `console` and
  `console-key` start the console in a process of its own, on the
  command the PowerShell host uses, or tell a running one `show` or
  `key` on its stdin. The console may come to the front (its pid alone
  is allowed; never under `CHATQ_NOFRONT`), and the host reads
  `console-ui.json` back each pass: its news becomes the host's, the
  panel hides while it shows, and its work in progress holds off a
  restart as the panel's does. A console that ends while a show was
  owed is started once more.
- **The panel's verbs reach the console.** `close`, `console-back`,
  `lock`, `unlock`, `toggle`, `hide`, `collapse`, `expand` and `reset`
  tell it `back`; `hotkey` does while it shows; `reload` and a settings
  change tell it `reload`.
- **`-Open console` starts the Rust host** with `--open console`
  instead of keeping PowerShell. The panel stays hidden until the
  console first answers, or 20 s with no word. An open not yet carried
  out is handed on across restarts and fuses.
- **`phone`** starts the phone setup dialog on Windows PowerShell's
  command, however the host was started.
- **A new vector, `overlay-launch`,** pins the console's and the phone
  setup's commands, compared under 5.1 and 7.
- **Not yet checked by hand:** that the console comes to the front from
  the Rust host (TESTING.md's Tier 1 check).

## 0.11.28 — The Rust host acts through steps

H3d of the Rust host's plan, still behind `CHATQ_RUST_HOST=1`.

- **The panel's clicks work under the Rust host.** `delete`,
  `reload-answer`, `config <k> <v>` (the settings box), `auto-on`,
  `auto-ask`, `auto-off`, `crash-on`, `crash-off` and `card` are each
  carried out by a one-shot `src/overlay-step.ps1` step that calls the
  PowerShell host's own functions, and what it says comes back as the
  host's balloon and said event. A config or crash step has the host
  read `config.json` again, and a switch set brings the reload
  PowerShell's does.
- **Two lanes.** Acting steps run one at a time, in order; a card has a
  lane of its own, where a newer card replaces one not yet started. A
  step that fails, hangs (killed at 30 s) or answers what cannot be read
  is logged once in 5 minutes in its verb's words and never holds the
  pass. A step runs a pass after its verb, so its news comes about a
  second later than PowerShell's.
- **The auto-continue notice** for a switch set during a close by hand
  is said once the close is taken back.
- **The PowerShell host is unchanged:** its crash verb moved into
  `Set-ChatOverlayCrashVerb`, which both hosts call.
- **A new test section, `overlay-act`,** runs the new ops under 5.1 and
  7 and compares their answers.

## 0.11.27 — The Rust host closes by hand

H3c of the Rust host's plan, still behind `CHATQ_RUST_HOST=1`.

- **The close button works under the Rust host.** A close is said
  ("Closed until you next sign in. Type chatoverlay to bring it back
  sooner."), held 4 s, and taken back by `show`, the hotkey or the
  console in that time, as PowerShell's is. While it is on its way the
  snapshot says `ui.closing`, other verbs wait, balloons are held, and a
  restart, a new version or the memory restart becomes a stop.
- **Closed until the next sign-in.** A close, and any stop, marks
  `closedSignIn` in `overlay-state.json` once the panel is gone; a host
  started in the same sign-in stays closed, and a start in a new one
  clears the mark, keeping the panel's place. The sign-in time is read
  natively, from this session's earliest `sihost`, else `explorer`.
- **The first pass** acts only on stop, restart and close, as
  PowerShell's first pass does.
- **Passes that keep failing while closing** end the host as the close,
  kept, rather than starting it again.
- **A vector, `overlay-closed.json`,** written from PowerShell under 5.1
  and 7, pins the sign-in check and the mark.

## 0.11.26 — The Rust host's events and balloons

H3b of the Rust host's plan, still behind `CHATQ_RUST_HOST=1`.

- **Events, as PowerShell keeps them.** The host makes the panel's
  events (ids `<start ms>-<n>`, kinds balloon and said, text cut at 250
  characters), saves them to `overlay-events.json`, reads them back at
  start, and drops one once the panel has seen it or after 10 minutes.
- **`opened` is taken.** A click that opens a chat gets PowerShell's
  balloon and says (the chat raised, or why not), and clears its unread
  mark.
- **The memory and leak balloons** are said from each pass's news, with
  PowerShell's 15- and 30-minute holds.
- **The memory restart.** Past an hour, the host restarts itself when
  its private memory is over `overlay.restartMB`, looked at 3 minutes in
  and every 5 after. Its figure is the process's private memory as is;
  PowerShell's is taken after a heap compaction, so the default 300 MB
  may not be reached (FUTURE_WORK.md).
- **The version check waits.** A new version on disk must hold 5 s
  before the host restarts on it, and neither the check nor the memory
  restart runs while the panel says something is under way.
- **Two vectors,** `overlay-hostevents.json` and `overlay-says.json`,
  written from PowerShell under 5.1 and 7, pin the events file, the
  memory balloon and `opened`'s says.

## 0.11.25 — The Rust host reads its verbs

H3a of the Rust host's plan, still behind `CHATQ_RUST_HOST=1`, and a
dependency's advisory fixed.

- **The Rust host reads `overlay-cmd` as PowerShell does.** Each line's
  stamp, verb and words are read by PowerShell's rules: a verb in any
  case, only the words a verb takes, a line over 5 minutes old dropped.
  `stop`, `restart` and `reload` are taken, `reload` reading
  `config.json` again. The panel's verbs (lock, unlock, show, hide,
  collapse, expand, reset, disguise and the like) and `hotkey` now reach
  the panel in the snapshot's `commands`, kept until the panel says
  they are done or 5 minutes pass. So the tray's Lock, `-Lock`/`-Unlock`
  and the hotkey work under the Rust host. The verbs it acts on itself
  (the switches, the ask, close, phone, the console and the panel's
  clicks) are still logged once in 5 minutes as not taken yet.
- **A vector, `native/vectors/overlay-verbs.json`,** written from
  PowerShell under 5.1 and 7, pins the lines, each verb's words and a
  pass's `commands`.
- **pulldown-cmark 0.13.5.** The panel's Markdown parser, which Slint
  brings in, is updated past RUSTSEC-2026-0414; 0.11.23's publish
  stopped at that advisory.

## 0.11.24 — A scripted scene

A director can play a scene on the native panel for a demo recording:
the character says what a script gives it, with its own replies and
mood, and the script hears which reply was picked.

- **A scripted scene for a demo recording.** With
  `CHATQ_PANEL_SCENE=<file>` set where the native panel starts, a
  director can put words in the character's box and hold its mood, in
  Character view. The panel takes the file every 120 ms (renamed, read,
  deleted, as the host takes `overlay-cmd`) and acts on each line once;
  a line it cannot read is logged in its data folder's
  `logs/overlay-panel.log` (the director's: `data/scene/<name>/logs/`)
  as `ui scene: <why>; skipped` and the rest still run. Without the
  variable nothing changes. The lines:
  `say {"name","text","replies":[{"id","label","primary"}],"mood"}`
  (up to 4 replies; each `\n` in `text` is a turn, timed like a skin
  line, the last one staying up), `mood <name> [ms]` (held for `ms`, or
  until the next mood; `mood -` lets it go) and `clear`.
- **A pick is written back.** A click on reply `i` appends
  `scene <id>` to `data/overlay-cmd` and ends the box; a click on the
  last turn of a box with no replies appends `scene click` and leaves
  it up. Other lines of that file (a card's, say) are not the scene's.
- **Quiet under a scene.** While the variable is set the skin's line
  events, the clock's lines and the poke and drag lines are off, so
  only the script speaks; the host's said and the ask still show when
  no scene box is up. The pointer, tray and hotkeys work as usual.
- **A line with no name draws no name.** A speech box line whose voice
  is empty now has no label and no gap, rather than a bare `:`.
- **`tools/overlay_scene.py`, the director.** It plays a scene JSON
  file (the skin, the view, the place, the starting chats and usage,
  and steps with `at`/`after`, chat and usage changes, `say`, `mood`,
  `clear`, `wait` for a pick and a `branch` per reply) in a private
  data folder under `data/scene/<name>/`, feeding `overlay.json` every
  second and reading the picks. It will not start while the real
  overlay runs. `--check` validates the file and stops; `--from <step>`
  starts mid-scene; `--exe <path>` picks the overlay build; `--force`
  starts though another overlay runs; `--selftest` plays hidden, with
  every wait cut short, and passes if the scene reaches its end. The
  scene's clock starts once the overlay is up. An overlay that does not
  take a scene file in 5 s (a build before 0.11.24) is an error, not a
  hang. `tools/scenes/example.json` is a sample.
- **The drive verb `say-pick <i>`** picks reply `i` of the box up as a
  click would, for tests and the director's `--selftest`.

## 0.11.23 — 0.11.22, shipped

0.11.22's release, which never shipped. The tag v0.11.22 is there, but
its publish stopped at the format check of the overlay's code, so it has
no release. Everything in 0.11.22 is in it, and so is everything since
0.11.15, the last release to reach the Marketplace. It is the first
under the extension's new ID (0.11.20).

- **The overlay's code is formatted** as `cargo fmt` wants; nothing it
  does changed.
- **TESTING.md says how to test, not how it went.** The dated runs, their
  figures, the check counts by version and the record of past reviews are
  gone; what each check runs, covers and passes on stays. The few facts
  only those records held are now in FUTURE_WORK.md, DEFERRED.md or a
  comment beside the code.

## 0.11.22 — A Rust host, on trial

H2 of the Rust host's plan (native/SPEC.md §3.10): `chatq-overlay.exe`
can be the overlay's host in PowerShell's place. It is opt-in twice: it
starts only with `"overlay": {"host": "rust"}` (`chatoverlay -Host rust`)
and `CHATQ_RUST_HOST=1` set where the overlay starts. Without both,
nothing changes.

- **What it does.** It takes the same lock as the PowerShell host, so
  only one of them runs. It collects every 2 s and saves `overlay.json`
  each time, and starts the native panel as its child, restarting it up
  to 3 times in 10 minutes; past that the panel's fuse blows and the WPF
  panel takes over, as today. `chatoverlay -Stop` and a restart work. It
  writes to `data/logs/overlay.log` like the PowerShell host.
- **What it does not do yet.** Clicks on the panel, the console, the
  panel's close button, keeping a stop until the next sign-in, continuing
  cut-off chats, the reset question,
  live usage, the watcher's state and the host-work notes. Those stay
  with the PowerShell host for now; the panel shows the chats and usage
  read from files.
- **It falls back on its own.** A Rust host that ends without being
  asked (a crash, a hang its watchdog ends after 60 s, or 5 collections
  in a row that fail) 3 times in 10 minutes is not started again for
  that version: the PowerShell host starts instead and says so once.
  `chatoverlay -Host rust` tries it again, its count started afresh. Its starts are kept in `data/native/host-starts.json` and the
  fuse in `data/native/host-fuse.json`.
- **Restarts.** It restarts only when the script on disk says a new
  version, looked at once a minute, and each restart goes back through
  the PowerShell launcher, which picks the host again.
- **`chatoverlay -Host rust|ps|shadow`** sets the host and restarts a
  running overlay onto it.
- **Apart from the Rust host: a git checkout's native panel no longer
  goes quietly.**
  Nothing stages `bin/<version>/` in a checkout, so at each version bump
  the overlay fell back to the WPF panel and said nothing. Since 0.11.11
  that panel lacks Character view, the skin picker and the
  Ctrl+Alt+Shift+D chord. With no `bin/<version>/`, the overlay now uses
  the checkout's own build in
  `native/overlay/target/x86_64-pc-windows-msvc/release/`, as long as its
  `--version` is the script's. The version is asked once per build and
  per process; one that hangs or will not start is asked again after a
  minute, not at every look. A restart onto new code finds the panel
  the same way, so a panel running from an older `bin/` moves to the
  build. Where that build is at another version, or `bin/` holds only
  another version's exe, `overlay.log` says so at every start and the
  tray once per version, with the cargo command that builds it; so does
  `chatoverlay -Panel native`. `bin/<version>/` still comes first, and
  the panel's fuse still wins. A zip install stays quiet as before
  (DEFERRED.md "The panel exe for install.ps1").
- **Apart from the Rust host: Character view's dials are redrawn, with
  a number in the middle.** Before, a working dial's colour stepped from
  cyan to violet at 5 minutes and pink at 20, its wedge was the minutes
  in the hour, and every dial was a bright pie under a lit rim. Now each
  dial is a dark disc with a ring of 20 dim red segments, and only what
  is live is lit. A working dial shows its age in the middle - minutes
  (`0` in the first minute), then hours (`1h`), with a play mark for a
  running one - and fills the ring in cyan from 12 o'clock, one lap at a
  time: 5 minutes, then to 20, then to 60, then one an hour. A knob
  marks where it is in the lap and three pips under the number count
  the laps done; it moves every second, and the hour ticks stay. A chat
  that needs you is a gold disc with `!`; finished and unread, a cyan
  disc with a check; cut off, a red number counting to the reset
  (minutes, then `3h`, then `2d`), or a red warning triangle with no
  reset time; queued, a dim share up to its send; idle, a smaller dashed
  grey ring. The top dial's brackets take its state's colour, and the
  finish flash and the unread diamond are cyan rather than green.
- **Apart from the Rust host: no chat names beside the dials, and the
  top dial is whole.** The chat names right of the dials are gone, and
  the HUD's window is that much narrower; rest the pointer on a dial for
  its chip and card, as before. A speech box that has to go right of
  the HUD, at a screen's left edge, now sits 34 units from the dials
  rather than from the names. The top dial sat so high that its
  corner brackets and hour ticks were cut off by the window's top edge;
  the dials now sit 6 units lower, so every mark shows.
- **Apart from the Rust host: the usage marks in Character view show
  their card.** Resting the pointer on the usage bars under the
  character showed nothing; it now shows the same usage card as the
  gauges in Panel view, with each window's percent and reset time.
- **Apart from the Rust host: no line from the speech box to the
  character.** The glowing line and dot that ran from the box to the
  character's mouth are gone. The box still sits beside the character,
  level with its mouth, and that alone says who is talking.
- **Apart from the Rust host: no glitches on a click in Character
  view.** Switching to Character view tore the tile panel, smeared it,
  went dark and threw bolts off the character; switching back ran the
  same backwards. Both ways are now a short fade, as they already were
  with Windows' Show animations off. The speech box no longer flashes a
  red line when its text changes or when it goes, and no longer
  flickers after it wipes in (how it comes and goes now is below).
- **Apart from the Rust host: no stray title bar on the HUD.** Windows
  could paint a classic title bar and frame, with the title
  `chatq-overlay`, straight into the HUD when one of its windows was
  activated or deactivated, and a close button when winit changed a
  window's flags. The parts the HUD did not draw again stayed on screen
  as grey-blue strips. The overlay now tells Windows not to paint them.
- **Apart from the Rust host: Character view starts unlocked.** One
  lock served both views, on by default and on again 2 minutes after
  the pointer left, so moving the character meant unlocking it each
  time. Character view now has a lock of its own, `stageLocked` in
  `data/overlay-state.json`: off by default (no key reads as off), so
  the character can be dragged straight away, and never locked again by
  itself. **Lock** in the tray menu, Ctrl+Alt+Shift+O and
  `chatoverlay -Lock`/`-Unlock` act on the lock of the view on show, and
  the menu says that view's; picked in Character view, Lock pins the character
  and is kept across restarts. Panel view, the folded strip and the WPF
  panel keep `locked` as before, relock included. With the overlay not
  running, `-Lock` and `-Unlock` set both.
- **Apart from the Rust host: the dark look is cyan and gold.** The
  crimson, neon green and magenta of 0.11.11 are gone. The dark look is
  blue-black now: cyan for the lines, the project names, the accent, the
  unread dot and the tray's ring, and a faint cyan under the pointer;
  gold for a chat that waits on you, warnings and Character view's
  action plate; red for cut off, critical and the unlocked edge; mint
  green for a chat at work in Panel view (Character view's dials work
  in cyan); and a warm white for text. Its greys are
  cooler and still readable: at least 4.5:1 against the ground for body
  text and 3:1 for the faintest. Running (blue) and queued
  (purple) keep their colours. Cut off is red in the light look too
  (`#CF222E`), so the tooltips and help that said magenta now say red.
  In Character view the timer under a choice is gold; the speech box's
  own colours are below. A
  pack's `colours` in skin.json still win, its `text` colouring the
  words too.
- **Apart from the Rust host: the speech box is drawn as a game's
  dialogue.** It follows a measured spec of a game's dialogue at its
  1080p sizes, in Rajdhani, an OFL face now built into the exe (its
  licence is in `THIRD-PARTY-NOTICES.html`); the dials and the rest of
  the HUD keep Bahnschrift. The line sits on a soft black see-through
  plate with no edge: the name coral, the words cyan, a warning's name
  red, a status line's label dim. It is no longer typed and has no
  cursor: each turn flickers in whole in about a third of a second, and
  stays up as long as it did before. A click on it goes to the next turn
  or dismisses it. The replies are rows: the selected one on a gold
  plate (cyan for the other kind) with a cut corner, the rest in their
  colour with a thin rule at their left. Left of them sit the asking
  chat's name in a coral tag and a key badge with the selected row's
  digit and a small pointer. A new selection wipes across in four steps,
  and a pick or the box's going cuts it at once, with no fade. The box
  still sits beside the character, its replies and timer under it. A
  pack's `name`, `text`, `primary` and `box` colours still win.

## 0.11.21 — The shadow times a PowerShell step

H1 of the Rust host's plan (native/SPEC.md §3.9): the go/no-go for doing
the overlay's acting work in short PowerShell steps. Only the opt-in
shadow (`"overlay": {"host": "shadow"}`) changes; the overlay does not.

- **A step for the overlay.** `src/overlay-step.ps1` is a new file
  beside the parts, run with no window, one op each time. It loads only
  the 9 parts its op reaches. It is fed the idle time and the process
  list, so it compiles no C# and asks WMI nothing; a call to either is
  refused and counted. It checks that the collector that started it is
  still there, before and after its op, and ends itself if not. A step
  from another version says so and does nothing; the shadow sends the
  panel's own version, which its build already holds to the script's.
- **The shadow runs a look every minute.** It asks the step for the
  cut-off chats the overlay would show now, worked out exactly as the
  overlay does but with nothing written: no old question marker pruned,
  no note kept, no chat continued, no log line. Its caches are kept from
  one look to the next in `data/native/overlay-carry-look.clixml`, and
  dropped when the version changes.
- **In PowerShell 7 where there is one.** The step runs in pwsh 7, which
  loads its parts in 46 MB to Windows PowerShell 5.1's 120:
  `overlay.stepPowerShell` in `config.json`, a full path to a pwsh.exe
  kept off the PATH, else pwsh on the PATH, else the standard install;
  with none, in 5.1, as the overlay itself still runs.
- **A step that hangs is ended.** A step still running after 30 s is
  killed and its files removed, so the next look starts on time. When
  the overlay stops, a running step gets 1 s and is then killed, within
  the 2 s the overlay gives the shadow to go. Step files a killed shadow
  left are removed when the next one starts. A look that failed is not
  compared: the last good one's rows would be out of date.
- **Compared and measured.** The step's rows are compared with the
  overlay's own cut-off rows. A difference must last 64 passes (about
  two looks) to be logged, as the two sides look at different times.
  Every step's run time, exit code and peak private memory are logged.
  The gate for going on: a median look of 1.5 s or less, a peak of
  120 MB or less under pwsh 7 (150 MB where only 5.1 is found), and no
  compiler started, over a day of real use. A first run here took 1.1 s,
  peaking at 67 MB under PowerShell 7 and 135 MB under Windows
  PowerShell 5.1. The day itself is still to be run
  (TESTING.md, "The overlay's steps").
- **chatqd unchanged.** The step runner chatqd already used now lives
  in `chatq-core`, where the overlay shares it. chatqd's steps behave
  as before, and its tests are unchanged.

## 0.11.20 — A new extension ID

The extension's ID now matches its name: `redaechan.chat-session-agent-mk5`.
A new ID is a new Marketplace listing, so the one you have,
`redaechan.charlie-and-the-chat-factory`, does not update to it: 0.11.19
is its last version.

- **What to do:** install **Chat Session Agent Mk.5 - Claude Code &
  Codex** from the Marketplace, or run
  `code --install-extension redaechan.chat-session-agent-mk5`; click
  **Uninstall it** when it asks, and reload the window. Best done while
  no queued prompt is running. The old listing will be marked
  deprecated, with this one as its replacement, so VS Code shows its
  users a banner with a switch to it.
- **A new display name too.** The Marketplace refuses a display name
  another listing has, and the old one keeps *Chat Session Agent Mk.5 -
  Claude, Codex, ...*; "Claude" and "Codex" stay in the new one for
  search. The READMEs' titles, the settings' section and the log's
  output channel take the new name as well.
- **The new one offers to remove the old one.** Both installed would act
  on every request twice, and VS Code refuses the same command from two
  extensions. So while the old ID is installed, the new one does nothing
  at all - no commands, no watching, no setup, no overlay - and leaves
  everything to the old one, which keeps working as before. One window
  at a time asks to uninstall it; after **Not now**, a window opened or
  reloaded 10 minutes later asks again. A disabled old one is not
  counted.
- **What carries over:** your `chatManager.*` settings, the **Chat
  Manager:** commands, the tool folder and everything in `data/` -
  among it the profile-line answer (**Never** stays never), the overlay's
  autostart, phone alerts and the queue. No question you answered comes
  back.
- **What does not:** what VS Code keeps per extension. The requests a
  window already took are forgotten, so the first window after the
  switch may offer once more a reload for a delete from the last 10
  minutes, or open again a chat whose overlay chip was clicked in the
  last 2 minutes. A chat handed to a queued run that is still going at
  the switch is not put back in its tab when the run ends: open it from
  the overlay or **Open chat...**. Nor does the window's last activation
  (`chatManager.lastActivationSessionId`), so for the first 30 seconds
  after the switch in each workspace, a new Claude tab that **Show it**
  opens is taken as maybe one Claude Code reopened by itself: judged,
  nothing ended. Nothing was kept in VS Code's secret storage.
- **For the one who publishes:** the old listing is marked Deprecated
  by hand in the Marketplace publisher portal after this one's first
  publish, with `redaechan.chat-session-agent-mk5` as its replacement;
  the old ID gets no release. The public repo is synced only after
  publish.yml has published the new listing, since its README's badge,
  link and install line name it (docs/marketplace-spec.md).
- **For the one who develops:** the self-test's last section, `versions`,
  fails when the files a release bumps disagree. The workspace's VS Code
  watcher now skips `tests/.sandbox`: the PowerShell extension opened
  each new `.ps1` there and held it, so the public split's second sync
  could not delete one (the failure in 0.11.14). Under 5.1 the self-test
  runs without `-ExecutionPolicy Bypass`, on the README's `RemoteSigned`.

## 0.11.19 — The shadow reads usage from its files

The next part of M9b step 3 (native/SPEC.md §7). Only the opt-in shadow
(`"overlay": {"host": "shadow"}`) changes; the overlay does not.

- **The shadow reads usage's files itself.** Claude Code's cached usage
  in `.claude.json` and the figure Codex writes into its rollouts are
  now read by the shadow, as often as PowerShell reads them: each file
  is looked at every 30 s and read again only once it has changed, and
  the rollouts are listed every 5 minutes. From those it works out each
  line itself: which figure is newer, the whole percents, a window
  whose reset has passed shown empty, a window marked full while the
  queue waits out its limit, whether the figure is old, the line's text
  and the time at its end ("cached 11:53", "last run Sat 12:00").
- **What asks the network is still PowerShell's.** The live figures for
  Claude, Codex and Copilot, why an ask failed, and the words about an
  ask under way ("asking...", the refresh button's note, "retry 12:30")
  are taken from PowerShell, as the shadow asks nothing itself. It never
  opens the saved login.
- **Usage is compared.** The header's `usage` and `usageText` are no
  longer left out of the comparison. A difference must last 20 passes
  to count, as each side looks at the files on its own 30 s. While
  Codex works, its rollout gains a figure every few seconds, so each
  side shows the one of its own look: a file's figure read at most one
  look (35 s) from PowerShell's counts as PowerShell's. A new
  rollout can still show on one side up to 5 minutes first, and the
  refresh button reads the files again in PowerShell only; both are
  listed as known differences in FUTURE_WORK.md.
- **Settled by vectors.** Three new vectors, `overlay-usage-parse`,
  `overlay-usage-files` and `overlay-usage-select`, pin PowerShell's
  reading of usage on 73 cases, among them Korea and Pacific time
  across the autumn clock change; the two PowerShells differ only on a
  reset time written with no zone. The Rust side agrees with every one.

## 0.11.18 — The shadow watches memory itself

The next part of M9b step 3 (native/SPEC.md §7). Only the opt-in shadow
(`"overlay": {"host": "shadow"}`) changes; the overlay does not.

- **The shadow looks at memory and leaks itself.** Each pass it looks
  for a program growing fast and then for Windows' memory running
  short, in that order, as PowerShell's host does: the commit figures at
  most every 10 s, and every process's private bytes at most once a
  minute, one list the two looks share. That list comes from one call
  that opens no process, so it holds what PowerShell's holds, System,
  Secure System and Registry among them. The looks run on the
  shadow's own settings (`memoryWarn`, `leakGB`); one that is not a
  number is a line in its log, as in PowerShell, and never the header's
  error.
- **They are compared, with some slack.** The two sides read Windows
  moments apart, so the header's `memory` and `leaks` are no longer
  left out of the comparison but compared loosely: the percent within
  1, the GB figures within 0.3 (a leak's within a minute of its growth
  more), a leak's minutes within 1, the top programs by name alone, and
  the leaks by name in any order. Memory low on one side only, under
  its line, is no difference: that side caught a moment at the line and
  stays low till 3 under, as PowerShell does. A difference must last 8
  passes for memory, 64 for its top programs (each side picks them once
  a minute) and 40 for leaks to count.
  The leaks are not compared at all for the first 11 minutes after the
  shadow starts, or after PowerShell's host restarts: neither side can
  name a leak before it has looked for 10 minutes.
- **What PowerShell would say, the shadow logs.** Memory going low and
  back, and a program growing, are each a `said:` line in
  overlay-shadow.log, every time, never held back as a repeated fault
  is.
- **The minute's sample has PowerShell's size too.** The `sample` line
  gains `psPrivate=`, the PowerShell host's private bytes, taken from
  the same list by its pid, so the two hosts' sizes stand side by side.
- **Settled by vectors and a live check.** A new vector,
  `overlay-memory`, pins PowerShell's memory look, its leak look, its
  memory-restart fuse and its sum of each program's bytes on 50 cases,
  answered alike by both PowerShells; the Rust side agrees with every
  one. For it, the sum gained a test seam in the overlay's PowerShell
  that nothing else sets. `tests/vectors/live-sums.ps1` holds the Rust
  list (`chatq-overlay --sums`) against PowerShell's on this PC: 379 of
  380 processes alike, the one missing the check's own short-lived
  child, and every shared one's bytes within 5% or 50 MB. The fuse is
  ported for the Rust host, which has no heap to compact; nothing calls
  it yet.

## 0.11.17 — The shadow reads its own config

The next part of M9b step 3 (native/SPEC.md §7). Only the opt-in shadow
(`"overlay": {"host": "shadow"}`) changes; the overlay does not.

- **The shadow reads config.json itself.** PowerShell reads its
  settings only at its start, on a reload and on a setting the panel
  changes, and the shadow cannot see those. So it watches PowerShell's
  snapshot: when the settings there change, it reads config.json and
  runs on what it read. Where what it read differs from PowerShell's
  and the file was written while PowerShell was reading it, it cannot
  tell which PowerShell saw, so it takes PowerShell's settings and says
  so. At its start it takes PowerShell's, and logs it if the file says
  otherwise. Each read again logs whether the two agree.
- **The settings are compared.** The snapshot's `config`, and the
  header's `autoContinue` and `autoOn` that come from it, are no longer
  left out of the comparison, so a slip in the Rust read of config.json
  shows as a difference.
- **Recent skips the shadow's own rows.** The chats left out of Recent
  are the live ones and those the shadow has a row for, cut-off rows
  included, not those PowerShell has a row for. A row the shadow gets
  wrong now shows in Recent too, and the Rust host will have no other
  rows to go by.
- **What PowerShell does with a config it refuses is settled.** A new
  vector, `overlay-config-refused`, shows that with a `try` above it,
  as every caller has, the error goes past the assignment under both
  PowerShells: a reload loses that pass and keeps the old settings, and
  the host's start fails. The `overlay-config` vector gains a whole
  file that is not an object, an empty file, one of white space, a
  byte-order mark and `1e999`; the Rust read agreed with every one.
- **The Rust lock check reads a folder as no watcher.** A folder named
  `watcher.lock` in data/ read as a running watcher to the Rust check
  (the native launcher's crash count uses it, and the Rust host will),
  where PowerShell reads it as none; now both say none. A new vector,
  `overlay-watcher`, pins PowerShell's check on twelve cases, among them a held lock, a
  read-only file (held) and a folder (not). The shadow still takes the
  watcher's state from PowerShell, as checking it means holding the
  lock for an instant, which the shadow must not do.

## 0.11.16 — The shadow's error, compared

The first part of the next step of moving the overlay off PowerShell
(native/SPEC.md §7, M9b step 3): the Rust collector brought to every
field the PowerShell one works out from files. Only the opt-in shadow
(`"overlay": {"host": "shadow"}`) changes; the overlay does not.

- **The header's error is compared.** The shadow's own errors (the
  chats, the tabs, the queue, Recent) are now checked against
  PowerShell's, by their category: `queue` of `queue: <message>`, as
  .NET and Rust word the same fault differently. An error only
  PowerShell can raise is taken from its snapshot, at the place in the
  pass where PowerShell sets it: one from a part that still runs in
  PowerShell alone (usage, the cut-off look, restarts, auto-continue,
  the reset ask), from closing the jobs answered in their chat, which
  the shadow never does, and from reading background work, which in
  Rust has no error.
- **Some differences will have to last longer to count.** Usage must
  differ for 4 passes, memory for 8 and leaks for 40 once they are
  compared; until then they are left out as before, and the rest still
  count at 2. Their PowerShell reads run on their own cadence, so the
  two sides see a change passes apart.
- **The shadow's log lists what it borrows.** At its start,
  `data/logs/overlay-shadow.log` names each field it takes from
  PowerShell rather than works out, and why. A test holds every field
  the comparison leaves out to that list, or to the few the host makes
  itself (its pid, its time, its commands and events, and the unread
  dots).

## 0.11.15 — The registry check in any zone

The first release since 0.11.6 to reach the Marketplace. v0.11.12 and
v0.11.13 are tags whose publish stopped at the test gate, and 0.11.14
was never tagged, so all three ship in this one.

- **The `overlay-registry` vector holds in any time zone.** pwsh 7
  reads a stamp with an offset, such as `+09:00`, as local time, so its
  read cases answered as Korea's zone does and the self-test under pwsh
  7 failed anywhere else; CI runs it in UTC. The generator now holds
  those cases to Korea's zone, as its other cases hold theirs to a zone
  of their own, and the Rust check reads them at +09:00. Nothing the
  overlay does changes.

## 0.11.14 — The new shard

The tray logo and the extension's icon are redrawn.

- **A new shard.** The tray logo and the extension's icon are now a
  data shard in a cradle, leaning a little right, not the red cartridge
  on the diagonal, which read as a pepper when small. Its red casing steps
  right at a slanted kink, a cyan core runs down a dark window and
  follows the kink, and it stands on a base plate with a cyan edge. It
  is still drawn from code (`skins/tools/make_chip.py`), with no logo
  and no third-party art. The extension's icon adds a white lane, gold
  pads and the cradle's silver posts. The tray's sits left, clear of
  the state dot.

## 0.11.13 — Magenta on the Mac too

0.11.12's release, which never shipped, with two fixes. The tag v0.11.12
is there, but its publish stopped at the checks below, so it has no
release. (Nor has this one: see 0.11.15.)
Everything in 0.11.12 is in it.

- **The macOS panel's cut-off rows are magenta,** as the Windows
  panel's have been since 0.11.11, which changed the Windows colours and
  left the Mac's orange. The light look's follows its Windows one too.
- **ctutils 0.4.4.** chatqd and the overlay now build with the fixed
  version of a crate `hmac` and `sha2` use (RUSTSEC-2026-0385: code
  meant to run in constant time could branch). The release check
  refuses 0.4.3.
- **`docs/sync-public.ps1` wraps its commit body** at 72, in two lines.

## 0.11.12 — The collector in Rust, in the shadow

The second step of moving the overlay off PowerShell (native/SPEC.md §7,
M9). The collector, the part of the overlay that reads what your chats
are doing every 2 s, now has a Rust copy. It runs only if you ask for it,
and it changes nothing: it builds its own snapshot beside the
PowerShell one and writes down where the two differ.

- **`"overlay": {"host": "shadow"}` in `data/config.json`** makes the
  native panel's PowerShell host start `chatq-overlay.exe --shadow`
  beside the panel. It closes with the host. Anything else, or no
  `host`, is `ps`, the same as before. The WPF panel does not start it.
- **It writes two files and nothing else.** It saves its snapshot and
  the differences in `data/native/overlay-shadow.json` (through a `.tmp`
  beside it, which a save that keeps failing can leave), and logs them
  in `data/logs/overlay-shadow.log`. It takes no lock (not even the
  watcher's), runs no command, and does nothing over the network. It
  never changes a chat, the queue or `config.json`.
- **What it covers:** the chats that are running and whether each is
  still alive, VS Code's open tabs, what each chat said last, background
  work, the queue and its times, the rows, Recent, the counts, reload
  asks and the notes. Usage, cut-off chats, the reset ask, auto-continue
  and memory come later. For those it takes PowerShell's own values, so
  the comparison measures only what has been ported. The dots for unread
  chats are ported but not compared: a click on the panel clears one in
  the PowerShell host alone, out of the shadow's sight.
- **A difference counts once it lasts two passes.** A chat that changes
  between the two collectors' passes is not reported.
- **It is small.** Over an hour of this PC's chats it held 4.7 MB
  private at most, flat after its first 20 minutes, against 145 to 177
  MB for the PowerShell host beside it. A pass takes about 10 ms, and
  the one in five that reads the process table up to about 35 ms. The
  log gives its memory and the minute's median and slowest pass once a
  minute. Over the hour and 20 minutes more the two collectors never
  differed (TESTING.md, "The shadow collector, the hour").
- **A day on real use.** Run for 24 hours beside the live overlay, it
  held 5.6 to 6.5 MB, 7.1 at most, and a pass took 11 to 20 ms in the
  median hour. Every difference it logged but one ended within 28 s: a
  chat seen changing a pass or two apart, or the PowerShell host
  restarting onto new code (TESTING.md, "The shadow collector, the
  day"). The one left, the panel's `ui` block, differed all day, as the
  WPF host beside it never writes one.
- **The repo is split.** github.com/phal40lax78/Chat-Session-Agent-Mk5
  is public again with a fresh history: the one-line installer and what
  it downloads, the phone's reply page, the README and its pictures, the
  changelog, the licence and the extension's README. Everything else,
  with the whole history, is in a private repo. The install line, the
  reply page's address and the Join link are 0.11.11's. The old
  addresses, under `Charlie-and-the-chat-factory`, now answer 404: an
  alert from 0.11.10 or earlier opens no reply page, and their install
  line no longer installs - use the one in the README. The README's test
  badge, which named CI the public repo no longer runs, is removed.

## 0.11.11 — Chat Session Agent Mk.5

A new name, a new dark look and a new icon. A skin pack can bring its
own tray picture, and the native panel has a Character view - a HUD
around the skin's character - beside its Panel view, the plain tile
panel it keeps to until you switch. The light look is unchanged.

- **A queued run's workflow, cut off: said; a hook's deny: no ask.** A
  queued run whose workflow was still going when print mode stopped
  waiting (its hour, `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`) ended `done`
  with nothing said, the rest of the work lost unseen; its alert now
  says `cut off as the run ended: workflow <name> (run <id>)`. And a run
  whose only denials came from the user's own PreToolUse hooks - the
  turn's or a workflow agent's, which the turn retried in an allowed
  form - read as `needs input`, alert, phone wait and overlay included,
  with no question anywhere; it is `done` now, saying `a hook blocked
  ...`.
- **Cut off is magenta now, not orange.** The cut-off state's colour,
  on both panels, the tray, the console and the extension, is magenta
  (`#F062E8` dark, `#BF3989` light), so it no longer reads as the amber
  of `needs input`. The phone page keeps its own orange.
- **A self-test run per sandbox.** `tests\run-tests.ps1` works in
  `tests\.sandbox\run-<pid>` and deletes only its own and dead runs'
  folders, so two runs at once no longer wreck each other.
- **The new name.** The extension is now *Chat Session Agent Mk.5 -
  Claude, Codex, ...*; windows, the tray's tooltip and menu, balloons
  and notices say Mk.5 (`Mk.5: 2 need you`, `Mk.5 - console`), and so
  do phone, toast and ntfy alert titles that name no chat
  (`📊 Mk.5 · usage`, was `📊 Charlie · usage`): a Tasker profile that
  matched `Charlie ·` needs `Mk.5 ·`; one on the event words is
  unchanged.
- **Renamed: the loader, the command, the folder and the repo.** The
  old name is gone from everything you see:
  - The loader is `Chat-Session-Agent-Mk5.ps1`. An update through the
    extension or `install.ps1` leaves a stand-in under the old name,
    `Charlie-and-the-chat-factory.ps1`, that loads the new one, so a
    profile line, a watcher or overlay of the old version restarting
    itself, or a window still on the old extension keep working; the
    extension then runs `chatinstall`, which rewrites the profile line
    to the new name (`replaced 1 line from an older location`).
  - The overlay's command is `chatoverlay` again, its name before
    0.10.11; `charlie` stays an alias of it, so a habit or a script
    keeps working. Help, hints, balloons and tooltips say
    `chatoverlay`. A terminal that loaded 0.11.10 and loads the update
    in place (the one-liner, or the loader dot-sourced again) drops the
    old `chatoverlay` alias first, which would otherwise hide the
    command.
  - New installs go in `~/Tools/Chat-Session-Agent-Mk5`. An existing
    `~/Tools/Charlie-and-the-chat-factory` stays the tool folder, data/
    and all, while it holds the tool and the new one does not exist; a
    set `chatManager.folder` or `CHAT_MANAGER_DIR` is unaffected.
  - The repo is github.com/phal40lax78/Chat-Session-Agent-Mk5 (GitHub
    redirects the old address), and the phone's reply page is at
    phal40lax78.github.io/Chat-Session-Agent-Mk5/reply.html. Alerts link
    the new page; the phone stays paired, as the site is the same, but a
    bookmark of the old page stops working: bookmark it again. The usage
    request's User-Agent says `Chat-Session-Agent-Mk5`.
  - Unchanged: the extension's ID (`redaechan.charlie-and-the-chat-factory`,
    so it updates in place), its `chatManager.*` settings and **Chat
    Manager:** commands, the `CHATQ_*` and `CHAT_MANAGER_DIR` variables,
    and every file in data/.
  - **What to do:** nothing, with the extension or `install.ps1`. From a
    git checkout, pull and run `chatinstall` once from the new loader
    (`. .\Chat-Session-Agent-Mk5.ps1`): the checkout has no stand-in, so
    until then a new shell's profile line names a file that is gone.
- **The dark look, red and green.** The dark look is now black with hot
  red (`#E8003A`) for the accent, the edges, the unseen-turn dot, the
  unlocked edge, the tray icon's ring and the ground under the pointer,
  and neon green (`#21FE64`) for the frame's lines, the project names
  and the busy state; the text is off-white. The WPF and native panels,
  the Mac panel's colours and the phone-alerts setup window take it;
  the console's chat titles and the setup window's heading are in
  Bahnschrift, which every Windows 10 and 11 has, in place of Georgia.
- **The shard.** The tray logo and the extension's icon are now a
  glossy red cartridge on the diagonal, a gold trace down its face, a
  comb of silver prongs at its upper end and a stepped shoulder near its
  lower one - drawn from code (`skins/tools/make_chip.py`), no logo, no
  third-party art - in place of the default skin's badge. The
  extension's icon is its slim drawing, with a raised face, a branching
  trace and four prongs; the tray's is wider, with a straight trace and
  three prongs, and sits up and left, clear of the state dot. Both
  panels' trays show it with the default skin; the badge stays the
  mascot.
- **A pack's own tray picture.** A skin pack's `stills/tray.png` (a
  square PNG, at most 1024x1024 and 8 MiB) is now its tray icon in both
  panels, ahead of its `tray` crop; a pack without one keeps its crop.
  One that is not square, too big or not a PNG is passed over for the
  crop, with one line in the log (docs/skin-pack.md).
- **Panel view and Character view, Panel view by default.** The
  native panel's tray menu has the two views under Skin, the one on
  show marked with a radio dot, the chord **Ctrl+Alt+Shift+D** shown
  beside them, and the chord switches between them from anywhere. **Panel view**, for
  when someone else can see the screen, is the tile panel alone - no
  character and no speech box, a line said at the foot as folded - and
  the panel and the tray speak and look as the plain built-in skin,
  whatever skin is picked; **Character view** is the HUD below, with
  the picked skin. Both work for every skin, the built-in included, and
  are never greyed. A first start, and every state from before this
  release, starts in Panel view; the view then lasts across restarts
  (`disguise` in `data/overlay-state.json`, true for Panel view), and
  the picked skin stays picked under it. A state left by an earlier
  0.11.11 build, its pack kept in `unmask`, starts in Panel view with
  that pack picked, so nothing is lost. Picking a skin from the Skin
  menu in Panel view picks it and switches to Character view, so the
  pick shows; a pack deleted meanwhile comes back as the built-in, kept
  for Refresh, as a deleted pack does. Switching to Character view, the
  skin's `unmask` line is said - its `{minutes}` how long Panel view was
  on, at most 4 a day, never while muted; the built-in skin's is `Out of
  Panel view after {minutes} min.` The WPF panel has no views to pick
  and no HUD; its tray shows the built-in face while the native panel
  is in Panel view, read at its start.
- **Character view.** On the native panel, Character view shows
  as a frameless HUD in place of the tile panel, with any skin, the
  built-in's badge included: no frame, no bar of buttons, every mark on
  a dark halo of its own so it reads on any wallpaper. The skin's
  character stands in the middle, fit to its box by its picture's shape;
  down its left, alert tags (AUTO, ASK n, RLD n, the notes - folded into
  NOTE n past four - and MUTE); down its right, up to five job dials,
  the one that needs you first, coloured by state and age, with a
  wedge for the age or the countdown, an hour tick a lap, a pulse when
  a chat finishes and a +N for the rest; under it, a thin bar a usage
  window with a caret for how far through it is. The speech box floats
  beside the character with a line to its mouth - left when it fits,
  else right, else below - says `Name:` inline with the turn hung under
  it, types with a block cursor and shows Next when a turn follows; it
  wipes in, glitches between turns and tears out. With no line up it
  says the host's status, or the cut-off ask with a picker (Continue n /
  Leave them, as the chip's): the text dims for a beat as the list
  comes, the cursor blinks while it waits, and a reply is picked by a
  click - or, once you have clicked the box, by its digit or the arrows
  and Enter - its row stays a moment and the box tears out; the ask is
  not asked again until it changes. The HUD never takes the keyboard by
  itself: only your click on the box, while it waits on a choice, gives
  it the keys, as a click gives any window; click elsewhere and they go
  back. Corners are cut, the text in Bahnschrift at each style's own
  weight, caps and spaced out on the tags. Switching to Character view
  runs a glitch - a tear, a smear, a beat of dark, the HUD through, a
  burst off the character - then the skin's `unmask` line; switching to
  Panel view runs it backwards in 300 ms. With Windows' animations off it is a 150 ms
  cross-fade and the dials stand still. Right-click the character for
  the tray menu; unlocked, drag it to move the HUD; the place kept is the
  panel's. Hovering a dial or a tag brings up its chip and card as a
  tile does. Folded, the HUD folds to the tile panel's strip. The
  native tile panel no longer carries the character, in Panel view or
  folded: 0.11.10's mascot and its speech box under it are gone from it,
  a skin's line is said at its foot, and the character lives in
  Character view alone, its box the HUD's. A pack's `accent`, `ink`
  and `gold` colours, which that box wore, are read no more, and the
  built-in skin no longer carries them. A
  pack's `colours` can now set the HUD's `text`, `name`, `box` and `primary`
  (docs/skin-pack.md). The WPF panel is unchanged.
- **The ask can continue by itself.** New config `overlay.askAutoSeconds`,
  0 (never) unless you set it, up to 3600: the cut-off ask left
  unanswered that many seconds continues the chats, as Continue would,
  marked answered from `timer` and said in overlay.log. It counts from
  when the overlay first had the ask as it is, so a chat joining it, or
  the overlay starting again, starts the wait again. Only an ask of the
  limit's chats alone: one with a chat a VS Code restart cut off waits
  for you, as those are never continued by themselves. Every panel acts
  on it; the HUD's picker shows it as a red timer draining to the
  deadline with its seconds left (`AUTO 4 S`), and the snapshot carries
  it as `header.ask.deadline`.

## 0.11.10 — The speech box

The native panel's lines now come in a speech box under the mascot,
typed out, rather than as a marker at the foot. The WPF panel is
unchanged.

- **The box.** Opened out, the skin's line shows in a box under the
  mascot: the skin's voice as its header, the line typed in at 18 ms a
  character, edged in the skin's accent colour (gold for an urgent
  line). A line in several parts shows one part a box, each held
  1.2 s plus 40 ms a character (4 s at most) before the next; the last
  stays its reading time; a part due while the panel is dragged waits
  for the drag's end. Folded, the line is said by the foot's marker
  as before. The box's typing runs only while it shows; a panel with
  nothing to type runs no timer for it.
- **Click it on.** Unlocked, a click on the box finishes the typing,
  then moves to the next part, then dismisses the line; three dismissals
  in 10 minutes make him quieter for the rest of the day. Locked, the
  panel lets clicks through to what is under it, as before.
- **Poke him.** Rest the pointer on the mascot for 1.5 s (locked too),
  or unlocked click him, and he says something - not while the bar, a
  chip, a card or the menu is over him there; at most once a minute
  by click and once in 10 minutes by resting. Three quick clicks get one
  more pointed line, then 5 minutes of silence.
- **He notices.** Moving the panel gets a line (at most 4 a day). The
  first look of the day out of quiet hours gets a morning line (its
  `{count}` the chats not at work or waiting); past 23:30
  with you at the PC he says the time, once a night; coming back after
  2 hours away with no chat at work gets a line too (at most 2 a day).
  Muted, none of these are said.
- **Typing measures nothing new.** The box lays each part out once,
  whole, and types into those lines, so the panel's kept text sizes do
  not grow a step at a time.

## 0.11.9 — The skin's lines

The native panel's mascot now speaks: the skin's lines, said at the
panel's foot where an open or a delete is said, in the skin's voice. The
WPF panel says none; the tool's own messages (an open, a delete, a
reload) are unchanged on both.

- **What he speaks about.** The panel reads each new snapshot against the
  last: a chat starting work, at work 5, 20 and 30 minutes, waiting on
  you (for permission, a question or input; once more 10 minutes on),
  finishing, all chats idle for 5 minutes, a usage window past 75% or
  90%, a window resetting after it ran high, a chat cut off by the limit,
  stopped by a 529, or by VS Code crashing, running out of memory or
  restarting, a cut-off chat resuming, a queued prompt sent, and a
  reload asked for (once more 30 minutes on). What is on screen as the
  panel starts, and a cut-off found over 10 minutes old, is not news.
  The default skin's lines are plain readouts ("alpha finished.").
- **He does not chatter.** Lines below urgent wait 45 s after the last
  one, at most 8 an hour, the least of them 3 an hour and 20 a day; the
  start of work is said about a third of the time and not twice in 10
  minutes, a finish not twice in 2. A chat waiting on you, a cut-off, a
  crash and a reload ask always get through and stay up 30 s or until
  the chat moves on. From 23:00 to 08:00 only those are said. The same
  thing from several chats at once is one line ("3 chats finished.").
  Every line of an event is said once before any repeats, a line said in
  the last 48 hours waits its turn, and a line too long for the box
  gives way to a shorter one. A skin with small talk says some into
  long silences, never within 10 minutes of an urgent line.
- **His face follows.** A line wears its own mood for as long as it is
  held, the skin's phrase rules choosing the face where the line hits
  one.
- **Kept apart.** What he has said, and when, is kept in
  `data/skin-state.json` beside `overlay-state.json`, so a restart does
  not repeat itself; delete it to start afresh.
- **Cut-off rows say why.** A cut-off row in `data/overlay.json` now
  carries `stop`: `limit`, `overloaded`, or `oom`, `crash` or `restart`
  for a VS Code end. Readers that do not know it are unaffected.

## 0.11.8 — The skin's face on the WPF panel

Charlie's face is gone from the tool. Its icons are now the skin's face,
as the native panel's tray icon has been since 0.11.7.

- **The WPF panel wears the skin's face.** Its tray icon, its window's
  taskbar button and Alt+Tab, the console's (the native panel's console
  too) and the phone setup window's are the tray
  still of the skin picked in the native panel's Skin menu (`skin` in
  `data/overlay-state.json`): the pack's `tray` crop, or the middle
  square of `ready`'s first frame for a pack with none. The count's
  colour dot is drawn over it as before. The WPF panel has no Skin menu,
  so it reads the pick as it starts; a pick made later shows from its
  next start.
- **A pack that will not do gives the default face.** A pack missing or
  broken, or a `skin` that is not a skin id (`[a-z0-9-]+`), gives the
  built-in face, with one line in `overlay.log` saying why.
- **The built-in face is the default skin's.** The WPF panel's own
  icon and the extension's Marketplace icon, `extension/icon.png`, are
  the default skin's round badge, drawn from code under the repo's MIT
  licence. `skins/tools/make_icon.py` makes both; `docs/make-icon.py`,
  `docs/cut-icon.py` and Charlie's pictures are deleted. A phone alert's
  icon, which is `extension/icon.png` on GitHub, shows the badge too.
- **A pack stays on this PC.** Skin packs live in `data/skins/`, which
  the repo and the extension's package never carry; a check of the
  package's files now says so.

## 0.11.7 — The Skin menu

The native panel's tray menu has a Skin submenu, so a pack in
`data/skins/` can be put on without a restart. The WPF panel is
unchanged.

- **Picking a skin.** Skin lists Default first, then each pack in
  `data/skins/` by name, then Refresh. The skin on show has a tick; a
  broken pack is greyed, its reason in the menu's tooltip. A pick
  switches at once: the mascot starts again on its mood at the first
  frame, and the skin's phrase rules are read again.
- **Kept.** The pick is saved as `skin` in `data/overlay-state.json` and
  worn at the next start; a save made by `charlie -Lock` and the like
  while the panel is not running keeps it.
- **A pack taken away.** Delete the folder of the skin on show and the
  panel shows the default within a second, with one line in its log; the
  pick stays saved, so putting the pack back and choosing Refresh, or
  restarting, brings it back.
- **The tray icon is the skin's.** The native panel's tray icon is now
  the skin's still (its `tray` crop in `skin.json`), the default skin's
  badge in place of Charlie's face, with the count and colour dot drawn
  over it as before.

## 0.11.6 — The console in a process of its own

- **With the native panel, the console runs in its own process.**
  `chatconsole`, the panel's maximize button, the tray's **Open console**
  and Ctrl+Alt+Shift+Q start a Windows PowerShell of its own for the
  console. It closes with the console's window: Esc, **← Panel**, the
  hotkey again or Alt+F4. Before, the hidden PowerShell behind the
  panel loaded the console into itself the first time it was asked for,
  and the console's parts stayed there until the overlay's next restart.
  Measured on this PC, that PowerShell settles at 131 MB private. It
  held 242 MB with the console open and 239 MB after it closed; now it
  holds 141 MB and 138 MB. The console's own process takes about 262 MB,
  only while the console is open. The WPF panel's console is unchanged.
- **The console takes about 2 s to open.** Each open starts the process
  afresh: 2.1 to 2.2 s to its first frame on this PC, its lists filled
  at about 2.8 s. Before, the first open took about 1.1 s and each one
  after it 0.2 s. Keeping the process loaded for 15 minutes after use
  would open it again in 0.1 to 0.3 s, but hold its 262 MB the whole
  time, so it closes at once.
- **The console runs the code on disk.** The overlay no longer keeps a
  copy of the console's code from its start (0.11.0). A console opened
  after an update, before the overlay has restarted onto it, runs the
  new code.
- **The console works as before.** The panel hides once the console
  shows and comes back as it closes. The overlay's verbs reach the
  console: its hotkey, the panel's own hotkey, hide, collapse, lock,
  unlock, Move to top right, Quit, a settings change and an answer to
  the limit's ask. A setting changed in the console reaches the panel.
  A balloon or said line from the console shows on the panel. While the
  console shows, or for up to 20 s while it starts, the overlay's
  code-change and memory restarts wait, as they do for the WPF console.
  If the console's process ends before a show sent to it is seen, it is
  started once more.
- **Only the overlay asks for usage.** The console shows the usage the
  overlay last read, and asks Claude, Codex and Copilot nothing itself.
- **The console comes to the front.** Checked by hand over a remote
  desktop: from the panel's maximize, the tray's **Open console** and
  `charlie -Console`, the console opened in front with the cursor in
  its text box. The hotkey is still to check at the PC itself; a
  console that Windows keeps behind flashes on the taskbar instead
  (TESTING.md S62).

## 0.11.5 — The mascot's moods

The native panel's mascot now wears a mood that follows your chats. The
WPF panel is unchanged.

- **What he shows.** Sad while a usage window is at its limit (and for
  5 minutes after it reaches it), while a cut-off ask or a chat waits
  for your answer; pleased for 7 seconds after a chat finishes; ready
  while chats work; idle otherwise - in that order, as the prototype has
  it. A mood whose face the skin lacks wears its fallback, the true mood
  kept apart for the hover card to come. Each change of mood is one line
  in the panel's log, with the reason.
- **Switching.** A new face starts at its first frame and its sheet takes
  the old one's place, so one atlas is still all that is held; a face
  with another frame rate starts the timer again at its own.
- **Moods in lines.** The skin's phrase rules (`moodmap.json`) are read
  as the skin loads, for the lines to come: a regex the panel cannot use
  (a look-around, a backreference) is left out with one log line.
- **A broken `lines.json`** now keeps the pack's own voice name; only the
  lines fall back to the default's.
- **Measured first.** The mascot animating costs 2.5 to 3.4% of one core
  on this PC, under the WPF panel's own cost, so it stays in the panel's
  window (TESTING.md, R1).

## 0.11.4 — The mascot on the panel

The native panel shows its mascot: the default skin's badge, animating
at the head of the opened-out stack. The WPF panel is unchanged.

- **One mood for now.** The mascot plays the default skin's `idle`, 24
  frames at 15 fps, whatever the queue does; the moods, a pack of your
  own and the Skin menu come later.
- **Only while you can see it.** The animation's timer runs only while
  the panel shows opened out; folded, hidden or out of a full screen's
  way, it stops, and the mascot is not drawn folded. It also stands
  still while the tray's menu is open.
- **One sheet in memory.** The panel holds one decoded atlas at a time
  (7.5 MiB for the default's), never more than 8 MiB; a larger sheet is
  refused before it is decoded. A pack's sheet that does not decode
  plays the default skin's instead, said in one line of the panel's log.
- **Height.** The mascot takes 132 of the panel's height, so the least
  the panel's height cap allows is now a row, the frame and the mascot.
  With no `data/skins/` folder at all the mascot plays all the same.

## 0.11.3 — The skin loader, not wired in yet

The native overlay's first piece of skin packs. It can read and check a
pack now, but shows none yet: nothing you run changes.

- **Packs are found and checked.** The overlay's loader lists the packs
  in `data/skins/`, checks each against `docs/skin-pack.md` and names the
  file and the rule a broken one breaks, for the Skin menu to grey it
  with that reason. A pack that is missing or broken gives the built-in
  default, with one line in the panel's log saying why.
- **The default skin is in the exe.** `skins/default/` is compiled into
  `chatq-overlay.exe`, so the overlay needs no `data/skins/` folder at
  all.
- **Forgiving where it can be.** A mood whose atlas is missing or broken
  wears its fallback face, a `lines.json` that does not read gives the
  default lines, and an unknown mood name or a newer minor format version
  is skipped - each said in one log line, the rest of the pack loaded.
  Only `idle` and `ready` must be whole.
- **The format, settled where the loader met it.** Which keys a manifest
  needs; a sprite grid may leave its last row short (22 to 25 frames on
  5 x 5); a mood switch starts at frame 0; `s` on an event is optional;
  `{close}` is a slot; `status.mood` comes before `sections.status`; the
  roast banks are under `conversations.habit.roast`.

## 0.11.2 — Skin packs and the Brain, not wired in yet

Two parts for the native overlay, in the repo and tested on their own.
Nothing you run changes: the overlay loads neither yet.

- **Skin packs: the mascot as data.** A pack is a folder - a manifest
  (`skin.json`), one sprite atlas and its frame data per mood, the lines
  (`lines.json`), the mood rules (`moodmap.json`) and its writer's notes -
  in the format `docs/skin-pack.md` sets out. To install one, drop it in
  `data/skins/<id>/`; to uninstall it, delete that folder. The overlay
  will list packs under Skin in its menu and fall back to the default for
  a pack that is missing or broken.
- **The default skin.** `skins/default/` is a neutral mascot - a round
  badge, seven moods, 24 frames each - with plain lines that only state
  facts ("{project} finished."). `skins/tools/make_default.py` draws it
  from code, so the repo holds no third-party art, and a writer copies
  the folder to start a pack of their own.
- **The Brain: a classifier beside the overlay.** `native/brain/` is
  `chatq-brain`, a small program on its own that answers the overlay's
  questions about a chat's last few turns over localhost. Four of them
  go to a model: did the assistant change more than was asked
  (`scope_drift`), did you change your mind (`contradiction`), is a
  reply left unread (`unread_reply`), is a prompt too thin
  (`prompt_quality`). Two - what kind of failure, and what to pull out
  of a tool's output - stay on regex rules.
- **Three backends, one picked.** `"backend"` in `data/brain/brain.json`
  picks the model behind those four: `gemini` (the default, Google's
  `gemini-3.1-flash-lite`), `anthropic` (Claude Haiku 4.5) or `local`
  (llama.cpp on this PC). Read once at start; any other name stops the
  Brain with an error, never a quiet fallback. Each backend's own
  `"model"` can be set there too.
- **Your key, in one file.** The Gemini API key goes in
  `data/brain/gemini-key` (or `GEMINI_API_KEY`), Claude's in
  `data/brain/anthropic-key` (or `ANTHROPIC_API_KEY`); each backend reads
  only its own, and a key is never logged, put in a URL or answered
  back. For Gemini a paid key is recommended: on the free tier Google
  may use the text to improve its products. Local needs no key.
- **Local, on request.** Nothing downloads until the menu asks
  (`POST /install`): then a llama.cpp server and one model, each pinned
  to a release and its sha256, resumed if cut off. Phi-4 mini is the
  default of seven; one model stays on disk. GPU (Vulkan) is opt-in. It
  loads on first use, unloads after 10 minutes idle, and waits rather
  than load when free memory is short.
- **What it costs, kept.** Each call adds a line to
  `data/brain/usage.jsonl` - tokens, time and cost, no chat text - and
  `/usage` sums it by day, month and all time, on all three backends.
  About $0.17 per 1,000 calls on Gemini, an estimated $0.63 on Claude,
  0 on local.
- **No fallback.** When the model does not answer in time - no key, a
  bad key, rate-limited, overloaded, offline, slower than 2.3 s (10 s
  on local) - that event is dropped: no line, no tag. Failure kinds and extraction keep
  their regex answer.
- **Why not a local model, by default.** On this PC no local model beat
  a rule that always says no by more than one case in 40, and few
  answered within 2.5 s; Gemini 3.1 Flash-Lite got 32 of 40 verdicts
  right, against that rule's 20, in about 1.1 s. Local is there for a
  PC with no network or no key, later - not the one to pick now.
- **What will ship, per question** (40 hand-labelled tails from real
  chats, tested on the same tails the prompts were tuned on, so
  optimistic): `unread_reply` yes, 9 of 10; `prompt_quality` the
  weak-or-fine verdict only, 9 of 10, not its 0-3 score; `scope_drift`
  provisionally, 8 of 10, to be checked on fresh tails; `contradiction`
  no, 6 of 10, still calling 4 of 5 clean tails a contradiction.

## 0.11.1 — The Rust panel ships

- **The VS Code extension carries the native panel.** Its package holds
  `chatq-overlay.exe` - built and checked by CI from the tagged source -
  with its licence notices, `THIRD-PARTY-NOTICES.html`, beside it. On
  Windows, setup puts both in
  `bin/<version>/x86_64-pc-windows-msvc/` beside the script, before the
  scripts, so the new loader finds its panel there. A file it
  cannot write - held by an antivirus, or the exe running - is logged
  and left, and the scripts still land. Other versions' `bin/<x.y.z>`
  folders are removed after; one in use stays until the next update.
  A Mac or Linux copies no exe.
- **The native panel is the default.** Without `"panel"` in
  `data/config.json`, the overlay draws the Rust panel where its exe is
  there, and the WPF panel where it is not - every zip and git install,
  which have no `bin/`, quietly. `charlie -Panel ps` keeps the WPF panel
  for good; an update leaves that choice alone.
- **A native panel that fails falls back to WPF.** An exe that will not
  start - blocked by an antivirus or AppLocker - or a panel that exits 3
  times in 10 minutes blows the panel's fuse for this version
  (`data/native/panel-fuse.json`): the WPF panel starts in its place,
  `data/logs/overlay.log` says why, and its tray says so once. The next
  version tries native again, as does `charlie -Panel native`, which
  clears the fuse and restarts a running overlay onto it.
- **The exe is unsigned,** so an antivirus may look twice at it; signing
  waits on a code-signing certificate account (DEFERRED.md). One that
  blocks it blows the fuse above, and the WPF panel draws.
- **`chatq-overlay --version`** prints its version, which is now the
  script's: the build fails if they differ, and so does the extension's
  package when the exe in it is another version's.
- **Releases attach the panel on its own:** the exe and its notices
  zipped, with `SHA256SUMS`, beside the VSIX.

## 0.11.0 — The overlay in Rust, if you want it

- **`charlie -Panel native` draws the panel in Rust.** On Windows,
  `chatq-overlay.exe` - the same panel in Rust and Slint, in a process
  of its own - takes the WPF panel's place, the hidden PowerShell still
  collecting the chats, doing what you click and drawing the console.
  It is `"panel": "native"` under `overlay` in `data/config.json`; the
  WPF panel stays the default, and `charlie -Panel ps` goes back. A
  running overlay starts again on the one chosen.
- **It is found beside the script, as chatqd is:**
  `bin/<version>/x86_64-pc-windows-msvc/chatq-overlay.exe` - a
  developer's build for now, put there by hand; none ships yet. With none
  there, the WPF panel, and one line in `data/logs/overlay.log` saying
  where it looked; `charlie -Panel native` says so too, and only reloads
  a running overlay, which would come back as the WPF panel anyway.
- **An update to a version with no build there draws the WPF panel.**
  The overlay's restart onto the new code no longer keeps the old
  version's build: it starts what a fresh start would.
- **The native panel's bar has no Windows title bar.** Shown, or shown
  again, the bar under the panel could draw a grey caption reading
  `chatq-overlay` with a close button until it was resized: Windows
  painted it each time the panel set its window's title. It is set
  unseen now.
- **The native panel logs each balloon,** with the tray up too.
- **What you click while the native panel starts again is done.** The
  panel says which of the overlay's commands it has carried out, and one
  started in its place carries out the rest, none twice.
- **A said line outlives a restart of the native panel,** shown again
  for its whole time, as a balloon is.
- **The console opens with no flash after the code changed.** The
  headless host keeps the console's code as it read it when it started,
  so the console opens in that process rather than in a restart.
- **The console asked for as the overlay starts is kept** across a
  restart in its first pass.
- **A command file the overlay cannot take no longer spins it.** An
  `overlay-cmd` that cannot be moved - held open, or denied - is tried
  again each pass, said once in the log, and no longer wakes every wait
  between passes at once.
- **A full screen, as Windows answers for it.** The native panel's
  reading of Windows' full-screen query is tested answer by answer: a
  busy screen, a game's full screen and a presentation step it aside;
  an app's own, quiet time and a failed query don't.
- **The panel's sandbox runs take no hotkeys.** `tests/m9/collect.ps1`
  and `tests/m9/audit.ps1` give their panel none unless `-Hotkey` and
  `-ConsoleHotkey` name some, so a real panel run in them never takes
  Ctrl+Alt+Shift+O or Q from the overlay you are using.

## 0.10.21 — The native watcher listens

- **An open reply window is listened to natively - for a developer, for
  now.** Where a build is there (see 0.10.15), chatqd no longer hands the
  phone's reply window to a PowerShell watcher: it reads the reply topic
  itself, at the same 6/15/20 s, logs what is not a reply as the
  PowerShell watcher does, saves where polling got to, logs `listening
  for phone replies …` and `replies closed`, and writes the board while
  it listens (native/SPEC.md 7, M3). That saves the watcher's PowerShell
  process for as long as it only listens: on the day measured, about 166
  MB private while it ran, 98 averaged over the day (native/SPEC.md 8,
  "Memory, measured"). Listening for an hour on ntfy.sh, chatqd itself
  held 2.58 MB private 60 s after its 10th poll, 2.77 on average and 3.49
  at most, against its 8 MB limit (TESTING.md S59; a build from just
  before the firewall handoff below).
- **A reply still goes to PowerShell, a step at a time.** A batch that
  holds a message that checks out - a reply, a board request, a pairing -
  goes whole to one `reply` step, which acts on it as the PowerShell
  watcher would; chatqd never moves `lastId` past it itself. A step that
  fails holds the next one back a minute, doubling to 10, with one line in
  `watcher.log` at most every 10 minutes; the batch is fetched again.
- **chatqd hands over when it panics, or when a firewall stops it.** The
  handoff in `data/native/handoff.json` is left for those two. A firewall
  that blocks outbound programs by default, with a rule that lets
  PowerShell out, refuses a new `chatqd.exe` at once: then chatqd says so in `watcher.log` - `the firewall blocks chatqd, so
  the PowerShell watcher listens for phone replies instead …` - and hands
  the open window to a PowerShell watcher, as 0.10.20 did, so phone
  replies keep working with nothing to set up. The next chatqd to start
  tries again; letting `chatqd.exe` out through the firewall saves that
  watcher's memory.
- **No Authorization header on the poll,** as the PowerShell watcher
  sends none; the system proxy as Windows gives it, the environment's
  proxy variables unread (native/SPEC.md 8).
- **`reply.hours` read as PowerShell reads it, list or not.** The native
  watcher's reading of `reply.hours` in `data/config.json` - how long an
  alert can be answered, and so what `data/replies.json` keeps when it is
  saved - now takes a `reply` written as a one-item list as its item, as
  PowerShell does; it fell back to 12 hours there, where PowerShell kept
  the hours you set.

## 0.10.20 — A reload ask is a quiet note

- **A reload ask is a quiet note at the panel's foot, gone in 30 s.**
  A VS Code window's reload question is no longer a yellow warning up
  with the usage: its marker is dim, an `i` in a ring, under the rows
  where the said marker goes, and its card no longer leads in yellow.
  Unanswered, it leaves the overlay 30 s after it came - the notice is
  still in VS Code's notification centre - as **later** would. Its
  **reload** and **later** come up on the panel, just past the marker,
  where they hung out past the panel's side.

## 0.10.19 — The bin on the tile

- **Delete is on the tile, always.** Every chat's tile, and a Recent
  line's box, is wider by a bin drawn at its right end - faint where it
  can't delete - and the panel with them; the chip's bin comes up over
  it, lit, and what it says - `sure?`, `opening`, `click again` - beside
  it, where all of it hung out past the panel's side. The card comes up just beside
  the panel, no longer out past the bin; a cut-off's **continue** and
  the auto chips still hang outside, and the card still goes past them.
- **Grab the panel by any tile.** Press a chat's tile and move it a few
  pixels: the panel follows, as from the bar, and nothing opens when you
  let go. A press that doesn't move still opens the chat.
- **A card's project and title are two lines.** The project, bold in its
  colour, on a line of its own, the title under it, still two lines at
  most, where the two ran on together.
- **A usage gauge's card hangs under it,** its tail up at the gauge's
  middle, centred on it and kept on the screen, rather than out to one
  side - over it, its tail down, where the screen's foot leaves no room.
- **Warnings on a card, not the panel.** Memory low, a program growing, a
  stopped watcher, the next queued prompt, an error, the limit's ask, a
  window's reload, what the chip's open or delete said and the unlocked
  hint are each a short tile in their colour with a glyph alone - a
  warning triangle, a ring with a cross or an `i`, an open padlock - and
  their words on the card a rest on it brings up, beside the panel as a
  chat's is. The ask's and the reload's chips keep their answers. An
  open's words show on its chat's card too. Folded, the markers are drawn
  under the line, as many as fit, so a memory warning is still a rest
  away. The foot still keeps the said marker's room, so no row is cut as
  it comes. `charlie -Print` and the macOS panel keep their lines.
- **chatqd's watcher tests hold on macOS.** They looked for Windows line
  ends and `USERPROFILE` where chatqd, as the SPEC says, writes the OS's
  own and starts in `HOME`; chatqd itself is unchanged. 0.10.18's tag
  never published: these failed on macOS behind 0.10.17's.

## 0.10.18 — The usage card in numbers

- **A usage gauge's card is one line of numbers again,** as the usage
  line read before 0.10.17: the provider, each window's percent - plain,
  amber or red as before - one reset time, the latest of a window at its
  limit else the 5h one's, and when the figure is from. The bars it drew
  repeated the gauge under it; the time goes once it has passed.
- **chatqd on macOS knows a binary named with `..` as the same one.**
  Off Windows Rust's `std::path::absolute` keeps `..`, where PowerShell's
  FullName drops it, so the preflight record could hold one binary twice;
  [Identity.of](native/crates/chatq-core/src/launch.rs) now drops it by
  text there, symlinks left alone. Windows names nothing differently.
  0.10.17's tag never published: this check failed on macOS.

## 0.10.17 — Clocks alone on a narrow panel

- **A chat's row on the Windows panel is its tile alone,** one a line:
  where it runs and its clock, in its state's colour, 36 units tall.
  Project, title and the row's words went to the hover card, which a
  rest on the row brings up as before; a glance at the panel is how long
  each chat has worked, waited or sat idle.
- **The panel is as wide as a tile.** About 150 units, the bar of six
  buttons just fitting, where it was 380 with the right half empty - so
  the dark look's gold lozenge, which sat left of them, is gone. Its
  width is no longer a setting there: the sides and corners no longer
  drag, only the top and bottom, for rows and then Recent lines.
  `charlie -Width` and config.json's `width` stay, for macOS, and say
  so when set on Windows. Words that no longer fit on
  one line - a note, "+N more", the collapsed line, a banner - wrap.
- **Usage is a gauge.** One thin bar a window, the 5h over the weekly,
  filled to its percent in its colour - the limit's at the limit, faint
  when stale - with no words. A rest on it brings up its card: each
  window's bar, percent and a countdown to its reset, and when the
  figure is from. With two providers open a mark says whose (Cl, Cx,
  Cp), all three starting with C. The collapsed panel draws the same
  gauges under its line, and their cards come up there too.
- **Usage only for what is open.** A provider's gauge shows only while a
  chat or job of it is open: Claude's with any chat, Codex's while a
  Codex job is queued or runs, Copilot's - which has no rows - not at
  all; with no chat open, none, and the refresh button's `checked` with
  it. macOS, `charlie -Print`, the console, the phone and the alerts
  are unchanged, and keep `usageView`.
- **The card says whose chat it is.** Its first lines are the project,
  bold in the project colour, and the title, two lines at most; under
  them, dim, what the row's words say that the card's state line does
  not - a queued prompt's place, say - then a rule.
- **A Recent line is a dot and how long ago,** its project and title on
  its card too.
- **The open is a ring.** The chip rings the tile in the accent's colour
  where it used to draw the name again as a button. The bin, and a
  cut-off's continue, hang just outside the panel on the side the card
  takes, and the card goes out past them.
- **The settings box: five rows.** Opacity, rows, theme, Recent and Cut
  off - Style, width and Usage gone. Wider than the panel, it hangs out
  to the left, or to the right by the screen's left edge.
  `charlie -Compact` and `prompts` stay, for macOS and `-Print`; the
  Windows panel draws the same whichever is set. The console's list keeps its one-line rows.

## 0.10.16 — The native watcher runs the queue, PowerShell a step at a time

- **chatqd runs the watcher's loop itself - for a developer, for now.**
  Where a build is there (see 0.10.15), chatqd no longer hands a queued
  job to a PowerShell watcher. It lists the queue, works out what is due and
  when, waits, keeps the machine awake, writes the board and takes
  `chatqrun -Now`, as the PowerShell watcher does (native/SPEC.md 7, M2).
  Each piece of PowerShell work - a job's run, a limit scan, an alert, the
  held summary, the auto-continue scan, the stray sweep, a usage
  heads-up, the repair after a crash - goes to a short-lived PowerShell,
  a *step*, that does that one thing through `src/native-step.ps1` and
  exits. No build ships yet, so no install changes.
- **Between steps only chatqd waits.** A step costs about 0.4 s and 100
  MB while it runs, and runs only on a pass where the PowerShell watcher
  would do that work too: the held summary outside quiet hours and not
  within 5 minutes of a failed try, the stray sweep only when the queue
  folder may hold a stray, a heads-up not already in
  `usage-alerts.json`. What a real wait and a real night cost is
  TESTING.md's S57, not yet run.
- **The phone's reply window still goes to a PowerShell watcher,** which
  listens until M3. chatqd now hands it what it knows - the limits it
  saw, its last probes and scans, the questions asked from the phone, the
  heads-ups and summary already sent - in `data/native/handoff.json`, the
  PowerShell-only caches in `carry.clixml`, so that watcher does not
  probe, scan or push again what chatqd just did. With replies on, an
  answerable alert opens the window, so most picks still end in that
  handoff.
- **A job run under chatqd names chatqd.** The job's `runnerPid`,
  `run-state`, `state.json` and `watcher.pid` all name chatqd's pid, as
  they named the PowerShell watcher's, and `permit.log` and `ask.log` tag
  their lines with it, so VS Code and the repair see the run as live
  while chatqd is. A step whose chatqd is gone ends itself at its next
  look, within about 10 s, and the next watcher marks its job
  `interrupted`, as after a watcher killed mid-run.
- **A pick that fails fails its job, once.** A pick step that does not
  start, does not load, dies or answers badly: `watcher.log` says
  `#<seq> error: helper step <reason>`, the job ends failed as `chatq
  error: helper step <reason>` with its `failed` alert, and the next pass
  goes on. A job removed meanwhile stays removed. A block scan, held
  summary or ask check whose step fails counts as tried, so it waits its
  interval rather than costing a step every pass.
- **Where chatqd differs** is in native/SPEC.md 8: a pick reads its job
  again, so one removed or no longer queued in the step's 0.4 s start is
  skipped where PowerShell would run it; and the PowerShell watcher a
  handoff starts runs the auto scan and the stray sweep on its first
  pass, since those timers are not carried.
- **A job its own id does not find is set aside, in both watchers.** A
  second job file holding the same id - a copy made by hand - or a blank
  id made the pick look for the job, find nothing and return, and the
  next pass pick it again at once: no wait in the PowerShell watcher, a
  step of 0.4 s and 100 MB a pass under chatqd. Now the loop passes it
  over, leaves its files as they are, and says once in `watcher.log`
  which files hold that id; the rest of the queue runs.
- **The PowerShell watcher is unchanged** but for that. With no chatqd
  build, or `"watcher": "ps"`, it runs as before: the seams it gained for
  steps stay unset there. M0's `hold` test seam is gone, since chatqd now
  waits for real.
- **Checks.** A self-test section of its own runs every step op, the
  watch state through JSON and back, the carry, a step's death with its
  parent, and an audit that classes every variable a step reaches;
  chatqd's own loop replays `timers.json`; and with a build, the same
  jobs run under the PowerShell watcher and under chatqd must leave the
  same logs, job files, `state.json` and board (TESTING.md).

## 0.10.15 — A shell opens light

- **The profile line loads a small part of the tool, and the rest on first
  use.** Most shells never run a chat command: they host `claude`, or
  other work. Now a shell's profile load takes `src/shell.ps1` alone - a
  stand-in for each command, the aliases, Tab, Shift+Tab, the arrows and
  Enter - and the whole tool loads the first time you run a command, or
  press Tab or Enter on a line that starts with one. A fresh Windows
  PowerShell with PSReadLine: 73 MB private instead of 108, a bare one
  being 55, median of 5 after a full collection. That first use waits
  the load the shell used to spend as it opened.
- **What a shell does as it opens is unchanged.** A job queued with no
  watcher, a phone's listening to pick up or the overlay to start: the
  shell checks the files for each, without the tool, and where one has
  something to do loads the tool at once and does it, as before. Charlie
  closed by hand since this sign-in is nothing to do, so those shells stay
  light too. A config that will not read, or a phone not yet paired with
  an alert out, loads it - the check leans to a load too many, never a
  duty missed.
- **Only a profile's load, in a shell a person types in.** A dot-source at
  the prompt, the watcher, the overlay, the processes it starts, the
  permission bridge, the question hook, a run under Claude Code
  (`CLAUDECODE`), a shell with no interactive session and the tests load
  the whole tool, as before.
- **Before the first use**, `Get-Help chatq` says the tool loads on first
  use, and the tool's own functions (`Get-ChatqJobs` and the rest) are not
  there yet. Tab on a parameter's name (`chatrm -Pro<Tab>`) loads it
  through the Tab key's own handler; Ctrl+Space's menu there, and Tab too
  with `$ChatNoKeyBindings` set or no PSReadLine, offers only the common
  parameters - an argument's Tab, or any command, loads the tool.
- **The tool a shell loads is the one on disk then.** An update since the
  shell opened loads on that shell's first use, where it used to wait for
  a new shell; one caught part way through its copy says it did not load,
  and a new shell has it.
- **A native watcher, chatqd, can stand in for the PowerShell one - for a
  developer, for now.** Where a chatqd build sits in
  `bin/<version>/<target>/` beside `data/`, or `CHATQ_CHATQD` names one,
  a launch starts it in the PowerShell watcher's place (native/SPEC.md,
  4.2). No build ships yet, so no install changes: a launch looks for
  `data/native` and `bin/`, and reads and writes nothing more. This first
  step saves no memory either: chatqd hands any work to a PowerShell
  watcher, and leaves when the queue is empty.
- **A native watcher that fails is set aside.** A build must answer
  `chatqd version` within 5 s before its first launch. A launch never
  acked, a crash, a failed check or a start that fails is a strike, and
  that same launch starts the PowerShell watcher instead; three in a day
  keep that version on PowerShell, with one `failed` alert, until
  `data/native/fuse.json` is deleted. `"watcher": "ps"` in
  `data/config.json`, set by hand, keeps the PowerShell watcher. A
  watcher loaded before an update starts the new version's build, never
  its own.
- **A native watcher reads the files as its PowerShell does.** chatqd
  reads `config.json`, the job files and `state.json` as the PowerShell it
  was started for reads them. Under PowerShell 7 a `config.json` with `//`
  comments or a trailing comma counts, so phone replies or auto-continue
  set there hand the work to a PowerShell watcher, and a job file written
  so is not passed over. Under Windows PowerShell 5.1 such a file reads as
  empty, as it does for the PowerShell watcher. Without a chatqd build
  none of this runs.
- **The rest of the watcher, ported but not yet used.** chatq-core,
  chatqd's library, now holds a Rust copy of most of what the PowerShell
  watcher works out: the queue's order, its timers, the board, a run's
  command line and environment, phone replies and their files, the logs,
  dates and DPAPI secrets (native/SPEC.md 7, M1). Each is held to what
  both PowerShells answer, in 19 files of cases they make. chatqd still
  hands every job to a PowerShell watcher, so nothing else changes yet.
- **CI builds chatqd** for Windows and for both kinds of Mac, tests it,
  and runs the PowerShell checks against that build. A release workflow,
  run by hand, makes its download files unsigned and publishes nothing.
- **The overlay says when a program keeps growing,** on Windows, memory
  low yet or not. On 2026-10-19 a Word that File Explorer's preview pane
  started for a `.docx` grew 0.25 to 0.45 GB a minute, to 21.5 GB, until
  a VS Code window died of it and cut a chat off. The memory warning said
  so once, at 95%, and then nothing: it reads a level, and a program
  growing 6 GB in 11 minutes looked the same as one standing still. Now,
  once a minute, the overlay reads each process's memory, and a process
  grown 2 GB or more since its figure 10 minutes back is said -
  `WINWORD grew 6.1 GB in 10 min, now 15.8 GB (pid 33188) - it may be
  leaking`: a line in `overlay.log`, a balloon in the tray, and a note on
  the panel while it keeps growing. Each program once in 30 minutes; with
  memory low in the same pass, one balloon says both. A process each, not
  a program's sum: VS Code's windows, new chats and a build's compilers
  add processes of one name all day, and nothing leaks. A process not
  running 10 minutes back is not counted. `overlay.leakGB` sets the
  amount; 0 turns it off. The memory warning names its top programs from
  the same walk of the processes, so it adds none.
- **The overlay starts again when it holds too much.** Its own memory
  climbs in steps over a day or two: over 78 runs in one PC's log a fresh
  one settled at 210 to 260 MB, and one up some 30 hours sat at 315 to
  322. After a compaction it restarts once it holds 300 MB or more
  (`overlay.restartMB`; 0 turns it off), 50 MB or more over the least it
  held from 30 minutes in, and has been up an hour - as it does for an
  update, once nothing is under way: not mid-drag, with the console up or
  a slider not at rest. `overlay.log` says why, and its stop line says a
  memory restart. A run that starts high never restarts for that, nor a
  new one in its first hour, so it cannot loop. Going by that log, about
  once a day.
- **What a restart forgets,** this one or an update's: the unread dots, a
  reset ask's phone alert still waiting for you to be away, and when the
  tray last said memory low or a program growing - so either may be said
  again soon after.

## 0.10.14 — A chat's title brings its group forward, VS Code in front or not

- **Clicking a chat's title on the panel brings its group forward** when
  its window was already in front. The window came up, but the chat's tab
  could sit in a group other than the one in use, out of view, though the
  log said `revealed`. Now, when the open makes no new tab and the chat's
  tab is in front of its own group, that group is focused.
- **A tab behind others in its own group is left.** Then Claude Code
  showed the chat somewhere else, the side bar say, and bringing that tab
  forward could wake a tab kept over a reload into a second claude on the
  same chat. So is a tab not surely the chat's: none, two of one label, or
  a label another chat of its folder has.
- **Each case is in the log** under **Chat Manager: Show log**, with what
  was in front and whether the window had focus - `revealed, but its tab
  is behind another in its group` among them. If a click still leaves the
  chat out of sight, that line says why.

## 0.10.13 — What a chat is doing, on a card when you rest on its row

- **Rest on a row and a card says what its chat is doing.** Since 0.10.10
  a row shows its state and how long, but not what the chat is at, and
  your prompt left the rows. Now, on Windows, as the open chip comes up -
  after 400 ms, or what `charlie -ChipDelay` set - a card comes up beside
  the panel, level with the row, on the side with more room: a speech
  bubble whose tail points at the row, so whose chat it is goes without
  saying - the row already names it. It says what the chat does now,
  under a word in its state's colour: **NOW**
  `Bash  git status --short` with a clock for how long that call has run;
  **WAITS** `Allow Bash` and the command, `Asks` and the question, or
  `Plan to approve` and its first line; **FINISHED 14:05**, **STOPPED**,
  **CUT OFF**, **QUEUED**. Then the three calls before (**EARLIER**), the
  todo list's progress (**TASKS** `1 of 3 · Writing the card`), your
  newest prompt, dimmed, and the end of Claude's newest words, each with
  its time.
- **It never gets in the way.** The card goes with the chip, 300 ms after
  the pointer leaves the row. It takes no click - the mouse goes through
  it - and no focus, and is in neither Alt+Tab nor the taskbar. A queued
  prompt's own row gets one, showing the prompt it will send; a banner
  never does, and none comes while the settings box is open, the panel is
  folded to one line or being dragged, out of a full screen's way, or in
  the console. It takes the panel's look, dark or light, and the panel's
  opacity.
- **A tile's clock has no seconds now.** A chat at work or waiting on you
  read `5:03`, ticking every second beside the rows; it reads `0h05` as
  an idle one does, moving on the minute. The card's clock for the call
  going keeps its seconds.
- **Read only while it shows.** The card reads the end of the chat's
  transcript as it comes up - 256 KB, or up to 4 MB while one line, a
  file read whole, is longer - and again on the 2 s pass only while it
  shows and the transcript grew. The prompt is what you typed: the file
  VS Code says is open with it, and a pasted picture, are left out, and a
  picture alone shows no prompt rather than an older one.
- **What looks like a secret** in a call's words, a question or a plan
  shows as `***`, as on the phone's permission page - the word after
  `token`, `password`, `session` and the like too, even in a question.
  Your prompt and Claude's words are as written: a card shows them only
  while you rest on the row.
- **Not on macOS,** and a Codex job's card has its prompt alone, its
  rollout unread: DEFERRED.md, "The hover card: what it leaves out".

## 0.10.12 — A deleted chat's tab closes, and `chatarchive`

- **A deleted Claude chat's tab closes.** After `chatrm`, `chatclean` or
  the overlay's delete, the tab stayed open on a chat no longer on disk.
  Now each VS Code window that had the chat as a tab closes it, the one in
  front too, and the reload offer says so: *Deleted "Old chat" and closed
  its tab. Reload to refresh the chat list?* - the reload is still asked
  for, since Claude Code's chat list is cached. The script names the
  windows from their `data/open-tabs/` files before the transcript goes,
  so a window on another folder closes its copy too.
- **A tab it cannot be sure of is left.** A tab is known only by its
  label, so a tab closes only when, right before the close, it is the one
  Claude tab of that label in the window, no other chat of its folder
  would carry the label, and the chat is not working or waiting on you -
  `chatrm` itself never asks that. Otherwise the tab stays, and one notice
  names the chats whose tabs were left. A tab the window's open-tabs file
  never listed - untitled, two of one label, a label two chats share, a
  chat older than its folder's newest 200 - stays without a word, and so
  does every tab when the window only sees the request as it starts or
  over 2 minutes late (DEFERRED.md). Codex and Copilot tabs and a chat in
  the side bar are not closed; archiving refuses a chat open in a window,
  as before.
- **`chatarchive` puts a chat away.** `chatarchive <id|title>` does what
  `chatrm -Archive` did, with `chatrm`'s switches - `-Force`,
  `-AllProjects`, `-NoWait`, `-DropJobs`, `-Provider` - and its Tab and
  Enter fill-in. A title typed in part asks `archive?` rather than
  `delete permanently?`. `chatrestore` brings a chat back as before; its
  help, the `chat` cheat sheet and `Get-Help chatarchive` say the new
  name.
- **BREAKING:** `chatrm` has no `-Archive` any more. `chatrm <chat>
  -Archive`, or a short form of it, now stops with *chatrm has no -Archive
  any more - chatarchive ... puts a chat away* and touches nothing, rather
  than search for a title that holds `-Archive`. Scripts that archived
  with `chatrm -Archive` need `chatarchive`.

## 0.10.11 — The overlay is `charlie`, in Charlie's colours

- **The overlay's command is `charlie`.** Every switch works as before -
  `charlie -Stop`, `charlie -Theme light`, `charlie -Print` - and a shell
  that starts the panel says `charlie started`. `chatoverlay` still works
  and does the same, and `Get-Help chatoverlay` shows charlie's help.
- **The dark look is Charlie's.** The panel is wine-black inside a thin
  gold double line, a gold lozenge and two hairlines at its top left;
  crimson under the pointer, hot pink for the accent - the settings'
  choices, the dot of a turn not seen, the unlocked and the sizing edge -
  ivory text and blush project names. Faint text reads 5:1 over a white
  desktop, where it read 2.5:1. The states keep their colours; usage
  within its limits is ivory where it was blue. It is all drawn in code:
  no image or font is added. Each chat's title is in Windows' own
  Georgia, in the panel and the console's list. The light look is as it
  was.
- **The tray icon's dot is ringed in crimson** in the dark look, and in the
  icon's near-black as before in the light one; it is drawn again when the
  look changes.
- **The console, the settings box, the open chip and the phone setup
  window take the same colours.** The console has the gold line; the setup
  window's heading is a serif over a short gold rule.
- **The reply page and the board, in a phone's dark mode,** are near-black
  with gold hairlines, a pink accent and serif headings, with a small gold
  flourish under the board's header; the PC's name there is a size
  smaller, so a Windows default name still fits a narrow phone. The
  board's Recent and Older headings read where they were all but
  invisible; an armed Send keeps its red, with dark text on it (7.6:1,
  where white read 2.5:1); the dot of a turn not seen takes the accent.
  Light mode is as it was.
- **On macOS** the panel takes the new colours and a gold line round it;
  the rest of the look waits for the panel's first run (DEFERRED.md).
- **A chat's name is its open button; delete is always on its row as a
  bin; idle and working are gone from its right.** On Windows a row no
  longer says `idle`, `working`, `running` or `needs you`: its tile's
  colour says it. What the tile cannot say stays - `cut off - resets
  13:00`, `#2 after #1`, a chat's background work. In their place, at the
  row's right end, is delete as a bin, faint where it cannot delete. Open
  is the row's project and title: under the pointer they turn the
  accent's colour, an underline sweeps under them from the left, and the
  open's glyph slides in at the title's end (an eye, watch, while a
  queued prompt runs in the chat); pressed, they sit a unit lower. The
  panel still lets clicks through, so the chip still comes up after a
  rest on the row - now as that name, drawn exactly over the row's, and
  the bin over the row's own - and takes the click; **sure?**, **click
  again** and `opening 3s` show beside the bin, and an armed bin turns
  red. In the console's list the name lights at once and opens the chat
  on a click; a click anywhere else on the row picks it, as before.
  macOS rows are as they were.
- **An alert is titled with its chat, after a mark for what happened.**
  Every toast and push was titled `chatq · done`, the chat named only in
  the text, so telling which chat meant opening it. Now it reads **✅
  Release notes** over `done · 4m · 2 turns`: ❓ needs input, ❌ failed,
  ▶️ started, ⏸️ limited, ⚠️ overloaded, ⏳ waiting, 🔐 permission, 💬
  reply. One whose text names no chat is `📊 Charlie · usage`, `🔔
  Charlie · test`, `💬 Charlie · reply` and so on, its text as it was: a
  name goes in the title only where the text already had it, so a new
  chat queued from the phone still keeps its sealed title out of the
  push. Your alert command
  gets the same title and words in `CHATQ_TITLE` and `CHATQ_TEXT`;
  `alerts.log` keeps the text as it was. The macOS overlay's notification
  says `Charlie` too.
- **BREAKING:** titles no longer start `chatq ·`. A Tasker profile that
  filtered on it matches nothing now: match the event at the start of the
  text, or, as README's *Reply from Tasker* now does, the reply link.

## 0.10.10 — Each chat's state on a tile, with a big clock

- **On Windows a row starts on a tile in its state's colour, a big clock
  on it.** A chat's state was a small dot and its age a few words at the
  row's end, hard to read from across the desk. Each row now starts on a
  tile, its border drawn in the state's colour - amber waiting on you,
  green at work, blue a job running, purple queued and dashed, orange cut
  off, grey idle - and its ground washed in for a chat that needs you
  (amber, or cut off), a little for one at work. A seven-segment clock lit
  in that colour, over the faint ghost of every segment, says for how
  long. Where a chat runs is marked at the tile's left, in its colour: a
  window with a title bar for VS Code, `>_` for a terminal, a play
  triangle while a queued prompt runs in it, a bare window when that is
  not known, and a ring for a job or a cut-off chat open nowhere, the
  triangle in it while the job runs. The unread dot sits on the tile's
  top right corner.
- **The clocks:** minutes and seconds while a chat works or waits on you
  (`5:03`), hours and minutes past the hour (`2h05`) and while it sits
  idle, moving on the minute; days and hours past 99 hours (`4d07`). A
  cut-off chat counts down to its reset (`-1h30`), then up from the
  cut-off; a 529 or a restart, with no reset, counts up at once. A queued
  prompt counts down to its send (`-0h12`), shows `--:--` when its words
  name no time (`after #2`) or the time has passed, and counts up once it
  runs. Every clock moves together, just after each whole second. The
  row's words say what the chat does with no age now: `workflow`, not
  `workflow 12m`.
- **A cut-off chat still open counts from the cut-off.** One with
  background work still out had kept the time that work began, on the
  panel and in the phone board's age.
- **What you typed is off the rows,** on Windows: each showed your newest
  prompt under its title, to anyone who could see your screen. The title
  has that line to itself now, under the project and the state's words;
  a full row is 42 units tall, from 36, to hold its tile. A cut-off
  row's chip - **don't continue** or **continue**, and open - goes on
  the title's line, under the words it is about, as the tile leaves the
  first line no room for it; compact rows keep it left of the words. A
  card with a chat's recent turns when you rest on its row is in
  DEFERRED.md ("A chat's prompt and recent turns on hover"). A row on
  macOS, in `chatoverlay -Print` and on the phone's board looks as it did:
  DEFERRED.md, "Row tiles on macOS, in -Print and on the phone's board".
- **Compact rows** (**Style**, or `chatoverlay -Compact on`) draw a
  smaller tile, with its clock, and the words at the line's end - one line
  a chat. The console's list draws the same tiles, compact, its clocks
  moving as the panel's do.

## 0.10.9 — A chat you stopped stays stopped

- **A turn you stop yourself no longer sends `done` to the phone.** Stop
  or Esc in a chat took it from busy to idle like any finished turn, so
  the phone and the toast said `<chat> · finished` for a turn you had cut
  short - right away with `phoneWhilePresent` on, otherwise once you were
  away. A chat whose last message is your Stop sends nothing now, and the
  overlay's log says why. That is read as the turn ends, so a `/cost`
  typed after the Stop changes nothing; its next turn that finishes
  alerts as before.
- **A VS Code crash no longer offers a chat you had stopped.** The chats a
  window's crash cut off left out one you stopped, but not when a workflow
  it started was still out: Claude Code 2.1.291 lets a workflow run on
  past a Stop, where earlier versions ended it. That chat came back as an
  orange row and the ask, and with `autoContinueCrash` on it was continued
  with no ask - *Continue from where you left off*, the turn you stopped.
  A chat whose last message is your Stop is never offered now. A workflow
  a turn before it started, which you never stopped, is left out too
  (DEFERRED.md).
- **`chatqrun -Stop` mid-run no longer alerts `failed`.** The run it
  ended counted as one that broke: a `failed · cancelled` alert, and for
  an auto-continue a try toward the two that turn it off for the chat.
  It ends as a cancel does now - failed, cancelled, nothing said - as
  `chatqcancel`, the console's and the phone's Stop always did. A chat
  open in VS Code is still shown fresh, with what the run wrote.

## 0.10.8 — The chats a VS Code crash stops, found and named

- **A VS Code window that runs out of memory or crashes no longer loses
  its chats without a word.** Once it was open again nothing said which
  chats had been at work, and they were gone from the overlay's list.
  chatq knew what a window's chats were doing only when it looked right
  before a reload it offered, so a window that went with no warning left
  nothing to find. The Windows overlay now keeps that note itself, for
  every window whose chats work, from what each pass reads anyway: each
  chat at work, by its window's extension host, in `data/host-work/` -
  written when what works there changes and every 10 minutes besides,
  and only while that host runs. Once the window goes, the chats it cut
  off mid-turn come back as orange rows and the ask, as a reload's did.
  **Developer: Reload Window**, **Restart Extensions** and VS Code
  updating itself are found the same way now.
- **Every wording says why the window went:**
  `VS Code ran out of memory`, `VS Code crashed`, or `VS Code restarted`,
  from VS Code's own `main.log` - read, never written. The row
  (`cut off - VS Code ran out of memory`), the ask, its balloon and the
  phone say it, and so does the prompt that continues the chat. VS Code's
  line for a window out of memory names no window and comes a few
  seconds before that window's extension host goes, so chatq waits until
  10 s after it, to see every window that went then - and 5 s more, as
  VS Code writes its log later still when it is short of memory itself.
  So a window's chats wait for the log to be sure - some 15 s for a
  window out of memory, 30 s at most - and the balloon and the phone,
  said once, say it right. A reload is sure as soon as the log has its
  window's exit, a moment after it goes.
- **The chats a crash cut off can be continued by themselves.** The
  tray's new **Continue chats a VS Code crash cut off** - config
  `autoContinueCrash`, off unless you turn it on - sends each its prompt
  at once, with no ask. Only where the log said out of memory or crashed,
  within 10 minutes of the window going, not to a chat you opened in a
  terminal meanwhile - a run beside its `claude` would make two writers -
  and not to one it continued in the last 2 hours: work that brings
  VS Code down again would be sent back into it each time. A reload's,
  and a window you closed, are still asked about.
- **The overlay says when memory runs short,** on Windows. At 95% of
  Windows' commit limit - memory and page file together - its first note
  turns amber with the figures and the programs holding the most, and
  the tray says it once in a balloon, not again within 15 minutes.
  `overlay.memoryWarn` sets the percent; 0 turns it off.
- **What it cannot tell:** a window you close yourself while its chats
  work is offered too, as restarted - chatq cannot tell that close from
  a reload. Two windows that go together may swap causes, and a window
  closed within 10 s after another ran out of memory leaves both as
  restarted: either may be the one that did. Should VS Code write one of
  their exits more than 5 s late, one may read as out of memory - the
  closed one, at worst. A log more than 30 s behind reads as restarted
  too, as does a host that outlives its window's renderer by more than
  10 s - 1.3 to 6 s in the three times seen. A portable VS Code's log is
  not read: its windows read as restarted, after the full 30 s where an
  installed VS Code's logs are there too. A window whose VS Code process
  was ended waits the 30 s as well. A turn begun a few seconds before
  its window went may not be noted, nor a workflow started by a turn
  that ended a few seconds before it. The notes are Windows only, as the
  extension's always were.
- **The overlay cleans up its memory every 5 minutes.** .NET left the
  overlay's garbage for 17 to 21 minutes at a time, and its memory rose
  from about 250 MB to 290 before each clean-up brought it back. The
  overlay now does it itself every 5 minutes after the first, 3 minutes
  in: a pause of about 0.1 s each time, which its log notes.
- **The console no longer keeps the log of every job you look at.** Each
  job picked in its queue kept its read log, up to half a megabyte, for
  as long as the overlay ran. Only the job on show keeps it now; going
  back to one read before reads it again. Closed, the console also lets
  go of its list of jobs and the rows it drew - under 1 MB here - and
  reads them again as it opens.
- **A queued run no longer reads up to 64 MB of its chat before it
  starts.** To check the chat is still there and was not continued
  meanwhile, the watcher also read the chat's permission mode and model,
  looking back up to 64 MB in a long chat - a string of up to 128 MB at
  once, on a PC that may be short of memory. It reads the last turn
  alone now, which is all that check uses.
- **The permission bridge and the ask hook load only what they use.**
  Each loaded all 22 parts a shell does, and the bridge lives as long as
  a queued run, up to 4 hours. The bridge now loads 9 and the hook 15: 87
  and 90 MB where 102 were, ready in 0.25 and 0.3 s rather than 0.4. A
  self-test check walks every command each one reaches, so a part one
  needs is never left out.
- **A question waiting on the phone no longer rereads its chat every 5
  seconds.** The ask hook emptied what it had read before each look,
  so each look read the last megabyte of the chat again - some 5 MB of
  garbage every 5 seconds, for a file that does not change while the
  question is up. A look now reads it again only once it has changed.
- **The phone's whole answer starts where the run did.** It read the
  last 8 MB of a run's log, and a run longer than that lost its start:
  one of 10 MB here sent 52 of its 70 parts. The whole log is read now,
  a piece at a time, and only the lines that make the answer become
  text - the tool output fed back, most of a long run's bytes, is passed
  over. Reading that 10 MB log took 19 MB at its peak, where the 8 MB
  read took 23 and a whole read 57. The console's log view reads the
  same way.
- **A cut-off chat's title no longer loads the whole chat list.** To
  name a chat the limit, a 529 or a VS Code restart cut off, the overlay
  loaded the index of every chat - about 2 MB here, kept for as long as
  it ran. It reads the title from that chat's own transcript now, as the
  index does, once per chat.

## 0.10.7 — A chat only opened keeps its age

- **Opening an old chat no longer makes it read as just used.** Opening
  a chat in VS Code starts a process for it, whose registry entry says
  now, and Claude Code writes a few records to its transcript that carry
  no time. So a chat last used an hour ago read `idle 1m` on the overlay
  and jumped to the top of its idle chats. The same went for the
  picker's ages, the phone's chat list and the overlay's Recent list once
  the chat was closed again. Each now takes when the chat was last at
  work: its transcript's newest timestamped record, which opening it
  never writes. The open chat's own row keeps its busy or waiting time
  from the registry as before.
- **Codex chats too.** The phone's chat list sorted and dated Claude and
  Codex chats by file write time; it now uses the time `chatfind` and the
  pickers already showed, for both. `chatrestore` dated an archived Codex
  chat by its file's write time; it now dates it by its rollout's newest
  record. The overlay lists no open Codex chats, so it had nothing to
  fix there.
- **One reader for each transcript field.** A chat's last time at work,
  its folder and its mode each had copies of their own - six of the
  folder alone - in the index, the overlay, the phone, the queue and the
  cut-off scan, some for Claude and some for Codex. Each is now read once, by `Get-ChatLastStamp`,
  `Get-ChatCwds` and `Get-ChatLastMode` in `src/core.ps1`, for both;
  the extension's picker and its reload check share `lastStamp` in
  `extension/safe-restart.js`. How much of a file each caller reads is
  still its own, since what that costs differs from one to the next.

## 0.10.6 — Two self-test checks that wait out a slow machine

- **Two checks in the self-test no longer fail on a slow machine.**
  Publishing 0.10.5 failed at first: on a slow CI runner, one check
  failed in the 5.1 self-test and another in pwsh 7's, on code that had
  passed three other times. The open-tabs check ends a process standing
  in for a VS Code window and waits for it, yet under 5.1 `Get-Process`
  still found it for a moment, so its tab stayed listed; the check now
  waits until `Get-Process` no longer finds it, 5 s at most. An older
  copy's launch of the phone setup waits for its window to hold a lock,
  and that check wanted the wait over within 500 ms of the lock being
  taken. It now allows 5 s of a 10 s wait: about 60 ms is what it takes,
  and the whole 10 s what a broken wait would. Each check still fails
  with the code it guards broken (TESTING.md, Slow machines).
- **One helper writes a check's Claude Code record.** Five sections each
  had a copy: `ConvertTo-Json`, then 5.1's `\u` escapes of `< > & '`
  undone. `ConvertTo-NodeJson`, in the sandbox section, now does it for
  all five, and the records come out as before. Nothing you see or set
  changes in this release.

## 0.10.5 — A window's buttons on the overlay's bar, idle tabs shown, and an overlay that keeps going

- **The watcher and the overlay no longer hold the folder they were
  started from.** Each inherited the folder of whatever started it - a
  shell, or VS Code - and kept it for as long as it ran: hours after VS
  Code had closed, and on through every watcher or overlay it handed
  over to, while Windows will not delete or rename a folder a process
  is in, or any folder above it. Both now start in your home folder, so
  a relative path in `CHATQ_CLAUDE`, `CHATQ_CODEX`, `CHATQ_GH`,
  `CHATQ_CODE`, `CLAUDE_CONFIG_DIR` or `CODEX_HOME`, in your alert
  command, or typed into the console's folder box is read from there.
  Under Windows PowerShell 5.1, starting either from a folder with `[`
  or `]` in its name could fail, or put it in a look-alike folder beside
  that one; neither happens now.
- **The overlay's buttons work like a window's: minimize, maximize,
  close.** The hide button looked like a download, and the console's was
  a speech bubble. Now the row ends as any window's caption does:
  minimize (a short line) hides the panel to the tray, maximize (a
  square) turns it into the console, and × closes it. Collapse, refresh
  and settings come first, as before.
- **The buttons sit on a bar along the panel's top strip, always there,
  and the bar moves the panel.** They used to float above the panel and
  come only once the pointer rested on it, with a six-dot grip to drag
  it by. Now the bar shows whenever the panel does and takes the mouse
  even while the panel is locked: hold it anywhere off a button and drag.
  The grip is gone, and so is the speech bubble. The rows below still let
  clicks through, but a click on the top strip now lands on the bar, not
  on the window underneath. The panel is a little taller for it, the
  panel's opacity fades the buttons and never the bar, and the settings
  box opens above the panel, or under the bar near the screen's top. A
  first start now puts the panel as far from the screen's top as from
  its right, with no room left above it for buttons.
- **The overlay stretches taller, into Recent.** It looked frozen: an
  edge drag only raised the row count, and with every open chat showing
  nothing grew. Now dragging the top or bottom edge outward first brings
  in the open chats not drawn yet, then adds Recent chats, newest first,
  up to 20 - even with Recent off - and stops there, never taller than
  what it has to show. Dragging back takes Recent off first, then rows.
  The count you let go at is saved as `overlay.recent`, which the
  console's Recent list, `chatoverlay -Print` and the phone board follow
  too; with no chat open, dragging in no longer lowers the saved row
  count.
- **Every open chat shows, idle VS Code tabs too.** A Claude tab a
  window's reload brought back has no process behind it, so the overlay
  listed its chat under Recent as if it were closed. Each VS Code window
  now lists its Claude tabs in `data/open-tabs/`, and the overlay and the
  phone board give each one an idle row of its own. A tab is matched to
  its chat by its label, so an untitled tab, two tabs of one label and a
  label two chats share are still left out.
- **A Claude reset reads one time, not a minute either side.** Claude's
  usage endpoint gives a reset a moment off the minute - 21:59:59.855 on
  one fetch, 22:00:00 on the next - and the clock time cut the first
  down, so the overlay, the phone board, `chatqlist` and the limit check
  showed one reset as 21:59 and 22:00 by turns. Its time is now taken to
  the nearest minute.
- **The overlay takes less of the processor, and no longer stops for a
  moment as a chat finishes or a chip opens one.** Its pointer check,
  eight times a second, now only notes that the pointer is away while it
  is well off the panel, where it worked out the bar's place, the edges
  and the chip each time; on the panel, the rows' places are kept until
  the rows are drawn anew or move. As a chat finished with its
  window in front, the overlay asked WMI for every process to find that
  window, which froze the panel, its bar and the console for 0.2 to
  0.5 s; it now reads Windows' own process list, in about 15 ms. Its C#
  is compiled once as it starts, in 0.25 s where three compiles took
  about half a second, and no longer at the first open from a chip or
  the first chat with a background shell, which froze it 0.15 to 0.25 s
  each. The VS Code windows' open-tab and reload files are parsed again
  only once they change, and their windows looked up once in 10 s rather
  than every 2 s, so a window that crashed without taking its file away
  shows its tabs, or its reload banner, up to 10 s longer.
- **The overlay's panel first shows sooner.** As it starts, the overlay
  looks through every transcript written in the last week for chats cut
  off by the limit. It read the last 256 KB of each and split it all into
  lines; it now reads back from the end, 64 KB first and more only where
  the last turn is further back - 49 ms for 104 transcripts, where it took
  219. As it runs, its log's filter of repeated lines no longer keeps
  every line it ever held back, and with the pointer near the panel each
  pointer check works out the bar's place once, not twice.
- **Three minutes in, the overlay gives back what its start took.** As
  it starts, the overlay reads the end of every transcript of the last
  week, and .NET kept the memory those reads took. It now packs that
  memory once, a pause of about 0.1 s: 22 to 82 MB given back on the
  six starts measured. Its memory grows back as it runs, though, so an
  hour on it holds about what it did: 252 to 284 MB on two runs, where
  one not packed held 300.
- **A busy chat no longer costs the overlay a large block of memory every
  2 s.** Each time a chat's transcript grew, the overlay read it again
  from 64 KB before where it had stopped, in case a line was cut there:
  a 130 KB string for every busy chat on every pass. A block that size
  goes on .NET's heap for large ones, which only a full collection clears
  and which is left full of holes after. It now reads on from the end of
  the last whole line it read: a transcript 2 KB longer is read in 8.7 ms
  where it took 13.9, taking 920 KB where it took 1.2 MB, and 300 such
  reads bring on no full collection where they brought one.
- **A long chat gone idle no longer leaves the overlay some 80 MB
  bigger.** The first time the overlay finds a chat idle, it reads its
  transcript from the start for background shells, 8 MB a pass - and
  each pass's text, a 16 MB string, went on .NET's heap for large ones:
  one overlay's went from 10 MB to 89 and stayed there. It now reads
  40 KB at a time, a line longer than that a piece at a time, and takes
  out only the lines that can start or end a shell. On a 40 MB
  transcript an 8 MB pass takes 34 to 48 ms where it took 46 to 87, and
  19 to 23 MB where it took 27 to 32, and the whole read brings on no
  full collection where it brought one or two.
- **The overlay's log no longer calls nearly every start's Recent list
  slow.** The overlay builds Recent a quarter second at a time, and
  logged any build over 250 ms - so one that spent its quarter second was
  logged as it stopped. A build is now logged only a quarter second past
  its slice, where a folder it asked after held it up, and a whole one -
  `chatoverlay -Print`'s, the phone board's - past 250 ms as before.
- **An error that gets past the overlay's own catch no longer stops it
  for good.** The overlay's passes run on a timer that sets itself going
  again only once its last run returns. With the PC's memory full, an
  error got past the overlay's catch, and the timer never ran again: the
  panel stayed on screen, but its rows stopped changing, no phone alert
  went out, no `chatoverlay` command was taken and new code did not
  restart it - for over an hour, until it was ended by hand. A timer
  stopped that way is now set going again at once, the pointer check's
  too, and the `ui:` line in `overlay.log` still says what went wrong.
- **The C# compiler's files go in `data/tmp`, not `%TEMP%`.** The Windows
  calls chatq makes - the overlay's, the watcher's, the alerts' - are
  compiled where a process first needs them, and the compiler wrote its
  working files under `%TEMP%`, where a process ended by force left a
  folder behind for good. They now go in a folder of their own in
  `data/tmp`, taken away once the compile is done - and one a process
  ended mid-compile left, by a compile a day later - and `TEMP` is put
  back after for whatever starts next. A chatq folder the compiler cannot work
  in - over some 180 characters deep, or named with a letter outside the
  PC's language for non-Unicode programs, an `é` on a Korean Windows -
  keeps them in `%TEMP%` as before.
- **A terminal opens 0.2 to 0.45 s sooner, and holds 10 to 44 MB less.**
  Loading chatq no longer searches every module folder for PSReadLine
  before binding its keys; a PowerShell without PSReadLine is passed over
  as before. And a shell no longer loads the overlay's panel, its console
  and its Mac panel, which only the overlay's own process draws: 8 MB
  less of .NET's heap and 0.1 to 0.2 s less to load - 124 MB where it
  was 168 on a PC with memory to spare, 101 where it was 111 on one
  nearly out. Every other chatq process leaves them out too: the
  watcher, the hooks, the phone's sender, the extension's runs and
  whatever the overlay starts. Only the overlay and the phone setup's
  window load it all. An overlay or terminal from before this update
  starts those two through the new copy, a second load: on a PC short of
  memory, a terminal opened before it may say the overlay did not start
  just before it shows.
- **Less code, the same behaviour.** A review took out about 650 lines of
  copies and steps nothing needed, across the scripts, the extension and
  the checks: one helper each where up to seven places wrote a log line,
  read an on/off switch, retried a lock file, cut text without splitting a
  character or printed a clock time; one reader for the usage Claude Code
  caches; one kit for the page checks and one for the test vectors.
  Nothing you see or set changes, and every check still runs.

## 0.10.4 — Codex catches up: its own sandbox, live usage, and overloads that wait

- **Codex usage, asked live - and a Codex limit check that spends no
  turn while the account is still limited.** The overlay's Codex line was
  only as new as Codex's last turn: days old, on an account used now and
  then. It now asks `codex app-server` (`account/rateLimits/read`, which
  starts no model turn and spends nothing) every 5 minutes while Codex
  works, every 15 while it is idle, once a window resets, and on refresh.
  The line ends in when it asked, not `last run`, and the snapshot
  carries the plan; a free plan's one window is 30 days and reads
  `month`. The rollout figure stays the
  fallback, and the newer of the two wins. With no `codex`, no Codex home
  or a codex older than 0.159.0, the overlay waits half an hour quietly;
  other failures back off 2 to 30 minutes and are logged. `chatoverlay
  -CodexUsage off` turns it off, an ask already out included. `chatqlist`,
  the phone and the alerts use that figure where it is newer, and only
  when it was asked under their own Codex home: the overlay keeps the
  `CODEX_HOME` of the shell that started it. A codex updated in place is
  seen without a restart. Before a Codex job runs, the limit
  check now asks the account first. When a window is still full, or the
  server says a limit is reached, the lane waits without a turn spent,
  and the watcher's log says so. Anything less clear still asks the
  cheap turn: only a turn finds an overload, a refused login, or one
  model's own limit.
- **Codex usage, archive and restore stay on one Codex home.** `chatrm
  -Archive` and `chatrestore` told `codex archive` / `unarchive` to look
  in whatever `$env:CODEX_HOME` said at that moment, while the thread
  itself was listed from the home chatq loaded with; set to another
  account's home since, codex answered "no session found" and the thread
  stayed put. Now archive goes to the home the rollout is under, the
  archive's manifest keeps it, and restore goes back there. `chatqlist`'s
  Codex usage and the overlay's read the home chatq lists Codex chats
  from as well, not the variable as it reads now.
- **A Codex app-server client, for what is to come.** chatq can now start
  `codex app-server` on a given Codex home, ask it a few things, and end
  it - always, a timeout or an error included. Live Codex usage and the
  limit check use it (above); the cut-off scan and the thread list will
  be built on it. Found on the way, on codex-cli 0.159.2: the server exits as
  soon as its input ends and drops any reply still being worked out, so
  chatq keeps its input open until every reply is in; and started on a
  Codex home that is not there, it makes one, so chatq never hands it one.
- **`chatrm -Archive` keeps a Codex thread that is at work.** A Claude
  chat open in a window was already kept; a Codex thread was handed to
  `codex archive` mid-turn, and the rest of the turn wrote into a rollout
  Codex had moved. Now one whose rollout got a record in the last minute
  is kept ("Codex is writing to it"), and so is one whose last
  `task_started` has no `task_complete` or `turn_aborted` yet - a turn
  waiting on an approval writes nothing. A killed codex - a job stopped,
  a window reloaded mid-turn - writes no end, so its turn does not keep
  the thread: on Windows a rollout no codex holds open to write has no
  turn going, a later turn ends it, and a rollout not written for 12 hours
  has none anywhere.
- **Codex chats are scoped by their whole folder.** A title matched Codex
  chats of the folder you stand in by its leaf name only, so in `D:\b\app`
  a Codex chat of `D:\a\app` counted as this project's - `chatq` could
  pick the sibling's chat with no "not in this project" word, and
  `chatfind` and `chatrm` listed it as this project's. The index now keeps each Codex chat's whole `cwd`, and the match
  is on that, however the folder is written. A row from an older index is
  read again once, by the next search, to get it; until then it goes by
  the leaf as before. "not in this project:" names a Codex chat's folder.
- **A Codex job saved with sandbox `managed` runs.** Newer Codex threads
  keep their sandbox as a permission profile, `managed`, and a job that
  read that word passed it on as `-c sandbox_mode=managed` - which codex
  refuses as its config loads ("unknown variant `managed`"), so the job
  failed before a turn. A sandbox word codex does not take now runs as
  `workspace-write`; `chatq` says so as it queues, and `jobs.log` as it
  runs. The app-server's camelCase words (`readOnly`, `dangerFullAccess`)
  are read as the kebab ones.
- **`-Sandbox` picks a Codex chat's sandbox for one job.** `chatq <codex
  chat> -Sandbox read-only` (or `workspace-write`, `danger-full-access`)
  runs that job in it; `chatqrun <n> -Sandbox` requeues one in it. `-Mode`
  on a Codex chat used to print "(given)" and then be ignored: it is
  refused now, and `-Sandbox` on a Claude chat too. A sandbox wider than
  the chat's sticks - the run records it, so later jobs for that chat take
  it as the chat's own - and `chatq` warns. The console has a Sandbox row
  of chips for a Codex chat, under the prompt box and in a waiting job's
  details, in place of the faint "runs in the sandbox it last used" line.
- **The phone's cap goes by the sandbox a Codex job runs in.** A retry, or
  a reply's prompt, of a Codex job given `danger-full-access` itself is
  capped at `workspace-write` as the job's own pick; the chat's sandbox is
  left as it read. The board's queue rows carry what each job runs in, so
  the chat view of a Codex job - which the board has no chat row for -
  says its sandbox, not `at most acceptEdits`.
- **A Codex chat's effort beside its model.** `chatq` shows the model and
  effort the chat last ran at - `gpt-5.6-terra at effort medium (as the
  chat last ran)` - and so do the console's running line and the job's
  history. Shown only: whether `codex exec resume` keeps that effort is
  not known yet, and nothing sends it.
- **The Codex limit check is a cheap turn on the chat's model.** Before a
  Codex job runs, chatq asks codex a throwaway `ok` to see whether the
  limit is over. It named no model unless `-Model` gave one, and no
  effort, so codex took both from `config.toml` - an `xhigh` turn on
  whatever model is set there, not the chat's, each time a lane was
  checked. It now names the chat's own model (or the `-Model`) and runs at
  `model_reasoning_effort=low`. A chat model the account has since lost is
  asked again without one, as Claude's check already did.
- **A Codex overload waits instead of failing the job.** A Codex turn that
  failed on a server error ("exceeded retry limit, last status: 503",
  "unexpected status 502"), "high demand", a model "at capacity" or "Flex
  capacity unavailable" failed the job, where Claude's 529 puts it back in
  the queue. It now goes back too, and its lane waits as Claude's does -
  but with no status page to read, it is simply tried again after 1, 2,
  5, 10, then every 15 minutes; before, a Codex outage would only have
  been looked at every 15. Only what the turn failed with counts: codex's
  stderr carries log noise of its own - a models refresh that timed out,
  an MCP probe's "unexpected status: 500" - that must not turn another
  failure into a retry. A 400, a context window that ran out, a refused
  login and the usage limit are read as before. The alert, the 6 h
  reminder, the job's history, `chatq`, the console's preview and the
  "sends" column say "when Codex is back", never Claude or
  status.claude.com. The wording comes from the codex-cli 0.159.2 binary,
  not from an overload seen in a run; one worded otherwise still fails.
- **One reading of Codex's usage, wherever it is shown.** The overlay's
  Codex row, the `chatqlist` and phone usage line, and the limit check
  each read the `rate_limits` snapshot from Codex's rollouts with a copy
  of their own, and the copies disagreed: when the newest snapshot had no
  window in it, the overlay went on to an older one while the other two
  stopped there - one showed a figure the others did not. The overlay,
  `chatqlist` and the phone now all show the newest snapshot that has a
  window, with its age. The limit check still stops at a newer one with no
  window - a turn under another login or plan logs one so - and blocks
  nothing on it: a full window from before is no longer the account's
  word, and waiting it out held the lane with no check to clear it. Each
  copy matched only compact JSON (`"rate_limits":{`), so a rollout written with spaces would
  have shown no Codex usage at all; spacing no longer matters. And a
  half-written last line - a rollout read while Codex writes it - now falls
  back to the snapshot above it in the same rollout, not to an older one.
- **Which `codex` runs the jobs, and how old it is.** chatq takes `codex`
  (and `claude`) from PATH before the copy the VS Code extension keeps
  current, so a `codex` installed by npm once and left there ran every
  job, however far behind it fell - and nothing said so. `chatinstall`
  now lists each CLI it found with its version, its path, and whether it
  came off PATH, is the extension's copy or was named by `CHATQ_CODEX` /
  `CHATQ_CLAUDE`; `chatproviders` has the same as `Cli`, `CliVersion`
  and `CliFrom`. When the one on PATH is older than the extension's, both
  warn. A `CHATQ_*` override is never second-guessed, and neither is
  Claude Code's own install, whose folder its installer puts on PATH:
  taken off PATH it would still be the one picked.

## 0.10.3 — A reload asked for on the overlay, continues first, and phone replies in the chat's own mode

- **The phone at the PC too: `phoneWhilePresent`.** Phone alerts waited
  until nobody had used the PC for `quietMinutes`, but being at the PC is
  not watching that one chat. `"phoneWhilePresent": true` in
  `config.json` sends them at once: the live chats' needs input and done,
  the reset ask, and chatq's own job alerts. `quietMinutes` 0 could not do
  it - that is never away, so live alerts never went. Reloads still wait
  for you to be really away.
- **Phone alerts end with usage and the chats at work.** Each phone
  alert gets a last line read as it goes: how much of each usage window
  is used and how many chats are busy or waiting on you - `Claude 5h 42%,
  week 18% · 3 working, 1 waiting`. The chats are counted as the overlay
  counts them, its own figures while it runs: a chat whose turn is over
  but whose workflow, background agent or background shell still runs is
  working. A provider at 0% in every window is
  not in use and left out - Claude or Codex alike. The reply page shows
  the same line under the title (the link's `s=`). Not on replies,
  pairing or permission pushes; the toast and `alerts.log` keep the alert
  as it was.
- **A phone reply runs in the chat's own mode.** A prompt, retry or allow
  from the phone was brought down to `acceptEdits` unless
  `reply.maxMode` said otherwise - so a chat in `auto` ran in
  `acceptEdits` from the phone, and lost Ultracode, which needs `auto`.
  The default is now `keep`: the chat's own mode, and a Codex chat's
  sandbox, as at the PC. `chatnotify -ReplyMaxMode <mode>` (new) sets a
  cap as before; `-ReplyMaxMode keep` lifts it. A `reply.maxMode` already
  in `config.json` is kept, read past a hand edit's case and spaces -
  `Keep` is keep, `Plan ` is plan; a word that is no mode caps at
  `acceptEdits`.
- **The collapsed overlay shows only the usage in use.** Its line showed
  Claude's usage always, and never Codex's. It now shows each provider
  with some window above 0% - the alert footer's rule - so a Codex user
  sees Codex, named; Claude alone stays unnamed, as before.
- **Codex usage no longer reads a window long reset.** `chatqlist` and the
  phone's status showed the last Codex rollout's percent even after
  that window reset - `Codex 5h 3%` days later, where the overlay said
  0%. A window whose reset passed now reads 0%, as the overlay has it;
  Claude's cached figure too.
- **A continue no longer waits behind other chats' prompts.** Continue,
  Continue all, the reset ask, the phone's continue, `chatq -Continue`
  and auto-continue queued in turn, so a chat the limit cut off waited
  behind every prompt queued for other chats. A continue only picks up
  work the limit cut off, so the queue now puts continues ahead of the
  prompts waiting, in the order they were queued - Continue all's in its
  list's order - with a job put first still ahead of them. Continue says
  `queued 3 continues ahead of the prompts waiting - one at a time, ...`.
  The watcher still runs one job at a time.
- **`chatq -New <folder>`: a new chat from the shell.** Only the console
  and the phone could queue a prompt for a chat that does not exist yet.
  `chatq -New . 'Release notes' -Prompt '...'` queues one for a new Claude
  chat in that folder - relative to the shell's - named as given, or by
  the prompt's first line. Without `-Prompt` the editor opens, as for any
  chat; `-Paste`, `-Attach`, `-Mode`, `-Model`, `-At`, `-In`, `-First`
  and `-WhatIf` work as well. Its first run makes the chat, and chatq
  says how to reach it: `chatq <first 8 of its id>`, or
  `claude --resume <id>` in a terminal.
- **Now is Next.** The console's **When** choice **Now** read as if it
  sent the word "now"; it is **Next** - the front of the queue - and its
  button says **Send**. Each When chip has a tooltip. A draft kept with
  Now comes back as Next.
- **A reload asked for shows on the overlay too.** A reload VS Code asks
  about after a delete, an archive or a queued run was only a notice,
  which slides into the notification centre in seconds. While one is
  unanswered the overlay now has a banner - *projA needs a reload -
  "Old chat" deleted - the chat list still shows it* - and its chip
  offers **reload** (or **reload anyway**, where the notice's button is
  that), which is the notice's button with the same checks, and
  **later**, which takes it off the overlay and leaves the notice in VS
  Code. The window reads the answer within 2 s. Collapsed, the panel and
  the tray's tooltip count it; `chatoverlay -Print` and the macOS panel
  show it as a line. The window lists its questions in
  `data/reload-pending/`; the overlay answers in `data/reload-answer/`.
- **A delete no longer finds working chats that are not.** Right after a
  delete, the reload notice named every other chat of the window as
  working, though the overlay called them idle. A window reloading - or
  a chat's process starting or ending - writes records with no turn in
  them to each chat it had open, and "written in the last minute" went by
  the file's date. It now goes by the time of the last turn in the
  transcript, before a reload, in the reload's own check and in the
  folder's judgement alike; a chat held only by that is named *(written
  in the last minute)* rather than by its title alone.
- **A chat opened from Session history after its run keeps Ultracode.**
  A queued run into a chat with Ultracode kept it, but when the run ended
  with its live view closed, chatq only asked; picking the chat from
  another tab's **Session history** instead started it without Ultracode
  or its session-only level, since chatq carried them only into an open
  of its own. Now the run's end arms that carry at once, for 30 minutes,
  so the chat takes them however it is opened again - Session history,
  the side bar, or chatq's **Open chat**, which still takes over. A spike
  also settled that the run's own `"ultracode": true` works: a new print
  run writes `ultra_effort_enter`, a resume with it writes nothing new -
  the history already says on - and one without writes the exit.
- **A run's end asks if you are back.** A run into a chat idle in a
  tab opens the chat again by itself when it ends only while nobody is
  at the PC, and asks (**Open chat**) while someone is. Away was judged
  as the run started, so a prompt queued for the night, started with you
  away, took its tab back under your hands in the morning. Now it is
  judged again as the run ends.
- **The overlay's chips take the first click.** A chip that came up
  under a resting pointer took no click until the pointer had moved off
  it, so open and delete always said **click again**. Now a click on it
  in its first 300 ms - one on its way to what is under the panel - is
  the only one it refuses, timed by the mouse's own clock.
- **An open from the overlay no longer pushes the rows down.** Its
  `opening '<title>' - 3s` was a line added above the rows, so every row
  moved down a line as the click landed, and a second click fell on
  another chat. It now says `opening '<title>' in VS Code - 3s` on a line
  at the foot of the panel, under every row, as it says how an open, a
  delete or a reload went; that line's room is kept free, so no row moves
  or is cut as it comes and goes.
- **The started alert says when the chat is still open.** Sometimes a
  run goes in beside a view of the chat that is still open. That can be
  a tab the handover could not close, the side bar, the handover turned
  off, a window with no chatq extension, or a tab whose idle process
  `liveIdle stop` ended. For these runs the `started` alert now ends
  `open in VS Code: do not type in it until done`. When a terminal's
  claude holds the chat, the alert ends `open in a terminal too: do not
  type there until done`. Anything typed into that view starts a second
  agent on the chat, and it works on the same files as the run. If the
  handover closed the tab, there is nowhere left to type, and the alert
  adds nothing.
- **A Cancel during the handover no longer counts a try.** A Cancel
  clicked while the windows are being asked, or while `liveIdle stop`
  ends the chat's process, puts back the job's attempt count and its
  start time from before. The run never went in, so a `chatqrun <n>`
  afterwards says attempt 1, or the earlier go's number. A job like this
  that never started at all, when requeued, looks for its prompt in the
  chat only after the moment it ended. Before, an older turn in the chat
  that opened with the same words could make the requeue send `continue`
  in place of a prompt that was never sent.
- **The 30 s hold after a handover only follows a tab that was closed.**
  A window that closes the chat's tab for a run puts the tab back when
  the run ends. The chat's next run still waits 30 s for that to happen.
  A handover that closed no tab (the tab was in use, or could not be
  told apart) no longer holds the next run 30 s for a put-back that
  never comes. The hold also still applies when the handover fails
  partway after a window has already closed its tab.
- **A wait that changes to a busy chat now says so.** A busy chat is now
  a wait reason of its own, `busy`. A job that goes from waiting on a
  background command, or on you leaving its tab, to waiting on a busy
  chat now writes that change to its history and to jobs.log. A busy
  wait right after queueing, or after a start, writes nothing new, as
  before.
- **A wait reads the same everywhere.** `chatqlist`, the job's history,
  the overlay, the console and the phone now all build a wait's text in
  one place, so they cannot drift apart. A background command started 6
  or more days ago now shows its date (`Sep 24`), not a weekday, which
  made a months-old start look like last week.
- **Two requests inside one of the extension's polls are both acted
  on.** `data/reload-request` and `data/open-request` each held one
  request. Two inside the window's 2-second look (say, a `chatrm` right
  after a queued run, or two clicks of the open chip) lost the first
  without anyone seeing it. Each file now holds the newest request,
  whole as before, plus the few written in the minute before it (at most
  three) under `earlier`. `data/signal.lock` is held while a file is
  written, so two writers never drop each other's requests. A writer
  that cannot get the lock within 3 s writes its request alone. Each
  window acts on every id it has not seen yet, oldest first. It keeps
  the last 16 ids in globalState and also in its own memory, so another
  window's write cannot drop them. A run's request carried under a later
  one still holds back the next run into its chat for 30 s.
  Compatibility: an older extension reads only the newest request, as it
  always did, and a file from an older script reads as its one request.
  The first look after updating from an older extension treats every
  request the file carries, up to the last one that extension took, as
  seen. So a delete or an open it already acted on is not asked or
  opened again after the reload.
- **After a Show it nobody took, the open chip does what Show it does.**
  After a run went in beside a chat's tab, a window offered **Show it**.
  If the answer was **Not now** (or nothing), the tab kept showing the
  chat from before the run. Its process never rereads the transcript, so
  the chip only brought that stale tab forward. Now, while that tab's
  process is still idle in the window, the chip does what Show it does.
  It checks the chat, closes the tab, ends the process if it outlived
  the close, and opens the chat again from disk. Where Show it would ask
  to reload instead (the chat working by then, or its check failing),
  the chip opens as it always did and never asks. The window forgets the
  offer when it reloads, when Show it runs, when a run takes the chat's
  tab, when a newer run's request for the chat comes in, or when the
  chip finds no process holding the chat or one working in it. That
  run's notice may still sit in the notification centre. Once the chip
  has acted, clicking the notice's **Show it** does nothing more, so the
  fresh tab is not closed and reopened again. Where windows cannot be
  told apart, as on a Mac, the chip opens as it always did.
- **The stale warning for a run beside a tab now comes once per run, not
  once per job.** Before, a job that ran beside the chat's tab, went
  back into the queue at the limit and then ran beside it again got no
  second warning in that window. The warning is now keyed to the run:
  its handover's id, or the 'running' write's own id when there was no
  handover. Later writes of the same run still say nothing more.
- **The live view's pinned todo stays up past the 5000 kept rows.** The
  parser now keeps the last TodoWrite's list apart from the rows.
  Before, once its row was dropped nothing was pinned until the next
  TodoWrite came.
- **A live view VS Code keeps but never shows again no longer holds the
  chat for two days.** Take a watch tab sitting behind others after a
  window reload. It now holds the chat's put-back for 10 minutes at
  most. The 10 minutes count from the first look after a window's start
  that finds the run ended, and they start over if the job runs again
  before the tab comes back. Once they run out, the chat is put back as
  for a closed view: opened where its tab was if nobody is at the PC,
  otherwise asked. If the tab is shown later, it says how the run ended,
  with **Open chat**.
- **Show it no longer ends a tab that Claude Code reopened by itself
  just after an extension-host restart.** From 2.1.284, Claude Code
  reopens the tabs it lost after **Developer: Restart Extension Host**
  or **Restart Extensions**. Most come back within 5 to 10 seconds, and
  such a tab looks just like the new tab Show it opens. For 30 seconds
  after a restart, a new tab now gets a second check that only judges
  and ends nothing. The notice then says to close the side bar's copy if
  there is one. Restart and reload are told apart the way Claude Code
  tells them: each activation saves `vscode.env.sessionId` in the
  workspace state, and the same id at the next activation means a
  restart. A lost tab Claude Code reopens later is still not caught: one
  behind others comes back only when you select it, and one whose chat
  is busy elsewhere is retried about once a minute. That gap is recorded
  in FUTURE_WORK.md.
- **Open chat... knows which window holds a chat, on Windows.** The
  picker reads each live chat's process once, in one Windows PowerShell
  call. A registry entry whose pid another process has taken since no
  longer counts as live, so that chat shows no state and opens from
  disk. A VS Code panel's parent process says whether the chat is in
  this window or another, and the list says `in this window` or `in
  another window`. The list first appears from the registry alone, then
  updates when that check comes back. A chat working in another window
  is now handed to that window, which brings its tab forward, instead of
  being refused. One open and idle there asks **Show it there** first,
  beside **Open here too**. If the chat moved meanwhile, say to this
  window's side bar, Show it there does nothing and says so, because a
  second copy was not asked for. If it was closed meanwhile, it opens
  here from disk, the only place left to show it. Off Windows nothing is
  looked at, and the picker works as before.
- **The picker finds a title written near a large chat's start.** Where
  the last 256 KB of a transcript hold no rename or Claude title, the
  first 256 KB are read too, as `chatfind`'s index does. A long chat
  renamed early no longer shows its first prompt.
- **The queue in the status bar.** `chatq 3 queued · 16:05` shows how
  many prompts wait and when the next one sends, by the board's rules:
  `next`, `after #15` while a run goes, a time, `when Claude is back`
  during an overload, or `watcher stopped` when nothing would send. A
  job put off because you are in its tab, or because a background
  command runs, has no send time. Its stored time is only the watcher's
  next check, so like the board the item reads `waits for you to leave
  its tab` or `waits for a background command`, and any real send time
  comes first. A click, or **Chat Manager: Show the queue**, opens the
  board. The item is hidden when nothing is queued, and it rereads a job
  file only when that file changed.
- **Ultracode goes with a queued run where a Workflow rule allows it.**
  A run into a chat that had Ultracode used to carry it only in auto or
  bypassPermissions mode. In any other mode Claude Code asks before each
  Workflow, and nobody can answer a run. Now a `Workflow` (or
  `Workflow(*)`) allow rule carries it in any mode but plan. chatq reads
  the rule from the settings the run loads: the user's `settings.json`
  in the job's config dir, the project's `.claude/settings.json` and
  `.claude/settings.local.json`. `watcher.log` names the file that
  allowed it. A deny or an ask rule for Workflow holds Ultracode back in
  every mode, and the history names the file: `Ultracode left off (the
  project settings deny Workflow)`. Plan mode holds it back even with an
  allow rule, because a plan run is meant to change nothing and a
  workflow's agents would: `Ultracode left off (plan mode changes
  nothing, and a workflow's agents would)`. A `CLAUDE_CODE_EFFORT_LEVEL`
  in the `env` of the user's or the project's settings now counts as
  set, like one in the watcher's environment, so no `--effort` goes with
  the run.
- **A queued run's Ultracode and level are what it took, not what it
  asked for.** Claude Code refuses neither. It drops Ultracode without a
  word, and it lowers a level the model or an org cap does not allow. So
  the history, the console and the live view said only what the run was
  started with. As a run ends, chatq now reads the run's own records. An
  `ultra_effort_exit` it wrote means Ultracode was not taken, and the
  effort on its first turn is the level it ran at. chatq updates the job
  to match, and its end in the history says `Ultracode not taken` or
  `ran at effort high, not max`. An Ultracode that is on but idle
  (workflows off, or a model below xhigh) may still read as taken. That
  is not yet checked.
- **Auto-continue after a 529.** With auto-continue on, a chat cut off
  by `529 Overloaded` used to stay `529 - waits for Claude` with nothing
  queued. It now gets "Continue from where you left off." too. It goes
  through the same checks as a limit, with the 529's own time in place
  of the reset: one first seen over 30 minutes after the 529 is left to
  you. A 529 has no reset to wait for. The watcher waits as it does for
  a 529 on one of its own jobs, with no alert, and sends the continue
  when status.claude.com says Claude Code is operational, or 15 minutes
  after the 529. While it waits, every other Claude prompt on that
  account waits too, as in any outage the watcher sees. That wait starts
  only while the chat still stands where the 529 left it, and it ends as
  soon as that stops being true. A chat you retried in the panel, or a
  continue you removed with Don't continue, holds nothing up. A chat
  open in VS Code is never sent one within 5 minutes of the 529. The row
  reads `#12 auto · 529`, and Don't continue skips it for this 529 only.
  With the switch off or on Ask, a 529 is handled as before: the reset
  ask is for the limit only.
- **A close by hand keeps the overlay closed.** The panel's ×, the
  tray's **Quit** and `chatoverlay -Stop` closed it only until the next
  shell or VS Code window started it again a moment later; `-AutoStart
  off` was the one lasting off. Now a close by hand is kept in
  `data/overlay-state.json` against this Windows sign-in (when its
  `sihost.exe` started), and the auto start leaves the overlay closed
  until you next sign in. A balloon says so as it goes: `Closed until
  you next sign in. Type chatoverlay to bring it back sooner.` For the 4
  s the balloon shows, `chatoverlay`, the hotkey, a click on the tray
  icon or the console takes the close back and the panel stays. An
  update's restart in those 4 s only ends it, and the close is kept.
  After that, `chatoverlay`, `chatconsole` or `chatoverlay -AutoStart
  on` lift it, and so does `chatuninstall`, so a reinstall in the same
  sign-in starts it again. Where the sign-in cannot be read, and on
  macOS, the close works as before. An update's restart is not a close.
- **The overlay keeps up with its own code.** It loaded the script once,
  so a `git pull` in a checkout or files copied in by hand left the old
  code running for days, and `chatnotify` could only say `the overlay
  runs an older copy`. The overlay now notes each file's write time and
  size as it starts and looks again once a minute. When something
  changed and has stood still for 5 s, it restarts on the new code the
  way `chatinstall` restarts it. It waits while the console shows, the
  settings box is open, a slider or a drag has not come to rest, an open
  is under way, a close is on its way, or a full screen holds it off.
  The macOS host does the same. The "older copy" status line is gone.
- **The overlay steps aside for a full screen.** While a full-screen
  app, a game or a presentation has the screen (Windows'
  `SHQueryUserNotificationState`, the same check Windows uses to hold
  back its own notifications), the panel hides and comes back once that
  ends. Nothing is saved. The tray's **Show**, the hotkey or
  `chatoverlay` bring it back during one.
- **A panel at the screen's foot keeps one unit clear, not five.**
  Dragged by its top edge, a panel at the foot of the screen stopped
  five units above it. The room kept for the `+N more` line was a guess
  of 18 units, and it is now that line's measured height.
- **Recent changes at once.** Picking Recent off, 5 or 10 in the
  settings box now runs a pass straight away. Before, the list changed
  on the next pass, up to two seconds later.
- **A waiting job's mode and model change in the console.** Before, only
  a queued prompt's text could be edited in place. To change anything
  else you had to Remove the job and send it again. A waiting Claude
  job's details now show **Mode** and **Model** chips, the same ones as
  under the prompt box. A click changes them for that job before it
  sends, the first chip gives back the chat's own, and the status line
  says what changed. A job the watcher started meanwhile, or one
  removed, is refused rather than put back in the queue.
- **Open in VS Code from the console.** A waiting or ended Claude job
  whose chat has a transcript gets **Open in VS Code** in its details.
  It opens the chat in its window, as the overlay's open chip does.
- **Every argument to npm's `claude.cmd` is quoted for cmd.exe.** A
  `.cmd` or `.bat` runs through cmd.exe, which acts on `& | < > ^ ( )`.
  Only a new chat's title was cleaned for it. Now every argument holding
  one of those is quoted for a `.cmd`/`.bat`, so a folder or file name
  with `&` or brackets reaches Claude whole. A lone `%`, as in a folder
  named `100%`, still goes.
- **What cmd.exe cannot carry is refused, not run.** cmd.exe cannot be
  handed a `"` or a `%name%` at all. Before, one could end the argument
  early and hand the rest of the line, an `&` and all, to cmd as a
  command of its own. Now a `-Model` holding a space, quote or `%` is
  refused when you queue it, in `chatq` and in the console's chips. A
  job that would still pass one is failed with the reason instead of
  started with a broken command line. That covers a job queued with such
  a model before this version, a job file edited by hand, or a data
  folder or attached image whose path holds a `"` or a `%name%`. The
  watcher fails only that job. The jobs behind it run, with no lane
  blocked and no "can't reach claude" alert.
- **The console maximizes again.** As the panel's mode it had no
  maximize. **Maximize** beside **← Panel**, or a double-click on the
  header, fills the screen's working area with the taskbar left clear.
  **Restore**, or another double-click, gives back the size it had, even
  after Windows' own Win+Up. A maximized console does not move when you
  drag its header. A console left maximized opens maximized, and
  `console-state.json` keeps `max` again.
- **The console's size holds across monitor scales.** Its size was kept
  in screen pixels, so a console sized on a 150% monitor held half as
  much again on a 100% one. `w` and `h` are now kept in WPF's units
  (`units: true`) and turned into the panel's screen's pixels as it
  opens. An older file's pixels are read as they are until the next
  save.
- **A stale reset-ask answer in the console says so.** An answer that
  came after the cut-off chats changed did nothing and said nothing
  while the console showed. The console now redraws the list and its
  status line says `the chats changed - here they are now`, still
  without going back to the panel.
- **The board's chat view says the chat's own mode.** It used to say `at
  most acceptEdits` for every chat. Now it says the mode the chat runs
  in, as Older chats does. With a cap set (`reply.maxMode`) and the
  mode above it, it says the cap - `acceptEdits (phone's limit)`. An
  open chat's mode is read along with its title and newest prompt. That
  first read now goes past a long turn's tool output to find the mode,
  so a chat already deep in a turn when the overlay starts still shows
  it. A cut-off or Recent chat's mode comes from its transcript.
  `at most <cap>` is left only for a chat whose mode the PC could not
  read, or a Codex job, which has no row on the board, and only under a
  cap; with none, the default, those say `the chat's own mode`.
- **The board's cut-off rows say what auto-continue will do.** The phone
  showed `cut off` where the overlay showed `#12 auto 13:01`. A cut-off
  row now has the overlay's short words. The chat view shows them in
  full: `cut off - resets 13:00 · auto-continue queues it`. This holds
  whether or not the overlay is running, because the board's own scan
  works out the same states.
- **A board from a scan shows a job at once.** With no overlay running,
  a board was sent again unchanged for 40 s. So a job that started or
  ended on its own could show up to 40 s late. The scan of the chats is
  still kept 40 s, because it is the slow part. The queue and each row's
  jobs are now read again on every ask.
- **The continue chip in every auto-continue mode.** With auto-continue
  set to ask or off, a cut-off row had no **continue** chip. It now has
  one in every mode, and its words stay the plain `cut off - resets
  13:00`. The exception is a chat that a terminal's `claude` holds.
  Claude Code's own wait continues it there, so a second continue would
  mean two writers on one chat.
- **One job maker for a reply and the board.** An alert reply's prompt
  now makes its job the same way the board's Send does
  (`New-ChatqPhoneJob`). The steps are the same as before: text check,
  cap, Codex sandbox, and the chat's own mode once it was typed into at
  the PC. They now live in one place, so a fix to one reaches both.
- **A job you answered in the chat stops saying it needs you, overlay or
  not.** Only the overlay's pass skipped a job waiting on input once its
  chat was typed into after it stopped. With the overlay off,
  `chatqlist` and the phone's **Status** kept listing the job as `needs
  you` until `chatqrm`. Both now skip it, `answered in the chat`, before
  they list. They read a transcript's tail only for a job whose chat
  moved after it stopped.
- **The phone sees a Codex chat that went on at the PC.** A **Send** or
  **Retry** from an old alert or board checked only a Codex chat's job,
  so it could still go into a thread typed on in the Codex panel since.
  The rollout is now read the way a Claude transcript is: a prompt typed
  after the alert refuses the act, and a job waiting on input is closed
  as answered. Codex's AGENTS.md preamble, its environment block and a
  compaction's copies of old messages don't count. Codex does not record
  who typed a prompt, so one sent while a job of the phone's ran counts
  as that job's own.
- **Replies through your own command: `chatnotify -CommandLinks on`.**
  With neither Join nor ntfy over https there was no way to carry a
  reply link, so a phone could not be paired. `-CommandLinks on` (or
  **Give it the reply link too** in the setup window) gives your command
  the link as `$env:CHATQ_LINK` and makes it a phone channel. It runs
  where Join and ntfy would go, past the same gates. At the PC it still
  runs, with no link. The pairing push can go through it. Off by
  default: the link is a key to the reply page, and chatq cannot tell
  where your command sends it.
- **A pairing confirmed while the setup window saves keeps its key.**
  Every writer read `config.json`, changed its part and saved the whole
  file, with no lock. A Save landing in the same instant as a pairing
  confirm could put back the copy with no key, and the phone was not
  paired after all. Now `data/config.lock` is held around every
  read-change-save: chatnotify and the setup window, the pairing, the
  overlay's settings, the ask and auto-continue switches. Each one reads
  the file again under the lock. A confirm whose pairing was replaced
  meanwhile says so and saves nothing. If the lock is held for more than
  3 s, chatnotify saves nothing and says `config.json is busy`.
- **A phone-made chat with no name no longer carries its prompt in
  alerts.** Every alert about such a chat (started, done, needs input,
  and the live alerts once you run it at the PC) carried its title
  through the push service, and that title was the prompt's first line.
  It now goes by `phone chat 14:02` until Claude titles the chat, then
  by Claude's title. The neutral title is kept in
  `data/held-titles.json`, so it holds after `chatqrm -Finished` or the
  console's Remove takes the chat's jobs.
- **A `claude -p` is told by its entrypoint too.** Claude Code 2.1.283
  registers a `claude -p` as `interactive`, just like a chat you type
  in. Only its `sdk-cli` entrypoint gives it away, so chatq could not
  tell someone's own `claude -p` from a window's chat. Show it, the open
  chip, the busy check, a reload's wait, the list repair, the phone's
  live alerts and the watcher's check for a window that opened the chat
  during a run now treat an `sdk-*` entry as the print-mode run it is,
  whether a queued prompt or your own script. Show it no longer ends a
  window's process while such a run is going into the chat. Workflows
  that run left behind are no longer read as dead while it goes on. The
  phone no longer sends a *done* or *needs input* for a queued run as if
  it were a chat you typed in. A run is no longer marked stale because
  your own `claude -p` went into the chat while it ran.
- **The open chip keeps the dot on a chat it cannot open in a tab.**
  Claude Code never lists a chat whose transcript starts as an SDK's,
  which is every chat **+ New chat** made. Its window offers to open it
  in a terminal instead, and the unread dot used to go even when you
  dismissed that offer. The chip still asks the window, but now exits
  `21`, which the overlay does not count as shown. The dot stays until
  you read the chat, and the tray says the window offers a terminal.
  When that window was not brought forward either, the chip exits `26`
  (other folders open), `42` (no `code` command) or `43` (`code`
  failed). The tray then gives both reasons as a warning, and `43` still
  points at `watcher.log`. Otherwise you would look for the offer in a
  window that may still be behind others.
- **A reload waits on a `claude -p` into a chat whose process chatq
  ended.** Show it and `liveIdle: stop` end a window's idle process, and
  a queued run's handover closes its tab. The side bar may still show
  that chat afterwards, and reloading it would load a run part way
  through. chatq now records in `data/idle-ended.json` which window each
  process was ended in, or left with its tab. That window's reload waits
  while any `claude -p` goes into one of those chats, chatq's or not. A
  note lasts while its window lives and at most seven days. Two writers
  at once take turns under `data/idle-ended.lock`, so neither note is
  lost. A window's own processes are looked up by pid, not by listing
  every process, so Show it does not wait longer before the window
  reopens the chat. Only chatq's own runs counted before. Counting every
  `claude -p` anywhere would have held every reload.
- **Screenshots pasted into a cancelled prompt are cleaned up.** VS Code
  saves a pasted image in `data/queue/` straight away, so cancelling the
  prompt tab left the image there for good. The watcher now **deletes**
  files there that no prompt links to once they are a day old, and says
  how many in `watcher.log`. It runs when the watcher starts and every
  six hours after. It never removes anything sooner, because another
  shell's open tab may be taking a screenshot at that moment. Job
  folders, the queue's own files and anything a prompt links to are
  always kept. If any prompt cannot be read, nothing is removed.
- **A reload no longer leaves its cut-off chats unnoticed (Windows).** A
  VS Code window that reloads while its chats work ends their `claude`
  processes. That can leave an answer half written, a permission prompt
  gone, or a workflow's agents dead, and nobody was told. Now every look
  chatq runs before a reload leaves a note of the chats at work in
  `data/host-work/<host pid>.json`: the update notice and its **Reload
  now**, a reload after **Later**, and **Reload anyway**. Within a
  minute of the reload the overlay asks about what was cut off, as it
  does when the limit is over: `VS Code restarted · 2 chats it cut off
  can continue`. The ask appears in the same banner, tray balloon,
  console header and phone alert. When there are both kinds it reads
  `limit over at 13:00, and VS Code restarted`. A chat is offered when
  its last message still owed an answer, or when a workflow or
  background agent it started never reported back. It is not offered if
  it finished, is working again, was written to since, or was held by
  another window. A chat whose process from before the reload still runs
  is kept and offered once that process is gone. The offer needs the
  overlay running with `autoContinue` not `off`; with `off` the chats
  show only as orange rows. Finding them needs each extension host's
  process chain, which only Windows gives.
- **Continuing a chat a restart cut off says what was lost.**
  **Continue** queues a prompt in the chat's own mode, ahead of the
  prompts waiting. The prompt says the window restarted mid-turn and
  names any workflow or agent that did not finish, since `claude
  --resume` does not bring background work back. It then adds Claude
  Code's own *Continue from where you left off*. The prompt is dropped
  if the chat went on first. **Leave them** drops a restart's chat for
  good, where a limit's chat keeps its orange row, and the chips'
  tooltips say which. Auto-continue never continues these chats by
  itself, even when switched on, because a reload may have stopped
  something you meant to stop. A reload with no chatq look before it is
  not found: Developer: Reload Window, Restart Extensions, or another
  extension's update.

## 0.10.2 — Charlie and the Chat Factory, in the tray, and a reopened tab keeps Ultracode

- **A new name: Charlie and the Chat Factory - Claude Code & Codex**,
  was Chat Manager for Claude Code & Codex, after the Charlie on the
  icon. The notices, the settings section and the log's output channel
  carry it; the commands keep their **Chat Manager:** names and the
  settings their `chatManager.*` keys. Every other name follows: the ID
  `redaechan.charlie-and-the-chat-factory`,
  `Charlie-and-the-chat-factory.ps1` in
  `~/Tools/Charlie-and-the-chat-factory`, the repo
  github.com/phal40lax78/Charlie-and-the-chat-factory, and the phone's
  reply page at phal40lax78.github.io/Charlie-and-the-chat-factory. A
  new ID is a new Marketplace extension, so
  `redaechan.claude-codex-chat-manager` never updates to it: install this
  one and uninstall that - both installed would act on every request
  twice. A profile line naming the old loader is still recognised, and
  `chatinstall` replaces it. The reply page's site is the same, so the
  phone stays paired; bookmark it again, as GitHub Pages does not
  redirect a renamed repo.
- **Charlie in the Windows tray, and the tray says her name.** The tray
  icon was a plain coloured dot; it is now the extension's icon, with
  that dot at her bottom right in the most urgent chat's colour, drawn
  at the size Windows shows small icons at the screen's scale. The
  console and the phone alerts window carry her on their taskbar button
  and in Alt+Tab. What was still called chatq there is Charlie now: the
  tooltip (`Charlie: 2 new, 2 working`), the balloons (`Charlie - limit
  over at 13:00`), and the windows (`Charlie - console`, `Charlie - phone
  alerts`). The tooltip now runs to the 127 characters Windows keeps,
  not the 63 .NET Framework allowed, so the longer name leaves 5h's reset
  whole. The commands keep their names, and so do the phone alerts'
  titles (`chatq · done`), which a Tasker profile may match. The icon
  ships inside `src/icon.ps1`, a new part `docs/make-icon.py` writes,
  since every install copies `src/*.ps1` and nothing else.
- **The icon is transparent inside, and closer.** Charlie is cut out of
  her dark purple background and outlined in the dark rounded frame's own
  stroke, as a sticker is, on whatever colour the theme has, the edge
  redrawn as a smooth curve rather than the cutout's bumps, its bangs'
  spikes and the shoulder's notch kept sharp; her head
  fills two thirds of the icon's width, which reads at the Extensions
  view's size. `docs/cut-icon.py` cuts her out and `docs/make-icon.py`,
  which replaces `docs/make-icon.ps1`, frames and outlines her; both need
  Python with OpenCV.
- **A tab chatq opens again keeps Ultracode and its effort level.** Show
  it, the chat put back after a queued run and the live view's **Open
  chat** close a chat's tab and open it again, which starts a new claude
  process - without Ultracode or a level set for the session only, so its
  input box held `/effort ultracode` or `/effort max` to send. chatq now
  hands both to that process as it starts: the tab comes up with them on,
  the effort chip showing so, nothing in its input box and no notice;
  the log says `carried`. Only what the process being replaced had counts:
  Ultracode switched on two days ago, in a process a VS Code restart or a
  Claude Code update ended since, is not brought back - chatq notes when
  each chat's process started and reads the chat's history no further
  back than that. Where they did not go in within a minute - a
  tab only revealed, not started again, or a Claude Code that starts
  claude another way - the notice then names what to type. A remote
  window (WSL, SSH), where claude starts on the other machine, keeps the
  pre-fill at once, as before. `chatManager.keepSessionSettings: false`
  (on by default) turns it off, back to the pre-fill. **Why:** a chat
  refreshed by chatq should be the chat you left, not one to set up
  again.

## 0.10.1 — Remove in the console, and the overlay's chips, say what they do

- **Remove in the console works, and says what it did.** Its first click
  turned the button into **Remove - sure?** for good, while only a second
  click 0.4-5 s later removed: one after longer - back from VS Code, say -
  asked again under the same label, and the second half of a double-click
  was dropped, both with nothing said. "Sure?" now lasts 5 s, in red, and
  goes back to **Remove** after, saying so; each click says what it did in
  the status line; the clicks are timed by the mouse's own times, not by
  when a busy window got to them. A removed job now stays removed: the
  watcher, checking it at that moment, wrote it back - queued, or failed -
  and a continue could still be sent. `Remove-ChatqJob` goes by the job's
  file, not the caller's copy, and says when it could not remove it;
  `chatqrm` and **Don't continue** say so too.
- **The overlay's delete and open chips say what they do.** A delete
  that asked and then deleted, or kept the chat, said so only in a tray
  balloon, which Focus Assist hides: the panel's line says it now, as it
  does for an open, and the second half of a double-click is no answer.
- **The open chip says what it is doing.** A line on the panel says
  `opening '<title>' - 3s` from the click, then `opened` or why not - every
  exit code, a crash and no answer in 60 s among them, which said nothing
  before - and the chip counts the seconds. A click the chip was not armed
  for - one that came up under a resting pointer, as it does right after
  a delete - says **click again** rather than nothing. The open no longer
  waits on `claude agents` to start: it reads Claude's session registry,
  as the panel and **Show it** do.

## 0.10.0 — a new name, queued runs you can watch, and Claude's questions on the phone

- **A new name: Chat Manager for Claude Code & Codex**, was VS Code Chat
  Manager, with a shorter Marketplace description, and a new ID:
  `redaechan.claude-codex-chat-manager`. It is a new Marketplace
  extension, so the old `redaechan.vs-code-chat-manager` never updates to
  it: install the new one and uninstall the old - both installed would
  act on every request twice. The notices, the settings section and the
  log's output channel carry the new name; the settings keep their
  `chatManager.*` keys. **Why:** search weights the name most, and "VS
  Code" matched every extension while "Claude" and "Codex" were missing.
- **The script, the folder and the repo renamed too:**
  `claude-codex-chat-manager.ps1` in `~/Tools/claude-codex-chat-manager`,
  from github.com/phal40lax78/claude-codex-chat-manager, and the phone's
  reply page at phal40lax78.github.io/claude-codex-chat-manager. A
  profile line naming the old `VS-code-chat-manager.ps1` is still
  recognised, and `chatinstall` replaces it. Bookmark the reply page
  again: GitHub Pages does not redirect a renamed repo.
- **Delete a chat from the overlay.** The row's chip has **delete**
  beside **open**. The first click turns it to **sure?** for 4 seconds; a
  second deletes the chat and its leftovers as `chatrm` does, and the
  window offers its reload. On a chat at work, waiting on you, or run by a
  terminal `claude` it is greyed rather than gone, so the chip does not
  change width as the chat's state does. A chat held by a queued prompt is
  kept, and the tray says why. There is no undo; `chatrm -Archive` still
  puts a chat away instead.
- **Resize the overlay by its edges, as any window.** With the buttons up,
  drag a side of the panel for its width, its top or bottom for its rows -
  a row for each row's height of travel - or a corner for both; the side
  across from the one dragged stays where it is. The pointer turns to that
  edge's arrows, and a blue line marks the side it sizes. The top grows
  the panel upward over its bottom, and by the screen's foot brings back
  the rows the foot had cut. Collapsed, the sides and corners size the
  width alone. Resting just outside the panel's edge brings the buttons
  and edges too. The width slider and `chatoverlay -Width` still hold the
  right edge.
- **The resize handle is gone** from the row of buttons, seven now. It was
  one spot to hold at the panel's top-right corner, and which way it sized
  was not what it looked like: left widened, down added rows.
- **A reply from the phone acts only on what the phone was shown.** An
  alert, and a board's handle, keep the chat and the job as they showed
  them. **Send**, **Continue**, **Retry** and **Allow edits & continue**
  do nothing when the chat took a prompt since - at the PC, or another
  job's - and those and **Skip** and **Stop** do nothing when the job was
  queued, run or stopped again since; the watcher's own requeue after a
  limit or a dropped network does not count, nor do the phone's own
  prompts or a background task's notice. Only what was written to the
  transcript after the alert is read, so a long turn or a compaction after
  a prompt at the PC hides nothing. An alert's push says so,
  `Radar viewer moved on at the PC since that alert`, with a link about the
  chat as it is now; the board says `the list is out of date`, goes back to
  a board asked for afresh, and keeps the text. A `needs input` job
  whose chat was answered at the PC is closed as the overlay closes one,
  with no overlay running too. **Why:** a text written for the old turn
  answered a newer question it was never meant for; an old **Allow** raised
  the mode for a stop nobody had seen; an old **Stop** ended a later run.
- **A job's own mode no longer outranks the chat's.** A phone **Send**
  after a job runs in that job's mode only while nothing went into the chat
  after it; then in the chat's own mode as the PC left it, when lower -
  `runs in plan, the chat's own at the PC`.
- **Half an hour for a reply to arrive.** A reply the phone sealed more than
  30 minutes before the PC reads it - 10 for **Status** and a whole answer
  asked again - is refused as too old, as the board's changes already were;
  it was `reply.hours` and 10 minutes. **Why:** replies left on ntfy.sh
  while the watcher was down ran when it came back, hours after the chat
  went on at the PC.
- **A usage limit's reset no longer restarts every chat's timer.** The
  overlay's and the phone's `working 40m` read `working 0m` on every chat
  at once when the 5-hour limit reset. Claude Code rewrites each chat's
  registry file then and stamps its status time anew, status changed or
  not; a chat still in the same status now keeps the time it entered it.
- **Work sent to the background shows on the overlay.** A chat whose turn
  started a workflow, a background agent or a background command stays a
  green row until the work ends, and says what runs and for how long:
  `workflow 12m`, `2 agents 3m`, `shell 5m`. The phone's board lists it
  under Working. It was `idle` - in every folder, not only another repo's -
  since Claude calls the chat idle the moment that turn ends. A command
  counts while one of Claude's own shells runs under the chat's process, so
  one stopped from the task list goes idle at once, and a dev server reads
  `shell` for as long as it runs.
- **A killed workflow no longer holds a reload for good.** An interrupt of
  the turn that started a workflow kills it without a `<task-notification>`,
  and `TaskStop` ends a task without one, so the check before a reload - and
  the wait before an update loads - took the work for still running until
  the chat's process ended. The workflow's run record now ends it, as does
  a `TaskStop`, and an agent whose own transcript finished its turn: eleven
  agent runs here finished unannounced.
- **A queued run takes the chat's tab's place, and you can watch it.** A
  run into a chat open idle in a VS Code tab now asks that window first
  (`data/run-state`, answered in `data/run-ack/`): the window opens the
  run's live view in the tab's group and closes the chat's tab, and Claude
  Code ends that process itself - nothing is killed. As the run ends,
  whatever the outcome, the view turns back into the chat's tab, loaded
  from disk - at once while the view is in front or you are away, else
  with **Open chat**. The tab in front of you is never taken: the job
  waits, `waits for you to leave its tab`, looking again after 1, 2, then
  5 minutes, with **Hand over now** for that one job. A tab that cannot
  be told apart is left, the view opens beside it, and the window says the
  old view is stale until the run ends. A Cancel during the handover ends
  the job there, and the next run into the chat waits 30 s while the
  window puts it back. `chatManager.watchRuns` (on) and `"handover"` in
  `data/config.json` (on) turn it off. **Why:** Claude
  Code has no way to send a prompt into an open tab, so the run went in
  beside it, hidden - nothing showed a job going, and a message typed in
  the stale tab forked the chat.
- **The live view.** An editor tab, `▶ #15 <title>`, that follows the
  run's log as it is written: the prompt, Claude's text, each tool with
  its argument and a running clock, results cut to 3 lines, subagents
  indented, edits as `+2 -1`, errors coloured, the todo being done pinned
  (`Now: run the tests (3/7)`), a permission waiting on the phone, and the
  end. **Cancel** (asked first), **Log**, **Open chat** once it ends. It
  takes the theme, survives a window reload, and keeps the last 5000 rows.
  It opens from the handover, a status bar item in windows on the job's
  folder (`chatq #15 running`), **Chat Manager: Watch the running queued
  prompt**, the overlay's chip (which reads **watch** on that row), the
  console's **Watch in VS Code**, and **Open chat...** on that chat - all
  of which refused a running chat before.
- **Show it closes the tab before it ends anything.** The check now only
  judges; the chat's own tab is brought forward by its id and closed, and
  a process that outlives the close by 8 seconds is ended then - only this
  window's, started before the click. A tab it cannot be sure of is left
  with its process, and a run's end no longer ends a process at all, away
  or not. **Why:** Show it ended the idle process first, and the Claude
  extension let go of the tab as the process died; the reopen made a
  second tab and left the old one reading *Claude Code process exited
  with code 1* (seen 2026-09-28, twice).
- **A queued run's background work survives.** Claude runs get
  `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` - commands run in the turn -
  with the Bash tool's timeouts at an hour (`BASH_MAX_TIMEOUT_MS`) and 30
  minutes (`BASH_DEFAULT_TIMEOUT_MS`), and print mode's wait for a
  workflow or agent at an hour (`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`),
  each only where the environment does not set it already. A run stopped
  at the 4-hour deadline after a turn that ended well counts as done, with
  a note. **Why:** `claude -p` kills a background shell 5 s after the turn
  ends (2.1.283), and a queued run's test suite died with it.
- **Never into a chat whose own work is out.** A run waits while the
  chat's own process has an agent or workflow out, as for a busy chat, and
  while it has a background command running - 20 minutes at most, then it
  goes in beside the chat without closing its tab, which would end a
  server; that wait never counts toward the 24-hour give-up. `chatqlist`,
  the overlay, the console and the phone's board say `waits for a
  background command (since 14:02)`.
- **A queued run keeps the chat's Ultracode and session-only effort.**
  Claude Code keeps both only in the chat's running process, so a run
  started plain dropped them. A run into a chat that had Ultracode on
  starts with it - `"ultracode": true` in the run's own settings, not
  `--effort ultracode`, which would force xhigh - and one whose effort
  was set for the session only - max always, or a level `/effort` set
  `(this session only)` - with `--effort <level>`. Only on the chat's own
  model: never with `-Model`, never a new chat's first run, never Codex;
  and no level where `CLAUDE_CODE_EFFORT_LEVEL` is set, which outranks
  it. The history, `watcher.log`, the console and the live view say
  `with Ultracode, at effort max`. **Why:** every queued run dropped them.
- **Ultracode only in a mode where a run can use it.** Claude Code asks
  before each Workflow unless the mode is auto or bypassPermissions, and
  a queued run has nobody to answer: every Workflow would be denied and
  the job end `needs input`. In any other mode the run goes without
  Ultracode, its level still carried, and its history says `Ultracode
  left off (default mode asks before each Workflow)`.
- **A tab chatq opens again holds `/effort ultracode`.** A tab closed and
  opened again - Show it, the chat put back after a run - is a new
  process, without Ultracode or a session-only level. Its input box now
  holds `/effort ultracode`, or `/effort max`: press Enter there. With
  both lost, the notice names the level to type next - typed, `/effort`
  leaves Ultracode on, where the tab's effort menu would save a level
  below max as every new session's default. It says `Ctrl+Enter`
  (`Cmd+Enter` on a Mac) where `claudeCode.useCtrlEnterToSend` is on. A
  chat whose tab is still there, or that a process holds again by the
  time you click **Open chat**, gets no pre-fill. **Why:** a refreshed tab
  dropped them without a word, and the effort menu offers Ultracode only
  at max.
- **How a chat's settings are read.** From its transcript, backwards, 16
  MB at most: `/effort`'s answers, the notices Claude Code writes with a
  prompt when Ultracode changed, and the level each turn a prompt of
  yours started ran at - so a max picked in the tab's effort menu counts
  as well. A compaction and a queued run's own notices are read as Claude
  Code reads them, so a chat switched off after either reads off.
- **A watcher started from a chat's terminal** no longer hands that
  chat's VS Code settings to its runs:
  `CLAUDE_CODE_SDK_READS_SESSION_STATE` (Claude Code 2.1.284) and
  `MCP_CONNECTION_NONBLOCKING` join the variables dropped.
- **A queued run's chat is marked as one.** Claude Code registers
  `claude -p` as an SDK run (`sdk-cli`), which the overlay drew as a
  terminal, `>_`; it is a play triangle now (`|>` in `chatoverlay
  -Print`), the delete chip stays greyed, the phone says `a queued
  prompt`, and the picker reads it as running.
- **Claude's questions on the phone.** A chat you run yourself that asks
  with `AskUserQuestion` shows the question on the board, `a question:
  Stability log` in place of `input needed`, and on the page of its `needs
  input` alert: every question, header and option, with each option's whole
  description. A very long text is cut and says so; a preview is not shown.
  The push says only `waiting on you: input needed (a question)`, and the
  question travels only on the sealed down topic. No hook, no setting: it
  is read from the chat's transcript, as the overlay reads it. **Why:** the
  alert said `input needed` and nothing more, so you went to the PC to
  find out what was asked.
- **Answer them from the phone, off by default.** `chatnotify -Ask on`, or
  **Answer Claude's questions from the phone** in the setup window (also
  `-AskWait <min>`, 240; `-Manual`), adds a small Claude Code hook as the
  plugin `chatq-ask`, through Claude Code's own CLI - your `settings.json`
  is never written. The hook runs beside the VS Code dialog, holds the
  question for the phone, and the first answer, the PC's or the phone's,
  counts. The phone picks options or types one under **Other**; it is
  text to Claude, never a deny, believed only on the phone's own sealed
  message, and refused above `reply.maxMode`. The watcher then checks the
  answer landed, and pushes `did not take the answer from the phone` or
  `went on without your answer` when it did not. `chatuninstall -All`
  removes the plugin first, and stops if it cannot. A question asked
  before the hook was loaded in that chat, a terminal chat, and a queued
  run's are shown, not answered. Each held question is a hidden Windows
  PowerShell of about 130 MB, 5 at most (`ask.maxOpen`), 4-8 seconds to
  start. **Why:** the question waits on you, and a phone that can show it
  can as well take the answer. It rests on how Claude Code 2.1.283 treats
  a hook on this tool, which its documentation does not describe, hence
  the landed check and the default of off. docs/phone-ask-spec.md has the
  design and what the spike saw.
- **The watcher starts under any execution policy.** The setup window and
  the outbox's sender, Windows PowerShell 5.1, start a watcher to listen
  for the phone's replies. For someone who only ever set a policy in
  PowerShell 7, 5.1's is still `Restricted`: that watcher could not load
  the script, said nothing, and no reply was read until a shell started
  one. It now starts with `-ExecutionPolicy Bypass` for the load alone,
  as the sender does, and drops it again before the loop, so the jobs it
  runs and your own alert command run under your policy. A watcher that
  fails to load says so in `data/logs/watcher.log`.
- **chatclean lists hidden chats again.** Since 0.8.1 a chat Claude Code
  left out of its lists is mended as a run into it ends, or as the window
  opens it. One hidden before that, or by a watcher that died mid-run, and
  neither run into nor opened since, stayed out of every window's history.
  `chatclean` now lists every such Claude chat again first, with the same
  one line at its end, and names each. A chat in use is left, and named;
  `chatclean` again once it is idle. Side transcripts are left alone.
- **The console moves from anywhere on its header.** A press on the
  header's padding, its grip or its counts drags the window; only its
  controls keep the press. Before, only the counts' own text took it.
- **One look for the panel and the console.** The console opens at the
  panel's opacity instead of fully opaque, and its header has the panel's
  **Opacity** slider and **Theme** chips: a change made there is the
  panel's when it comes back, kept in config.json, and the settings box
  shows it.
- **Continued one at a time, and said so.** The watcher runs one job at a
  time, so the chats one limit cut off are continued one after another,
  never side by side - with **Now** or **In turn** alike, since **When**
  is for Send alone and Continue always queues in turn. The queue said
  `sends 16:51` on every one of them all the same. Now only the first
  does; each of the rest says `after #9`, the job before it - in the
  console, the panel, the phone's board and `chatqlist`, and on an
  auto-continue's row. The console's queue gives the jobs behind a
  chat's first their time too, where they said only `queued`. Continue
  says `queued 4 continues - one at a time, each when its limit is
  over`; **Continue all**'s tooltip says it, and that When is for Send;
  Send's line says when **Now** waits for a job running, and the soon
  alert `3 queued · they go then, one at a time`.
- **A job's number is its own.** A new job took one past the highest
  number a saved job held, and `chatq` without `-Prompt` saves its job
  only once its editor tab is closed: a job queued meanwhile - from the
  console, the phone, auto-continue or another `chatq` - took the same
  number, and for the same chat the same prompt file, over the text in the
  open tab; removing either job then took the other's prompt, and
  `chatqrm <n>` reached only one of them. A prompt file in `data/queue`
  now holds its number from the moment the job takes it, and a number is
  taken holding `data/job-numbers.lock`, so a shell, the overlay and the
  watcher never take one between them.
- **Nor two jobs one id.** Two processes queueing for one chat in the same
  second could give both jobs the same id, and the second job's file
  replaced the first's. The id is taken under the same lock, and held by
  the job's folder until its file is saved.

## 0.9.0 — the overlay and permissions on the phone, cut-off chats continued, updates that wait

Five pieces of work land together: the phone gets the overlay, Claude's
whole answer and a queued run's permission prompts; usage heads-ups,
quiet hours and a spoken line come with them; a chat the usage limit cut
off is asked about at the reset, or continued by itself; and a new
version of the extension waits for the window's chats before it reloads.

### The overlay on the phone, and Claude's whole answer there

- **Claude's whole answer on the phone.** A `done`, `needs input` or
  `failed` alert's page now shows the chat's whole last turn above the box
  you answer in - its text, a line per tool it used (three or more fold
  into one), code blocks, and a limit or a 529 as a note - rather than the
  alert's 200 characters. **Show all** and **Copy**; while the keyboard is
  up it folds to one line, so **Send** stays in sight. Over 30,000
  characters (`reply.fullMax`) the start is left out and the page says how
  much. Nothing decrypted is kept on the phone: a reload fetches it again,
  and **Ask the PC for it** has it sent again once ntfy.sh has dropped it.
  `chatnotify -FullText off` leaves the excerpt only.
- **The overlay on the phone.** The reply page opened from a bookmark or a
  home-screen shortcut - no alert - is the board: usage with a bar per
  window, the chats waiting on you, working, cut off and idle, the queue
  with when each job sends, and Recent, in the overlay's order and
  colours, with a search over them; **Older chats** adds the PC's 30
  newest, Codex's too. Tap a chat for its view: where it runs, what a
  message would wait on, its newest prompt, **Send**, and what the
  overlay's chips and the console offer for it - **Send now**,
  **Skip**, **Stop**, **Continue**, **Allow edits & continue**, **Retry**,
  **Continue at reset**, **Don't continue** - and **Read the last answer**.
  **+ New chat** starts one in a folder chatq already knows, in
  `reply.newMode` (`default`). It refreshes every 30 s while it is on the
  screen, for 10 minutes. `chatnotify -Compose off` turns it off.
- **Listen all the time.** The PC reads the phone while an alert is out, as
  before; `chatnotify -Listen always` (or the setup window's **Listen all
  the time**) keeps a hidden PowerShell listening while a phone is paired,
  so the board works with no alert out: about 60-120 MB, and an ntfy.sh
  request every 20 s, 6 s for two minutes after the phone asked for
  something. It never keeps the PC awake. `chatqrun -Stop` ends it until
  the next shell or overlay start.
- **Within ntfy.sh's free limits.** The PC now also posts to a second
  topic, the down topic, worked out from the phone's key and in no push,
  link or file: sealed as a reply is (AES-256 and HMAC-SHA256, under a key
  of its own), raw-deflated first so most answers fit in one 4 KB message
  that ntfy.sh keeps 12 hours - a longer one goes as one attachment, kept 3
  hours. An address without an account gets 250 messages a day, which
  alerts through ntfy share, so whole answers stop at `reply.downPerDay`
  (150) and boards and acks 50 after that; the board says when few are
  left. Nothing the phone sends names a chat, a job or a folder - only
  handles the PC gave it - and every job it makes runs within
  `reply.maxMode`, as a reply's does. A phone paired on 0.8.0 needs no new
  pairing. The push that goes beside an act's sealed answer names no more
  than a push may: a new chat's says `new chat queued as #15 - runs in
  default`, never the title or first line typed on the phone, nor the
  folder.
- **Continue at reset is an answer, as the overlay's are.** It marks the
  cut-off in `data/auto/` as the reset ask's Continue does, so a
  continue you then skip from the phone (**Don't continue**) stays
  skipped: neither auto-continue nor the reset ask takes the chat up
  again for that reset.
- **A board with no overlay running** - built from a scan of the registry
  and the transcripts - is sent again for 40 s, past the page's 30 s
  refresh, and its cut-off look reads a transcript again only once it
  changed: inside a run, the scan held up the run's own output and its
  permission requests. A folder on another machine is offered without
  being looked at, as the overlay's Recent does.
- **Why:** "if I can open a browser and use it, why not display the whole
  overlay on it? - on the phone". An alert showed only the end of the
  reply, and the phone could reach a chat only through an alert about it.

### A queued run's tool call, approved from the phone

- **Approve a queued run's tool call from the phone.** A queued Claude run
  that meets a permission prompt - a `git push`, an edit its mode does not
  allow - was told no, and parked as `needs input` until you were back.
  With `chatnotify -Permit on` (or **Approve tool calls from the phone** in
  the setup window) it asks the phone instead: a `chatq · permission` push
  that names the chat and the kind of call, and a page that shows the call
  itself - sealed for the phone, so neither Join nor ntfy can read it -
  with **Allow once** and **Deny** (with a note for Claude). The run waits
  `permit.waitMinutes` (10) and goes on; a call nobody answered is denied,
  and the job ends `needs input` as before. Off by default: it lets a
  paired phone make a command run on this PC. An Allow is that one call,
  as shown - no "always allow", no other mode, no later call - and the
  bridge that answers claude believes it only when it opens the phone's
  sealed answer itself and it names that very request. Claude runs only,
  in `default`, `manual`, `acceptEdits` or `auto`; never for a question,
  a plan, chatq's own `data/` or a Claude settings file. 10 asks a run, 20
  an hour. A bridge that does not start costs that run once, retried
  without it. `-PermitWait`, `-PermitTools`, and `permit.*` in
  `config.json`. Spike S35 settled the contract against claude.exe
  2.1.283 (TESTING.md). The push goes even while you are at the PC and
  in quiet hours: the run waits on it, and a held one could only expire.
- **What the page shows is what Allow runs.** The PC works out the
  request's digest again from the request as it sends the card, and
  declines one whose file was changed after it was asked; the card hides
  only plain values that look like secrets - never one with `$( )`, a
  backtick, `|`, `;`, `&`, `<` or `>` in it - and when anything was hidden
  or cut to fit, the page says *Not all of this call is shown ... If you
  cannot tell what it does, Deny.* A write to a path on another machine
  says so, and is never looked at from the PC.
- **chatq's own files by any name.** The rules that never ask the phone
  now see `data/` and a Claude settings file however a tool names them:
  Git Bash's `/c/Users/...`, a `\\?\` or `\\localhost\c$` prefix, an
  NTFS stream (`::$DATA`), trailing dots, the 8.3 short name, `~` and
  `$HOME`, and a relative `data\` from chatq's own folder. A path that
  cannot be read counts as `data/`.
- **A permission push whose request could not be registered** - replies.json
  locked, say - no longer goes: it opened nothing on the phone for a request
  already declined.
- **The bridge reads past a byte-order mark.** A parent on .NET Framework
  whose console input is UTF-8 - a GitHub runner's Windows PowerShell -
  writes one into a child's stdin before anything else, and the bridge
  left `initialize` behind it unanswered. claude sends none; the bridge
  now skips one wherever it comes from.

### Usage heads-ups, quiet hours, read aloud, and Tasker

- **Usage heads-ups, with Send now.** A new phone event, `usage`. The
  overlay (Windows) alerts once when a 5-hour or weekly window, Claude's
  or Codex's, reaches `-UsageAt` (90% by default; up to three, `75, 90`),
  so a long task is not started into a wall. The watcher alerts 10
  minutes before a limit resets with prompts queued - its page offers
  **Send now**, which asks the PC to try at once, a probe first, so
  nothing is typed while the limit still holds - and once more when it
  has reset with two or more waiting. Each goes once, recorded in
  `data/usage-alerts.json` before it is sent. `-UsageAlerts off`,
  `-UsageReset off`; a `phoneEvents` list gets them only once `usage` is
  ticked, and `chatnotify` says so.
- **Quiet hours.** `chatnotify -QuietHours 00:00-07:00` holds the phone's
  alerts in that window, this PC's clock, except the urgent ones (`failed`,
  or `-Urgent`), and sends one summary when it ends - `held 00:00-07:00:
  2 done, 1 needs input`, a line each - from the next alert, the watcher
  or the overlay, whichever sees it first. Nothing is dropped: a summary
  that fails goes back and is tried again. The toast and your command
  still run; the command is told `CHATQ_QUIET=1`. Tests, replies and the
  pairing push always go.
- **Read aloud.** `chatnotify -Say 'needs input', failed` has Join speak a
  short line for those events - `Parser rewrite needs input`, in Korean
  for a Hangul title - not the alert's text. Off by default: Join speaks
  through the phone's speaker as well as headphones. Never in quiet
  hours, never for a reply, the pairing push or the summary.
- **A reply typed outside the browser.** An alert's link now takes
  `&text=...`, which the page puts in the box - it never sends it. A
  Tasker profile can turn a notification's reply field, or its own dialog,
  into one tap on **Send**; README has the recipe. A link that sent by
  itself could be opened by anything and would send with the phone's
  key, so the tap on Send stays the one thing that sends.
- **The setup window** has all four: Read aloud under Send test, quiet
  hours with what still comes through, usage and resets.

### What the limit cut off: asked about, or continued by itself

- **Once the limit is over, the overlay asks.** Five minutes after the
  reset, the chats the usage limit cut off are counted, and one prompt
  offers to continue them all: a toast, `chatq - limit over at 13:00`,
  `3 chats it cut off can continue: ...`, and a banner at the foot of the
  panel's header, `limit over at 13:00 · 3 chats it cut off can continue`.
  Rest on the banner for its chip, **continue 3** or **leave them**; the
  tray's menu has **Continue 3 cut-off chats** and **Leave them** at its
  top, gone again once it is answered; the console's **Cut off** header
  says it, with **Leave them** beside **Continue all**. A click on the
  toast opens the console, where the chats are listed - with
  `overlay.cutOff` off too - and it never answers by itself, since a toast
  is often clicked only to be rid of it. Continue queues *"Continue from
  where you left off."* for each, the job `chatq <title> -Continue` makes.
  Each cut-off is asked about once, and announced once, across restarts.
- **Left out of the ask:** a 529, which has no reset to wait for; a chat a
  terminal's `claude` holds - Claude Code continues it itself there, and a
  second writer would clash - named in the banner's tooltip instead; a
  reset over 12 hours ago; an old limit record with no reset time; and,
  while a 5 h or weekly window is still at its limit, everything, until
  that reset too. A chat with a job already queued or running is not
  asked about.
- **The reset time on the usage line.** Claude's line reads
  `5h 100% resets 13:00 · week 46%`: the window you wait on - the latest
  of those at their limit, else the 5 h one - with its reset, red while it
  is at its limit. The collapsed line and the tray dot's tooltip say it
  too (`5h 43%, resets 13:00`), and the tooltip counts `2 can continue`
  apart from the rest cut off. A narrow panel wraps the line rather than
  hiding a window. The bars view already had a countdown.
- **Ask is the default, and one switch turns it off.** The settings box
  has a seventh row, **Cut off**: **Continue**, **Ask** or **Leave**. From
  a shell, `chatq -AutoContinue ask|on|off`, which tells a running
  overlay. Both write `autoContinue` at the top of `data/config.json`,
  beside `liveIdle`. Off is how it was: the rows are only marked orange.
  Continue is the automatic mode, below.
- **Cut-off rows stay longer.** A row now stays while its reset is under
  12 hours ago, or while the cut-off is under 12 hours old, so a chat asked
  about overnight still has its orange row in the morning.
- **The scan runs with `overlay.cutOff: false` while the ask is on.** That
  setting still hides the rows; the ask needs the scan to count them. With
  both off, nothing is scanned, as before.
- **The phone, when you are away.** The ask goes to the phone as one
  `limited` alert, `limit over at 13:00 · 3 chats it cut off can continue -
  answer on the PC`, through the same gates as the alerts for the chats you
  run yourself. Its page offers Status alone: the answer is given at the PC
  (FUTURE_WORK).
- **macOS** (untested): the `CQ` menu has **Continue N cut-off chats** and
  **Leave them** at its top while there is an ask, a notification says it
  once, and the lines view shows the reset time. An answer names the
  chats the menu showed, so one cut off while the menu was open is not
  continued with them.
- **Auto-continue, chosen: `autoContinue: "on"`.** A Claude chat the
  usage limit cuts off gets *"Continue from where you left off."* queued
  for it by itself, a minute after the limit resets - above all the chat
  nobody has open any more, which nothing else would continue. Opt-in: the
  settings box's **Cut off** row is now **Continue**, **Ask** and
  **Leave**; `chatq -AutoContinue on|ask|off`, the tray's **Auto-continue
  cut-off chats** (checked while on; unchecked goes back to Ask), the Mac
  menu's item and **Chat Manager: Auto-continue cut-off chats...** in VS
  Code set the same `autoContinue`. Only the word `"on"` turns it on -
  `true` still reads as ask - and only for what the limit cuts off from the
  moment it is chosen: older cut-offs are shown, never queued, and the
  Windows overlay says what it does once, in a balloon.
  `chatq '<title>' -AutoContinue always|never|default` sets one chat,
  `always` continuing it even with the switch on ask or off. While it is
  on nothing is asked; ask and off leave the rows as they were.
- **What it leaves alone:** a chat a terminal's `claude` holds, a 529, a
  weekly limit days out, a cut-off you came back to more than 30 minutes
  after its reset, and one the reset ask answered. A chat open in a VS
  Code panel waits 5 minutes past the reset, for the panel's own
  auto-continue to go first. The overlay scans once a minute and the
  watcher every 5 while it runs. Each cut-off is queued once - one marker
  in `data/auto/`, the file the ask's answer is, so the two never both act
  on it; a continue you remove stays removed for that reset, even when a
  background task's note wakes the chat into the limit again before it;
  and 2 that fail in a row stop it for that chat. The streak and the
  chats set to always or never, in `data/auto-continue.json`, are changed
  under a lock, so the overlay and the watcher writing at once lose
  neither's change. It never touches what chatq runs itself: a prompt you
  queued still comes back as a continue when the limit cuts it off.
- **Every surface says what it will do with a cut-off chat,** and takes it
  back: the overlay's orange row reads `#12 auto 13:01`, `resets 13:00 ·
  never` and so on, in full in its tooltip; its chip has **don't continue**
  or **continue** beside open, left of the row's words; the collapsed line
  counts `(1 auto)`; the console's Cut off list has **Don't continue**, one
  click in the list and the queue alike, and a per-chat **Default / Always
  / Never**; `chatqlist` says what the switch is and whether anything runs
  to act on it, tags each cut-off, and shows `continue (auto)`; the board
  too.
- **The live alert for a chat the limit cut off is now `limited`** when
  auto-continue queued a continue for it - priority 0, about that job,
  with **Don't continue** on the phone's page - where it was `done`. So a
  `-Events` list without `limited` now drops it. The phone cannot turn
  auto-continue on or off.
- **`chatrm` drops a chat's auto-continue** without `-DropJobs`; a job you
  queued still keeps the chat. A chat deleted or archived before its
  continue runs is skipped without a `failed` alert.
- **The overlay's chip holds one chip or more,** made for each row - its
  tooltips too - a click counting only when it goes down and up on the
  same chip, the banner's answers included. Every row's title starts at
  one column, a row with no where mark keeping its place. **continue**
  clicked twice before the list redraws queues one continue, not two.
- **A kept auto-continue never hides.** With the switch turned to ask or
  off, a continue auto-continue had already queued stays in the queue and
  still runs at the reset: it now has a row of its own, where it had
  folded onto a plain orange row that no longer said so.
- **Why:** the owner asked on 2026-09-27 for an option to be told about
  a reset and continue on a confirm, as the default, and for the automatic
  continue beside it; both land here. Claude Code continues an open
  terminal session by itself, but not a chat whose tab was closed, a
  process chatq ended, or a PC that slept - and never says so on the phone.
  The spec, with how the two modes were fitted together, is
  [docs/auto-continue-spec.md](docs/auto-continue-spec.md).

### An update, and the chats a reload would stop

- **An update no longer ends the chats of a window by surprise.** A new
  version of the extension runs in a window only once that window
  reloads, and a reload ends every `claude` process the Claude extension
  started there: a turn in flight, a permission prompt, a workflow or a
  background agent, in every Claude tab of the window. On 2026-09-27 that
  happened twice, each time after a new VSIX was installed from the
  command line while chats worked. Now the running version notices the
  new one - by VS Code's event, or its `extensions.json` changing, which
  also tells the same version installed again - and says so once per
  install, naming what a reload would stop: *VS Code Chat Manager 0.9.0 is
  installed. Loading it reloads this window, which stops the 2 chats
  working here: ...*, with **Reload when they're idle**, **Reload now** and
  **Later**; with nothing working, a one-line notice and **Reload the
  window**, looked at again as it is clicked. **Reload when they're idle**
  puts an item in the status bar (a click cancels it) and looks every 25
  seconds; it reloads the window once every chat of the window has been
  idle for a minute straight, and never while a queued prompt goes into
  one of them - a chatq job running counts even when no process of the
  window holds its chat any more. Right before the reload the registry is
  read once more, so a turn begun during the last look still holds it. A
  reload that fails is said, with **Try again**. It lives in memory only:
  a window closed meanwhile does nothing. Which chats are the window's,
  and which work, is the script's word (`Get-ChatHostWork`,
  `src/host-work.ps1`): a `claude` whose parents lead to this window's
  extension host, busy, waiting on a prompt, with a workflow or background
  agent out, or with a queued run going in - the judgement `Test-ChatIdle`
  makes of a folder, made of one window. A background shell still does
  not count.
- **A reload, not Restart Extension Host.** VS Code's Developer command
  starts the extension hosts again from the extensions it already had:
  checked in VS Code 1.108.2, a VSIX installed from the command line is
  never loaded by it, and the old version comes back up. A reload loads
  the new one; the terminals survive it. Tool-folder scripts too old to
  look at the chats (before 0.9.0) are said as that, in the log and the
  status bar.
- **chatq's own reloads look at the window's chats first.** A reload the
  window takes by itself - after a delete with `autoReload`, or after a
  queued run - and a plain **Reload** clicked on a request that found
  nothing working, maybe minutes later, now look at this window's chats
  again right then, whatever folder they are in. One working, and the
  window says which and asks, with **Reload anyway**; one that cannot be
  looked at stops a reload the window would take by itself. **Reload
  anyway**, clicked on a warning within a minute, reloads as before;
  clicked later, the window's chats are looked at again, and any working
  that the warning did not name is asked about first.
- **Why the reload and the second look:** a review of the integrated
  0.9.0, before release, found that the restart never loaded the update,
  and that a Reload anyway could be clicked hours after a warning that
  named one chat, over another's workflow started since.
- **chatrm waits for a safe reload by default.** What `-WaitForIdle` did
  is now what every delete does while a VS Code window is up: it blocks
  until the project's chats have been quiet for a minute, then says the
  window is safe to reload. `-NoWait` says whether now is safe and
  returns, as a delete did before; `-WaitForIdle` is still accepted.

## 0.8.1 — chatnotify, and hidden chats listed again

- **chatqnotify is chatnotify.** It is no longer only about chatq's queue:
  the same command sets up replies from the phone and the alerts for the
  chats you run yourself in VS Code or a terminal. The help, the cheat
  sheet, the setup window's hints and VS Code's **Phone alerts...** all
  say `chatnotify` now. `chatqnotify` still works, as an alias, and
  `Get-Help chatqnotify` finds the same help.
- **A chat a queued prompt runs into stays in Claude Code's list.**
  Claude Code leaves a chat out of its session list - and will not restore
  it into a tab - when the first `entrypoint` in its transcript's first
  64 KB, or with none there the last one in its last 64 KB, is an SDK's. `claude -p` stamps
  `sdk-cli`, so one queued prompt or phone reply hid a chat whose first
  prompt was a pasted screenshot. Now, as a run ends, the watcher adds one
  line at the chat's end - `{"type":"chatq-listed",...}`, a type Claude
  Code's loaders skip - that lists it again. The file keeps its write
  time.
- **A hidden chat opens from the overlay again.** Before the open chip,
  **Chat Manager: Open chat...** or **Show it** opens a chat in a tab, the
  extension checks it as Claude Code does, and mends one hidden by its
  last records the same way - one hidden before this version, or whose
  run was cut short. One busy in a process right now, or whose line
  cannot be written, is left, and said, rather than opened blank. One
  hidden by its first records can never be listed - every chat **+ New
  chat** started, or your own `claude -p` - so instead of a blank tab it
  is offered in a terminal, `claude --resume`.
- **A chat opened from the overlay has its header again.** Its tab showed
  the chat with nothing above it - no title, no **Session history**, no
  **New session** - and an edit to approve came without its diff. The
  extension opened it with Claude Code's `primaryEditor.open`, which makes
  every tab a "full editor", a mode without them. It now opens an ordinary
  Claude tab, as a tab's own **New session** does, in the same group as
  before, still making no group and locking none, and leaving
  `claudeCode.preferredLocation` alone. An edit to approve shows its diff
  again; with editor groups not locked, it opens in the chat's own group,
  in front of the chat, as it does for any Claude tab. A tab opened the old
  way keeps its mode through a reload: close it once and open the chat
  again. With Claude Code older than 2.1.281, or one that refuses the new
  way, it opens as it did.
- **A chat a queued run went into shows the run, even with you at the
  PC.** A reply from the phone into a chat open in a VS Code tab ran
  beside that tab's own process, and the window only asked **Show it?**.
  A message typed into the tab instead went on from the tab's memory:
  the chat forked, and the run's turn stayed on a branch neither the tab
  nor its process ever saw. Now, when the chat's process here is idle,
  the window does **Show it** by itself as the run ends - at the PC too,
  and while other chats work, since it touches that one chat alone: its
  idle process ended, its tab closed and opened again from disk. And
  when you are away, a chat nothing holds opens in a tab by itself even
  while another chat works. `chatManager.autoReloadAfterRun: false`
  still makes the window always ask.
- **A job you answered in the chat stops saying it needs you.** A queued
  prompt parked on input - a tool it was not allowed, with nobody there -
  kept its chat's row amber, and `chatqlist` and the phone's status saying
  `needs you`, long after you had gone on in that chat yourself. Now the
  overlay skips such a job once anything is typed into its chat after it
  stopped, `answered in the chat`, as a reply from the phone already did.
- **No reload for a new chat.** A window on the folder a **+ New chat**
  started in is only told of it now: Claude Code lists no chat `claude -p`
  started, so the reload it used to offer showed nothing, and cut off
  whatever else worked in that window.
- **The phone's status shows Claude's usage as it is.** It read the figure
  from Claude Code's own cache, which moves only when Claude Code asks: on
  2026-09-27 it said 37% of the 5 h window, 35 minutes old, while the
  overlay showed 62%. It now takes the overlay's live figure when that is
  newer, and `chatqlist` does too.
- **Why:** on 2026-09-27 a chat answered from the phone vanished from VS
  Code's list, and each open from the overlay made a blank chat instead.
  Its first prompt was a screenshot, and the reply, run as `claude -p`,
  wrote `sdk-cli` last. TESTING's S25 had left open whether VS Code lists a
  chat `claude -p` started: it does not (S37). A run under an entrypoint of
  chatq's own would list both kinds, but Claude Code also turns on for it
  what it keeps off for `claude -p` - the Artifact tool, autoDream - so
  runs stay `sdk-cli` (FUTURE_WORK).

## 0.8.0 — replies from the phone, and alerts for the chats you run yourself

- **Phone alerts in a window.** `chatqnotify -Setup` opens one window for
  all of it: the Join key - the key itself, or the whole push URL Join's
  page shows - **Find devices**, the device to send to, and **Send test**;
  replies from the phone and **Pair phone**; which events reach the phone,
  the quiet minutes, the chats you run yourself and the desktop toast; and,
  folded away, ntfy and your own command. **Save** goes through the same
  code as `chatqnotify`'s switches, so the two never disagree about
  `data/config.json`. The overlay's tray has it as **Phone alerts...**, and
  VS Code's command palette as **Chat Manager: Phone alerts...**. It is WPF,
  so Windows only; elsewhere `chatqnotify -Setup` prints the switches that
  do the same.
- **Alerts for the chats you run yourself.** A chat you drive in VS Code or
  a terminal's `claude` now reaches the phone too, not only what chatq
  runs: `needs input` once it has waited on you for 20 seconds, `done` when
  a turn ends. Only while you are away - no keyboard or mouse for
  `quietMinutes` - and then whichever window is in front, its own VS Code
  window included. Never about a chat chatq is running a prompt in, and one
  alert per chat and event every 3 minutes at most. The overlay sends them,
  so it must be
  running (it starts by itself on Windows), and one started before this
  version has to be restarted: `chatqnotify` says when it runs an older
  copy. `chatqnotify -LiveAlerts off` keeps the phone to what chatq runs.
- **Reply from the phone.** With `chatqnotify -Reply on` and a phone
  paired, a tap on an alert opens a page to type the chat's next prompt, or
  press **Allow edits & continue**, **Continue**, **Retry**, **Skip**,
  **Stop** or **Status**, as the alert allows. The phone seals the reply and
  posts it to an ntfy.sh topic; the watcher polls that topic, does what it
  says, and answers with a push - itself an alert that can be answered.
  After an alert that can be answered goes out, the watcher listens for
  `reply.hours` (12) - one is started just for that when none runs - and
  never keeps the PC awake for it. `chatqrun -Stop` stops the listening
  too, until the next such alert.
- **A reply never runs a job above `acceptEdits`.** A job a reply queues or
  requeues runs in its old job's own mode, or the chat's, brought down to
  `reply.maxMode` in `config.json` - `acceptEdits` unless set otherwise -
  and a Codex one in `workspace-write` at most. Nothing in a reply picks a
  mode, and links in its text pull no files from `data/queue`.
- **Pairing, confirmed by a code.** `chatqnotify -Pair`, or **Pair phone**,
  sends one push; the page it opens makes a key on the phone, sends it back
  sealed, and shows a six-digit code. The phone is paired once you confirm
  the same code on the PC - `chatqnotify -Pair` asks, or
  `chatqnotify -Confirm 123456`, or the window's **Confirm**. Pairing again
  replaces the phone at once, and every link already out stops working.
- **No secret in an alert.** After the pairing, an alert's link names the
  alert and nothing else, so Join - whose push is a GET, logged in full -
  and whoever reads an ntfy alert topic cannot answer one. ntfy.sh sees the
  reply topic and the sealed text only, and GitHub Pages serves a static
  page that loads nothing. `chatqnotify -ReplyPage <https URL>` serves that
  page from a copy on a site of your own.
- **One notification per chat.** Join shows the alerts about one chat as
  one notification: `done` replaces `started` instead of piling up under it
  (`join.perChat`, on unless false). Join's alerts carry chatq's icon
  (`join.icon`; `""` for none).
- **Which events reach the phone.**
  `chatqnotify -Events done, failed, 'needs input'`, or the window's
  boxes, keeps the rest off the phone; the toast and your command still get
  every one. `all` puts them back. Tests, replies and the pairing push
  always go.
- **`chatqnotify -Devices`** lists the devices on the Join key saved, or on
  `-ApiKey`, with Join's groups after them.
- **`chatqnotify` alone says more:** the events the phone gets, whether the
  chats you run yourself alert and what stops them, whether replies are
  on, the phone paired and since when, how long the watcher listens, the
  last reply, and the answers to a pairing waiting for their code.
- **Why:** on 2026-09-26 Join was set up, its test reached the phone, and
  then no alert came. Nothing was broken: only prompts queued with `chatq`
  alerted, and the chats run straight in VS Code never passed through
  chatq. They alert now, through the overlay, while you are away. The
  replies were asked for at the same time, so an alert can be answered
  where it is read; the pairing, its code and the mode cap are there
  because a push is read by more than the phone it goes to.

## 0.7.2 — chats open as tabs, and the overlay starts by itself

- **The open chip opens a tab.** A click on a row's **open** opens the chat
  in an editor tab of its own in its window, or brings forward the tab that
  already shows it. It ends no process and judges nothing busy, so a tab
  there already comes forward as it is: a queued run that ended while that
  tab's process lived shows through **Show it**, or once the tab is closed
  and the chat opened again. The chip no longer depends on
  `chatManager.showFresh`; with no Claude Code extension the window says it
  cannot open the chat.
- **Never a second copy of a working chat.** A chat working in its window
  outside the tabs - in the side bar, most likely - is not opened: a tab
  would start a second process on it mid-answer. The window says so; click
  open again once it finishes. One idle there still gets a tab and a second
  process, since nothing reaches the side bar's chat, and the window says to
  close the side bar's copy. A working chat opens only when exactly one
  Claude tab here carries its label and no other chat of its folder would:
  two tabs of one label, a label another chat has - the same title, or the
  same first 24 characters, open or not - or a chat of no title, count as
  no tab, since a tab carries no session id and that one may be the other
  chat's; renaming one of the two tells them apart. The other chats looked
  at are those of every folder of the window as well as the chat's own,
  the newest 200 of each; a look not done in 1.5 s counts as shared, and
  says so in the log. On a Mac, where the window holding a chat cannot be
  told, a working chat with no tab of its own here is left the same way.
- **A terminal's chat is turned away, working or not.** Whose a chat was
  used to be looked up only once it was idle, so a terminal's `claude`
  mid-turn read as a window's working chat and was sent on to VS Code. The
  tray now says it is open in a terminal, and nothing is written.
- **The chat's tab group is left unlocked.** Claude Code locks the editor
  group it makes for its tabs (`claudeCode.lockEditorGroups`, on by
  default), and a chat's tab opens into such a group, so the next file went
  to another group, or a new one. Once the chip, Show it or the picker has
  the tab up, the group holding that chat's tab is unlocked - only while it
  is the active group, since the command acts on that one, and only when it
  holds Claude tabs alone; one holding other editors is left as it is.
  `claudeCode.lockEditorGroups` set to `true` in any settings scope makes
  the lock your choice, and no group is unlocked. Claude Code's own **Open
  in New Tab** still locks the group it starts;
  `"claudeCode.lockEditorGroups": false` stops that.
- **Show it uses a tab too.** After a queued run the chat's old idle
  process is ended as before, and the chat opens in a tab of its own,
  loaded from disk. Reload Webviews is gone. Where the old process is still
  there, the window offers a reload, as before - with **Reload anyway** when
  the chat, or another in its folder, is working. The warning says which:
  when only another chat works, it says that chat is still working and a
  reload now would cut it off - no longer that the old process could not
  be ended, with a plain **Reload**. Where the window had the chat outside
  its tabs, it says that copy is stale now and can be closed.
- **A stale tab is found by Claude's label.** A chat already open in a tab
  has that tab closed and opened again. Claude shortens a title over 25
  characters to its first 24 and `…`, and a tab labelled that way was not
  recognised, so it stayed stale. Both forms count now. A tab whose label
  another Claude tab shares, or another chat of the folder would carry, is
  never taken as sure - closing the wrong one would cut off the other
  chat - and a chat with no title never is, since every such tab reads
  "Claude Code"; you are told to close the tab yourself. A new tab that
  turns up just before the close is taken as the chat's, and nothing is
  closed. A Claude tab is known by its `viewType` alone, the Claude Code
  extension's `claudeVSCodePanel`: Cline's tabs, whose name holds "claude"
  too, and a markdown preview are never closed or taken for a chat.
- **Resize the overlay.** A handle beside the grip: drag it sideways for
  the width, up and down for the rows, with the panel's right edge held
  under the buttons. The settings box has **Width** (260-800) and **Rows**
  (1-30) sliders, and `chatoverlay -Width 460 -Rows 12` sets both from a
  shell, refusing a value out of range. The panel never runs past its
  screen's bottom from wherever it sits - moved lower, it draws fewer rows,
  and moved up again, more - and the rows that do not fit are counted on
  the `+N more` line.
  Dragged down, it never ends with fewer rows than were set, even with
  fewer chats open than that. Near the screen's left edge it widens to the
  right rather than off the screen. The sliders show the size a drag left,
  and where a change of width moved the panel is kept for its next start.
- **The overlay starts by itself** on Windows: with every new shell, and
  when a VS Code window starts - as soon as the scripts are in place. On a
  first install that is the moment the extension has copied them, before
  it asks about the profile line, and that question may never be answered.
  It is where a chat is opened from now. Three ways stop that, all one
  switch: **Chat Manager: Overlay: start by itself...** in the command
  palette, On or Off - Off also closes a running overlay, and no terminal
  or profile line is needed; `chatoverlay -AutoStart off`; or
  `overlay.autoStart` false in `data/config.json`. A missing `config.json`
  reads as on. One that is there but
  cannot be read reads as off: it may be the file that said off. On macOS
  it stays off until `-AutoStart on`. A start that fails says why in
  `overlay.log`. During an update it starts from the new scripts once they
  are all copied, and not while another window is copying them.
- **Open chat... in VS Code.** **Chat Manager: Open chat...** in the command
  palette lists this window's Claude chats, newest first and 200 at most.
  Each shows its title - a rename, Claude's own title, else the first
  prompt - how long ago it was written, and what runs it: open, working,
  a terminal, or a queued prompt running. Picked, it opens in a tab as the
  overlay's chip opens one. A chat in a terminal, one a queued prompt or
  any `claude -p` is going into, or one working elsewhere in VS Code, is
  not opened. One open and idle elsewhere - another window, or the side
  bar - asks first, with **Open here too**. What runs it is read again
  after that question and right before the open, so one that began to
  work meanwhile is refused as it would have been at once. A tab here
  counts as the chat's only while no other chat of its folder would carry
  its label, as with the chip: working, such a chat is refused; idle, it
  asks. The list is up at once; a title not read within a quarter of a
  second shows the chat's id until it is. A `$(` in a title is shown as
  typed, not as an icon.
- **Recent in the overlay.** Under the open chats, a faint **Recent** list
  of the newest Claude chats not open, one line each: project, title, how
  long ago. Rest on one and **open** opens it as a tab, as on an open row.
  Five by default. The settings box's **Recent** row picks off, 5 or 10,
  and `chatoverlay -Recent 12` any count from 0 to 20 (`overlay.recent`; 0
  is none). Lines the screen cannot hold are left off. Side transcripts,
  empty ones and chats whose folder is gone are never listed; whether a
  folder is there is asked again every 3 minutes, and never of one on a
  network share or mapped drive, which counts as there - a share asleep
  would hold the panel. `chatoverlay -Print` lists them too, the whole
  count at once; the Mac panel does not yet.
- **A dot for a turn you have not seen,** on Windows only. A chat that
  finished a turn - went from working or waiting to idle - while you were
  elsewhere has a small blue dot before its state, and the collapsed line
  and the tray dot's tooltip say `2 new`. A chat whose window was in front
  as it finished gets none: any window of its VS Code counts, or for a
  terminal's `claude` any tab of the terminal that draws it. A console
  that Windows handed off to Windows Terminal cannot be matched to it, so
  that chat gets the dot even with its tab in front. The chip clears it
  once its open sent the window its request (`ended 0`, `25`, `40` or `41`
  in `overlay.log`); one turned away - a chat at work (`10`), a
  terminal's, a queued prompt running in it - one that failed before the
  request, or one not answered within 60 s leaves it. A new turn, or its
  session ending, clears it too. The overlay keeps it in memory only: a
  restart clears every dot, and reading the chat in VS Code clears none.
  The Mac panel has no dot: it has no chip to clear one, and no window in
  front to spare a chat one.
- **Where each chat runs.** After a chat's dot, a small window outline for
  a VS Code panel, or `>_` for a terminal's `claude`, from its entry in
  `~/.claude/sessions/`. `chatoverlay -Print` and the Mac panel put `>_`
  before a terminal's chat.
- **Compact rows.** The settings box has a **Style** row: **full**, each
  chat with its newest prompt under it, or **compact**, one line a chat.
  `chatoverlay -Compact on` does the same from a shell; it is `prompts`
  turned off. The box is laid out afresh to stay short: Width and Rows
  share a row, and Style and Recent come under Theme and Usage.
- **A quicker open chip.** It comes after a 400 ms rest on a row, not a
  whole second: a pointer crossing the panel seldom rests even that long on
  one row. `chatoverlay -ChipDelay 250` sets it, 100 to 3000 ms
  (`overlay.chipDelayMs`).
- **The console opens in the panel's place.** It is no longer a window of
  its own: the console button, the tray's **Open console**, the console
  hotkey and `chatconsole` turn the panel itself into the console, grown
  from its top-right corner - its right edge and top held, kept on the
  panel's screen - at the size it was last left, else 980 x 680. While it
  is the console it is a window like any other: it takes clicks and the
  keyboard, has a taskbar button and a place in Alt+Tab, and is not kept
  on top, so another window can cover it and files can be dragged onto it
  from Explorer. Its header moves it and the grip at its corner resizes
  it. The buttons, the open chip and the panel's rows rest meanwhile.
  **Esc**, **← Panel** in its header, the console hotkey again while it
  is in front, or Alt+F4 bring the panel back exactly as it was - its
  place, width, rows and fold, and the tray if it was hidden there - and
  the draft is kept. The hotkey on a console another window covers brings
  it forward instead; the tray's item and `chatconsole` only ever bring it
  forward, as a command from a shell can arrive a couple of seconds late.
  Hide, collapse, lock, unlock, Move to top right and Quit go back to the
  panel first - after the folder picker closes, or a drag of the header
  is let go, when they come during one; a theme change keeps what is
  typed, in the console still. A width set from a shell meanwhile holds
  the panel's right edge as it comes back, and where that leaves it is
  kept for the next start. A size kept from a screen at a lower scale
  opens no smaller than 640 x 420 on this one, its right edge still at
  the panel's. Its list draws each chat as the panel's rows do - the
  dot, where it runs, the state, the unread dot - one line each, the
  picked one with an accent bar, and a recent chat faint as in the
  panel's Recent. `console-state.json` keeps its size and the draft, no
  longer a place or a maximized state: where it opens comes from the
  panel.
- **Logs.** Every click on open goes in `overlay.log` with the chat's short
  id, and so does how it ended, 0 included. `watcher.log` gets one `show`
  line per show: how it was asked for, the old process, busy, the windows,
  the outcome. The extension's log says whether each open made a new tab,
  revealed one, failed or was not opened, and which verdict Show it and a
  show on its own acted on. A command the extension runs for a show - an
  open, a tab closed, a reload - gets 15 s: one that never answers is
  logged and taken as failed, and the shows after it still run.
- **Why:** on 2026-09-25 a click on open ended the chat's idle process, and
  the window then opened the chat and ran Reload Webviews. That left two
  views, each resuming the chat with a process of its own. A second click
  ended both, and the stale tab was not recognised by its shortened label,
  so both views were left on "Claude Code process exited with code 1".
- **Fixed:** an overlay row for an open chat nothing had titled yet is
  titled by its first real prompt again. With two or more user records at
  the transcript's start, they were read as one line, and no prompt was
  found in it.
- **Fixed:** the overlay's buttons stuck under the panel. They go under it
  when the panel sits too near the screen's top, and they kept to that side
  for as long as there was room under it - so a panel started at the top
  and then dragged down had them under it until the overlay restarted.
  They now keep their side only while they are up, so opening the settings
  box, or a drag short of the screen's edge, still never moves them out
  from under the pointer; the next time they come, they are on the panel's
  top edge wherever there is room.

## 0.7.1 — a new icon, and releases from CI

- **A new icon:** the Marketplace and the Extensions view show a photo in
  place of the chat bubble, on the same rounded square. The photo meets the
  square halfway: a little of its left end is cut, and bands filled with
  its own background make up the rest above and below.
  `docs/make-icon.ps1` makes it from `docs/icon-source.jpg`.
- **The Marketplace listing shows the terminal too:** Tab filling in a
  title for `chatrm`, `chatq` queueing a prompt, and `chatqlist`. vsce
  takes no SVG there, so `docs/make-demo.ps1` now also draws those three
  frames as PNGs, with headless Edge.
- **Updating, said plainly:** a window runs a new version of the extension
  once you click **Restart Extensions** or reload; VS Code restarts none by
  itself. An extension installed from a `.vsix` file is pinned and never
  updates by itself until **Auto Update** is turned on for it.
- **Releases from CI:** `.github/workflows/publish.yml`
  publishes a `v*` tag and makes its GitHub release, signing in as an
  Entra app rather than with a PAT. Run by hand, it publishes nothing: it
  builds the VSIX, signs in, and checks that the publisher accepts the app
  (docs/marketplace-spec.md, Publishing).

## 0.7.0 — one extension on the VS Code Marketplace

- **Install from the Marketplace.** **VS Code Chat Manager**
  (`redaechan.vs-code-chat-manager`) carries the PowerShell scripts as
  well as the VS Code half. On its first start it puts them in
  `~/Tools/VS-code-chat-manager` (`chatManager.folder` moves it), asks once
  before adding the profile line - **Add**, **Not now**, **Never** - and,
  where the execution policy would stop that line, offers to allow local
  scripts for your user. VS Code's own extension updates then keep the
  scripts up to date, and each moves a running watcher and overlay onto the
  new copy.
- **What it never does:** write into a git checkout - the folder or any
  folder above it; it says when the scripts there are another version -
  write over a newer copy or one whose version it cannot read, write into
  a folder that holds other files, or act in two windows at once. A
  `chatManager.folder` that is not a full path is refused for the default.
  Where the policy would stop the profile line, **Add** says so and allows
  local scripts first; where a line is already there but never runs, it
  offers that once. "Added." comes only once the line is really there; a
  copy or an add that fails says so. The answers live in
  `data/extension.json`, beside the rest. Every process it starts is logged
  with its command line under **Chat Manager: Show log**; **Chat Manager:
  Install terminal commands** asks again, even after Never.
- **One version for both halves.** The extension was 2.1.0; it is now the
  tool's own, 0.7.0, and `extension/build.js` refuses to pack the two apart.
- **The old extension retires.** `phal40lax78.chat-manager-reload`, which
  was copied into `~/.vscode/extensions/` by hand, is replaced. While it is
  still installed and watches the same file, the new one handles no
  request, since both would act on each, and offers to uninstall it. Settings move from `chatManagerReload.*`
  to `chatManager.*`; the old ones are still read where the new ones are
  unset, and `signalFile` gives way to `chatManager.folder`.
- **Why:** nothing kept the two halves in step. On 2026-09-25 the script
  was 0.6.0 while every window still ran the 2.0.0 extension, which ignores
  the overlay's open requests, so the open chip did nothing.
- **`chatinstall -NoRestart`**, for the extension, which installs into
  each PowerShell in turn and restarts the watcher and overlay once, after
  the last. `chatinstall` now names `chatManager.folder` where it named
  `chatManagerReload.signalFile`.
- **The one-liner stays**, for the terminal alone.

## 0.6.0 — show the chat fresh

- **Show it, not Reload.** A chat a VS Code window still holds shows a
  queued run only once that window redraws it. 0.5.0 reloaded the whole
  window for that; now the window redraws only its web views (**Developer:
  Reload Webviews**) and opens the chat where you read it - the side bar
  here. It does this by itself under 0.5.0's rules: you away, nothing in the
  folder working, a window on exactly that folder, and that judgement at
  most 20 s old. Otherwise the notification offers **Show it**. The click
  ends the chat's old idle process and judges the folder again, right then;
  with a chat working it opens the chat fresh in an editor tab of its own
  instead, and nothing is cut off. Terminals, editors and other extensions
  keep running either way. Whether other web views (a Codex chat, a
  preview) and an unsent draft come through is still to be checked (S30
  items 14 and 2).
- **The old process.** Reload Webviews alone is not enough: the chat's old
  `claude` process keeps the old memory. While you are away, chatq ends it
  as the run finishes, so your next message there starts from disk even if
  nothing redraws the view. While you are at the PC it is left alone until
  you click Show it - what a side bar does when the chat on screen loses its
  process is still to be checked (S30).
- **The overlay's open chip.** Move onto a Claude row and rest a second, and
  a small **open** appears at its right end - a window of its own, like the
  buttons', that takes no focus and is in neither Alt+Tab nor the taskbar;
  the rest of the panel stays click-through. It shows once per visit to a
  row, and a pointer it came up under has to move off it before a click
  counts. A click shows the chat up to date in its window, the same way,
  and brings that window forward with `code -n <folder>` - or opens one
  there, which shows the chat as it starts. The tray says when it could not:
  a queued prompt running in that chat, a terminal holding it, a window with
  other folders open, no `code` command. A window on exactly the folder is
  told from its title, a profile's name after the folder's included.
- **The overlay's buttons can be pointed at directly.** They came up only
  after the pointer rested on the panel, so reaching them meant going to the
  panel, waiting, and crossing to them before they went. Resting on the spot
  they go - above the panel, or below it near the screen's top - brings them
  too, and the gap between them and the panel counts as theirs. The same
  350 ms rest applies: a pointer passing over that corner on its way to the
  window underneath must not find buttons that take its click. No rest
  counts while a mouse button is held, so a tab or a file dragged across
  that corner in the app below is never dropped onto them.
- **What is never ended.** Only a VS Code window's process is ever ended -
  its registry entry says `claude-vscode` and its parent is `Code.exe` -
  never a terminal's, and never one busy, waiting, or with a workflow or
  background agent in flight; its registry file is read again just before.
  A chat open in a terminal is never shown in VS Code as well: that would be
  a second writer, and the alert says to type there. `liveIdle: stop` now
  goes through the same checks, and with background work in flight it
  waits, as for a busy chat. Ending a process ends the background shells it
  runs too, dev servers included. Background work is told apart by who
  started it - each transcript record names its writer, `claude-vscode` for
  the window, `sdk-cli` for a `claude -p` run - never by when: a workflow
  the window's own process started holds it whenever it began, even during
  a queued run, and one a finished queued run left behind never holds it.
- **Never beside a run.** A queued prompt going into the chat, or any
  `claude -p` writing into it, makes Show it and the chip leave it alone
  and say so: showing it then would load it part way through. After a run's
  or the chip's request, the next queued run into that chat waits 30 s
  while the window shows it; a run into a chat a window opened while the
  run went on is followed by the same Show it, since that window loaded it
  part way.
- **The window's other idle chats.** Reload Webviews ends their processes
  as well; each starts again, from disk, when you open it.
- **The alert** says what to do by what became of the old process: `Show it
  in VS Code to see the run`, `... before typing in this chat` when it was
  left running, or to type in the terminal that holds it.
- **The extension** is 2.1.0, with `chatManagerReload.showFresh` (on); off,
  or without the Claude Code extension, it reloads as 0.5.0 did. The overlay
  asks through a file of its own, `data/open-request`, so a click and a
  run's request never overwrite each other. **Update the extension too:** a
  2.0.0 one would now offer a reload after `liveIdle: stop` runs as well.
- **Unchanged:** deletes, archives and new chats still reload the window.
  Whether Reload Webviews would do for them is S30.
- **Fixed:** the command lines chatq builds for its own child processes -
  the toast on PowerShell 7, the watcher, the console's index sync, the
  overlay - doubled only `'`. PowerShell also ends a quoted string on a
  curly quote, so a reply's excerpt with one could end the string early; all
  four are doubled now.
- **Which `code`.** The chip's `code -n` uses the `code.cmd` beside the VS
  Code that is running, before the one on PATH: a machine with two installs
  may have the other first on PATH. On the machine this was built on that
  was a system install left half-updated, whose `code` crashed every time,
  so the first real clicks raised no window. `watcher.log` now names the
  `code` that failed. `CHATQ_CODE` still overrides it.
- **Fixed:** a new index that could not be swapped in was dropped without a
  word. Anything reading the index at that moment - the overlay's console,
  its 10-minute sync, a virus scan - fails the swap, and a restored or new
  chat then stayed missing from Tab until the next sync. The swap now tries
  five times over about 0.4 s, then warns.
- **Layout: the script and `src/`.** The one file had passed 13,000 lines.
  `VS-code-chat-manager.ps1` now loads fourteen parts from `src/`, in the
  order the file had them; nothing they do changed, and the profile line,
  the watcher and the overlay still load the same path. Copying it by hand
  means copying `src/` with it; without a part it says which and loads
  nothing. The one-line installer downloads the repo as one zip, since
  files fetched one by one from raw.githubusercontent.com can come from two
  versions for minutes after a push. The self-test is split the same way,
  into `tests/sections/`.

## 0.5.0 — chatq in a window

- **`chatconsole`**, the overlay's window for chatq: pick a chat - cut off,
  open in VS Code, recent, or found by search - write to it, and send it now
  or queue it. Also the speech bubble on the overlay's buttons, **Open
  console** in the tray, and **Ctrl+Alt+Shift+Q** (`-ConsoleHotkey`). It
  takes the keyboard only when you open it, and closing it keeps the draft -
  the chat, the text, the files, the choices - across restarts too.
- **Files by drag and paste.** Drop files on the prompt, or paste a
  screenshot or files copied in Explorer with Ctrl+V; each is copied aside at
  once, off the window's thread, and moves into the job on Send.
- **Send now.** The job goes to the front and runs within seconds; a chat
  working in VS Code is looked at every 30 s rather than every 5 minutes. A
  line says beforehand what Send will do: a limit, a busy chat, a reload.
- **New chats.** + New chat starts a Claude chat in a folder, named by you or
  by the prompt's first line. Its session id is chosen when it is queued and
  handed to `claude -p --session-id` with `--name` (spike S25), so a retry
  after a limit continues that same chat, never a second one. The extension
  offers a window on that folder a reload to pick it up; whether VS Code's
  chat list then shows it is still to be checked (S25).
- **Cut off, marked.** The overlay colours chats the limit or a 529 stopped
  orange - `cut off - resets 13:00` - and gives one not open a row of its
  own; the console continues one, or all of them. It looks a week back for
  a limit still ahead, and otherwise at the last 12 hours; it looks again
  at once when a job or a chat's state changes, never reads a chat that is
  working, and reads a transcript again only once it changed.
- **The queue as a console.** Each job says where it stands; pick one for
  its reply, its log, and Try now, First, Remove, Cancel, Requeue or Write to
  this chat; a waiting prompt can be edited in place.
- **One job core.** `chatq`, `chatqrm`, `chatqrun`, `chatqlog` and the
  console make and change jobs through the same functions, and the commands
  print exactly what they did. The index is now written whole and swapped
  in, so a reader never sees half of it.
- **Fixed:** `chatqlog` on a job still running failed with "being used by
  another process" - the run holds its log open. `chatqrm -Force` on a job
  that ended meanwhile, with no watcher left, marked it failed and lost its
  result; it now says it had already ended.
- **No Reload to click on coming back.** A chat open in a VS Code window never
  shows a chatq run until that window reloads, and until now the window only
  ever asked. It reloads by itself now when, as the run ended, nobody had used
  the PC for `quietMinutes` (5 — the same clock that sends the alert to the
  phone) and no other chat in the folder was working or had been written in
  that time. It still asks at the PC (you may be typing in that very window),
  on an idle clock that cannot be read or `quietMinutes` 0, and in a window
  with more than one folder or opened on a parent one, since only the chat's
  own folder was judged. A window opened after the run already shows it, so
  it neither asks nor reloads - nor for a new chat a run started, which it
  lists already. A new chat is never reloaded for by itself.
- **The chat the run just wrote no longer counts as busy** for having just
  been written. What Claude says of its own open process still counts: after
  the run that can only be a window's, and it may be mid-answer.
- The busy check asks the job's own Claude home (`CLAUDE_CONFIG_DIR`) for its
  open sessions, not the watcher's.
- **A refused login says what Claude said.** Every 401 and 403 read as
  `Claude is logged out · run claude, then /login`, and nothing kept what
  Claude had actually said. A subscription that has run out is refused the
  same way, so on 2026-09-23 a lapsed plan was reported as a lost login, and
  afterwards there was no telling which it had been. The alert now quotes the
  API's own message — `Claude login refused: OAuth token has expired. (401) ·
  run claude, then /login, or check the subscription` — and so do
  `data/logs/watcher.log`, the `chatqlist` status line, the console's line
  before Send (which had called it "limited until") and the job's result.
  Codex the same, with `codex login`.
- **The watcher log keeps the whole error too**, on an `error text:` line of
  its own, type and all — the message alone does not say what kind of refusal
  it was.
- **The extension** has words for a new chat, and reloads by itself after a
  queued run as above; `chatManagerReload.autoReloadAfterRun: false` makes it
  always ask. Copy its files over the installed ones to update it (see the
  README for the update line).

## 0.4.0 — every running chat at a glance

- **`chatoverlay`** keeps a small panel in the top-right corner, above other
  windows. It shows every open Claude chat: its project, title, newest prompt,
  and a dot for what it is doing. Amber is waiting on you and goes to the top,
  green is working, grey is idle. A chat open in two windows is one row.
  Queued prompts appear on their chat's row, or as a purple row of their own
  when that chat is not open.
- **A slash command is the newest thing sent.** Claude Code does not count one
  as a prompt: after `/compact` its own record of the last prompt still names
  the one before. So the overlay reads the command from the transcript. While
  `/compact` runs nothing on disk names it yet, and the row says a command is
  running instead of showing the older prompt as current.
- **Usage at the top, live.** A line each for Claude, Codex and Copilot, as
  the collapsed panel has it, ending with when that figure is from - or, from
  the settings box or `-UsageView bars`, a bar in the server's own colour and
  a reset countdown per window. Claude's five-hour and weekly windows, and one
  model's weekly window once used; Codex's; Copilot's monthly quotas. Claude
  Code caches its figure only when a window opens its usage view, and here
  that copy read 55% while the account stood at 79%. So the overlay asks
  Claude's usage endpoint itself: every five minutes while a chat works, every
  fifteen while all are idle, as a window resets, and on the refresh button.
  It uses the login Claude Code saved, reads the token for that one request,
  and never stores, logs or refreshes it. An expired login or a refusal falls
  back to the cached figure, marked with its age. `-LiveUsage off` keeps to
  the cache.
- **Copilot's quota through the GitHub CLI.** VS Code keeps only the plan on
  disk, so the overlay runs `gh api copilot_internal/user` - what VS Code's
  Copilot status reads - every fifteen minutes and on refresh. `gh` keeps its
  own login and hands the overlay no token. No `gh`, or one not logged in,
  means no Copilot line; `-CopilotUsage off` stops asking.
- **It keeps to the endpoint's own wait.** Asked once a minute, the endpoint
  refused after about an hour and said to wait 48 minutes. So the overlay now
  asks every five, and when refused it waits as long as `Retry-After` says,
  showing `retry 11:22`. The refresh button does not ask inside
  that wait. The last live figure and the wait survive a restart.
- **Out of the way.** It never takes focus and clicks go through it. The tray
  dot, in the most urgent chat's colour, shows and hides it and has a menu.
  **Ctrl+Alt+Shift+O** unlocks it for dragging (`-Hotkey` changes the key),
  and it locks itself two minutes after the pointer leaves.
- **Buttons on its top edge when you point at it,** outside the panel and
  flush with its top-right corner: a grip to drag it by, collapse to one line
  (counts and usage), refresh usage, a settings box, hide to the tray, and
  close. Refresh turns while it asks and then says when Claude answered;
  Codex's figure is never asked for - it moves when Codex runs - and says it
  is from Codex's last run, with its date once over a week old. The settings
  box has an opacity slider, the theme (Dark, Light, or System to follow
  Windows' light or dark mode), and usage as lines or bars. The buttons are a
  small window of their own, so the panel never takes a click. The choices
  are kept in `config.json`; `chatoverlay -Theme`, `-Opacity`, `-UsageView`,
  `-Collapse` and `-Refresh` do the same from a shell.
- **Cheap.** One hidden Windows PowerShell, about 160 MB and under 0.1% CPU on
  this machine with ten chats open. It re-reads a file only once it changed,
  and a transcript only from where it stopped: the first look at a 20 MB chat
  reads its last 256 KB, where Claude Code writes each turn's prompt and title.
- **`chatoverlay -AutoStart on`** brings it back with every new shell, as the
  watcher comes back. Nothing is registered with the OS. `chatinstall` restarts a
  running overlay on the new copy, and `chatuninstall` stops it.
- **`chatoverlay -Print`** draws the same in the console. That is Linux's only
  view.
- **macOS, untested:** a floating panel and a `CQ` menu bar item, drawn by
  JavaScript for Automation, so nothing needs installing. Live usage is off
  there by default, since reading the login from the keychain asks for a
  password.
- **The watcher reads the same session list.** When `claude agents` cannot
  run, its fallback now reads `~/.claude/sessions/` the overlay's way. It also
  keeps what a chat is waiting for. A macOS-style `procStart` no longer rejects
  every session as a reused pid.

## 0.3.1 — no "safe to reload" while another chat is working

- **A chat running a workflow or a background agent is no longer called
  idle.** The turn that starts one ends at once, and the work writes only to
  its own files, so a minute later the check read the chat as finished. The
  terminal then said `safe to reload now`, and a reload would have killed the
  work. Now the transcript is searched for a start with no
  `<task-notification>` after it. Only starts since the chat's process began
  count: anything older died with an earlier process.
- **Claude's own word comes first.** A chat that `claude agents` lists as
  `busy` or `waiting` is active, whatever its transcript looks like.
- **The window's Reload offer says so too.** The request left for the
  extension now carries `busy`. While a chat works, the window warns — *A chat
  in this workspace is still working, and reloading now would cut it off* —
  with **Reload anyway**, and `autoReload` does not fire. Before, the button
  appeared the same either way, and the warning was only in the terminal. Copy
  `extension/` again to get this (see the README for the update line).

## 0.3.0 — files and screenshots with a queued prompt

- **`chatq <title> -Attach a.png, spec.pdf`** sends files with the prompt —
  images, text, code, PDF, as many as you like, a wildcard too
  (`.\shots\*.png`). They are copied into the job, `data/queue/<id>/`, before
  the prompt is written, so the originals can move or change in the hours
  before it sends. A file missing, or one that cannot be copied, queues
  nothing; the same file twice goes once.
- **`chatq <title> -Paste`** takes the clipboard as it is now: a screenshot, files
  copied in Explorer, or text — which becomes the prompt, or goes under the one
  given, quotes and all, and helps pick the chat as a typed prompt does.
  Windows only.
- **Ctrl+V in the editor tab.** VS Code saves a pasted image beside the prompt
  file, in `data/queue/`, and links it; chatq moves it into the job and points
  the link there. Checked again just before the job sends, so an image pasted
  into a prompt reopened with `chatq <n>` counts too. A link to any file
  outside `data/queue/` is left exactly as written and never opened by chatq:
  it names a file where it is, for the chat to open or change there — a copy
  would have it edit a snapshot, `../config.json` would reach chatq's own data,
  and a `\\host` path would open a connection to that host.
- **`chatq <n> -Attach` / `-Paste`** adds files to a job while it waits.
- **How each chat gets them.** Claude gets every path under the prompt,
  `Attached files - read each one:`, and opens them with its own Read tool — it
  sees an image as a picture and reads PDF — with `--add-dir` for the job's
  folder. Codex gets images properly, one `-i` each and a `--` so the thread id
  is never read as another image, and the other files under the prompt. A
  "continue" sends no files; they went with the prompt.
- `chatqlist` counts a job's files (`+2 files`), `chatq <n>` names them,
  `chatqrm` removes them with the job, and more than 10 files or 20 MB draws a
  warning.

## 0.2.1 — what a first day of real use turned up

- **A prompt typed after the title is caught.** `chatq <title> <some words>`
  reads every word as the title — that is what lets a title be typed without
  quotes — so the words meant for the chat went looking for one instead, and
  the pick was a guess. When the pick is a guess and what was typed reads like
  a prompt (six words or more, or a path or URL in it), `chatq` now says so and
  shows the `-Prompt` form.
- **The cut-off list names the chat.** It fell back to the transcript's uuid
  when the index had no row for that chat yet — which is exactly the state a
  chat the limit has just stopped is in. The title is read from the transcript
  instead, so it can go straight into the `-Continue` line printed under it.
- **The usage line no longer contradicts the status line above it.**
  `Claude 5h 0%` sat next to `Claude limited until 11:50`, because both
  providers' figures come from caches that refresh only when that tool itself
  runs. The window that is blocked now reads `limited` — `5h limited` for the
  five-hour one, `week limited` for a weekly one, a 529 neither — and a figure
  an hour old or more is marked `stale`.
- **`data/logs/jobs.log`** keeps a line per job event — queued, every state it
  moves through, and removals. A job's own history goes with its file, so until
  now a `chatqrm` left no trace at all, and where a job went could only be
  guessed from the watcher logging an empty queue.
- **`chatqnotify -ApiKey` takes the whole Join push URL**, quoted, and reads the
  key and device out of it. Unquoted it never arrives — PowerShell stops at the
  first `&` — so the help now says to paste the key alone.
- `chatq`'s cheat sheet said phone alerts went through Join. They also go to a
  desktop toast and to ntfy.

## 0.2.0 — chatrm and chatq in one tool: VS-code-chat-manager

The repo was chatq; it is now VS-code-chat-manager, and chatrm 1.3.0 is inside
it. The chatrm repo stays as it was.

- **One file, one index, one install.** chatrm's proven code is the base and the
  queue sits on top of it; chatq's copy of chatrm's index, readers, providers
  and scoping is gone.
  - Every command keeps its name. `chatqinstall` and `chatquninstall` fold into
    `chatinstall` and `chatuninstall`.
  - `chatinstall` replaces a profile line for chatrm or chatq with its own,
    since they define the same commands.
- **One Tab for all three.** The completer serves `chatrm`, `chatfind` and
  `chatq`, and `chatq` gets chatrm's one-line Tab cycling, so a multi-word title
  needs no opening quote any more. Subagent chats are no longer offered (the
  search skipped them, so Tab offered what it then could not find), `chatq` is
  never offered a Copilot chat, and a title that happens to be hex (`add…`,
  `cafe…`) completes instead of nothing.
- **Fixes carried from chatq into the chatrm half:** a Hangul Codex thread name
  is read as UTF-8; a Claude title with a quote in it comes back unescaped; a
  zero-width cell no longer throws; typographic apostrophes are quoted safely;
  the whole file is StrictMode-safe at load and in every key handler.
- **The two halves know each other.**
  - `chatrm` keeps a chat that has a prompt queued for it, and names the job;
    `-DropJobs` drops the jobs first, waiting out a running one.
  - A queued run into a chat still open in a window asks that window to reload,
    through the extension.
  - A Copilot title given to `chatq` is refused with the reason, never quietly
    swapped for another chat.
- **The extension** is now `phal40lax78.chat-manager-reload` 2.0.0, with
  `chatManagerReload.*` settings. It watches the new folder and the old chatrm
  one, says what happened (deleted, archived, a queued run), and never reloads
  unasked after a queued run.
- **Delete takes every leftover:** besides the sidecar folder, `file-history`
  and `session-env`, now `tasks`, `debug`, security state, telemetry, todos, a
  background job's folder, and the plan file when no other chat in the project
  shares its slug — after
  [claude-chats-delete](https://github.com/ataleckij/claude-chats-delete)'s
  inventory. They go only once the transcript is gone, so a chat a live window
  holds open keeps them.
- **Archive and restore.** `chatrm … -Archive` moves a Claude chat and its
  leftovers into `data/archive/`, or archives a Codex thread through
  `codex archive`; `chatrestore` lists and brings them back. `chatuninstall
  -All` will not delete an archive that is the only copy.
- **Retries that know when to stop.**
  - A dropped connection is retried after 1, 2 and 5 minutes. The count lives in
    the job, and chatq's own 4-hour cap is never mistaken for one.
  - An expired login holds that account's jobs, with one alert.
  - A job that breaks before any reply `maxRetries` (5) times in a row gives up;
    one that makes progress each time never does.
  - An overload past 6 hours sends one reminder.
- **More ways to hear about it:** a desktop toast (on by default), ntfy as JSON
  so Hangul survives, and a command of your own with the alert in its
  environment. The phone stays quiet while you are at the PC.
- **`chatq -Model`** runs one job on another model, and its probe asks with that
  model. **`-First`** (and `chatqrun <n> -First`) puts a job at the front, in one
  queue order the watcher, the list and the board all share.
- **Usage in `chatqlist`**: how much of Claude's and Codex's windows are used,
  from their own caches, with how old the figure is.
- **The watcher picks up an update:** `chatinstall` asks a running one to hand
  over after its current job. The successor carries on with what it knew —
  limits, overloads, alerts already sent.
- **The repo:** README badges, demo frames made by `docs/make-demo.ps1` from the
  real commands, a comparison with similar tools, CI on Windows PowerShell 5.1
  and PowerShell 7, a v0.2.0 release, and a mock sponsor badge until one is set
  up.

## 0.1.0 — first release

- **Queue a prompt for an existing chat** while the usage limit is hit:
  `chatq <title> -Prompt …`, or with no `-Prompt` in an editor tab named after
  the chat. `-Continue` queues a "continue" for a chat the limit cut off.
- **The chat is picked when you queue, and the pick is printed.** The order is
  id, then exact title, contains and every word. It searches this project
  before any other. When nothing matches, the guess comes from this project's
  chats. The newest candidate wins unless others were active within 5 hours,
  and then relevance decides: a character-bigram cosine that works for Hangul
  and English alike, with no model call.
- **A background watcher sends at the reset.**
  - It reads the reset time from Claude's own limit record in the transcript,
    or from Codex's rate-limit snapshot.
  - It confirms with a throwaway probe that saves nothing.
  - It then resumes each chat in its own folder and in the permission mode it
    last used, one job at a time.
  - Anything that would ask a question is denied, and the job is parked as
    needs-input.
  - A limit hit again mid-run requeues the job, as "continue" if the prompt had
    already landed.
- **Status.**
  - `chatqlist` shows one line per job, with long prompts summarised.
  - `chatq <n>` opens a prompt, and edits count until it is sent.
  - `chatqlist -Board` is a live markdown board for VS Code's preview.
  - `chatqlog <n>` shows what a run did.
- **`API Error: 529 Overloaded`** (and any other 5xx) is no longer a failure.
  - The job is requeued, as "continue" if the prompt had landed.
  - chatq watches `status.claude.com`'s JSON every minute and resumes as soon as
    the Claude Code component is operational.
  - An overload the page never shows is retried after 1, 2, 5 and 10 minutes,
    then every 15.
  - Chats you left stopped on a 529 are listed next to the limit-cut ones, for
    `-Continue`.
- **Phone alerts through Join** for started, needs input, done, failed,
  limited and overloaded. The key is DPAPI-protected on Windows. Titles start
  `chatq ·`, for Tasker filters.
- **Chats still open in a VS Code window.** A busy chat waits. An idle one runs
  with a "reload the window" note, or with `liveIdle: stop` its idle process is
  ended first.
- **Built for unattended runs.**
  - The machine is kept awake while a job is due within 6 h.
  - The watcher is restarted from the profile after a reboot.
  - API keys and the parent chat's session variables are kept out of runs.
  - Prompts go to the CLI as raw UTF-8, so Hangul survives Windows PowerShell
    5.1.
- **Limits are tracked per account and per model.**
  - A job queued under `CLAUDE_CONFIG_DIR` / `CODEX_HOME` keeps that account.
    Otherwise it runs in the default account, never the watcher's inherited one.
  - An Opus-only weekly limit holds up no other model.
  - A limit record older than an "allowed" probe no longer blocks the queue
    again.
- **Guesses stay inside a project.** From a folder that is no project, a title
  that matches nothing is refused, unless `-AllProjects` is given.
- **Works under a caller's `Set-StrictMode -Version Latest`.** On pwsh 7,
  timestamps read back from job files keep their time zone.
- One file, PowerShell 5.1 and 7, everything under `data/` beside the script.
  One-line install.
