#!/bin/sh
set -e

echo "pulling my recent config"
git pull

echo "Updating tmux config"
cat tmux_config.conf > ~/.tmux.conf

echo "done with Tmux!!"

echo "Updating vim config"

echo "putting custom/extra config file to my_configs.vim"
cat vim_config.vim > ~/.vim_runtime/my_configs.vim

echo "Installing all plugins using Vundle"
vim +PluginInstall +qall

echo "changing diractory to ~/.vim_runtime"
cd ~/.vim_runtime

echo "Git pull with rebase - awsome vimrc"
git pull --rebase

echo "source vimrc file"
vim vim -c ~/.vimrc

echo "source tmux file"
tmux source ~/.tmux.conf

echo "Sucessfully updated vim config!"
