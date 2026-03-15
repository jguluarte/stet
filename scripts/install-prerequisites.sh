#!/usr/bin/env bash
# Check for and install system prerequisites for stet development.
# These are system-level tools that live outside devbox.
# Exits non-zero if any prerequisite is still missing after prompts.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

failed=0

ok()   { printf "${GREEN}ok${RESET}    %s\n" "$1"; }
miss() { printf "${YELLOW}missing${RESET} %s\n" "$1"; }
fail() { printf "${RED}FAIL${RESET}  %s\n" "$1"; failed=1; }

prompt_install() {
  local name="$1" docs_url="$2" curl_cmd="$3" brew_cmd="$4"

  printf "\n${BOLD}%s is not installed.${RESET}\n" "$name"
  printf "Install it now? [y/N] "
  read -r answer || answer="n"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    eval "$curl_cmd" || true
  else
    printf "\nInstall manually:\n"
    printf "  ${BOLD}Docs:${RESET}     %s\n" "$docs_url"
    printf "  ${BOLD}curl:${RESET}     %s\n" "$curl_cmd"
    printf "  ${BOLD}Homebrew:${RESET} %s\n" "$brew_cmd"
  fi
}

check_devbox() {
  if command -v devbox >/dev/null; then
    ok "devbox $(devbox version 2>/dev/null || echo '?')"
    return 0
  fi
  miss "devbox"
  prompt_install "Devbox" \
    "https://www.jetify.com/docs/devbox/installing-devbox" \
    "curl -fsSL https://get.jetify.com/devbox | bash" \
    "brew install jetify-com/devbox/devbox"
  command -v devbox >/dev/null || fail "devbox still not installed"
}

check_direnv() {
  if command -v direnv >/dev/null; then
    ok "direnv $(direnv version 2>/dev/null || echo '?')"
  else
    miss "direnv"
    prompt_install "direnv" \
      "https://direnv.net/docs/installation.html" \
      "curl -sfL https://direnv.net/install.sh | bash" \
      "brew install direnv"
    command -v direnv >/dev/null || { fail "direnv still not installed"; return; }
  fi
  check_direnv_hook
  check_direnv_allowed
}

check_direnv_allowed() {
  if direnv exec . true 2>/dev/null; then
    ok "direnv allowed"
    return
  fi
  miss "direnv not allowed for this repo"
  printf "\nRun ${BOLD}direnv allow${RESET} now? [y/N] "
  read -r answer || answer="n"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    direnv allow || true
    ok "direnv allowed"
  else
    printf "\nRun manually:\n"
    printf "  direnv allow\n"
  fi
}

check_direnv_hook() {
  local hook='eval "$(direnv hook zsh)"'
  local rc="$HOME/.zshrc"

  if grep -qF 'direnv hook zsh' "$rc" 2>/dev/null; then
    ok "direnv hook in $rc"
    return
  fi
  miss "direnv hook in $rc"
  printf "\n${BOLD}direnv needs a shell hook to work automatically.${RESET}\n"
  printf "Add the following to %s?\n" "$rc"
  printf "\n  %s\n\n" "$hook"
  printf "Add it now? [y/N] "
  read -r answer || answer="n"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    printf '\n%s\n' "$hook" >> "$rc"
    ok "added direnv hook to $rc"
  else
    printf "\nAdd this line to your shell rc file manually:\n"
    printf "  %s\n" "$hook"
  fi
}

check_ollama() {
  if command -v ollama >/dev/null; then
    ok "ollama $(ollama --version 2>/dev/null | awk '{print $NF}' || echo '?')"
    return 0
  fi
  miss "ollama"
  prompt_install "Ollama" \
    "https://ollama.com/download" \
    "curl -fsSL https://ollama.com/install.sh | sh" \
    "brew install ollama"
  command -v ollama >/dev/null || fail "ollama still not installed"
}

check_ollama_model() {
  if [[ -z "${STET_MODEL:-}" ]]; then
    fail "STET_MODEL is not set — run 'direnv allow' to load .envrc"
    return
  fi
  local model="$STET_MODEL"
  if ! command -v ollama >/dev/null; then
    fail "model check skipped — install ollama first"
    return
  fi
  if ollama show "$model" >/dev/null 2>&1; then
    ok "model $model"
    return
  fi
  miss "model $model"
  printf "\n${BOLD}Model %s is not pulled.${RESET}\n" "$model"
  printf "Pull it now? [y/N] "
  read -r answer || answer="n"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    ollama pull "$model" || true
  else
    printf "\nPull manually:\n"
    printf "  ollama pull %s\n" "$model"
  fi
  ollama show "$model" >/dev/null 2>&1 || fail "model $model not available"
}

printf "${BOLD}Checking prerequisites...${RESET}\n\n"

check_devbox
check_direnv
check_ollama
check_ollama_model

if [[ "$failed" -ne 0 ]]; then
  printf "\n${RED}${BOLD}Prerequisites not met.${RESET}\n"
  exit 1
fi

printf "\n${BOLD}Done.${RESET}\n"
