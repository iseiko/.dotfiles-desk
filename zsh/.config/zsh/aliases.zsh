
alias ls='eza --icons=always '
alias ll='eza -lh --icons=always --git '
alias la='eza -lah --icons=always --git '
alias tree='eza -lh --tree --icons=always --git '

compdef eza=ls

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
  alias cat='batcat'
fi

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

alias -- -='cd -'

alias vim='nvim'

alias ytdown='yt-dlp -x --audio-format mp3 --add-metadata --embed-thumbnail -o "%(artist)s - %(title)s.%(ext)s" --audio-quality 0 --no-overwrites'

alias soft='sudo systemctl soft-reboot'
