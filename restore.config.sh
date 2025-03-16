#!/bin/bash
# restore_configs.sh
#
# This script restores configuration files from your dotfiles repo
# into your system based on the mappings defined below.
#
# Configurations handled:
#   - zsh: restores ~/.zshrc and ~/.config/zsh/aliases
#   - bash: restores ~/.bash_profile
#   - tmux: restores ~/.config/tmux/tmux.conf
#   - vim: restores ~/.vimrc
#
# Adjust REPO_DIR if your dotfiles repo is located elsewhere.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dotfiles"

# Define an array of repo file (relative path) and destination pairs
config_files=(
    "zsh/.zshrc:$HOME/.zshrc"
    "zsh/aliases:$HOME/.config/zsh/aliases"
    "bash/.bash_profile:$HOME/.bash_profile"
    "tmux/tmux.conf:$HOME/.config/tmux/tmux.conf"
    "vim/vimrc:$HOME/.vimrc"
)

echo "Restoring configuration files from your dotfiles repo..."

for file in "${config_files[@]}"; do
    repo_file="${file%%:*}"
    dest="${file##*:}"
    src="$REPO_DIR/$repo_file"
    echo "Processing: $src"
    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dest")"
        # Backup the existing destination file if it exists
        if [[ -f "$dest" ]]; then
            cp "$dest" "$dest.bak"
            echo "Backup created for $dest -> ${dest}.bak"
        fi
        cp "$src" "$dest"
        echo "Restored: $src -> $dest"
    else
        echo "Warning: $src not found in repo, skipping."
    fi
done

echo "Ensuring essential tools are installed..."

### Homebrew
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Restore Homebrew taps from the saved list
if [ -f "$REPO_DIR/homebrew/taps.list" ]; then
    while IFS= read -r tap; do
        if ! brew tap | grep -q "^$tap\$"; then
            echo "Tapping $tap..."
            brew tap "$tap"
        fi
    done < "$REPO_DIR/homebrew/taps.list"
fi

if [ -f "$REPO_DIR/Brewfile" ]; then
    echo "Installing Homebrew packages from Brewfile..."
    brew bundle --file="$REPO_DIR/Brewfile"
else
    echo "Warning: Brewfile not found in repo."
fi

### Zsh
if ! command -v zsh &> /dev/null; then
    echo "zsh not found. Installing zsh via Homebrew..."
    brew install zsh
fi

# (Optional) Install oh-my-zsh if desired
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh not found. Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

### Tmux
if ! command -v tmux &> /dev/null; then
    echo "tmux not found. Installing tmux via Homebrew..."
    brew install tmux
fi

# Install TPM (Tmux Plugin Manager) if not present
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "TPM not found. Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

### Vim
if ! command -v vim &> /dev/null; then
    echo "vim not found. Installing vim via Homebrew..."
    brew install vim
fi

echo "Installing vim plugins (if configured with vim-plug)..."
vim +PlugInstall +qall

### Trigger Tmux Plugin Install (via TPM)
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing tmux plugins via TPM..."
    tmux new-session -d -s temp_session "sleep 2; ~/.tmux/plugins/tpm/bin/install_plugins; tmux kill-session -t temp_session"
fi

echo "Restore complete. Your system now reflects your dotfiles and plugin customizations."