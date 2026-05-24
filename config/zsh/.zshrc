# ─── Базовый .zshrc с автодополнением и подсветкой синтаксиса ───

# Путь к вашим скриптам
export PATH="$HOME/.local/bin:$PATH"

# История
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Автодополнение
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# Плагины
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Приглашение: user@host в цвете
autoload -U colors && colors
PROMPT='%B%F{blue}%n%f@%F{green}%m%f %F{yellow}%~%f%b %# '
