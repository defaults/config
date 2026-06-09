# Developer Mac Config

This repo is the portable source of truth for developer settings that should move between Macs.

Use Git for this instead of a one-time folder copy. The files live in different places on macOS, but the scripts map those places into one repo layout and back again. That gives you repeatable setup for a new Mac and ongoing sync between machines.

## What Is Tracked

- Shell: `dotfiles/zsh/zshrc -> ~/.zshrc`, `dotfiles/zsh/zprofile -> ~/.zprofile`, `dotfiles/shell/profile -> ~/.profile`, `~/.config/zsh/aliases`
- Terminal/editor tools: Oh My Zsh dependency, nvm dependency, tmux, standalone Vim config, asdf `.tool-versions`
- Homebrew: `dotfiles/homebrew/Brewfile`
- Git: `dotfiles/git/gitconfig -> ~/.gitconfig`, optional `dotfiles/git/gitignore_global -> ~/.gitignore_global`
- SSH: `~/.ssh/config` only
- Cursor: sanitized user `settings.json`, `keybindings.json`, snippets, and extension list
- Ghostty: terminal config
- Raycast: extension inventory only, for manual reinstall/reference

## What Is Not Tracked

These are intentionally excluded because they are secret, large, or machine-specific:

- SSH private keys, `known_hosts`, and generated agent sockets
- `~/.config/gcloud`, GitHub `hosts.yml`, 1Password, Docker, Kubernetes, and other token stores
- Docker config/state, including `~/.docker/config.json`, contexts, buildx state, and app settings
- Raycast installed extension bundles, app database, AI history, preferences, and account/login state
- Cursor CLI config, agent permission state, `globalStorage`, `workspaceStorage`, history, logs, extension binaries, MCP caches, and full project caches
- Full `~/.oh-my-zsh` and `~/.nvm` checkouts, generated shell caches, and installed Node versions
- Old `~/.vim_runtime`; the repo now carries a standalone Vim config instead
- App caches and login sessions

Move secrets through 1Password, cloud provider login flows, SSH key generation/import, or each tool's official migration flow.

## Export From This Mac

Run this whenever the current Mac has the settings you want to preserve:

```sh
./import_configs.sh
git diff --stat
git diff
git add .
git commit -m "Update developer Mac config"
git push
```

The export script does not commit or push automatically.

## Restore On A New Mac

Clone the repo, inspect what would change, then restore:

```sh
git clone git@github.com:codervikash/config.git ~/Life/config
cd ~/Life/config
./restore.config.sh --dry-run
./restore.config.sh
```

The restore script backs up replaced files under:

```text
~/.config-restore-backups/<timestamp>/
```

Useful variants:

```sh
./restore.config.sh --no-brew
./restore.config.sh --no-cursor-extensions
./restore.config.sh --only bash
./restore.config.sh --only zsh,git
./restore.config.sh --only cursor --no-cursor-extensions
```

Both import and restore support partial categories:

```sh
./import_configs.sh --list
./restore.config.sh --list
./import_configs.sh --only vim
./restore.config.sh --only vim
```

Available categories are `homebrew`, `zsh`, `bash`, `shell`, `tmux`, `vim`, `git`, `asdf`, `ssh`, `cursor`, `ghostty`; import also supports `raycast`.

## New Mac Checklist

1. Install Xcode Command Line Tools: `xcode-select --install`
2. Sign in to 1Password and enable the SSH agent if Git commit signing or GitHub SSH depends on it.
3. Clone this repo and run `./restore.config.sh --dry-run`.
4. Run `./restore.config.sh`.
5. Sign in again to tools that should not be copied: GitHub CLI, Google Cloud, Docker, Cursor, npm, Kubernetes, and cloud provider CLIs.
6. Open Cursor and verify Settings Sync is either disabled or intentionally aligned with this repo.
7. Clone active projects separately under `~/Life` or your preferred workspace path.
8. Open Raycast and use Raycast Sync/export for full state if you want it; use `dotfiles/raycast/extensions.txt` only as a lightweight reference.
9. Open Docker Desktop or OrbStack and recreate machine-specific contexts/login state manually.
10. Install project-specific Node versions with `nvm install` as needed.

## Notes

Cursor project state is not portable and is intentionally not tracked. Clone/open projects separately on each Mac.

Cursor settings are sanitized on export to remove machine-specific Kubernetes tool paths and project-specific Gemini state.

Managed home dotfiles use visible names inside the repo, then restore to hidden names on the target Mac. Example: `dotfiles/zsh/zshrc` restores to `~/.zshrc`.

Restore is idempotent: it installs prerequisites first, skips unchanged files, backs up only files it actually changes, and prints restart/reopen notes for tools that need it.

Keep this repo boring. Add files only when they are plain text, portable, reproducible, and safe to publish to a private Git repo. Prefer app-native sync/manual login for anything with tokens, caches, databases, machine IDs, or large generated state.
