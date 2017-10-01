#!/bin/sh
set -e

echo "My vim setup is based in 'amix/vimrc' cloning it"
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime

echo "calling awsome vimrc install script"
sh ~/.vim_runtime/install_awesome_vimrc.sh

echo "putting custom/extra config file to my_configs.vim"
cat my_configs.vim > ~/.vim_runtime/my_configs.vim

echo "Installing all plugins using Vundle"
vim +PluginInstall +qall

echo "Everything done!! Enjoy."
