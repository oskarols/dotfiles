# Pull in brew binaries / Fix Ubuntu not pulling this in automatically
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

# To use Homebrew's directories rather than ~/.pyenv add to your profile:
# export PYENV_ROOT=/usr/local/var/pyenv


# starting redis:
# redis-server /usr/local/etc/redis.conf

# auto start pyenv-virtualenv
# if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

alias matrix="cmatrix -C red -n -s"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias gpwl="git push origin HEAD --force-with-lease"
alias gbranch="git for-each-ref --sort='authordate:iso8601' --format=' %(authordate:relative)%09%(refname:short)' refs/heads"
alias gb="git for-each-ref --sort=committerdate refs/heads/ --format='%(color:green)%(committerdate:relative)%(color:reset)%09%(HEAD) %(color:yellow)%(refname:short)%(color:reset)%09%09%(contents:subject)'"
alias gpush="git push origin HEAD"
alias grebasemaster="git checkout master && git pull && git checkout - && git rebase master"
alias gs="git status"
alias gresetlast="git reset --soft HEAD~1 && git reset HEAD ."

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Show git branch name
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\[\033[32m\]osol\[\033[00m\]:\[\033[36m\]\w\[\033[00m\]\[\033[33m\]\$(parse_git_branch)\[\033[00m\]$ "

n ()
{
    # Block nesting of nnn in subshells
    if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi

    # The default behaviour is to cd on quit (nnn checks if NNN_TMPFILE is set)
    # To cd on quit only on ^G, remove the "export" as in:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    nnn "$@"

    if [ -f "$NNN_TMPFILE" ]; then
            . "$NNN_TMPFILE"
            rm -f "$NNN_TMPFILE" > /dev/null
    fi
}

# Conf editor for nnn
export VISUAL=code
