#!/usr/bin/env bash
# =============================================================
# cybermonk-session.sh
# Launches the full CyberMonk tmux environment — 9 named windows
# Run standalone: ./cybermonk-session.sh
# Or from anywhere after install: cybermonk
# =============================================================

SESSION="cybermonk"

# ── Tune these if shells still race (oh-my-zsh / slow machine) ───────────────
WIN_DELAY=0.8    # seconds to wait after new-session / new-window
PANE_DELAY=0.4   # seconds to wait after split-window

# ── If session exists, just attach ───────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "↩  Session '$SESSION' already running — attaching..."
    exec tmux attach-session -t "$SESSION"
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
has()     { command -v "$1" &>/dev/null; }
send()    { tmux send-keys -t "${SESSION}:${1}" "$2" Enter; }
pane()    { tmux select-pane -t "${SESSION}:${1}.${2}"; }
new_win() { tmux new-window   -t "$SESSION" -n "$1"; sleep "$WIN_DELAY"; }
split_h() { tmux split-window -h -p "$1"    -t "${SESSION}:${2}"; sleep "$PANE_DELAY"; }
split_v() { tmux split-window -v -p "$1"    -t "${SESSION}:${2}"; sleep "$PANE_DELAY"; }

# =============================================================
# WINDOW 0: MONK  ·  Editor · Git · Shell
# ┌──────────────────────┬──────────────┐
# │                      │      1       │
# │          0           │   lazygit    │
# │    editor / shell    ├──────────────┤
# │                      │      2       │
# │                      │    shell     │
# └──────────────────────┴──────────────┘
# =============================================================
tmux new-session -d -s "$SESSION" -n "MONK"
sleep "$WIN_DELAY"

split_h 30 "MONK"        # pane 2 = right 30%
split_v 50 "MONK.2"      # pane 3 = bottom-right

pane "MONK" 2
has lazygit \
    && send "MONK" "lazygit" \
    || send "MONK" "echo '  lazygit not found — run: brew install lazygit'"

pane "MONK" 1
send "MONK" "claude /morning-briefing"
# pane 3 stays as a clean shell

# =============================================================
# WINDOW 1: FILES  ·  Navigation & Preview
# ┌─────────────────────┬───────────────┐
# │                     │               │
# │          0          │       1       │
# │    yazi (file mgr   │  bat / glow   │
# │     w/ preview)     │   visidata    │
# │                     │               │
# └─────────────────────┴───────────────┘
# =============================================================
new_win "FILES"
split_h 35 "FILES"       # pane 2 = right 35%

pane "FILES" 1
if   has yazi;   then send "FILES" "yazi"
elif has ranger; then send "FILES" "ranger"
elif has nnn;    then send "FILES" "nnn"
else                  send "FILES" "echo '  install: brew install yazi'"
fi
# pane 1 stays as shell for bat/glow/visidata

# =============================================================
# WINDOW 2: RECON  ·  OSINT & Enumeration
# ┌──────────────────┬──────────────────┐
# │        0         │        2         │
# │  amass/subfind/  │  sherlock/maigret│
# │  theharvester/   │  dnstwist/fierce │
# │  recon-ng/bbot   │  dnsx/httpx      │
# ├──────────────────┴──────────────────┤
# │                  1                  │
# │       jq · fx · gron · yq · miller  │
# └─────────────────────────────────────┘
# =============================================================
new_win "RECON"
split_v 28 "RECON.1"     # pane 2 = bottom 28%
pane "RECON" 1
split_h 50 "RECON.1"     # pane 3 = top-right

pane "RECON" 3
send "RECON" "echo '  Tools: sherlock · maigret · dnstwist · dnsx · httpx · fierce · ncrack'"
pane "RECON" 2
send "RECON" "echo '  Parse: jq · fx · gron · yq · htmlq · miller · dasel · dsq'"
pane "RECON" 1
send "RECON" "echo '  Tools: amass · subfinder · theharvester · bbot · recon-ng · maigret · trufflehog'"

# =============================================================
# WINDOW 3: SCAN  ·  Active Pentesting
# ┌──────────────────┬──────────────────┐
# │        0         │        2         │
# │  nmap/masscan/   │  gobuster/ffuf/  │
# │  rustscan/hydra  │  feroxbuster/    │
# │  hashcat/sqlmap  │  nikto/nuclei    │
# ├──────────────────┴──────────────────┤
# │                  1                  │
# │      httpx · httpie · curl · socat  │
# └─────────────────────────────────────┘
# =============================================================
new_win "SCAN"
split_v 28 "SCAN.1"      # pane 2 = bottom 28%
pane "SCAN" 1
split_h 50 "SCAN.1"      # pane 3 = top-right

pane "SCAN" 3
send "SCAN" "echo '  Tools: gobuster · ffuf · feroxbuster · nikto · wpscan · nuclei · sqlmap'"
pane "SCAN" 2
send "SCAN" "echo '  HTTP: httpx · httpie · curl · socat · proxychains-ng · netcat'"
pane "SCAN" 1
send "SCAN" "echo '  Tools: nmap · masscan · rustscan · hydra · john-jumbo · hashcat · aircrack-ng'"

# =============================================================
# WINDOW 4: NET  ·  Network Monitoring
# ┌─────────────────────────────────────┐
# │                  0                  │
# │             bandwhich               │
# ├──────────────────┬──────────────────┤
# │        1         │        2         │
# │  tcpdump/ngrep/  │  netscanner/     │
# │  tshark/socat    │  darkstat/mtr    │
# └──────────────────┴──────────────────┘
# =============================================================
new_win "NET"
split_v 40 "NET.1"       # pane 2 = bottom 40%
split_h 50 "NET.2"       # pane 3 = bottom-right

pane "NET" 3
if has netscanner; then
    send "NET" "sudo netscanner"
else
    send "NET" "echo '  Tools: netscanner · darkstat · mtr · doggo · whois · croc'"
fi

pane "NET" 2
send "NET" "echo '  Tools: tcpdump · ngrep · tshark · socat · tor · torsocks · proxychains-ng'"

pane "NET" 1
if has bandwhich; then
    send "NET" "sudo bandwhich"
else
    send "NET" "echo '  install: brew install bandwhich   (run with sudo)'"
fi

# =============================================================
# WINDOW 5: SYS  ·  System & Containers
# ┌─────────────────────────────────────┐
# │                  0                  │
# │                btop                 │
# ├──────────────────┬──────────────────┤
# │        1         │        2         │
# │     asitop       │    genact        │
# │  (Apple Silicon) │                  │
# └──────────────────┴──────────────────┘
# =============================================================
new_win "SYS"
split_v 35 "SYS.1"       # pane 2 = bottom 35%
split_h 50 "SYS.2"       # pane 3 = bottom-right

pane "SYS" 3
has genact && send "SYS" "genact" || send "SYS" "echo '  install: brew install genact'"

pane "SYS" 2
if has asitop; then
    send "SYS" "sudo asitop"
else
    send "SYS" "echo '  install: brew install asitop   (Apple Silicon perf monitor)'"
fi

pane "SYS" 1
has btop && send "SYS" "btop" || send "SYS" "htop"

# =============================================================
# WINDOW 6: AI  ·  AI Assistants & Pair Programming
# ┌───────────────────────┬─────────────────────┐
# │           0           │          1          │
# │   aichat / ollama /   │   aider / codex /   │
# │   mods / llm          │   gemini-cli        │
# └───────────────────────┴─────────────────────┘
# =============================================================
new_win "AI"
split_h 50 "AI"          # pane 2 = right 50%

pane "AI" 2
send "AI" "echo '  Pair programming: aider · codex · gemini-cli · claude'"

pane "AI" 1
if   has aichat; then send "AI" "aichat"
elif has ollama; then send "AI" "ollama run llama3"
elif has mods;   then send "AI" "mods"
elif has llm;    then send "AI" "llm"
else                  send "AI" "echo '  AI tools: aichat · ollama · mods · llm · fabric-ai · sgpt'"
fi


# =============================================================
# Land on MONK · editor pane
# =============================================================
tmux select-window -t "${SESSION}:MONK"
pane "MONK" 1

exec tmux attach-session -t "$SESSION"
