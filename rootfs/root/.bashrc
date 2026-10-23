export TERM=xterm-256color
export MICRO_TRUECOLOR=1
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'

# MicroPython on an ESP32 (mpremote)
esp()     { mpremote "$@"; }
esp-run() { mpremote run "$1"; }
esp-up()  { mpremote cp "$1" :main.py + reset; }
esp-ls()  { mpremote ls; }
