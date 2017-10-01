#!/bin/sh
set -e

"pulling my recent config"
git pull

echo "putting custom/extra config file to my_configs.vim"
cat my_configs.vim > ~/.vim_runtime/my_configs.vim

echo "Installing all plugins using Vundle"
vim +PluginInstall +qall

"changing diractory to ~/.vim_runtime"
cd ~/.vim_runtime

"Git pull with rebase - awsome vimrc"
git pull --rebase

"Sucessfully updated!"
