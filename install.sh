#!/usr/bin/env bash

set -e

echo "🧘 Installing Cyber-Monk Environment..."

# 1. Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew shellenv
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

# 2. Install Brew packages
echo "Installing Brew packages..."
brew bundle --file="$(dirname "$0")/Brewfile"

# 3. Create required directories
mkdir -p ~/.config
mkdir -p ~/.local/bin

# 4. Symlink dotfiles
echo "Linking dotfiles..."

ln -sf "$(dirname "$0")/dotfiles/.zshrc" ~/.zshrc
ln -sf "$(dirname "$0")/dotfiles/.tmux.conf" ~/.tmux.conf
ln -sf "$(dirname "$0")/dotfiles/ai" ~/.local/bin/ai

# Neovim config
mkdir -p ~/.config/nvim
ln -sf "$(dirname "$0")/dotfiles/nvim/init.lua" ~/.config/nvim/init.lua

chmod +x ~/.local/bin/ai

# iTerm2 preferences
echo "Configuring iTerm2..."
ITERM_PREFS="$(cd "$(dirname "$0")" && pwd)/dotfiles/iterm2"
# Copy plist so the current session picks it up immediately
cp "${ITERM_PREFS}/com.googlecode.iterm2.plist" \
    ~/Library/Preferences/com.googlecode.iterm2.plist
# Point iTerm2 at the dotfiles folder — future changes save back here automatically
defaults write com.googlecode.iterm2 PrefsCustomFolder "${ITERM_PREFS}"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
echo "  ✔  iTerm2 configured — restart iTerm2 to apply"

# 5. Install TPM (tmux plugin manager)
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Symlink cybermonk session launcher to PATH
chmod +x "$(dirname "$0")/cybermonk-session.sh"
ln -sf "$(dirname "$0")/cybermonk-session.sh" ~/.local/bin/cybermonk

# Install Claude slash command skills
echo "Installing Claude skills..."
mkdir -p ~/.claude/commands
cp "$(dirname "$0")/.claude/commands/morning-briefing.md" ~/.claude/commands/morning-briefing.md
echo "  ✔  morning-briefing skill"

# Install icalBuddy for calendar access (morning briefing)
if ! command -v icalBuddy &>/dev/null; then
    brew install ical-buddy 2>/dev/null \
        && echo "  ✔  ical-buddy" \
        || echo "  ⚠  ical-buddy install failed — run: brew install ical-buddy"
else
    echo "  ✔  ical-buddy already installed"
fi

echo ""
echo "Installing non-Homebrew tools..."

# -------------------------------------------------------
# Ruby gems — wpscan & whatweb
# Uses Homebrew Ruby for a current, non-system version
# -------------------------------------------------------
echo "  [gem] Installing Ruby tools..."
GEM_BIN="$(brew --prefix ruby)/bin/gem"
if [ -x "$GEM_BIN" ]; then
    "$GEM_BIN" install wpscan  2>/dev/null && echo "  ✔  wpscan"  || echo "  ⚠  wpscan failed"
    "$GEM_BIN" install whatweb 2>/dev/null && echo "  ✔  whatweb" || echo "  ⚠  whatweb failed"
else
    echo "  ⚠  Homebrew Ruby not found — skipping wpscan and whatweb"
fi

# -------------------------------------------------------
# Python tools via pipx (each in its own virtualenv)
# -------------------------------------------------------
echo "  [pipx] Installing Python tools..."
pipx ensurepath --force > /dev/null 2>&1 || true

PIPX_TOOLS=(
    "wafw00f"     # WAF detection tool
    "holehe"      # Check if email is registered on sites
    "netexec"     # Network pentesting Swiss army knife (crackmapexec successor)
    "wapiti3"     # Web application vulnerability scanner
    "dnsrecon"    # DNS enumeration and recon
    "shell-gpt"   # Shell-integrated GPT CLI (sgpt)
)

for tool in "${PIPX_TOOLS[@]%%#*}"; do
    tool="$(echo "$tool" | awk '{print $1}')"
    pipx install "$tool" --quiet 2>/dev/null \
        && echo "  ✔  $tool" \
        || echo "  ⚠  $tool failed (may already be installed or unavailable)"
done

# -------------------------------------------------------
# Rust tools via cargo
# -------------------------------------------------------
if command -v cargo &>/dev/null; then
    echo "  [cargo] Installing Rust tools..."
    cargo install tui-journal --quiet 2>/dev/null \
        && echo "  ✔  tui-journal" \
        || echo "  ⚠  tui-journal failed"
else
    echo "  ⚠  cargo not found — skipping tui-journal"
    echo "       Install Rust: https://rustup.rs"
fi

# -------------------------------------------------------
# Go tools via go install
# -------------------------------------------------------
if command -v go &>/dev/null; then
    echo "  [go] Installing Go tools..."
    go install github.com/jmhobbs/terminal-parrot@latest 2>/dev/null \
        && echo "  ✔  terminal-parrot" \
        || echo "  ⚠  terminal-parrot failed"
else
    echo "  ⚠  go not found — skipping terminal-parrot"
    echo "       Install Go: brew install go"
fi

# -------------------------------------------------------
# Metasploit — official Rapid7 installer
# -------------------------------------------------------
if command -v msfconsole &>/dev/null; then
    echo "  ✔  metasploit already installed"
else
    echo "  [metasploit] Running official Rapid7 installer..."
    curl -s https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb \
        -o /tmp/msfinstall \
    && chmod 755 /tmp/msfinstall \
    && /tmp/msfinstall \
    && echo "  ✔  metasploit" \
    || echo "  ⚠  metasploit install failed — try manually: https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html"
fi

echo ""
echo "🧘 Cyber-Monk installed."
echo "Restart terminal or run: source ~/.zshrc"