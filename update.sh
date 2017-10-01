#!/bin/sh
set -e

"pulling my recent config"
git pull

"Updating tmux config"
cat tmux_config.conf > ~/.tmux.conf

"done with Tmux!!"

"Updating vim config"

echo "putting custom/extra config file to my_configs.vim"
cat vim_config.vim > ~/.vim_runtime/my_configs.vim

echo "Installing all plugins using Vundle"
vim +PluginInstall +qall

"changing diractory to ~/.vim_runtime"
cd ~/.vim_runtime

"Git pull with rebase - awsome vimrc"
git pull --rebase

"Sucessfully updated vim config!"
