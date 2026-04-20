# shell-config

Minimalist zsh configuration with [starship](https://starship.rs/), Nord theme, transient prompt and fast startup.

![Prompt preview](preview.svg)

Replaces `oh-my-zsh` + `oh-my-posh` with pure zsh + starship. All useful plugins (autosuggestions, syntax highlighting, completion, colored man pages) are kept but sourced directly, without a framework layer.

## Features

- **Two-line prompt** with Nord palette: path with home icon, command duration, `✓`/`✘` status, git branch with change counters, time, battery.
- **Transient prompt**: validated prompts collapse to `󰋜 path ❯`, keeping history readable.
- **Conditional home icon**: `󰋜` alone in `$HOME`, `󰋜 subdir` elsewhere.
- **Fast startup**: ~50–100 ms versus 400+ ms with oh-my-zsh + oh-my-posh.
- **Lazy-loaded NVM**: only initialized on the first `node`/`npm` call.
- **Cached `compinit`**: checks `.zcompdump` once a day.
- **atuin and zoxide integration** if installed.

## Requirements

- zsh
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal (for the `󰋜`, ``, ``, `` glyphs and friends)
- `curl` (to install starship if it's missing)

Optional tools detected at install time and loaded conditionally:

| Tool | Role | Install on Debian/Ubuntu |
|---|---|---|
| `starship` | prompt engine (required) | official install script |
| `zoxide` | smart `cd` based on frecency | `apt install zoxide` |
| `atuin` | searchable, enriched shell history | `curl -sS https://setup.atuin.sh \| sh` |
| `eza` | modern `ls` replacement | `apt install eza` |
| `bat` | `cat` replacement with syntax highlighting | `apt install bat` |
| `fzf` | fuzzy finder (used by the `g`, `d`, `s` functions) | `apt install fzf` |

## Installation

A single script handles everything — backup of existing config, tool detection, writing `~/.config/starship.toml` and `~/.zshrc`.

```bash
git clone https://github.com/<user>/shell-config.git
cd shell-config
bash setup-shell.sh
exec zsh
```

The script is idempotent: you can re-run it without breaking anything. Each run creates a timestamped backup at `~/.config-backup-YYYYMMDD-HHMMSS/`.

## Prompt structure

```
╭─[ 󰋜 path ] 󱑓 duration ✓/✘                     branch [status]  hh:mm  󰁹 %
╰─    ❯ 
```

| Segment | Role | Color (Nord palette) |
|---|---|---|
| `╭─` `╰─` | decorative arms | nord13 (warm yellow) |
| `[ ]` | path delimiters | nord11 (red) |
| `󰋜 path` | home icon and path truncated to 3 levels | nord15 (purple) |
| `󱑓 duration` | command duration with milliseconds | nord10 (blue) |
| `✓` / `✘` | previous command status | nord14 green / nord11 red |
| `   ` | three decorative diamonds | nord14 / nord13 / nord12 |
| `❯` | final chevron (green on success, red on error) | nord13 / nord11 |
| ` branch` | current git branch | nord13 |
| `[ ... ]` | git status (added, modified, untracked, ahead/behind) | nord13 |
| ` hh:mm` | time | nord7 (cyan) |
| `󰁹 %` | battery (icon and color vary with level) | nord11 → nord14 |

## Bundled shortcuts

zsh functions using `fzf` for interactive selection:

| Command | Role |
|---|---|
| `checkout` | interactive branch checkout |
| `commits` | interactive commit checkout (with preview) |
| `push "message"` | `git add . && git commit -m "..." && git push` |
| `clean-git` | delete local branches whose remote is gone |
| `g` | fzf menu: push / log / branches / pull |
| `d` | fzf docker menu: kill all / ps -a / lazydocker |
| `s` | fzf shell menu: reset / exec zsh / atuin history |
| `unlock` | `ssh-add` to load SSH keys into the agent |

## Customization

All colors live in the `[palettes.nord]` palette inside `~/.config/starship.toml`. Changing a single entry (e.g. `nord13` for warm yellow) propagates to every segment that uses it.

To add your own aliases or environment variables without modifying this repo, create `~/.zshrc.local` and append the following to your `~/.zshrc`:

```bash
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

## Uninstall

```bash
# Restore the previous config
cp ~/.config-backup-YYYYMMDD-HHMMSS/.zshrc ~/
rm ~/.config/starship.toml

# Optional: clean up leftovers
rm -rf ~/.oh-my-zsh ~/.cache/oh-my-posh
```

## License

MIT
