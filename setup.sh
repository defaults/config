#!/bin/sh
set -e

echo "checking if homebrew present"
if ! hash brew 2>/dev/null; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "checking if wget present, installing if not"
if ! hash wget 2>/dev/null; then
    brew install wget --with-libressl
fi
echo "install source-code pro font"
brew tap caskroom/fonts && brew cask install font-source-code-pro

echo "My vim setup is based in 'amix/vimrc' cloning it"
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime

echo "calling awsome vimrc install script"
sh ~/.vim_runtime/install_awesome_vimrc.sh

echo "putting custom/extra vim config file to vim_config.vim"
cat vim_config.vim > ~/.vim_runtime/my_configs.vim

echo "Install Vundle"
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

echo "Installing all plugins using Vundle"
vim +PluginInstall +qall
vim +GoInstallBinaries

echo "installing cmake, required for YouCompleteMe"
wget -qO- https://cmake.org/files/v3.10/cmake-3.10.0-rc5.tar.gz | tar xvz -C ~/Downloads
cd ~/Downloads/cmake-3.10.0-rc5
./bootstrap
make
make install
cd ..
rm -rf cmake-3.10.0-rc5

echo "switching to YouCompleteMe"
cd ~/.vim_runtime/my_plugins/YouCompleteMe
./install.py --clang-completer

echo "source vimrc file"
vim vim -c ~/.vimrc

echo "install tmux"
brew install tmux

echo "putting tmux config file to tmux_config.conf"
cat tmux_config.conf > ~/.tmux.conf

echo "cloning tmux plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "source tmux file"
tmux source ~/.tmux.conf

echo "installing tmux plugins"
# start a server but don't attach to it
tmux start-server
# create a new session but don't attach to it either
tmux new-session -d
# install the plugins
~/.tmux/plugins/tpm/scripts/install_plugins.sh
# killing the server is not required, I guess
tmux kill-server

echo "installing node js"
echo 'export PATH=$HOME/local/bin:$PATH' >> ~/.bashrc
. ~/.bashrc
mkdir ~/local
mkdir ~/node-latest-install
cd ~/node-latest-install
curl http://nodejs.org/dist/node-latest.tar.gz | tar xz --strip-components=1
./configure --prefix=~/local
make install # ok, fine, this step probably takes more than 30 seconds...
curl https://www.npmjs.org/install.sh | sh

echo "putting bash_profile to~/.bash_profile"
cat bash_profile.conf > ~/.bash_profile
source ~/.bash_profile

echo "Everything done!! Enjoy."
