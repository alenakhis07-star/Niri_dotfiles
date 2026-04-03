
function run_fastfetch() {
    # Получаем ширину терминала
    local term_width=$(tput cols)

    if [ "$term_width" -gt 62 ]; then
        # Если окно широкое — выводим всё как обычно (цвета подтянутся из конфига)
        fastfetch
    else
        # Если окно узкое — скрываем логотип, чтобы текст не разъехался
        fastfetch --logo none
    fi
}
#function run_fastfetch() {
#  echo ""
#  pokemon-colorscripts -r --no-title
#}


export EDITOR="nvim"
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


# Запуск
run_fastfetch
# --- Powerlevel10k Instant Prompt ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[[ $- != *i* ]] && return

# --- History ---
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups  # Удаляет старые дубликаты из истории
# --- Подключение плагинов и тем ---
source ~/powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh


eval "$(zoxide init zsh)"
# Настройка fzf
autoload -U compinit; compinit
source ~/somewhere/fzf-tab.plugin.zsh

# Заменяем стандартный ls на eza с иконками и цветами
alias ls='eza -a --icons=always --color=always --group-directories-first'
alias ll='eza -lh --icons=always --group-directories-first'
alias la='eza -a --icons=always --group-directories-first'
alias lt='eza --tree --icons=always' # Вывод деревом (очень красиво)
alias vim='nvim'
alias sudo='sudo '
# --- Prompt & Keys ---
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
# Для клавиши Delete
bindkey "^[[3~" delete-char

# Для других возможных кодов
bindkey "^[3;5~" delete-char  # Ctrl+Delete
bindkey "^[3~" delete-char    # Обычный Delete
