# Pull in brew binaries
export PATH="/usr/local/bin:$PATH"

alias pyserv="python3 -m http.server --cgi"
alias config="subl ~/.bash_profile"
alias reload="source ~/.bash_profile"
alias dotfiles="cd ~/coding/dotfiles"
alias phoenixconfig="subl ~/.phoenix.js"

alias coding="cd ~/coding"
alias st3="cd /Users/oskarols/Library/Application\ Support/Sublime\ Text\ 3/"

alias ll="ls -la"

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

export GIT_EDITOR="code --wait"
export VISUAL="code --wait"
export EDITOR="code --wait"

# pyenv auto completions
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# nvm
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

# To use Homebrew's directories rather than ~/.pyenv add to your profile:
# export PYENV_ROOT=/usr/local/var/pyenv


# starting redis:
# redis-server /usr/local/etc/redis.conf

# auto start pyenv-virtualenv
# if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

alias matrix="cmatrix -C red -n -s"