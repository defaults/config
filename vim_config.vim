set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin("~/.vim_runtime/my_plugins")

" let Vundle manage Vundle,
Plugin 'VundleVim/Vundle.vim'

" You complete me
Plugin 'Valloric/YouCompleteMe'

" Extension of CtrlP plugin - command palette
Plugin 'fisadev/vim-ctrlp-cmdpalette'

" A Vim plugin which shows a git diff in the gutter
Plugin 'airblade/vim-gitgutter'

" surround vim
Plugin 'surround.vim'

" for insert mode auto-completion for quotes, parens, brackets, etc
Plugin 'delimitMate.vim'

" coloriser - for chowing css/scss colors
Plugin 'colorizer'

" Tasklist for vim
Plugin 'TaskList.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" check also when just opened the file
let g:syntastic_check_on_open = 1
" don't put icons on the sign column (it hides the vcs status icons of signify)
let g:syntastic_enable_signs = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
" custom icons (enable them if you use a patched font, and enable the previous 
" setting)
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '⚠'
let g:syntastic_style_error_symbol = '✗'
let g:syntastic_style_warning_symbol = '⚠'
let g:syntastic_check_on_wq = 0
let g:syntastic_python_checkers=['python']


" set relative number
set relativenumber

" no show mode as already shown in statusbar
set noshowmode

" commands finder mapping
nmap ,c :CtrlPCmdPalette<CR>

" for selected command to be executed by default
let g:ctrlp_cmdpalette_execute = 1

let g:gitgutter_async = 0
let g:gitgutter_realtime = 1

" Tasklist ------------------------------

" show pending tasks list
map <F2> :TaskList<CR>

nmap ,cc <Plug>Colorizer

" open shell sourcing bashrc file
set shell=bash\ --login
