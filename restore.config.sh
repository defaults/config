#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
BACKUP_DIR=""
DRY_RUN=0
INSTALL_BREW=1
INSTALL_CURSOR_EXTENSIONS=1
NVM_VERSION="v0.39.4"
RESTART_NOTES=()
SELECTED_CATEGORIES=()

usage() {
    cat <<'USAGE'
Usage: ./restore.config.sh [--dry-run] [--only category[,category...]] [--no-brew] [--no-cursor-extensions] [--list]

Restores portable developer settings from this repo to the current Mac.
Existing files are backed up under ~/.config-restore-backups/<timestamp>/.

Default is all categories.

Categories:
  homebrew  zsh  bash  shell  tmux  vim  git  asdf  ssh  cursor  ghostty

Examples:
  ./restore.config.sh --only bash
  ./restore.config.sh --only zsh,git
  ./restore.config.sh --only cursor --no-cursor-extensions
USAGE
}

list_categories() {
    printf '%s\n' homebrew zsh bash shell tmux vim git asdf ssh cursor ghostty
}

is_valid_category() {
    case "$1" in
        homebrew|zsh|bash|shell|tmux|vim|git|asdf|ssh|cursor|ghostty) return 0 ;;
        *) return 1 ;;
    esac
}

add_categories() {
    local value="$1"
    local category
    IFS=',' read -ra parts <<< "$value"
    for category in "${parts[@]}"; do
        [[ -z "$category" ]] && continue
        if ! is_valid_category "$category"; then
            echo "unknown category: $category" >&2
            echo "valid categories:" >&2
            list_categories >&2
            exit 2
        fi
        SELECTED_CATEGORIES+=("$category")
    done
}

want() {
    local candidate selected
    if [[ "${#SELECTED_CATEGORIES[@]}" -eq 0 ]]; then
        return 0
    fi

    for candidate in "$@"; do
        for selected in "${SELECTED_CATEGORIES[@]}"; do
            [[ "$selected" == "$candidate" ]] && return 0
        done
    done

    return 1
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --only)
            shift
            [[ "$#" -gt 0 ]] || { echo "--only requires a category" >&2; exit 2; }
            add_categories "$1"
            ;;
        --only=*)
            add_categories "${1#--only=}"
            ;;
        --no-brew) INSTALL_BREW=0 ;;
        --no-cursor-extensions) INSTALL_CURSOR_EXTENSIONS=0 ;;
        --list)
            list_categories
            exit 0
            ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
    esac
    shift
done

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf 'dry-run:'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

section() {
    echo
    echo "==> $1"
}

note_restart() {
    RESTART_NOTES+=("$1")
}

ensure_backup_dir() {
    if [[ -z "$BACKUP_DIR" ]]; then
        BACKUP_DIR="$HOME/.config-restore-backups/$(date '+%Y%m%d-%H%M%S')"
        run mkdir -p "$BACKUP_DIR"
    fi
}

backup_path_for() {
    local dest="$1"
    echo "$BACKUP_DIR${dest#$HOME}"
}

restore_file() {
    local src="$1"
    local dest="$2"

    if [[ ! -f "$src" ]]; then
        echo "skip missing $src"
        return
    fi

    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
        echo "unchanged $dest"
        return
    fi

    echo "restore $src -> $dest"
    if [[ -e "$dest" || -L "$dest" ]]; then
        local backup
        ensure_backup_dir
        backup="$(backup_path_for "$dest")"
        run mkdir -p "$(dirname "$backup")"
        run cp -p "$dest" "$backup"
        echo "backup $dest -> $backup"
    fi

    run mkdir -p "$(dirname "$dest")"
    run cp "$src" "$dest"
}

restore_dir() {
    local src="$1"
    local dest="$2"

    if [[ ! -d "$src" ]]; then
        echo "skip missing $src"
        return
    fi

    if [[ -d "$dest" ]] && diff -qr "$src" "$dest" >/dev/null 2>&1; then
        echo "unchanged directory $dest"
        return
    fi

    echo "restore directory $src -> $dest"
    if [[ -d "$dest" ]]; then
        local backup
        ensure_backup_dir
        backup="$(backup_path_for "$dest")"
        run mkdir -p "$(dirname "$backup")"
        run rsync -a "$dest"/ "$backup"/
        echo "backup $dest -> $backup"
    fi

    run mkdir -p "$dest"
    run rsync -a "$src"/ "$dest"/
}

install_homebrew_bundle() {
    local brewfile="$DOTFILES_DIR/homebrew/Brewfile"
    local brew_bin=""

    if [[ "$INSTALL_BREW" -ne 1 ]]; then
        echo "skip Homebrew install because --no-brew was provided"
        return
    fi

    if command -v brew >/dev/null 2>&1; then
        brew_bin="$(command -v brew)"
    elif [[ -x /opt/homebrew/bin/brew ]]; then
        brew_bin="/opt/homebrew/bin/brew"
    elif [[ -x /usr/local/bin/brew ]]; then
        brew_bin="/usr/local/bin/brew"
    fi

    if [[ -z "$brew_bin" ]]; then
        echo "Homebrew not found; installing Homebrew"
        run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        note_restart "Open a new shell after Homebrew install so brew shellenv/path changes are active."
        if [[ "$DRY_RUN" -eq 1 ]]; then
            echo "dry-run: skipping Homebrew bundle because brew is not available until install completes"
            return
        elif [[ -x /opt/homebrew/bin/brew ]]; then
            brew_bin="/opt/homebrew/bin/brew"
        elif [[ -x /usr/local/bin/brew ]]; then
            brew_bin="/usr/local/bin/brew"
        else
            echo "Homebrew install did not expose brew; open a new shell and rerun restore"
            return
        fi
    fi

    if [[ -f "$brewfile" ]]; then
        echo "installing Homebrew bundle from $brewfile"
        run "$brew_bin" bundle --file="$brewfile" --no-upgrade
    else
        echo "skip missing $brewfile"
    fi
}

install_oh_my_zsh() {
    local zshrc="$DOTFILES_DIR/zsh/zshrc"

    if [[ ! -f "$zshrc" ]] || ! grep -q '\.oh-my-zsh' "$zshrc"; then
        return
    fi

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "Oh My Zsh already installed"
        return
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo "git not found; install Xcode Command Line Tools, then rerun restore for Oh My Zsh"
        return
    fi

    echo "installing Oh My Zsh"
    run git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    note_restart "Open a new shell after Oh My Zsh install."
}

install_nvm() {
    local zshrc="$DOTFILES_DIR/zsh/zshrc"

    if [[ ! -f "$zshrc" ]] || ! grep -q 'NVM_DIR' "$zshrc"; then
        return
    fi

    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        echo "nvm already installed"
        return
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo "git not found; install Xcode Command Line Tools, then rerun restore for nvm"
        return
    fi

    echo "installing nvm $NVM_VERSION"
    run git clone https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
    run git -C "$HOME/.nvm" checkout "$NVM_VERSION"
    note_restart "Open a new shell before using nvm."
}

install_cursor_extensions() {
    local list_file="$DOTFILES_DIR/cursor/extensions.txt"
    local cursor_cli=""
    local installed_any=0

    if [[ "$INSTALL_CURSOR_EXTENSIONS" -ne 1 ]]; then
        echo "skip Cursor extensions because --no-cursor-extensions was provided"
        return
    fi

    if command -v cursor >/dev/null 2>&1; then
        cursor_cli="$(command -v cursor)"
    elif [[ -x "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]]; then
        cursor_cli="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    fi

    if [[ -z "$cursor_cli" ]]; then
        echo "Cursor CLI not found; install Cursor first, then rerun extension restore"
        return
    fi

    if [[ ! -f "$list_file" ]]; then
        echo "skip missing $list_file"
        return
    fi

    while IFS= read -r extension_id; do
        [[ -z "$extension_id" || "$extension_id" == \#* ]] && continue
        if "$cursor_cli" --list-extensions 2>/dev/null | grep -qx "$extension_id"; then
            echo "Cursor extension already installed $extension_id"
            continue
        fi
        echo "install Cursor extension $extension_id"
        run "$cursor_cli" --install-extension "$extension_id"
        installed_any=1
    done < "$list_file"
    if [[ "$installed_any" -eq 1 ]]; then
        note_restart "Restart Cursor after extension changes."
    fi
}

if want homebrew; then
    section "Install Homebrew packages"
    install_homebrew_bundle
fi

if want zsh shell; then
    section "Install zsh prerequisites"
    install_oh_my_zsh
    install_nvm
fi

if want zsh shell bash; then
    section "Restore shell config"
    if want zsh shell; then
        restore_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
        restore_file "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"
        restore_file "$DOTFILES_DIR/zsh/aliases" "$HOME/.config/zsh/aliases"
    fi

    if want shell; then
        restore_file "$DOTFILES_DIR/shell/profile" "$HOME/.profile"
    fi

    if want bash shell; then
        restore_file "$DOTFILES_DIR/bash/bash_profile" "$HOME/.bash_profile"
    fi
fi

if want tmux vim ghostty; then
    section "Restore terminal and editor config"
    if want tmux; then
        restore_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
    fi
    if want vim; then
        restore_file "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"
    fi
    if want ghostty; then
        restore_file "$DOTFILES_DIR/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    fi
fi

if want git asdf; then
    section "Restore git and version manager config"
    if want git; then
        restore_file "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
        restore_file "$DOTFILES_DIR/git/gitignore_global" "$HOME/.gitignore_global"
    fi
    if want asdf; then
        restore_file "$DOTFILES_DIR/asdf/tool-versions" "$HOME/.tool-versions"
    fi
fi

if want ssh; then
    section "Restore SSH config"
    restore_file "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
    if [[ "$DRY_RUN" -eq 0 && -f "$HOME/.ssh/config" ]]; then
        chmod 700 "$HOME/.ssh"
        chmod 600 "$HOME/.ssh/config"
    fi
fi

if want cursor; then
    section "Restore Cursor config"
    restore_file "$DOTFILES_DIR/cursor/User/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
    restore_file "$DOTFILES_DIR/cursor/User/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
    restore_dir "$DOTFILES_DIR/cursor/User/snippets" "$HOME/Library/Application Support/Cursor/User/snippets"
    install_cursor_extensions
fi

echo
echo "Restore complete."
if [[ "${#RESTART_NOTES[@]}" -gt 0 ]]; then
    echo
    echo "Restart/reopen notes:"
    printf ' - %s\n' "${RESTART_NOTES[@]}" | sort -u
fi
echo "Not restored by design: SSH private keys, known_hosts, cloud credentials, Docker state, Raycast state, Cursor CLI state/caches/globalStorage/workspaceStorage, Oh My Zsh generated state, nvm-installed Node versions, and app login tokens."
