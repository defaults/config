#!/bin/bash
# export_configs.sh
#
# This script copies your key developer configuration files
# (including plugin configuration and Homebrew settings)
# into your dotfiles Git repository.
#
# Configurations handled:
#   - zsh: ~/.zshrc and aliases from ~/.config/zsh/aliases
#   - bash: ~/.bash_profile (if any)
#   - tmux: ~/.config/tmux/tmux.conf
#   - vim: ~/.vimrc (and indirectly the vim_runtime folder if you manage it separately)
#   - Homebrew: Brewfile and taps
#
# Adjust REPO_DIR to point to your local dotfiles repository.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dotfiles"
CONFIG_DIR="$REPO_DIR/dotfiles"

# Ensure base directories exist in your repo
mkdir -p "$CONFIG_DIR/zsh" "$CONFIG_DIR/bash" "$CONFIG_DIR/tmux" "$CONFIG_DIR/vim" "$CONFIG_DIR/homebrew"

# Define an array of source files and their corresponding destination paths
config_files=(
    "$HOME/.zshrc:zsh/.zshrc"
    "$HOME/.config/zsh/aliases:zsh/aliases"
    "$HOME/.bash_profile:bash/.bash_profile"
    "$HOME/.config/tmux/tmux.conf:tmux/tmux.conf"
    "$HOME/.vimrc:vim/vimrc"
)

echo "Config files: ${!config_files[@]}"
echo "Exporting configuration files to your dotfiles repo..."

for file in "${config_files[@]}"; do
    src="${file%%:*}"
    dest="$CONFIG_DIR/${file##*:}"
    echo "Processing: $src"
    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dest")"
        echo "$src -> $dest"
        cp "$src" "$dest"
        echo "Copied: $src -> $dest"
    else
        echo "Skipping: $src not found."
    fi
done

echo "Extracting plugin configurations..."

### Zsh: Extract the plugin line (if using oh-my-zsh style) from ~/.zshrc
if [ -f "$HOME/.zshrc" ]; then
    grep '^plugins=(' "$HOME/.zshrc" > "$CONFIG_DIR/zsh/zsh_plugins_config.list"
    echo "Extracted zsh plugin configuration to $CONFIG_DIR/zsh/zsh_plugins_config.list"
fi

### Tmux: Extract plugin lines (if using TPM) from tmux.conf
if [ -f "$HOME/.config/tmux/tmux.conf" ]; then
    grep '^set -g @plugin' "$HOME/.config/tmux/tmux.conf" > "$CONFIG_DIR/tmux/tmux_plugins_config.list"
    echo "Extracted tmux plugin configuration to $CONFIG_DIR/tmux/tmux_plugins_config.list"
fi

### Vim: Extract vim-plug plugin lines from ~/.vimrc
if [ -f "$HOME/.vimrc" ]; then
    grep -E "Plug\s+'[^']+'" "$HOME/.vimrc" > "$CONFIG_DIR/vim/vim_plugins_config.list"
    echo "Extracted vim plugin configuration to $CONFIG_DIR/vim/vim_plugins_config.list"
fi

### Homebrew:
# Dump a Brewfile of installed formulae and casks
echo "Exporting Homebrew configuration..."
brew bundle dump --describe --file="$CONFIG_DIR/Brewfile" --force

# Export Homebrew taps (taps are treated like plugins)
brew tap > "$CONFIG_DIR/homebrew/taps.list"
echo "Exported Homebrew taps list to $CONFIG_DIR/homebrew/taps.list"

# Commit and push changes to your repo
cd "$REPO_DIR" || { echo "Dotfiles repo not found!"; exit 1; }
git add .
git commit -m "Update configs and plugin lists $(date '+%Y-%m-%d %H:%M:%S')"
git push

echo "Export complete. Your dotfiles repo is up to date."