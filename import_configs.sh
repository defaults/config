#!/usr/bin/env bash
set -euo pipefail

# Export portable developer settings from this Mac into the repo.
# This script intentionally does not commit or push.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
SELECTED_CATEGORIES=()

usage() {
    cat <<'USAGE'
Usage: ./import_configs.sh [--only category[,category...]] [--list]

Exports portable developer settings from this Mac into the repo.
Default is all categories.

Categories:
  homebrew  zsh  bash  shell  tmux  vim  git  asdf  ssh  cursor  ghostty  raycast

Examples:
  ./import_configs.sh --only bash
  ./import_configs.sh --only zsh,git
  ./import_configs.sh --only cursor --only ghostty
USAGE
}

list_categories() {
    printf '%s\n' homebrew zsh bash shell tmux vim git asdf ssh cursor ghostty raycast
}

is_valid_category() {
    case "$1" in
        homebrew|zsh|bash|shell|tmux|vim|git|asdf|ssh|cursor|ghostty|raycast) return 0 ;;
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
        --only)
            shift
            [[ "$#" -gt 0 ]] || { echo "--only requires a category" >&2; exit 2; }
            add_categories "$1"
            ;;
        --only=*)
            add_categories "${1#--only=}"
            ;;
        --list)
            list_categories
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
    shift
done

copy_file() {
    local src="$1"
    local dest="$2"

    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        echo "copied $src -> $dest"
    else
        echo "skip missing $src"
    fi
}

copy_dir() {
    local src="$1"
    local dest="$2"

    if [[ -d "$src" ]]; then
        mkdir -p "$dest"
        rsync -a --delete "$src"/ "$dest"/
        echo "synced $src -> $dest"
    else
        echo "skip missing $src"
    fi
}

copy_cursor_settings() {
    local src="$HOME/Library/Application Support/Cursor/User/settings.json"
    local dest="$DOTFILES_DIR/cursor/User/settings.json"

    if [[ ! -f "$src" ]]; then
        echo "skip missing $src"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    if command -v jq >/dev/null 2>&1; then
        jq 'del(."vs-kubernetes", ."geminicodeassist.project")' "$src" > "$dest"
        echo "copied sanitized Cursor settings -> $dest"
    else
        cp "$src" "$dest"
        echo "copied raw Cursor settings because jq is unavailable -> $dest"
    fi
}

write_raycast_extensions() {
    local src="$HOME/.config/raycast/extensions"
    local output="$DOTFILES_DIR/raycast/extensions.txt"

    mkdir -p "$(dirname "$output")"
    if [[ ! -d "$src" ]]; then
        : > "$output"
        echo "Raycast extensions directory not found; wrote empty list -> $output"
        return
    fi

    : > "$output"
    while IFS= read -r package_file; do
        local name title
        name="$(awk -F'"' '/"name"[[:space:]]*:/ { print $4; exit }' "$package_file")"
        title="$(awk -F'"' '/"title"[[:space:]]*:/ { print $4; exit }' "$package_file")"
        if [[ -n "$name" ]]; then
            if [[ -n "$title" ]]; then
                printf "%s\t%s\n" "$name" "$title" >> "$output"
            else
                printf "%s\n" "$name" >> "$output"
            fi
        fi
    done < <(find "$src" -mindepth 2 -maxdepth 2 -name package.json -print | sort)

    sort -u "$output" -o "$output"
    echo "wrote Raycast extension inventory -> $output"
}

write_cursor_extensions() {
    local output="$DOTFILES_DIR/cursor/extensions.txt"
    local cursor_cli=""

    if command -v cursor >/dev/null 2>&1; then
        cursor_cli="$(command -v cursor)"
    elif [[ -x "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]]; then
        cursor_cli="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    fi

    mkdir -p "$(dirname "$output")"
    if [[ -n "$cursor_cli" ]]; then
        "$cursor_cli" --list-extensions 2>/dev/null | sort -u > "$output" || true
        echo "wrote Cursor extension list -> $output"
    else
        : > "$output"
        echo "Cursor CLI not found; wrote empty extension list -> $output"
    fi
}

mkdir -p "$DOTFILES_DIR"

if want zsh shell; then
    copy_file "$HOME/.zshrc" "$DOTFILES_DIR/zsh/zshrc"
    copy_file "$HOME/.zprofile" "$DOTFILES_DIR/zsh/zprofile"
    copy_file "$HOME/.config/zsh/aliases" "$DOTFILES_DIR/zsh/aliases"

    if [[ -f "$HOME/.zshrc" ]]; then
        grep '^plugins=(' "$HOME/.zshrc" > "$DOTFILES_DIR/zsh/zsh_plugins_config.list" || true
    fi
fi

if want shell; then
    copy_file "$HOME/.profile" "$DOTFILES_DIR/shell/profile"
fi

if want bash shell; then
    copy_file "$HOME/.bash_profile" "$DOTFILES_DIR/bash/bash_profile"
fi

if want tmux; then
    copy_file "$HOME/.config/tmux/tmux.conf" "$DOTFILES_DIR/tmux/tmux.conf"

    if [[ -f "$HOME/.config/tmux/tmux.conf" ]]; then
        grep '^set -g @plugin' "$HOME/.config/tmux/tmux.conf" > "$DOTFILES_DIR/tmux/tmux_plugins_config.list" || true
    fi
fi

if want vim; then
    copy_file "$HOME/.vimrc" "$DOTFILES_DIR/vim/vimrc"

    if [[ -f "$HOME/.vimrc" ]]; then
        grep -E "Plug[[:space:]]+'[^']+'" "$HOME/.vimrc" > "$DOTFILES_DIR/vim/vim_plugins_config.list" || true
    fi
fi

if want git; then
    copy_file "$HOME/.gitconfig" "$DOTFILES_DIR/git/gitconfig"
    copy_file "$HOME/.gitignore_global" "$DOTFILES_DIR/git/gitignore_global"
fi

if want asdf; then
    copy_file "$HOME/.tool-versions" "$DOTFILES_DIR/asdf/tool-versions"
fi

# SSH config is portable. Private keys and known_hosts are intentionally excluded.
if want ssh; then
    copy_file "$HOME/.ssh/config" "$DOTFILES_DIR/ssh/config"
fi

if want cursor; then
    copy_cursor_settings
    copy_file "$HOME/Library/Application Support/Cursor/User/keybindings.json" "$DOTFILES_DIR/cursor/User/keybindings.json"
    copy_dir "$HOME/Library/Application Support/Cursor/User/snippets" "$DOTFILES_DIR/cursor/User/snippets"
    write_cursor_extensions
fi

if want ghostty; then
    copy_file "$HOME/Library/Application Support/com.mitchellh.ghostty/config" "$DOTFILES_DIR/ghostty/config"
    copy_file "$HOME/.config/ghostty/config" "$DOTFILES_DIR/ghostty/config"
fi

if want raycast; then
    write_raycast_extensions
fi

if want homebrew; then
    if command -v brew >/dev/null 2>&1; then
        mkdir -p "$DOTFILES_DIR/homebrew"
        brew bundle dump --describe --file="$DOTFILES_DIR/homebrew/Brewfile" --force
        brew tap > "$DOTFILES_DIR/homebrew/taps.list"
        echo "exported Homebrew bundle -> $DOTFILES_DIR/homebrew/Brewfile"
    else
        echo "Homebrew not found; skipping Brewfile export"
    fi
fi

echo
echo "Export complete. Review with: git diff --stat && git diff"
