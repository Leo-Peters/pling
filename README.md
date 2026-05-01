# pling

Make your taskbar flash and play a sound when a long-running task finishes — or when an AI agent (Claude Code, Aider, Codex CLI, …) needs your attention.

## Platform support

| Platform | Taskbar flash | Desktop notification | Sound |
|---|---|---|---|
| WSL2 / Windows Terminal | FlashWindowEx (orange taskbar) | Toast (via PowerShell) | MediaPlayer / paplay / aplay / mpv |
| Linux (GNOME/KDE/X11) | xdotool urgency hint | notify-send | paplay / aplay / mpv |
| macOS | Dock bounce | osascript notification | afplay |
| Windows (native PowerShell) | FlashWindowEx | Toast notification | Console beep |
| Fallback | Terminal bell (`\a`) | — | — |

## Install

### Linux / macOS / WSL2

```bash
git clone https://github.com/Leo-Peters/pling.git
sudo cp pling/pling pling/out-of-nowhere-message-tone.mp3 /usr/local/bin/
sudo chmod +x /usr/local/bin/pling
```

The mp3 next to the script enables the bundled-sound fallback. Skip it if you'll set your own sound via `--set-sound`.

### Windows (native PowerShell)

```powershell
git clone https://github.com/Leo-Peters/pling.git
Copy-Item pling\pling.ps1 -Destination "C:\Tools\"   # or anywhere on your PATH
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

## AI agent integration

`pling` is agent-agnostic — it just flashes and plays a sound. To get pinged when an agent finishes a turn, paste the snippet for your agent into the matching config file. Each snippet assumes `pling` is on your `PATH` at `/usr/local/bin/pling`; adjust the path if not.

### Claude Code — `~/.claude/settings.json`

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "/usr/local/bin/pling -m 'Claude finished'" }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          { "type": "command", "command": "/usr/local/bin/pling -m 'Claude needs input'" }
        ]
      }
    ]
  }
}
```

If `settings.json` already exists, merge the `hooks` key in — don't overwrite the file.

### Aider — `~/.aider.conf.yml`

```yaml
notifications_command: "/usr/local/bin/pling -m 'Aider finished'"
```

You also need to launch aider with `--notifications` (or set `notifications: true` in the same file) so it actually fires the command.

### Codex CLI — `~/.codex/config.toml`

```toml
[features]
codex_hooks = true

[[hooks.Stop]]

[[hooks.Stop.hooks]]
type = "command"
command = "/usr/local/bin/pling -m 'Codex finished'"
timeout = 30
```

If your config already has a `[features]` table, add `codex_hooks = true` to it instead of declaring `[features]` twice.

### Anything else (Cursor, Gemini CLI, Continue, …)

These don't have a native finish-event hook. Fall back to the shell-chain pattern:

```bash
agent-cli && pling                 # post-command chain
pling -- agent-cli                 # wrap (preserves exit code)
```

## Options

```
-m MSG            Notification message (default: "Task complete")
-s FILE           Play a sound file (.wav, .mp3, .ogg)
--set-sound FILE  Save a default sound so you never need -s again
-h, --help        Show help
```

## Sound configuration

Sound resolution order (first match wins):

1. `-s FILE` flag on the current invocation
2. Path saved via `--set-sound`, stored in `~/.config/pling/config`
3. The bundled `out-of-nowhere-message-tone.mp3` if it sits next to the `pling` script
4. No sound — flash + notification only

Set a persistent default:

```bash
pling --set-sound ~/sounds/done.wav
```

> If you copy only the `pling` script to `/usr/local/bin/`, the bundled mp3 won't follow it. To keep audio working out-of-the-box, copy the mp3 alongside (or run `pling --set-sound /path/to/it`).

Sample sound from [Notification Sounds](https://notificationsounds.com).

## How it works

1. **Taskbar flash** — On WSL2, pling calls the Win32 `FlashWindowEx` API via PowerShell to make the taskbar button flash orange. On Linux it uses `xdotool` urgency hints. On macOS it bounces the Dock icon.
2. **Desktop notification** — Uses `notify-send` (Linux), Windows Toast (WSL2/Windows), or `osascript` (macOS).
3. **Sound** — Plays the configured sound file using whichever audio player is available (`paplay`, `aplay`, `afplay`, `mpv`, or Windows `MediaPlayer`).
4. **Fallback** — If nothing else works, prints the terminal bell character (`\a`).

## Requirements

**Bash version:**
- Bash 4+
- Optional: `notify-send`, `xdotool`, `osascript`, `paplay`/`aplay`/`afplay`/`mpv`

**PowerShell version:**
- PowerShell 5.1+ (ships with Windows 10/11)

## Credits

Sample sound from [Notification Sounds](https://notificationsounds.com).

## License

MIT — see [LICENSE](LICENSE).
