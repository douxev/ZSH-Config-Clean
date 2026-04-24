#!/usr/bin/env bash

set -euo pipefail

C_OK=$'\033[1;32m' ; C_WARN=$'\033[1;33m' ; C_ERR=$'\033[1;31m' ; C_RST=$'\033[0m'
log()  { echo "${C_OK}[OK]${C_RST} $*" ; }
warn() { echo "${C_WARN}[WARN]${C_RST} $*" ; }
err()  { echo "${C_ERR}[ERR]${C_RST} $*" ; exit 1 ; }

[[ $EUID -eq 0 ]] && err "Ne lance pas ce script en root."
[[ -z "${HOME:-}" ]] && err "\$HOME n'est pas défini."

BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
log "Backups dans $BACKUP_DIR"

# -----------------------------------------------------------------------------
# 1. Backup
# -----------------------------------------------------------------------------
for f in "$HOME/.zshrc" "$HOME/.scripts/theme_omp.yaml" "$HOME/.config/starship.toml" ; do
  [[ -f "$f" ]] && cp -v "$f" "$BACKUP_DIR/" || true
done

# -----------------------------------------------------------------------------
# 2. Tools verif
# -----------------------------------------------------------------------------
echo
echo "${C_OK}── Vérification des outils ─────────────────────────────────${C_RST}"

MISSING=()

check_tool() {
  local name="$1" ; local install_hint="$2"
  if command -v "$name" >/dev/null 2>&1 ; then
    log "$name : $(command -v "$name")"
  else
    warn "$name : manquant — install : $install_hint"
    MISSING+=("$name")
  fi
}

if ! command -v starship >/dev/null 2>&1 ; then
  warn "starship n'est pas installé."
  echo -n "    L'installer maintenant via le script officiel ? [y/N] "
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]] ; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  else
    err "starship est requis. Installe-le puis relance le script."
  fi
fi
log "starship : $(starship --version | head -1)"

check_tool zoxide "cargo install zoxide  |  ou :  apt install zoxide"
check_tool atuin  "cargo install atuin   |  ou :  https://docs.atuin.sh/#install"
check_tool eza    "cargo install eza     |  ou :  apt install eza"

# bat : sur Debian/Ubuntu le binaire s'appelle batcat
if command -v bat >/dev/null 2>&1 ; then
  log "bat : $(command -v bat)"
elif command -v batcat >/dev/null 2>&1 ; then
  log "bat : $(command -v batcat)  (aliasé vers 'bat' dans .zshrc)"
else
  warn "bat : manquant — install : apt install bat  (le binaire s'appellera batcat)"
  MISSING+=("bat")
fi

check_tool fzf    "apt install fzf       |  ou :  git clone https://github.com/junegunn/fzf"

if (( ${#MISSING[@]} > 0 )) ; then
  echo
  warn "Outils manquants : ${MISSING[*]}"
  warn "Le .zshrc fonctionnera quand même (chargement conditionnel),"
  warn "mais certains alias/fonctions ne marcheront pas."
  echo
fi

# -----------------------------------------------------------------------------
# 3. Config starship (thème Nord fidèle au theme_omp.yaml)
# -----------------------------------------------------------------------------
mkdir -p "$HOME/.config"
cat > "$HOME/.config/starship.toml" <<'STARSHIP_EOF'
# ~/.config/starship.toml
# Thème Nord inspiré fidèlement du theme_omp.yaml
# Ligne 1 : ╭─[ path ] ⏱ durée ✓/✘  ... [droite]  git  heure  batterie
# Ligne 2 : ╰─🟢🟡🟠 ▶

# ─── Clés racine (AVANT toute section [table]) ───
add_newline = false
palette     = "nord"

format = """
[╭─](nord13)[\\[](nord11)\
$directory\
[\\]](nord11) \
$cmd_duration\
$status\
$line_break\
[╰─](nord13)[](nord14)[](nord13)[](nord12) [](nord13) \
$character"""

right_format = """$git_branch$git_status$time$battery"""

# ─── Palette Nord ───
[palettes.nord]
nord0  = "#2E3440"
nord1  = "#3B4252"
nord2  = "#434C5E"
nord3  = "#4C566A"
nord4  = "#D8DEE9"
nord5  = "#E5E9F0"
nord6  = "#ECEFF4"
nord7  = "#8FBCBB"
nord8  = "#88C0D0"
nord9  = "#81A1C1"
nord10 = "#5E81AC"
nord11 = "#BF616A"
nord12 = "#D08770"
nord13 = "#EBCB8B"
nord14 = "#A3BE8C"
nord15 = "#B48EAD"

[character]
success_symbol = "[❯](nord13)"
error_symbol   = "[❯](nord11)"
vimcmd_symbol  = "[❮](nord14)"

[directory]
format            = "[$path]($style)[$read_only]($read_only_style)"
style             = "nord15"
home_symbol       = "󰋜"
truncation_length = 3
truncation_symbol = "…/"
read_only         = " 🔒"
read_only_style   = "nord11"

[directory.substitutions]
# Supprime le slash après l'icône maison : "󰋜/Downloads" → "󰋜 Downloads"
"󰋜/" = "󰋜 "

[cmd_duration]
format            = "[󱑓 $duration]($style) "
style             = "nord10"
min_time          = 0
show_milliseconds = true

[status]
format         = "[$symbol]($style)"
symbol         = "✘ "
success_symbol = "[󰸞 ](nord14)"
style          = "nord11"
disabled       = false

[git_branch]
format = "[  $branch]($style) "
style  = "nord13"

[git_status]
format     = "([$all_status$ahead_behind]($style) )"
style      = "nord13"
conflicted = "="
ahead      = "⇡${count} "
behind     = "⇣${count} "
diverged   = "⇕ ⇡${ahead_count} ⇣${behind_count} "
untracked  = "?${count} "
stashed    = "󰆼 ${count} "
modified   = " ${count} "
staged     = " ${count} "
renamed    = "»${count} "
deleted    = "✘${count} "

[time]
disabled    = false
format      = "[ $time ]($style)"
style       = "nord7"
time_format = "%H:%M"

[battery]
format   = "[$symbol$percentage]($style) "
disabled = false

[[battery.display]]
threshold          = 10
style              = "nord11"
discharging_symbol = "󰁺 "
charging_symbol    = "󰢜 "

[[battery.display]]
threshold          = 30
style              = "nord12"
discharging_symbol = "󰁼 "
charging_symbol    = "󰂆 "

[[battery.display]]
threshold          = 60
style              = "nord13"
discharging_symbol = "󰁾 "
charging_symbol    = "󰂈 "

[[battery.display]]
threshold          = 90
style              = "nord14"
discharging_symbol = "󰂀 "
charging_symbol    = "󰂊 "

[[battery.display]]
threshold          = 100
style              = "nord14"
discharging_symbol = "󰁹 "
charging_symbol    = "󰂅 "

[rust]
format   = "[$symbol($version )]($style)"
symbol   = "🦀 "
style    = "nord11"
disabled = false

[python]
format   = "[$symbol$pyenv_prefix($version )(\\($virtualenv\\) )]($style)"
symbol   = "🐍 "
style    = "nord13"
disabled = false

[nodejs]
format   = "[$symbol($version )]($style)"
symbol   = " "
style    = "nord14"
disabled = false

# Modules désactivés (perf)
[aws]
disabled = true
[gcloud]
disabled = true
[azure]
disabled = true
[kubernetes]
disabled = true
[docker_context]
disabled = true
[package]
disabled = true
[java]
disabled = true
[ruby]
disabled = true
[php]
disabled = true
[lua]
disabled = true
[golang]
disabled = true
[c]
disabled = true
[cmake]
disabled = true
[haskell]
disabled = true
[helm]
disabled = true
[terraform]
disabled = true
[username]
disabled = true
[hostname]
disabled = true
[memory_usage]
disabled = true
STARSHIP_EOF
log "Config starship écrite : ~/.config/starship.toml"

# -----------------------------------------------------------------------------
# 4. new .zshrc
# -----------------------------------------------------------------------------
cat > "$HOME/.zshrc" <<'ZSHRC_EOF'
# ~/.zshrc — zsh pur + starship + atuin (thème Nord)

# -----------------------------------------------------------------------------
# Historique zsh
# -----------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt EXTENDED_HISTORY
setopt INTERACTIVE_COMMENTS

# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]] ; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# -----------------------------------------------------------------------------
# Key bindings
# -----------------------------------------------------------------------------
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# -----------------------------------------------------------------------------
# Plugins (sourcés directement, pas d'oh-my-zsh)
# -----------------------------------------------------------------------------
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Colored man pages
man() {
  env \
    LESS_TERMCAP_mb=$'\e[01;31m'      LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m'          LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m'   LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    man "$@"
}

# -----------------------------------------------------------------------------
# Environment variables
# -----------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH:$HOME/go/bin"
export EDITOR=vim
export VISUAL=vim
export QT_QPA_PLATFORM=wayland
export XAUTHORITY="$HOME/.Xauthority"

# Fix Xwayland authorization
if [[ "${XDG_SESSION_TYPE:-}" = "wayland" ]] ; then
  XAUTH_FILE=$(ps aux | grep -oP '/run/user/[0-9]+/\.mutter-Xwaylandauth\.[A-Z0-9]+' | head -1)
  [[ -n "$XAUTH_FILE" ]] && export XAUTHORITY="$XAUTH_FILE"
fi

# Cargo / Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# NVM (chargé en lazy)
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
  nvm "$@"
}
node() { unset -f node ; nvm use default >/dev/null 2>&1 ; node "$@" ; }
npm()  { unset -f npm  ; nvm use default >/dev/null 2>&1 ; npm  "$@" ; }

# SSH agent (une seule instance)
if ! pgrep -u "$USER" ssh-agent >/dev/null ; then
  eval "$(ssh-agent -s)" >/dev/null
fi

# -----------------------------------------------------------------------------
# Prompt : starship + transient (style Nord, reproduit du theme_omp.yaml)
# -----------------------------------------------------------------------------
eval "$(starship init zsh)"

# Transient prompt : <#EBCB8B>󰋜 {cwd} </> (équivalent du transient oh-my-posh)
_transient_prompt_widget() {
  emulate -L zsh
  [[ $CONTEXT == start ]] || return 0
  while true ; do
    zle .recursive-edit
    local -i ret=$?
    [[ $ret == 0 && $KEYS == $'\4' ]] || break
    [[ -o ignore_eof ]] || exit 0
  done
  local saved_prompt=$PROMPT saved_rprompt=$RPROMPT
  # Nord13 = #EBCB8B (jaune chaud)
  # Icône 󰋜 remplace ~ : dans $HOME → "󰋜", ailleurs dans $HOME → "󰋜 sousdir", sinon path
  local display_path
  if [[ "$PWD" == "$HOME" ]] ; then
    display_path="󰋜"
  elif [[ "$PWD" == "$HOME"/* ]] ; then
    display_path="󰋜 ${PWD#$HOME/}"
  else
    display_path="$PWD"
  fi
  PROMPT="%F{#EBCB8B}${display_path} ❯%f "
  RPROMPT=''
  zle .reset-prompt
  PROMPT=$saved_prompt
  RPROMPT=$saved_rprompt
  if (( ret )) ; then zle .send-break ; else zle .accept-line ; fi
  return ret
}
zle -N zle-line-init _transient_prompt_widget

# -----------------------------------------------------------------------------
# Autres outils (chargés seulement s'ils sont installés)
# -----------------------------------------------------------------------------
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"

[[ -f "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
command -v atuin >/dev/null && eval "$(atuin init zsh)"

# -----------------------------------------------------------------------------
# Aliases — basiques
# -----------------------------------------------------------------------------
alias plz="sudo "
alias py=python3
alias bat=batcat
alias zset="vim ~/.zshrc"
alias nvim="~/.scripts/nvim-linux-x86_64.appimage -c 'Neotree toggle'"
alias galias='~/.scripts/galias.sh'
alias nano="vim"
alias "sudo nano"="sudo vim"

# Listing (eza)
alias ll="eza -lm -h -F -L 2 --no-user --git"
alias la="eza -lam -h -F -L 2 --no-user --git"
alias ls="eza -GF --icons"
alias l="eza -GF --icons"

# Dev
alias m="make -j"
alias mm="make -C build -j"
alias display="python3 ~/.scripts/DISPLAY_UNIFIED.py"
alias header="~/.scripts/header.out"
alias demodulate="python3 ~/.scripts/demodulate.py"

# Historique
alias history="atuin search -i"

# Custom
alias prout="echo prout"

# -----------------------------------------------------------------------------
# Fonctions
# -----------------------------------------------------------------------------
unlock() { ssh-add ; }

fmenu() {
  local cmd
  cmd=$(printf "%s\n" "$@" | fzf --height=20% --reverse --cycle --info=inline -m --no-mouse)
  [[ -n $cmd ]] && eval "$cmd"
}

push() {
  git add .
  git commit -m "$*"
  git push
}

checkout() {
  local branch
  branch=$(git branch | grep -v "^\*" | fzf --height=20% --reverse --info=inline)
  [[ -n "$branch" ]] && git checkout "$(echo "$branch" | xargs)"
}

commits() {
  local sha
  sha=$(git log --pretty=format:"%h %s (%an, %ar)" | \
        fzf --height=20% --reverse --info=inline --no-multi \
            --delimiter=" " \
            --preview "echo {} | cut -d' ' -f1 | xargs git show --color=always" | \
        cut -d" " -f1)
  [[ -n "$sha" ]] && git checkout "$sha"
}

clean-git() {
  git fetch --prune
  git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
}

g() { fmenu 'push' 'git log' 'git branch -a' 'git pull' ; }
d() { fmenu 'docker kill $(docker ps -a -q)' 'docker ps -a' 'lazydocker' ; }
s() { fmenu 'exec zsh' 'reset' 'atuin search -i' ; }
ZSHRC_EOF
log "Nouveau ~/.zshrc écrit"

# -----------------------------------------------------------------------------
# 5. Final
# -----------------------------------------------------------------------------
cat <<EOF

${C_OK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RST}
${C_OK} Installation terminée — thème Nord actif${C_RST}
${C_OK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RST}

Backups   : $BACKUP_DIR
Starship  : $(starship --version | head -1)

${C_WARN}À faire :${C_RST}
  1. Teste : ${C_OK}exec zsh${C_RST}
  2. Pour revenir en arrière : cp $BACKUP_DIR/.zshrc ~/
EOF

if (( ${#MISSING[@]} > 0 )) ; then
cat <<EOF
  3. Installe les outils manquants : ${MISSING[*]}
EOF
fi

cat <<EOF

${C_WARN}Notes :${C_RST}
  • oh-my-zsh n'est plus sourcé. Pour le virer : rm -rf ~/.oh-my-zsh
  • Cache oh-my-posh à nettoyer :  rm -rf ~/.cache/oh-my-posh
  • NVM est chargé en lazy : \`node\` ou \`npm\` l'initialise au 1er appel
  • Mesurer chaque segment :  starship timings
  • Les icônes Nerd Font (󰋜, , etc.) nécessitent une Nerd Font dans ton terminal

EOF
