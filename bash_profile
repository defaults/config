if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
  __GIT_PROMPT_DIR=$(brew --prefix)/opt/bash-git-prompt/share
  source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
fi

# set the standardized VISUAL and EDITOR environment variables for programs like Git
export VISUAL=vim
export EDITOR="$VISUAL"

# set alias

# mapping vim to use mac vim (bypass to use updated vim in macOS)
alias vim="/Applications/MacVim.app/Contents/MacOS/Vim"

# mapping vi to vim
alias vi="vim"

export PATH=/Users/vikakumar/Life/Personal/google-cloud-sdk/completion.bash.inc:$PATH
export PATH=/Users/vikakumar/Life/Personal/google-cloud-sdk/path.bash.inc:$PATH

# Setting PATH for Python 2.7
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"
export PATH

# Add environment variable COCOS_CONSOLE_ROOT for cocos2d-x
export COCOS_CONSOLE_ROOT=/Users/vikakumar/Downloads/cocos2d-x-3.15.1/tools/cocos2d-console/bin
export PATH=$COCOS_CONSOLE_ROOT:$PATH

# Add environment variable COCOS_X_ROOT for cocos2d-x
export COCOS_X_ROOT=/Users/vikakumar/Downloads
export PATH=$COCOS_X_ROOT:$PATH

# Add environment variable COCOS_TEMPLATES_ROOT for cocos2d-x
export COCOS_TEMPLATES_ROOT=/Users/vikakumar/Downloads/cocos2d-x-3.15.1/templates
export PATH=$COCOS_TEMPLATES_ROOT:$PATH

# Add environment variable ANT_ROOT for cocos2d-x
export ANT_ROOT=/usr/local/apache-ant/bin
export PATH=$ANT_ROOT:$PATH

# Add environment variable NDK_ROOT for cocos2d-x
export NDK_ROOT=/Users/vikakumar/Life/AndroidDev/android-ndk-r10e
export PATH=$NDK_ROOT:$PATH

# Add environment variable ANDROID_SDK_ROOT for cocos2d-x
export ANDROID_SDK_ROOT=/Users/vikakumar/Life/AndroidDev/sdk
export PATH=$ANDROID_SDK_ROOT:$PATH
export PATH=$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools:$PATH

# alias for cocos build
alias cocos_build="cocos run -s ~/Life/Zynga/butterchicken/client/ -p android --android-studio"
