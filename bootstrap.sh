#!/usr/bin/env bash
#
# Fresh-Mac bootstrap. Installs everything the playbook needs, then runs it.
#
# On a brand-new Mac:
#   1. Sign into the App Store (for mas apps).
#   2. Get this repo (git clone, or download zip & unzip).
#   3. cd into it and run:  ./bootstrap.sh
#
# Safe to re-run: every step is skipped if already satisfied.

set -euo pipefail

# Always run from the repo root (this script's dir).
cd "$(dirname "${BASH_SOURCE[0]}")"

bold() { printf "\033[1m==> %s\033[0m\n" "$1"; }

# 1. Xcode Command Line Tools (git, compilers — a fresh Mac has none).
if ! xcode-select -p >/dev/null 2>&1; then
  bold "Installing Xcode Command Line Tools (accept the GUI prompt)..."
  xcode-select --install
  # Wait until the user finishes the installer dialog.
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  bold "Command Line Tools installed."
else
  bold "Command Line Tools already present."
fi

# 2. Homebrew.
if ! command -v brew >/dev/null 2>&1; then
  bold "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  bold "Homebrew already installed."
fi

# Load brew into this shell (Apple Silicon vs Intel paths).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 3. Ansible.
if ! command -v ansible-playbook >/dev/null 2>&1; then
  bold "Installing Ansible..."
  brew install ansible
else
  bold "Ansible already installed."
fi

# 4. Galaxy requirements (roles + collections from requirements.yml).
bold "Installing Ansible Galaxy roles & collections..."
ansible-galaxy role install -r requirements.yml
ansible-galaxy collection install -r requirements.yml

# 5. Run the playbook (asks for your login/sudo password via -K).
bold "Running the playbook..."
ansible-playbook main.yml -K

bold "Done. Some macOS settings need a logout/login to fully apply."
