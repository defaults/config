# My Tmux and Vim config file

Sharing my vim and Tmux config with script to install and update.

## Vim Config
My vim config is on top of awesome and quite popular vim config by Amir Salihefendic [https://github.com/amix] checkout https://github.com/amix/vimrc. I have added few new plugings on top of it to customize for me.

Plugins/Features added by me:
- Valloric/YouCompleteMe - Vim autocomplete
- fisadev/vim-ctrlp-cmdpalette - `<leader>c` to get command palette and fuzzy search it
- airblade/vim-gitgutter - Git diff inside vim
- surround.vim - all about surround
- delimitMate.vim - to add auto closing brackets, quotes etc.
- coloriser - see color on top of hex/reg in files
- TaskList.vim - task list like eclipse

## Tmux Config
Will update all features and keyword mapping soon.. :-P

## Installation
Git clone and run setup.sh, it pulls awsome vim sets it up and applies my cofig on top of it
```
$ git clone https://github.com/codervikash/config.git
$ sh ./config/setup.sh
```

## Updating
Git pull and run update.sh, it updates awsome vim as well as my cofig file
```
$ git pull origin master
$ sh update.sh
```

## Contributing:
Your contributions are always welcome, please fork thhe repo and send a PR. TO file bug raise a issue or directly contact me on my [mail](mailto:mailkumarvikash@gmail.com) or reach on twitter [@codervikash](https://twitter.com/codervikash)

## Licence
MIT
