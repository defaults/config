#!/bin/sh
set -e

echo "My vim setup is based in 'amix/vimrc' cloning it"
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime

echo "calling awsome vimrc install script"
sh ~/.vim_runtime/install_awesome_vimrc.sh

echo "putting custom/extra vim config file to vim_config.vim"
cat vim_config.vim > ~/.vim_runtime/my_configs.vim

echo "Installing all plugins using Vundle"
vim +PluginInstall +qall

echo "putting tmux config file to tmux_config.conf"
cat tmux_config.conf > ~/.tmux.conf

echo "Everything done!! Enjoy."
