# pling

Make your taskbar flash and play a sound when a long-running task finishes — or when Claude needs your attention.

## Platform support

| Platform | Taskbar flash | Desktop notification | Sound |
|---|---|---|---|
| WSL2 / Windows Terminal | FlashWindowEx (orange taskbar) | Toast (via PowerShell) | MediaPlayer / paplay / aplay / mpv |
| Linux (GNOME/KDE/X11) | xdotool urgency hint | notify-send | paplay / aplay / mpv |
| macOS | Dock bounce | osascript notification | afplay |
| Windows (native PowerShell) | FlashWindowEx | Toast notification | Console beep |
| Fallback | Terminal bell (`\a`) | — | — |

## Install

Copy the script somewhere on your PATH:

```bash
# Bash (WSL2 / Linux / macOS)
cp pling /usr/local/bin/

# PowerShell (Windows)
Copy-Item pling.ps1 -Destination "C:\Tools\"   # or anywhere on your PATH
```

## Usage

```bash
# Flash the taskbar
pling

# Flash after a command finishes
make build; pling

# Wrap a command — flash when it exits (preserves exit code)
pling -- make build

# Flash with a custom notification message
pling -m "Build done"

# Flash and play a sound
pling -s ~/sounds/done.wav

# Save a default sound so you never need -s again
pling --set-sound ~/sounds/done.wav
```

PowerShell equivalent:

```powershell
.\pling.ps1
.\pling.ps1 -Message "Build done"
cargo build; .\pling.ps1
```

## Claude Code integration

```bash
pling --install-hook
```

This writes two hooks into `~/.claude/settings.json`:

- **Stop** — runs `pling -m 'Claude finished'` whenever Claude finishes generating output.
- **Notification** — runs `pling -m 'Claude needs input'` whenever Claude asks a question or needs your approval.

The PowerShell version installs the Stop hook into `%USERPROFILE%\.claude\settings.json`:

```powershell
.\pling.ps1 -InstallHook
```

The install is idempotent — running it again won't create duplicates.

## Options

```
-m MSG            Notification message (default: "Task complete")
-s FILE           Play a sound file (.wav, .mp3, .ogg)
--set-sound FILE  Save a default sound so you never need -s again
--install-hook    Install as a Claude Code hook
-h, --help        Show help
```

## Sound configuration

Set a persistent default sound file so every invocation plays audio automatically:

```bash
pling --set-sound ~/sounds/done.wav
```

This saves the path to `~/.config/pling/config`. You can override it per-invocation with `-s`.

A sample sound (`out-of-nowhere-message-tone.mp3`) is included in this repo. Sounds from [Notification Sounds](https://notificationsounds.com).

## How it works

1. **Taskbar flash** — On WSL2, pling calls the Win32 `FlashWindowEx` API via PowerShell to make the taskbar button flash orange. On Linux it uses `xdotool` urgency hints. On macOS it bounces the Dock icon.
2. **Desktop notification** — Uses `notify-send` (Linux), Windows Toast (WSL2/Windows), or `osascript` (macOS).
3. **Sound** — Plays the configured sound file using whichever audio player is available (`paplay`, `aplay`, `afplay`, `mpv`, or Windows `MediaPlayer`).
4. **Fallback** — If nothing else works, prints the terminal bell character (`\a`).

## Requirements

**Bash version:**
- Bash 4+
- `python3` (only needed for `--install-hook` when `settings.json` already exists)
- Optional: `notify-send`, `xdotool`, `osascript`, `paplay`/`aplay`/`afplay`/`mpv`

**PowerShell version:**
- PowerShell 5.1+ (ships with Windows 10/11)

## Credits

Sample sound from [Notification Sounds](https://notificationsounds.com).

## License

MIT — see [LICENSE](LICENSE).
